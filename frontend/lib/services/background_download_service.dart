import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_background_service/flutter_background_service.dart';

/// Notification channel used for the persistent foreground-service
/// notification. Must match a channel already created via
/// flutter_local_notifications (see DownloadService.init) since Android
/// requires the channel to exist before it can be referenced here.
const String kDownloadServiceNotificationChannelId = 'download_progress_channel';

/// Sets up the Android foreground service that performs course downloads
/// (video + material) so they keep running after the app is closed or
/// swiped from Recents. Call once, early in main(), before any downloads
/// are queued. No-op on non-Android platforms.
Future<void> initializeBackgroundDownloadService() async {
  if (kIsWeb || !Platform.isAndroid) return;

  final service = FlutterBackgroundService();
  await service.configure(
    androidConfiguration: AndroidConfiguration(
      onStart: onDownloadServiceStart,
      autoStart: false,
      isForegroundMode: true,
      notificationChannelId: kDownloadServiceNotificationChannelId,
      initialNotificationTitle: 'Downloads',
      initialNotificationContent: 'Preparing to download…',
      foregroundServiceNotificationId: 445566,
      foregroundServiceTypes: [AndroidForegroundType.dataSync],
    ),
    iosConfiguration: IosConfiguration(autoStart: false),
  );
}

/// Thin client used by DownloadService to talk to the background isolate.
class BackgroundDownloadClient {
  final FlutterBackgroundService _service = FlutterBackgroundService();

  Stream<Map<String, dynamic>?> get onProgress => _service.on('progress');
  Stream<Map<String, dynamic>?> get onComplete => _service.on('complete');
  Stream<Map<String, dynamic>?> get onError => _service.on('error');

  Future<void> ensureRunning() async {
    if (!await _service.isRunning()) {
      await _service.startService();
      // Give the isolate a brief moment to spin up and attach its
      // service.on(...) listeners before we send it work.
      await Future.delayed(const Duration(milliseconds: 300));
    }
  }

  Future<void> enqueue({
    required String taskId,
    required String url,
    required String filePath,
    required int downloadedBytes,
    required String title,
  }) async {
    await ensureRunning();
    _service.invoke('enqueue', {
      'taskId': taskId,
      'url': url,
      'filePath': filePath,
      'downloadedBytes': downloadedBytes,
      'title': title,
    });
  }

  void cancel(String taskId) {
    _service.invoke('cancel', {'taskId': taskId});
  }
}

class _DownloadTask {
  _DownloadTask({
    required this.taskId,
    required this.url,
    required this.filePath,
    required this.downloadedBytes,
    required this.title,
  });

  final String taskId;
  final String url;
  final String filePath;
  final int downloadedBytes;
  final String title;

  factory _DownloadTask.fromMap(Map<String, dynamic> map) => _DownloadTask(
        taskId: map['taskId'] as String,
        url: map['url'] as String,
        filePath: map['filePath'] as String,
        downloadedBytes: (map['downloadedBytes'] as num?)?.toInt() ?? 0,
        title: map['title'] as String? ?? 'Download',
      );
}

