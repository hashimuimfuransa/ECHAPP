import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';

/// Live Session Provider for managing live session state
final liveSessionProvider = StateNotifierProvider<LiveSessionNotifier, LiveSessionState>((ref) {
  return LiveSessionNotifier();
});

/// Live Session State
class LiveSessionState {
  final bool isLoading;
  final String? error;
  final List<LiveSession> upcomingSessions;
  final List<LiveSession> pastSessions;
  final List<LiveSession> allSessions;
  final LiveSession? currentSession;
  final RecordingResponse? currentRecording;
  final int currentPage;
  final int totalPages;

  LiveSessionState({
    this.isLoading = false,
    this.error,
    this.upcomingSessions = const [],
    this.pastSessions = const [],
    this.allSessions = const [],
    this.currentSession,
    this.currentRecording,
    this.currentPage = 1,
    this.totalPages = 1,
  });

  LiveSessionState copyWith({
    bool? isLoading,
    String? error,
    List<LiveSession>? upcomingSessions,
    List<LiveSession>? pastSessions,
    List<LiveSession>? allSessions,
    LiveSession? currentSession,
    RecordingResponse? currentRecording,
    int? currentPage,
    int? totalPages,
  }) {
    return LiveSessionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      upcomingSessions: upcomingSessions ?? this.upcomingSessions,
      pastSessions: pastSessions ?? this.pastSessions,
      allSessions: allSessions ?? this.allSessions,
      currentSession: currentSession ?? this.currentSession,
      currentRecording: currentRecording ?? this.currentRecording,
      currentPage: currentPage ?? this.currentPage,
      totalPages: totalPages ?? this.totalPages,
    );
  }
}

/// Live Session Notifier
class LiveSessionNotifier extends StateNotifier<LiveSessionState> {
  final LiveSessionService _liveSessionService = LiveSessionService();

  LiveSessionNotifier() : super(LiveSessionState());

  /// Load teacher sessions
  Future<void> loadTeacherSessions({
    String? status,
    int page = 1,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _liveSessionService.getTeacherSessions(
        status: status,
        page: page,
      );

      if (status == 'scheduled') {
        state = state.copyWith(
          isLoading: false,
          upcomingSessions: response.sessions,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        );
      } else if (status == 'ended') {
        state = state.copyWith(
          isLoading: false,
          pastSessions: response.sessions,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          allSessions: response.sessions,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        );
      }
    } catch (e) {
      debugPrint('Load Teacher Sessions Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load sessions: $e',
      );
    }
  }

  /// Load course sessions (for students)
  Future<void> loadCourseSessions(
    String courseId, {
    String status = 'scheduled',
    int page = 1,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _liveSessionService.getCourseSessions(
        courseId,
        status: status,
        page: page,
      );

      if (status == 'scheduled') {
        state = state.copyWith(
          isLoading: false,
          upcomingSessions: response.sessions,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        );
      } else {
        state = state.copyWith(
          isLoading: false,
          allSessions: response.sessions,
          currentPage: response.currentPage,
          totalPages: response.totalPages,
        );
      }
    } catch (e) {
      debugPrint('Load Course Sessions Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load course sessions: $e',
      );
    }
  }

  /// Load lesson sessions
  Future<void> loadLessonSessions(String lessonId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final sessions = await _liveSessionService.getLessonSessions(lessonId);
      state = state.copyWith(
        isLoading: false,
        allSessions: sessions,
      );
    } catch (e) {
      debugPrint('Load Lesson Sessions Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load lesson sessions: $e',
      );
    }
  }

  /// Create a new session
  Future<bool> createSession({
    required String courseId,
    required String sectionId,
    String? lessonId,
    required String title,
    String? description,
    required DateTime scheduledAt,
    required int duration,
    int maxParticipants = 100,
    SessionSettings? settings,
  }) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final session = await _liveSessionService.createSession(
        courseId: courseId,
        sectionId: sectionId,
        lessonId: lessonId,
        title: title,
        description: description,
        scheduledAt: scheduledAt,
        duration: duration,
        maxParticipants: maxParticipants,
        settings: settings,
      );

      // Add to upcoming sessions
      final updatedUpcoming = [session, ...state.upcomingSessions];
      state = state.copyWith(
        isLoading: false,
        upcomingSessions: updatedUpcoming,
      );
      return true;
    } catch (e) {
      debugPrint('Create Session Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to create session: $e',
      );
      return false;
    }
  }

  /// Join a session
  Future<JoinSessionResponse?> joinSession(String sessionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final response = await _liveSessionService.joinSession(sessionId);
      state = state.copyWith(isLoading: false);
      return response;
    } catch (e) {
      debugPrint('Join Session Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to join session: $e',
      );
      return null;
    }
  }

  /// End a session
  Future<bool> endSession(String sessionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final session = await _liveSessionService.endSession(sessionId);

      // Update the session in the list
      final updatedUpcoming = state.upcomingSessions
          .map((s) => s.id == sessionId ? session : s)
          .toList();

      state = state.copyWith(
        isLoading: false,
        upcomingSessions: updatedUpcoming,
      );
      return true;
    } catch (e) {
      debugPrint('End Session Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to end session: $e',
      );
      return false;
    }
  }

  /// Cancel a session
  Future<bool> cancelSession(String sessionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final session = await _liveSessionService.cancelSession(sessionId);

      // Remove from upcoming sessions
      final updatedUpcoming = state.upcomingSessions
          .where((s) => s.id != sessionId)
          .toList();

      state = state.copyWith(
        isLoading: false,
        upcomingSessions: updatedUpcoming,
      );
      return true;
    } catch (e) {
      debugPrint('Cancel Session Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to cancel session: $e',
      );
      return false;
    }
  }

  /// Get session recording
  Future<RecordingResponse?> getRecording(String sessionId) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final recording = await _liveSessionService.getSessionRecording(sessionId);
      state = state.copyWith(
        isLoading: false,
        currentRecording: recording,
      );
      return recording;
    } catch (e) {
      debugPrint('Get Recording Error: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to get recording: $e',
      );
      return null;
    }
  }

  /// Clear error
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Set current session
  void setCurrentSession(LiveSession session) {
    state = state.copyWith(currentSession: session);
  }

  /// Refresh all sessions
  Future<void> refresh() async {
    await Future.wait([
      loadTeacherSessions(status: 'scheduled'),
      loadTeacherSessions(status: 'ended'),
      loadTeacherSessions(),
    ]);
  }
}
