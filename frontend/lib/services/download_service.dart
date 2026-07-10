import 'dart:async';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:excellencecoachinghub/models/download.dart';
import 'dart:convert';
import 'package:path/path.dart' as p;
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:excellencecoachinghub/services/background_download_service.dart';

class DownloadService extends ChangeNotifier {
  static final DownloadService _instance = DownloadService._internal();
  factory DownloadService() => _instance;
  DownloadService._internal();

  @override
  void notifyListeners() {
    // Safely notify listeners, ignoring errors when widgets are disposed
    try {
      super.notifyListeners();
    } catch (e) {
      // Ignore errors when widgets are disposed during active downloads
      print('DownloadService: Error notifying listeners (widget likely disposed): $e');
    }
  }

  final Dio _dio = Dio(BaseOptions(
    connectTimeout: const Duration(seconds: 30), // Reduced for faster connection
    receiveTimeout: const Duration(minutes: 60), // Reduced for faster downloads
    sendTimeout: const Duration(seconds: 30), // Reduced for faster uploads
    headers: {
      'Accept-Encoding': 'gzip', // Enable compression for faster transfers
    },
  ));

  final Map<String, Download> _downloads = {}; // Key: lessonId
  final Map<String, CancelToken> _cancelTokens = {}; // Key: lessonId
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final Map<String, int> _lastNotificationProgress = {}; // Key: lessonId, Value: last progress shown
  final Map<String, int> _notificationIds = {}; // Key: lessonId, Value: notification ID
  final Map<String, String> _filenameToLessonId = {}; // Key: filename (without ext), Value: lessonId
  static const String _downloadsKey = 'downloaded_videos';
  static const String _filenameMapKey = 'filename_to_lesson_id_map';
  bool _isInitialized = false;
  Future<void>? _initFuture;

  // On Android, actual transfers run in a foreground service (see
  // background_download_service.dart) so they survive the app being closed
  // or swiped from Recents. Other platforms keep downloading in-process via
  // the direct Dio methods below (background survival isn't attempted there).
  bool get _useBackgroundService =>
      !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  BackgroundDownloadClient? _bgClient;
  StreamSubscription<Map<String, dynamic>?>? _bgProgressSub;
  StreamSubscription<Map<String, dynamic>?>? _bgCompleteSub;
  StreamSubscription<Map<String, dynamic>?>? _bgErrorSub;

  // Per-task (taskId = lessonId for videos, "material_$lessonId" for
  // materials) bookkeeping for downloads running in the background service.
  final Map<String, Completer<String>> _taskCompleters = {};
  final Map<String, void Function(double)?> _taskOnProgress = {};
  final Map<String, void Function()?> _taskOnSuccess = {};
  final Map<String, void Function(String)?> _taskOnError = {};

  // Optional callback: called when a download completes or fails so the
  // caller (e.g. NotificationNotifier via the provider) can persist the
  // notification to the backend and surface it in the Notifications page.
  Future<void> Function({required String title, required String message, required String type})? onNotificationCreated;

  // Initialize the service and load persisted downloads
  Future<void> init() async {
    if (_isInitialized) {
      print('Download service already initialized');
      return;
    }

    print('Initializing download service...');

    try {
      // Initialize local notifications
      if (!kIsWeb && defaultTargetPlatform != TargetPlatform.windows) {
        const AndroidInitializationSettings initializationSettingsAndroid =
            AndroidInitializationSettings('@mipmap/ic_launcher');

        final DarwinInitializationSettings initializationSettingsIOS =
            DarwinInitializationSettings(
          requestAlertPermission: true,
          requestBadgePermission: true,
          requestSoundPermission: true,
        );

        final InitializationSettings initializationSettings = InitializationSettings(
          android: initializationSettingsAndroid,
          iOS: initializationSettingsIOS,
        );

        await _notifications.initialize(
          initializationSettings,
          onDidReceiveNotificationResponse: (NotificationResponse response) {
            // Handle notification tap
            print('Notification tapped: ${response.payload}');
          },
        );

        // Create download progress notification channel with higher importance
        const AndroidNotificationChannel progressChannel = AndroidNotificationChannel(
          'download_progress_channel',
          'Download Progress',
          description: 'Shows download progress notifications',
          importance: Importance.high,
          showBadge: true,
          playSound: false,
        );

        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(progressChannel);

        // Create high importance channel for completion/failure notifications
        const AndroidNotificationChannel highImportanceChannel = AndroidNotificationChannel(
          'high_importance_channel',
          'High Importance Notifications',
          description: 'This channel is used for important notifications.',
          importance: Importance.max,
          showBadge: true,
          playSound: true,
        );

        await _notifications
            .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
            ?.createNotificationChannel(highImportanceChannel);
      }

      _dio.interceptors.add(LogInterceptor(
        requestBody: false,
        responseBody: false,
        error: true,
        logPrint: (obj) => print('Dio: $obj'),
      ));
    } catch (e) {
      print('Error initializing notifications: $e');
      // Continue anyway - notifications are optional
    }

    if (_useBackgroundService) {
      try {
        await initializeBackgroundDownloadService();
        final client = BackgroundDownloadClient();
        _bgClient = client;
        _bgProgressSub = client.onProgress.listen(_handleBgProgress);
        _bgCompleteSub = client.onComplete.listen(_handleBgComplete);
        _bgErrorSub = client.onError.listen(_handleBgError);
      } catch (e) {
        print('Error initializing background download service: $e');
        _bgClient = null;
      }
    }

    // Always load from storage, even if other initialization fails
    try {
      await _loadFilenameMap();
      await _loadDownloadsFromStorage();
      print('Loaded ${_downloads.length} downloads from storage');
      await _scanForExistingDownloads();
      print('Scan complete. Total downloads now: ${_downloads.length}');
    } catch (e) {
      print('Error loading downloads from storage: $e');
      // Try to load from storage again with error handling
      try {
        await _loadDownloadsFromStorage();
        print('Retry: Loaded ${_downloads.length} downloads from storage');
      } catch (e2) {
        print('Retry failed: $e2');
      }
    }

    _isInitialized = true;
    print('Download service initialization complete');
  }

