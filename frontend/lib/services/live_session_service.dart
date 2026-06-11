import 'dart:convert';
import 'package:flutter/foundation.dart';

import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/live_session.dart';

/// Service for live session and BigBlueButton operations
class LiveSessionService {
  final ApiClient _apiClient;

  LiveSessionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Create a new live session with BBB meeting
  Future<LiveSession> createSession({
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
      final body = {
        'courseId': courseId,
        'sectionId': sectionId,
        'lessonId': lessonId,
        'title': title,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'duration': duration,
        'maxParticipants': maxParticipants,
        'settings': settings?.toJson() ?? SessionSettings().toJson(),
      };

      final response = await _apiClient.post(
        '${ApiConfig.baseUrl}/live/sessions',
        body: jsonEncode(body),
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final session = LiveSession.fromJson(data['session']);
      debugPrint('Session created with scheduledAt: ${session.scheduledAt}');
      debugPrint('Session created with scheduledAt (local): ${session.scheduledAt.toLocal()}');
      return session;
    } catch (e) {
      debugPrint('Create Live Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create live session: $e');
    }
  }

  /// Get live sessions for the teacher
  Future<LiveSessionsResponse> getTeacherSessions({
    String? status,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/live/teacher/sessions?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';

      final response = await _apiClient.get(url);
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final sessions = (data['sessions'] as List?)
              ?.map((s) => LiveSession.fromJson(s))
              .toList() ??
          [];

      return LiveSessionsResponse(
        sessions: sessions,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      debugPrint('Get Teacher Sessions Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch teacher sessions: $e');
    }
  }

  /// Get live sessions for a course (for students)
  Future<LiveSessionsResponse> getCourseSessions(
    String courseId, {
    String status = 'scheduled',
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/live/courses/$courseId/sessions?status=$status&page=$page&limit=$limit',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final sessions = (data['sessions'] as List?)
              ?.map((s) => LiveSession.fromJson(s))
              .toList() ??
          [];

      return LiveSessionsResponse(
        sessions: sessions,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      debugPrint('Get Course Sessions Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course sessions: $e');
    }
  }

  /// Get live sessions for a specific lesson
  Future<List<LiveSession>> getLessonSessions(String lessonId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/live/lessons/$lessonId/sessions',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return (data['sessions'] as List?)
              ?.map((s) => LiveSession.fromJson(s))
              .toList() ??
          [];
    } catch (e) {
      debugPrint('Get Lesson Sessions Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch lesson sessions: $e');
    }
  }

  /// Join a live session
  Future<JoinSessionResponse> joinSession(String sessionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId/join',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return JoinSessionResponse.fromJson(data);
    } catch (e) {
      debugPrint('Join Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to join session: $e');
    }
  }

  /// End a live session (teacher only)
  Future<LiveSession> endSession(String sessionId) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId/end',
        body: '{}',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return LiveSession.fromJson(data['session']);
    } catch (e) {
      debugPrint('End Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to end session: $e');
    }
  }

  /// Update a scheduled session (teacher only)
  Future<LiveSession> updateSession({
    required String sessionId,
    String? title,
    String? description,
    DateTime? scheduledAt,
    int? duration,
    int? maxParticipants,
    SessionSettings? settings,
  }) async {
    try {
      final body = <String, dynamic>{};
      if (title != null) body['title'] = title;
      if (description != null) body['description'] = description;
      if (scheduledAt != null) body['scheduledAt'] = scheduledAt.toIso8601String();
      if (duration != null) body['duration'] = duration;
      if (maxParticipants != null) body['maxParticipants'] = maxParticipants;
      if (settings != null) body['settings'] = settings.toJson();

      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId',
        body: jsonEncode(body),
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return LiveSession.fromJson(data['session']);
    } catch (e) {
      debugPrint('Update Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update session: $e');
    }
  }

  /// Cancel a scheduled session (teacher only)
  Future<LiveSession> cancelSession(String sessionId) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId/cancel',
        body: '{}',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return LiveSession.fromJson(data['session']);
    } catch (e) {
      debugPrint('Cancel Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to cancel session: $e');
    }
  }

  /// Delete a session (teacher only) - works for any status
  Future<void> deleteSession(String sessionId) async {
    try {
      final response = await _apiClient.delete(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId',
      );
      response.validateStatus();
    } catch (e) {
      debugPrint('Delete Session Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete session: $e');
    }
  }

  /// Get recording for a session
  Future<RecordingResponse> getSessionRecording(String sessionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId/recordings',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return RecordingResponse.fromJson(data);
    } catch (e) {
      debugPrint('Failed to fetch session recording: $e');
      throw ApiException('Failed to fetch session recording: $e');
    }
  }

  /// Get session attendance details
  Future<SessionAttendanceResponse> getSessionAttendance(String sessionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/live/sessions/$sessionId/attendance',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      return SessionAttendanceResponse.fromJson(data);
    } catch (e) {
      debugPrint('Failed to fetch session attendance: $e');
      throw ApiException('Failed to fetch session attendance: $e');
    }
  }
}