/// Entry point executed inside the foreground service's own isolate. Keeps
/// running (and keeps the process alive via stopWithTask="false") for as
/// long as there is queued work, then stops itself.
@pragma('vm:entry-point')
void onDownloadServiceStart(ServiceInstance service) async {
  DartPluginRegistrant.ensureInitialized();

  final dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30),
    receiveTimeout: const Duration(minutes: 60),
    sendTimeout: const Duration(seconds: 30),
    headers: {'Accept-Encoding': 'gzip'},
  ));

  final List<_DownloadTask> queue = [];
  final Set<String> cancelledTaskIds = {};
  String? activeTaskId;
  CancelToken? activeCancelToken;

  void updateNotification(String content) {
    if (service is AndroidServiceInstance) {
      service.setForegroundNotificationInfo(title: 'Downloads', content: content);
    }
  }

  Future<void> processQueue() async {
    if (activeTaskId != null) return;

    if (queue.isEmpty) {
      updateNotification('All downloads complete');
      await Future.delayed(const Duration(seconds: 2));
      if (queue.isEmpty && activeTaskId == null) {
        service.stopSelf();
      }
      return;
    }

    final task = queue.removeAt(0);
    activeTaskId = task.taskId;

    int maxRetries = 5;
    int retryDelayMs = 3000;

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      if (cancelledTaskIds.remove(task.taskId)) {
        service.invoke('error', {'taskId': task.taskId, 'message': 'Cancelled', 'cancelled': true});
        break;
      }

      final cancelToken = CancelToken();
      activeCancelToken = cancelToken;

      try {
        updateNotification('Downloading: ${task.title}');

        final response = await dio.get<ResponseBody>(
          task.url,
          options: Options(
            responseType: ResponseType.stream,
            followRedirects: true,
            validateStatus: (status) => status == 200 || status == 206,
            headers: {
              if (task.downloadedBytes > 0) 'range': 'bytes=${task.downloadedBytes}-',
            },
          ),
          cancelToken: cancelToken,
        );

        final file = File(task.filePath);
        final isResuming = task.downloadedBytes > 0 && response.statusCode == 206;
        int received = isResuming ? task.downloadedBytes : 0;
        final sink = file.openWrite(mode: isResuming ? FileMode.append : FileMode.write);

        final contentLength = int.tryParse(response.headers.value('content-length') ?? '-1');
        final total = (contentLength != null && contentLength != -1) ? contentLength + received : -1;
        double lastReportedProgress = -2;

        try {
          await response.data!.stream.listen(
            (chunk) {
              sink.add(chunk);
              received += chunk.length;
              if (total != -1) {
                final progress = received / total;
                if (progress - lastReportedProgress >= 0.01 || progress >= 1.0) {
                  lastReportedProgress = progress;
                  service.invoke('progress', {'taskId': task.taskId, 'progress': progress});
                  updateNotification('${task.title} — ${(progress * 100).floor()}%');
                }
              } else {
                service.invoke('progress', {'taskId': task.taskId, 'progress': -1.0});
              }
            },
            onError: (e) => throw e,
            cancelOnError: true,
          ).asFuture();
        } finally {
          await sink.close();
        }

        service.invoke('complete', {'taskId': task.taskId, 'filePath': task.filePath});
        break;
      } on DioException catch (e) {
        if (CancelToken.isCancel(e)) {
          service.invoke('error', {'taskId': task.taskId, 'message': 'Cancelled', 'cancelled': true});
          break;
        }

        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          retryDelayMs *= 2;
          continue;
        }

        String message = 'Download failed';
        if (e.response?.statusCode == 403) {
          message = 'Access denied. Please check your subscription or login again.';
        } else if (e.response?.statusCode == 401) {
          message = 'Authentication failed. Please log in again.';
        } else if (e.response?.statusCode == 404) {
          message = 'File not found. It may have been removed.';
        } else if (e.type == DioExceptionType.connectionTimeout ||
            e.type == DioExceptionType.receiveTimeout) {
          message = 'Connection timeout. Please check your internet connection.';
        } else if (e.type == DioExceptionType.connectionError) {
          message = 'Network error. Please check your internet connection.';
        }
        service.invoke('error', {'taskId': task.taskId, 'message': message, 'cancelled': false});
        break;
      } catch (e) {
        if (attempt < maxRetries) {
          await Future.delayed(Duration(milliseconds: retryDelayMs));
          retryDelayMs *= 2;
          continue;
        }
        service.invoke('error', {'taskId': task.taskId, 'message': e.toString(), 'cancelled': false});
        break;
      }
    }

    activeTaskId = null;
    activeCancelToken = null;
    unawaited(processQueue());
  }

  service.on('enqueue').listen((event) {
    if (event == null) return;
    queue.add(_DownloadTask.fromMap(event));
    unawaited(processQueue());
  });

  service.on('cancel').listen((event) {
    final taskId = event?['taskId'] as String?;
    if (taskId == null) return;
    if (taskId == activeTaskId) {
      activeCancelToken?.cancel();
    } else if (queue.any((t) => t.taskId == taskId)) {
      queue.removeWhere((t) => t.taskId == taskId);
      service.invoke('error', {'taskId': taskId, 'message': 'Cancelled', 'cancelled': true});
    } else {
      // Not active and not queued yet (race with enqueue) — remember it so
      // it's skipped the moment it's dequeued.
      cancelledTaskIds.add(taskId);
    }
  });

  service.on('stopService').listen((event) {
    service.stopSelf();
  });
}
