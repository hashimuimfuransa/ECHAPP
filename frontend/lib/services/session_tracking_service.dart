import 'dart:async';
import 'package:flutter/foundation.dart';
import './infrastructure/api_client.dart';
import '../config/api_config.dart';

/// Tracks real foreground "time spent in app" and reports it to the backend.
///
/// There is no reliable way to derive time-in-app from login/logout timestamps
/// alone (most users never explicitly log out), so this service keeps a local
/// stopwatch of foreground time and periodically flushes elapsed seconds to the
/// backend, which simply accumulates them. A stopped/paused app stops the
/// stopwatch, so backgrounded time is never counted.
class SessionTrackingService {
  SessionTrackingService._();
  static final SessionTrackingService instance = SessionTrackingService._();

  static const _heartbeatInterval = Duration(seconds: 60);

  final ApiClient _apiClient = ApiClient();
  final Stopwatch _stopwatch = Stopwatch();
  Timer? _heartbeatTimer;

  /// Call when the app becomes active: cold start, or resume from background.
  void appResumed() {
    if (!_stopwatch.isRunning) {
      _stopwatch.reset();
      _stopwatch.start();
    }
    _heartbeatTimer ??= Timer.periodic(_heartbeatInterval, (_) => _flush(keepRunning: true));

    unawaited(_notifySessionStart());
  }

  /// Call when the app goes to the background (paused/inactive/detached).
  void appPaused() {
    _heartbeatTimer?.cancel();
    _heartbeatTimer = null;
    unawaited(_flush(keepRunning: false));
  }

  Future<void> _notifySessionStart() async {
    try {
      await _apiClient.post(ApiConfig.sessionStart);
    } catch (e) {
      debugPrint('SessionTrackingService: failed to notify session start: $e');
    }
  }

  Future<void> _flush({required bool keepRunning}) async {
    final elapsedSeconds = _stopwatch.elapsed.inSeconds;
    _stopwatch.stop();
    _stopwatch.reset();
    if (keepRunning) {
      _stopwatch.start();
    }

    if (elapsedSeconds <= 0) return;

    try {
      await _apiClient.post(
        ApiConfig.sessionHeartbeat,
        body: {'seconds': elapsedSeconds},
      );
    } catch (e) {
      debugPrint('SessionTrackingService: failed to send heartbeat: $e');
    }
  }
}