  // Ensure initialization before accessing downloads
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      _initFuture ??= init();
      await _initFuture;
    }
  }

  // Load the filename→lessonId map from shared prefs
  Future<void> _loadFilenameMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final json = prefs.getString(_filenameMapKey);
      if (json != null) {
        final Map<String, dynamic> decoded = jsonDecode(json);
        decoded.forEach((k, v) => _filenameToLessonId[k] = v as String);
      }
    } catch (e) {
      print('DownloadService: Error loading filename map: $e');
    }
  }

  // Save the filename→lessonId map to shared prefs
  Future<void> _saveFilenameMap() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_filenameMapKey, jsonEncode(_filenameToLessonId));
    } catch (e) {
      print('DownloadService: Error saving filename map: $e');
    }
  }

  // Show download progress notification
  Future<void> _showDownloadProgressNotification(String lessonId, String title, double progress) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    // Only update notification every 10% to avoid spam
    final progressPercent = (progress * 100).floor();
    final lastProgress = _lastNotificationProgress[lessonId] ?? 0;
    if (progressPercent - lastProgress < 10 && progress < 1.0) return;

    _lastNotificationProgress[lessonId] = progressPercent;

    final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'download_progress_channel',
      'Download Progress',
      channelDescription: 'Shows download progress notifications',
      importance: Importance.high,
      priority: Priority.high,
      showProgress: true,
      maxProgress: 100,
      progress: progressPercent,
      ongoing: true,
      autoCancel: false,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: false,
      presentBadge: true,
      presentSound: false,
    );

    final NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    final notificationId = _notificationIds[lessonId] ?? lessonId.hashCode;
    _notificationIds[lessonId] = notificationId;

    try {
      await _notifications.show(
        notificationId,
        'Downloading: $title',
        '$progressPercent% complete',
        platformDetails,
        payload: '/downloads',
      );
    } catch (e) {
      print('Error showing download progress notification: $e');
    }
  }

  // Show download completion notification
  Future<void> _showDownloadCompleteNotification(String lessonId, String title) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    // Cancel progress notification
    final notificationId = _notificationIds[lessonId];
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      _notificationIds.remove(lessonId);
      _lastNotificationProgress.remove(lessonId);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Download Complete',
        '$title is ready to watch',
        platformDetails,
        payload: '/downloads',
      );
    } catch (e) {
      print('Error showing download complete notification: $e');
    }
  }

  // Show download failed notification
  Future<void> _showDownloadFailedNotification(String lessonId, String title, String error) async {
    if (kIsWeb || defaultTargetPlatform == TargetPlatform.windows) return;

    // Cancel progress notification
    final notificationId = _notificationIds[lessonId];
    if (notificationId != null) {
      await _notifications.cancel(notificationId);
      _notificationIds.remove(lessonId);
      _lastNotificationProgress.remove(lessonId);
    }

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'high_importance_channel',
      'High Importance Notifications',
      channelDescription: 'This channel is used for important notifications.',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    try {
      await _notifications.show(
        DateTime.now().millisecondsSinceEpoch % 100000,
        'Download Failed',
        '$title: $error',
        platformDetails,
        payload: '/downloads',
      );
    } catch (e) {
      print('Error showing download failed notification: $e');
    }
  }

  // Scan for existing downloaded files and create records for them
  Future<void> _scanForExistingDownloads() async {
    try {
      final directory = await _getAppDirectory();
      final dir = Directory(directory);
      int created = 0;
      
      if (await dir.exists()) {
        final files = dir.listSync();
        
        for (final file in files) {
          if (file is File && file.path.endsWith('.mp4')) {
            final fileName = p.basenameWithoutExtension(file.path);
            final lessonId = _extractLessonIdFromFilename(fileName);
            
            if (lessonId != null && !_downloads.containsKey(lessonId)) {
              final download = Download(
                id: lessonId,
                lessonId: lessonId,
                fileName: fileName,
                originalTitle: fileName,
                localPath: file.path,
                url: '',
                type: DownloadType.video,
                downloadProgress: 1.0,
                isDownloading: false,
                status: DownloadStatus.completed,
              );
              _downloads[lessonId] = download;
              created++;
            }
          }
        }
        
        if (created > 0) {
          await _saveDownloadsToStorage();
          print('Created records for $created existing downloads');
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error scanning for existing downloads: $e');
    }
  }

  // Extract lesson ID from filename using stored map, hex pattern, or lesson_ prefix
  String? _extractLessonIdFromFilename(String filename) {
    // 1. Check stored filename→lessonId map (covers arbitrary filenames)
    if (_filenameToLessonId.containsKey(filename)) {
      return _filenameToLessonId[filename];
    }
    // 2. If filename IS a 24-char hex MongoDB ObjectId, use it directly
    if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(filename)) {
      return filename;
    }
    // 3. If filename starts with "lesson_" followed by a hex ID
    if (filename.startsWith('lesson_')) {
      final idPart = filename.substring(7);
      if (RegExp(r'^[0-9a-fA-F]{24}$').hasMatch(idPart)) {
        return idPart;
      }
    }
    return null;
  }

  // Load downloads from shared preferences
  Future<void> _loadDownloadsFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsJson = prefs.getString(_downloadsKey);
      
      if (downloadsJson != null) {
        final List<dynamic> downloadsList = json.decode(downloadsJson);
        for (final downloadJson in downloadsList) {
          final download = Download.fromJson(downloadJson);
          // Verify the file still exists before adding to memory
          final file = File(download.localPath);
          if (await file.exists()) {
            // Reset isDownloading status on load
            _downloads[download.lessonId] = download.copyWith(
              isDownloading: false,
              status: download.status == DownloadStatus.downloading 
                  ? DownloadStatus.paused 
                  : download.status,
            );
          } else {
            // File doesn't exist anymore, remove from storage
            await _removeDownloadFromStorage(download.lessonId);
          }
        }
        notifyListeners();
      }
    } catch (e) {
      print('Error loading downloads from storage: $e');
      // Clear the downloads map if there's an error
      _downloads.clear();
    }
  }

  // Save downloads to shared preferences
  Future<void> _saveDownloadsToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final downloadsList = _downloads.values
          .map((download) => download.toJson())
          .toList();
      await prefs.setString(_downloadsKey, json.encode(downloadsList));
    } catch (e) {
      print('Error saving downloads to storage: $e');
    }
  }

  // Remove a specific download from storage
  Future<void> _removeDownloadFromStorage(String lessonId) async {
    try {
      _downloads.remove(lessonId);
      await _saveDownloadsToStorage();
      notifyListeners();
    } catch (e) {
      print('Error removing download from storage: $e');
    }
  }

  // Get app documents directory
  Future<String> _getAppDirectory() async {
    final directory = await getApplicationDocumentsDirectory();
    return directory.path;
  }

  // ─────────────────────────────────────────────
  //  Background-service event handlers
  //  (taskId == lessonId for videos, "material_$lessonId" for materials)
  // ─────────────────────────────────────────────
  void _handleBgProgress(Map<String, dynamic>? event) {
    if (event == null) return;
    final taskId = event['taskId'] as String?;
    if (taskId == null) return;
    final progress = (event['progress'] as num?)?.toDouble() ?? 0.0;

    final download = _downloads[taskId];
    if (download != null) {
      _downloads[taskId] = download.copyWith(downloadProgress: progress);
      notifyListeners();
      if (progress >= 0) {
        _showDownloadProgressNotification(taskId, download.originalTitle, progress);
      }
      if (progress >= 1.0) {
        _saveDownloadsToStorage();
      }
    }
    _taskOnProgress[taskId]?.call(progress);
  }

  void _handleBgComplete(Map<String, dynamic>? event) async {
    if (event == null) return;
    final taskId = event['taskId'] as String?;
    if (taskId == null) return;
    final filePath = event['filePath'] as String? ?? _downloads[taskId]?.localPath ?? '';

    final download = _downloads[taskId];
    if (download != null) {
      _downloads[taskId] = download.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        status: DownloadStatus.completed,
      );
      notifyListeners();
      await _saveDownloadsToStorage();
      await _showDownloadCompleteNotification(taskId, download.originalTitle);
      await onNotificationCreated?.call(
        title: 'Download Complete',
        message: '${download.originalTitle} is ready to watch',
        type: 'success',
      );
    }

    _taskOnSuccess[taskId]?.call();
    _taskCompleters.remove(taskId)?.complete(filePath);
    _taskOnProgress.remove(taskId);
    _taskOnSuccess.remove(taskId);
    _taskOnError.remove(taskId);
  }

  void _handleBgError(Map<String, dynamic>? event) async {
    if (event == null) return;
    final taskId = event['taskId'] as String?;
    if (taskId == null) return;
    final message = event['message'] as String? ?? 'Download failed';
    final cancelled = event['cancelled'] == true;

    final download = _downloads[taskId];
    if (download != null) {
      _downloads[taskId] = cancelled
          ? download.copyWith(isDownloading: false, status: DownloadStatus.paused)
          : download.copyWith(isDownloading: false, status: DownloadStatus.failed, error: message);
      notifyListeners();
      await _saveDownloadsToStorage();
      if (!cancelled) {
        await _showDownloadFailedNotification(taskId, download.originalTitle, message);
        await onNotificationCreated?.call(
          title: 'Download Failed',
          message: '${download.originalTitle}: $message',
          type: 'error',
        );
      }
    }

    if (cancelled) {
      _taskCompleters.remove(taskId)?.complete(download?.localPath ?? '');
    } else {
      _taskOnError[taskId]?.call(message);
      _taskCompleters.remove(taskId)?.completeError(Exception(message));
    }
    _taskOnProgress.remove(taskId);
    _taskOnSuccess.remove(taskId);
  }

  // Download video with progress tracking and pause/resume support
  Future<String> downloadVideo({
    required String url,
    required String fileName,
    required String originalTitle,
    required String lessonId,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    if (_useBackgroundService && _bgClient != null) {
      return _downloadVideoViaService(
        url: url,
        fileName: fileName,
        originalTitle: originalTitle,
        lessonId: lessonId,
        onProgress: onProgress,
        onSuccess: onSuccess,
        onError: onError,
      );
    }
    return _downloadVideoDirect(
      url: url,
      fileName: fileName,
      originalTitle: originalTitle,
      lessonId: lessonId,
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  // Queues a video download with the Android foreground service so it keeps
  // running after the app is closed. The returned Future completes (or
  // throws) when the service reports the task done/failed.
  Future<String> _downloadVideoViaService({
    required String url,
    required String fileName,
    required String originalTitle,
    required String lessonId,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    final directory = await _getAppDirectory();
    final filePath = p.join(directory, "$fileName.mp4");

    final file = File(filePath);
    final existing = _downloads[lessonId];
    if (await file.exists() && existing != null && existing.status == DownloadStatus.completed) {
      onProgress?.call(1.0);
      onSuccess?.call();
      return filePath;
    }

    int downloadedBytes = 0;
    if (await file.exists()) {
      downloadedBytes = await file.length();
    }

    final download = Download(
      id: lessonId,
      lessonId: lessonId,
      fileName: fileName,
      originalTitle: originalTitle,
      localPath: filePath,
      url: url,
      type: DownloadType.video,
      downloadProgress: existing?.downloadProgress ?? (downloadedBytes > 0 ? -1.0 : 0.0),
      isDownloading: true,
      status: DownloadStatus.downloading,
    );
    _downloads[lessonId] = download;
    _filenameToLessonId[fileName] = lessonId;
    await _saveFilenameMap();
    notifyListeners();
    await _saveDownloadsToStorage();

    final completer = Completer<String>();
    _taskCompleters[lessonId] = completer;
    _taskOnProgress[lessonId] = onProgress;
    _taskOnSuccess[lessonId] = onSuccess;
    _taskOnError[lessonId] = onError;

    try {
      await _bgClient!.enqueue(
        taskId: lessonId,
        url: url,
        filePath: filePath,
        downloadedBytes: downloadedBytes,
        title: originalTitle,
      );
    } catch (e) {
      _taskCompleters.remove(lessonId);
      _taskOnProgress.remove(lessonId);
      _taskOnSuccess.remove(lessonId);
      _taskOnError.remove(lessonId);
      _downloads[lessonId] = download.copyWith(isDownloading: false, status: DownloadStatus.failed, error: e.toString());
      notifyListeners();
      await _saveDownloadsToStorage();
      onError?.call(e.toString());
      rethrow;
    }

    return completer.future;
  }

  // Original in-process download path, used on platforms where the
  // foreground service isn't available (iOS, desktop, web).
  Future<String> _downloadVideoDirect({
    required String url,
    required String fileName,
    required String originalTitle,
    required String lessonId,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    print('Starting download video in service');
    print('URL: $url');
    print('Filename: $fileName');
    print('Lesson ID: $lessonId');
      
    int maxRetries = 5; // Increased from 3 to 5 for slow connections
    int retryDelay = 3000; // Increased from 2 to 3 seconds

    for (int attempt = 0; attempt <= maxRetries; attempt++) {
      try {
        print('Download attempt ${attempt + 1} for lesson: $lessonId');
        
        final directory = await _getAppDirectory();
        print('Download directory: $directory (Attempt ${attempt + 1})');
        final filePath = p.join(directory, "$fileName.mp4");
        print('File path: $filePath');
    
        // Check if file already exists and is complete
        final file = File(filePath);
        if (await file.exists()) {
          final download = _downloads[lessonId];
          if (download != null && download.status == DownloadStatus.completed) {
            print('File already exists and is complete');
            onProgress?.call(1.0);
            onSuccess?.call();
            return filePath;
          }
        }

        // Check for partial download
        int downloadedBytes = 0;
        if (await file.exists()) {
          downloadedBytes = await file.length();
        }

        // Create/Update download record
        final download = Download(
          id: lessonId,
          lessonId: lessonId,
          fileName: fileName,
          originalTitle: originalTitle,
          localPath: filePath,
          url: url,
          type: DownloadType.video, // Default to video type
          downloadProgress: _downloads[lessonId]?.downloadProgress ?? (downloadedBytes > 0 ? -1.0 : 0.0), // -1 means unknown if we have file but no total
          isDownloading: true,
          status: DownloadStatus.downloading,
        );
        _downloads[lessonId] = download;
        // Persist filename→lessonId so scans can resolve this file in the future
        _filenameToLessonId[fileName] = lessonId;
        await _saveFilenameMap();
        notifyListeners();
        await _saveDownloadsToStorage();

        print('Download record created with localPath: $filePath');

        final cancelToken = CancelToken();
        _cancelTokens[lessonId] = cancelToken;

        print('Starting actual download with Dio. Range: bytes=$downloadedBytes-');
        
        try {
          // Note: the video/material URL is a direct, unsigned CloudFront/S3 URL,
          // not an API endpoint. Attaching the app's Firebase Authorization header
          // here makes CloudFront/S3 try to parse it as an AWS signature and reject
          // the request with 403 Access Denied, so no auth headers are sent here.

          // First, get the file size to enable chunked downloading
          int? totalFileSize;
          try {
            final headResponse = await _dio.head(
              url,
              options: Options(
                validateStatus: (status) => status == 200 || status == 206,
              ),
              cancelToken: cancelToken,
            );
            totalFileSize = int.tryParse(headResponse.headers.value('content-length') ?? '-1');
            print('Total file size: $totalFileSize bytes');
          } catch (e) {
            print('Could not get file size, falling back to single stream: $e');
          }

          // Use single stream download for reliability (chunked download has concurrency issues)
          print('Using single stream download for reliability');
          await _downloadSingleStream(
            url: url,
            filePath: filePath,
            downloadedBytes: downloadedBytes,
            cancelToken: cancelToken,
            download: download,
            lessonId: lessonId,
            onProgress: onProgress,
          );
      
          print('Download completed successfully');
          _downloads[lessonId] = download.copyWith(
            isDownloading: false,
            downloadProgress: 1.0,
            status: DownloadStatus.completed,
          );
          _cancelTokens.remove(lessonId);
          notifyListeners();
          await _saveDownloadsToStorage();
          await _showDownloadCompleteNotification(lessonId, originalTitle);
          await onNotificationCreated?.call(
            title: 'Download Complete',
            message: '$originalTitle is ready to watch',
            type: 'success',
          );
          onSuccess?.call();

          return filePath;
        } on DioException catch (e) {
          if (CancelToken.isCancel(e)) {
            print('Download paused: $lessonId');
            _downloads[lessonId] = download.copyWith(
              isDownloading: false,
              status: DownloadStatus.paused,
            );
            notifyListeners();
            await _saveDownloadsToStorage();
            return filePath;
          }
          
          // Handle specific HTTP errors
          String errorMessage = 'Download failed';
          if (e.response?.statusCode == 403) {
            errorMessage = 'Access denied. Please check your subscription or login again.';
          } else if (e.response?.statusCode == 401) {
            errorMessage = 'Authentication failed. Please log in again.';
          } else if (e.response?.statusCode == 404) {
            errorMessage = 'Video not found. It may have been removed.';
          } else if (e.type == DioExceptionType.connectionTimeout) {
            errorMessage = 'Connection timeout. Please check your internet connection.';
          } else if (e.type == DioExceptionType.receiveTimeout) {
            errorMessage = 'Download timeout. Please try again.';
          } else if (e.type == DioExceptionType.connectionError) {
            errorMessage = 'Network error. Please check your internet connection.';
          }
          
          print('Download DioException: ${e.type}, Status: ${e.response?.statusCode}, Message: $errorMessage');
          throw Exception(errorMessage);
        }
      } catch (e) {
        print('Download attempt ${attempt + 1} failed: $e');
        
        // Don't retry if it was cancelled
        if (e is DioException && CancelToken.isCancel(e)) {
          rethrow;
        }

        if (attempt < maxRetries) {
          print('Retrying in ${retryDelay / 1000} seconds...');
          await Future.delayed(Duration(milliseconds: retryDelay));
          retryDelay *= 2; // Exponential backoff
          continue;
        }

        print('All download attempts failed.');
        if (_downloads.containsKey(lessonId)) {
          _downloads[lessonId] = _downloads[lessonId]!.copyWith(
            isDownloading: false,
            status: DownloadStatus.failed,
            error: e.toString(),
          );
          notifyListeners();
          await _saveDownloadsToStorage();
          await _showDownloadFailedNotification(lessonId, originalTitle, e.toString());
          await onNotificationCreated?.call(
            title: 'Download Failed',
            message: '$originalTitle: ${e.toString()}',
            type: 'error',
          );
        }
        onError?.call(e.toString());
        rethrow;
      }
    }
    return ''; // Should never reach here due to rethrows and returns inside loop
  }

  // Single stream download (reliable method for all file sizes)
  Future<void> _downloadSingleStream({
    required String url,
    required String filePath,
    required int downloadedBytes,
    required CancelToken cancelToken,
    required Download download,
    required String lessonId,
    Function(double)? onProgress,
  }) async {
    final response = await _dio.get<ResponseBody>(
      url,
      options: Options(
        responseType: ResponseType.stream,
        followRedirects: true,
        validateStatus: (status) => status == 200 || status == 206,
        headers: {
          if (downloadedBytes > 0) 'range': 'bytes=$downloadedBytes-',
        },
      ),
      cancelToken: cancelToken,
    );

    final File file = File(filePath);
    
    // If we requested a range but got 200 (Full Content), it means the server 
    // doesn't support Range or the file changed. We must restart from 0.
    bool isResuming = downloadedBytes > 0 && response.statusCode == 206;
    int currentReceived = isResuming ? downloadedBytes : 0;
    
    final IOSink raf = file.openWrite(mode: isResuming ? FileMode.append : FileMode.write);

    try {
      int? contentLength = int.tryParse(response.headers.value('content-length') ?? '-1');
      int actualTotal = (contentLength != null && contentLength != -1) ? (contentLength + currentReceived) : -1;

      await response.data!.stream.listen(
        (List<int> chunk) {
          raf.add(chunk);
          currentReceived += chunk.length;

          if (actualTotal != -1) {
            double progress = currentReceived / actualTotal;

            // Update progress more frequently for smoother UI (every 1% instead of 2%)
            if (progress > (download.downloadProgress + 0.01) || progress >= 1.0 || progress < download.downloadProgress) {
              download.downloadProgress = progress;
              _downloads[lessonId] = download.copyWith(downloadProgress: progress);
              onProgress?.call(progress);
              notifyListeners();
              _showDownloadProgressNotification(lessonId, download.originalTitle, progress);
              
              // Save to storage on major milestones (every 5%) or completion for better performance
              if (progress >= 1.0 || (progress * 20).floor() > ((download.downloadProgress - 0.05) * 20).floor()) {
                _saveDownloadsToStorage(); 
              }
            }
          } else {
            // Indeterminate progress - use a pulsing pattern to show activity
            if (download.downloadProgress != -1.0) {
              download.downloadProgress = -1.0;
              _downloads[lessonId] = download.copyWith(downloadProgress: -1.0);
              onProgress?.call(-1.0);
              notifyListeners();
            }
          }
        },
        onError: (e) {
          if (CancelToken.isCancel(e)) return;
          throw e;
        },
        cancelOnError: true,
      ).asFuture();
    } finally {
      await raf.close();
    }
  }

  // Pause a download
  void pauseDownload(String lessonId) {
    if (_useBackgroundService && _bgClient != null && _taskCompleters.containsKey(lessonId)) {
      _bgClient!.cancel(lessonId);
      return;
    }
    if (_cancelTokens.containsKey(lessonId)) {
      _cancelTokens[lessonId]!.cancel();
      _cancelTokens.remove(lessonId);
    }
  }

  // Resume a download
  Future<void> resumeDownload(String lessonId, {String? newUrl}) async {
    final download = _downloads[lessonId];
    if (download != null && (download.status == DownloadStatus.paused || download.status == DownloadStatus.failed)) {
      await downloadVideo(
        url: newUrl ?? download.url,
        fileName: download.fileName,
        originalTitle: download.originalTitle,
        lessonId: download.lessonId,
      );
    }
  }

  // Check if video is downloaded locally by lesson ID
  Future<bool> isVideoDownloadedByLessonId(String lessonId) async {
    try {
      final download = _downloads[lessonId];
      if (download != null) {
        return download.status == DownloadStatus.completed;
      }
      return false;
    } catch (e) {
      return false;
    }
  }
  
  // Check if video is downloaded locally by filename
  Future<bool> isVideoDownloaded(String fileName) async {
    try {
      final directory = await _getAppDirectory();
      final filePath = p.join(directory, "$fileName.mp4");
      final file = File(filePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  // Get local file path for a downloaded video ONLY if it's fully completed
  Future<String?> getLocalVideoPathById(String lessonId) async {
    try {
      final download = _downloads[lessonId];
      if (download != null && download.status == DownloadStatus.completed) {
        final file = File(download.localPath);
        if (await file.exists()) {
          return download.localPath;
        }
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get local file path for a downloaded video by filename (legacy compatibility)
  Future<String?> getLocalVideoPath(String fileName) async {
    try {
      // Find download record by filename
      final download = _downloads.values.firstWhere(
        (d) => d.fileName == fileName && d.status == DownloadStatus.completed,
        orElse: () => throw Exception('Not found'),
      );
      
      final file = File(download.localPath);
      if (await file.exists()) {
        return download.localPath;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Get download status for a specific lesson
  Download? getDownloadStatus(String lessonId) {
    return _downloads[lessonId];
  }

  // Get all downloads
  List<Download> getAllDownloads() {
    // Ensure initialization is triggered (non-blocking)
    _ensureInitialized();
    return _downloads.values.toList();
  }

  // Delete a downloaded video
  Future<bool> deleteDownload(String lessonId) async {
    try {
      pauseDownload(lessonId); // Ensure it's not downloading
      
      final download = _downloads[lessonId];
      if (download != null) {
        final file = File(download.localPath);
        
        if (await file.exists()) {
          await file.delete();
        }
        
        // Remove from downloads map and storage
        await _removeDownloadFromStorage(lessonId);
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  // Download notes or materials with organization metadata
  Future<String> downloadNotesOrMaterial({
    required String url,
    required String title,
    required String lessonId,
    required DownloadType type,
    String? lessonTitle,
    String? sectionTitle,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    if (_useBackgroundService && _bgClient != null) {
      return _downloadNotesOrMaterialViaService(
        url: url,
        title: title,
        lessonId: lessonId,
        type: type,
        lessonTitle: lessonTitle,
        sectionTitle: sectionTitle,
        onProgress: onProgress,
        onSuccess: onSuccess,
        onError: onError,
      );
    }
    return _downloadNotesOrMaterialDirect(
      url: url,
      title: title,
      lessonId: lessonId,
      type: type,
      lessonTitle: lessonTitle,
      sectionTitle: sectionTitle,
      onProgress: onProgress,
      onSuccess: onSuccess,
      onError: onError,
    );
  }

  // Queues a notes/material download with the Android foreground service so
  // it keeps running after the app is closed.
  Future<String> _downloadNotesOrMaterialViaService({
    required String url,
    required String title,
    required String lessonId,
    required DownloadType type,
    String? lessonTitle,
    String? sectionTitle,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    final downloadId = '${type.name}_$lessonId';

    if (_downloads.containsKey(downloadId) && _downloads[downloadId]!.status == DownloadStatus.completed) {
      onProgress?.call(1.0);
      onSuccess?.call();
      return _downloads[downloadId]!.localPath;
    }

    String fileExtension = '.pdf';
    final lowerUrl = url.toLowerCase();
    if (lowerUrl.endsWith('.doc') || lowerUrl.endsWith('.docx')) {
      fileExtension = '.docx';
    } else if (lowerUrl.endsWith('.txt')) {
      fileExtension = '.txt';
    } else if (lowerUrl.endsWith('.md')) {
      fileExtension = '.md';
    }

    final directory = await _getAppDirectory();
    final fileName = '${type.name}_$lessonId$fileExtension';
    final filePath = p.join(directory, fileName);

    int downloadedBytes = 0;
    final file = File(filePath);
    if (await file.exists()) {
      downloadedBytes = await file.length();
    }

    final download = Download(
      id: downloadId,
      lessonId: lessonId,
      fileName: fileName,
      originalTitle: title,
      localPath: filePath,
      url: url,
      type: type,
      lessonTitle: lessonTitle,
      sectionTitle: sectionTitle,
      downloadProgress: downloadedBytes > 0 ? -1.0 : 0.0,
      isDownloading: true,
      status: DownloadStatus.downloading,
    );
    _downloads[downloadId] = download;
    notifyListeners();
    await _saveDownloadsToStorage();

    final completer = Completer<String>();
    _taskCompleters[downloadId] = completer;
    _taskOnProgress[downloadId] = onProgress;
    _taskOnSuccess[downloadId] = onSuccess;
    _taskOnError[downloadId] = onError;

    try {
      await _bgClient!.enqueue(
        taskId: downloadId,
        url: url,
        filePath: filePath,
        downloadedBytes: downloadedBytes,
        title: title,
      );
    } catch (e) {
      _taskCompleters.remove(downloadId);
      _taskOnProgress.remove(downloadId);
      _taskOnSuccess.remove(downloadId);
      _taskOnError.remove(downloadId);
      _downloads[downloadId] = download.copyWith(isDownloading: false, status: DownloadStatus.failed, error: e.toString());
      notifyListeners();
      await _saveDownloadsToStorage();
      onError?.call(e.toString());
      rethrow;
    }

    return completer.future;
  }

  // Original in-process download path, used on platforms where the
  // foreground service isn't available (iOS, desktop, web).
  Future<String> _downloadNotesOrMaterialDirect({
    required String url,
    required String title,
    required String lessonId,
    required DownloadType type,
    String? lessonTitle,
    String? sectionTitle,
    Function(double)? onProgress,
    Function()? onSuccess,
    Function(String)? onError,
  }) async {
    try {
      // Generate a unique ID for this download
      final downloadId = '${type.name}_$lessonId';

      // Check if already downloaded
      if (_downloads.containsKey(downloadId) && _downloads[downloadId]!.status == DownloadStatus.completed) {
        onProgress?.call(1.0);
        onSuccess?.call();
        return _downloads[downloadId]!.localPath;
      }

      // Determine file extension from URL
      String fileExtension = '';
      if (url.toLowerCase().endsWith('.pdf')) {
        fileExtension = '.pdf';
      } else if (url.toLowerCase().endsWith('.doc') || url.toLowerCase().endsWith('.docx')) {
        fileExtension = '.docx';
      } else if (url.toLowerCase().endsWith('.txt')) {
        fileExtension = '.txt';
      } else if (url.toLowerCase().endsWith('.md')) {
        fileExtension = '.md';
      } else {
        fileExtension = '.pdf'; // Default to PDF
      }

      final directory = await _getAppDirectory();
      final fileName = '${type.name}_$lessonId$fileExtension';
      final filePath = p.join(directory, fileName);

      // Create download record
      final download = Download(
        id: downloadId,
        lessonId: lessonId,
        fileName: fileName,
        originalTitle: title,
        localPath: filePath,
        url: url,
        type: type,
        lessonTitle: lessonTitle,
        sectionTitle: sectionTitle,
        downloadProgress: 0.0,
        isDownloading: true,
        status: DownloadStatus.downloading,
      );
      
      _downloads[downloadId] = download;
      notifyListeners();
      await _saveDownloadsToStorage();

      // Note: this is a direct, unsigned CloudFront/S3 URL, not an API endpoint.
      // Sending the app's Firebase Authorization header here makes CloudFront/S3
      // try to parse it as an AWS signature and reject with 403 Access Denied.
      final response = await _dio.get<ResponseBody>(
        url,
        options: Options(
          responseType: ResponseType.stream,
          followRedirects: true,
          validateStatus: (status) => status == 200 || status == 206,
        ),
      );

      final File file = File(filePath);
      final IOSink raf = file.openWrite();
      
      try {
        int currentReceived = 0;
        int? contentLength = int.tryParse(response.headers.value('content-length') ?? '-1');

        await response.data!.stream.listen(
          (List<int> chunk) {
            raf.add(chunk);
            currentReceived += chunk.length;

            if (contentLength != null && contentLength != -1) {
              double progress = currentReceived / contentLength;
              
              // Update progress more frequently for smoother UI
              if (progress > (download.downloadProgress + 0.01) || progress >= 1.0) {
                download.downloadProgress = progress;
                _downloads[downloadId] = download.copyWith(downloadProgress: progress);
                onProgress?.call(progress);
                notifyListeners();
                
                // Save to storage on major milestones for better performance
                if (progress >= 1.0 || (progress * 20).floor() > ((download.downloadProgress - 0.05) * 20).floor()) {
                  _saveDownloadsToStorage(); 
                }
              }
            } else {
              // Indeterminate progress
              if (download.downloadProgress != -1.0) {
                download.downloadProgress = -1.0;
                _downloads[downloadId] = download.copyWith(downloadProgress: -1.0);
                onProgress?.call(-1.0);
                notifyListeners();
              }
            }
          },
          onError: (e) {
            throw e;
          },
          cancelOnError: true,
        ).asFuture();
      } finally {
        await raf.close();
      }
      
      // Mark download as completed
      _downloads[downloadId] = download.copyWith(
        isDownloading: false,
        downloadProgress: 1.0,
        status: DownloadStatus.completed,
      );
      notifyListeners();
      await _saveDownloadsToStorage();
      onSuccess?.call();

      return filePath;
    } on DioException catch (e) {
      final downloadId = '${type.name}_$lessonId';
      
      // Handle specific HTTP errors
      String errorMessage = 'Download failed';
      if (e.response?.statusCode == 403) {
        errorMessage = 'Access denied. Please check your subscription or login again.';
      } else if (e.response?.statusCode == 401) {
        errorMessage = 'Authentication failed. Please log in again.';
      } else if (e.response?.statusCode == 404) {
        errorMessage = 'File not found. It may have been removed.';
      } else if (e.type == DioExceptionType.connectionTimeout) {
        errorMessage = 'Connection timeout. Please check your internet connection.';
      } else if (e.type == DioExceptionType.receiveTimeout) {
        errorMessage = 'Download timeout. Please try again.';
      } else if (e.type == DioExceptionType.connectionError) {
        errorMessage = 'Network error. Please check your internet connection.';
      }
      
      print('Download DioException for notes/materials: ${e.type}, Status: ${e.response?.statusCode}, Message: $errorMessage');
      
      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId] = _downloads[downloadId]!.copyWith(
          isDownloading: false,
          status: DownloadStatus.failed,
          error: errorMessage,
        );
        notifyListeners();
        await _saveDownloadsToStorage();
      }
      
      onError?.call(errorMessage);
      rethrow;
    } catch (e) {
      final downloadId = '${type.name}_$lessonId';
      print('Download failed for notes/materials: $e');
      
      if (_downloads.containsKey(downloadId)) {
        _downloads[downloadId] = _downloads[downloadId]!.copyWith(
          isDownloading: false,
          status: DownloadStatus.failed,
          error: e.toString(),
        );
        notifyListeners();
        await _saveDownloadsToStorage();
      }
      
      onError?.call(e.toString());
      rethrow;
    }
  }

  // Get downloads by type
  List<Download> getDownloadsByType(DownloadType type) {
    return _downloads.values.where((download) => download.type == type).toList();
  }

  // Get downloads by lesson
  List<Download> getDownloadsByLesson(String lessonId) {
    return _downloads.values.where((download) => download.lessonId == lessonId).toList();
  }

  // Check if notes/materials are downloaded
  Future<bool> isContentDownloaded(String lessonId, DownloadType type) async {
    final downloadId = '${type.name}_$lessonId';
    final download = _downloads[downloadId];
    return download?.status == DownloadStatus.completed;
  }

  // Get total storage used by downloads
  Future<int> getTotalDownloadedSize() async {
    int totalSize = 0;
    
    for (final download in _downloads.values) {
      final file = File(download.localPath);
      if (await file.exists()) {
        totalSize += await file.length();
      }
    }
    
    return totalSize;
  }

  // Get current network type for adaptive downloading
  Future<ConnectivityResult> _getNetworkType() async {
    try {
      final results = await Connectivity().checkConnectivity();
      if (results.isNotEmpty) {
        return results.first;
      }
    } catch (e) {
      print('Error checking network type: $e');
    }
    return ConnectivityResult.none;
  }

  // Get adaptive chunk size based on network type
  int _getAdaptiveChunkSize(ConnectivityResult networkType) {
    switch (networkType) {
      case ConnectivityResult.wifi:
        return 20 * 1024 * 1024; // 20MB chunks for WiFi (increased for speed)
      case ConnectivityResult.ethernet:
        return 25 * 1024 * 1024; // 25MB chunks for Ethernet (increased for speed)
      case ConnectivityResult.mobile:
        return 5 * 1024 * 1024; // 5MB chunks for mobile (increased for speed)
      case ConnectivityResult.bluetooth:
        return 2 * 1024 * 1024; // 2MB chunks for Bluetooth (increased)
      case ConnectivityResult.vpn:
        return 8 * 1024 * 1024; // 8MB chunks for VPN (increased)
      case ConnectivityResult.none:
      default:
        return 5 * 1024 * 1024; // 5MB chunks default (increased)
    }
  }

  // Get adaptive parallel chunks based on network type
  int _getAdaptiveParallelChunks(ConnectivityResult networkType) {
    switch (networkType) {
      case ConnectivityResult.wifi:
        return 12; // 12 parallel chunks for WiFi (doubled for speed)
      case ConnectivityResult.ethernet:
        return 16; // 16 parallel chunks for Ethernet (doubled for speed)
      case ConnectivityResult.mobile:
        return 4; // 4 parallel chunks for mobile (increased for speed)
      case ConnectivityResult.bluetooth:
        return 2; // 2 chunks for Bluetooth (increased)
      case ConnectivityResult.vpn:
        return 6; // 6 parallel chunks for VPN (doubled)
      case ConnectivityResult.none:
      default:
        return 4; // 4 parallel chunks default (increased)
    }
  }
}