/// Live Sessions Response
class LiveSessionsResponse {
  final List<LiveSession> sessions;
  final int totalPages;
  final int currentPage;
  final int total;

  LiveSessionsResponse({
    required this.sessions,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}

/// Join Session Response
class JoinSessionResponse {
  final String joinUrl;
  final bool isModerator;
  final Map<String, dynamic> session;

  JoinSessionResponse({
    required this.joinUrl,
    required this.isModerator,
    required this.session,
  });

  factory JoinSessionResponse.fromJson(Map<String, dynamic> json) {
    return JoinSessionResponse(
      joinUrl: json['joinUrl'] ?? '',
      isModerator: json['isModerator'] ?? false,
      session: json['session'] ?? {},
    );
  }
}

/// Recording Response
class RecordingResponse {
  final String? recordingUrl;
  final int duration;
  final String? format;
  final String? sessionTitle;

  RecordingResponse({
    this.recordingUrl,
    this.duration = 0,
    this.format,
    this.sessionTitle,
  });

  factory RecordingResponse.fromJson(Map<String, dynamic> json) {
    return RecordingResponse(
      recordingUrl: json['recordingUrl'],
      duration: json['duration'] is int ? json['duration'] : (json['duration'] is num ? (json['duration'] as num).toInt() : 0),
      format: json['format'],
      sessionTitle: json['sessionTitle'],
    );
  }

  bool get hasRecording => recordingUrl != null && recordingUrl!.isNotEmpty;
}

/// Session Attendance Response
class SessionAttendanceResponse {
  final Map<String, dynamic> session;
  final int totalEnrolled;
  final int totalAttended;
  final List<Map<String, dynamic>> attendedStudents;
  final List<Map<String, dynamic>> notAttendedStudents;
  final int attendanceRate;

  SessionAttendanceResponse({
    required this.session,
    required this.totalEnrolled,
    required this.totalAttended,
    required this.attendedStudents,
    required this.notAttendedStudents,
    required this.attendanceRate,
  });

  factory SessionAttendanceResponse.fromJson(Map<String, dynamic> json) {
    int toInt(dynamic value) {
      if (value == null) return 0;
      if (value is int) return value;
      if (value is num) return value.toInt();
      if (value is String) return int.tryParse(value) ?? 0;
      return 0;
    }

    return SessionAttendanceResponse(
      session: json['session'] ?? {},
      totalEnrolled: toInt(json['totalEnrolled']),
      totalAttended: toInt(json['totalAttended']),
      attendedStudents: (json['attendedStudents'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      notAttendedStudents: (json['notAttendedStudents'] as List<dynamic>?)
              ?.map((e) => e as Map<String, dynamic>)
              .toList() ??
          [],
      attendanceRate: toInt(json['attendanceRate']),
    );
  }
}
