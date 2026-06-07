import 'dart:convert';
import 'package:flutter/foundation.dart';

import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/teacher_course.dart';
import '../models/student_performance.dart';
import '../models/course.dart';

/// Service for teacher-related API operations
class TeacherService {
  final ApiClient _apiClient;

  TeacherService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  static int _toInt(dynamic value) {
    if (value == null) return 0;
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  /// Get teacher dashboard statistics
  Future<TeacherDashboardStats> getDashboardStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.baseUrl}/teacher/dashboard-stats');
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return TeacherDashboardStats.fromJson(data);
    } catch (e) {
      debugPrint('Get Teacher Dashboard Stats Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch dashboard stats: $e');
    }
  }

  /// Get courses assigned to the teacher
  Future<TeacherCoursesResponse> getAssignedCourses({
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teacher/courses?page=$page&limit=$limit',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final courses = (data['courses'] as List?)
              ?.map((c) => TeacherCourse.fromJson(c))
              .toList() ??
          [];

      return TeacherCoursesResponse(
        courses: courses,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      debugPrint('Get Assigned Courses Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch assigned courses: $e');
    }
  }

  /// Get detailed content of a course (sections and lessons)
  Future<CourseContent> getCourseContent(String courseId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teacher/courses/$courseId/content',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return CourseContent.fromJson(data);
    } catch (e) {
      debugPrint('Get Course Content Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course content: $e');
    }
  }

  /// Get students enrolled in a course
  Future<CourseStudentsResponse> getCourseStudents(
    String courseId, {
    String? status,
    int page = 1,
    int limit = 20,
    String? search,
  }) async {
    try {
      String url = '${ApiConfig.baseUrl}/teacher/courses/$courseId/students?page=$page&limit=$limit';
      if (status != null) url += '&status=$status';
      if (search != null && search.isNotEmpty) url += '&search=$search';

      final response = await _apiClient.get(url);
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      final students = (data['students'] as List?)
              ?.map((s) => StudentPerformance.fromJson(s))
              .toList() ??
          [];

      return CourseStudentsResponse(
        students: students,
        totalPages: _toInt(data['totalPages']),
        currentPage: _toInt(data['currentPage']),
        total: _toInt(data['total']),
      );
    } catch (e) {
      debugPrint('Get Course Students Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course students: $e');
    }
  }

  /// Get detailed performance data for a specific student
  Future<DetailedStudentPerformance> getStudentPerformance(
    String courseId,
    String studentId,
  ) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/teacher/courses/$courseId/students/$studentId/performance',
      );
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;

      return DetailedStudentPerformance.fromJson(data);
    } catch (e) {
      debugPrint('Get Student Performance Error: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student performance: $e');
    }
  }
}

/// Teacher Dashboard Stats
class TeacherDashboardStats {
  final TeacherOverview overview;
  final List<RecentSession> recentSessions;
  final List<String> courseIds;

  TeacherDashboardStats({
    required this.overview,
    required this.recentSessions,
    required this.courseIds,
  });

  factory TeacherDashboardStats.fromJson(Map<String, dynamic> json) {
    return TeacherDashboardStats(
      overview: json['overview'] != null
          ? TeacherOverview.fromJson(json['overview'])
          : TeacherOverview.empty(),
      recentSessions: (json['recentSessions'] as List?)
              ?.map((s) => RecentSession.fromJson(s))
              .toList() ??
          [],
      courseIds: (json['courseIds'] as List?)
              ?.map((id) => id.toString())
              .toList() ??
          [],
    );
  }
}

/// Teacher Overview Stats
class TeacherOverview {
  final int totalCourses;
  final int totalStudents;
  final int activeStudents;
  final int upcomingSessions;
  final int totalSessionsConducted;
  final double totalTeachingHours;

  TeacherOverview({
    required this.totalCourses,
    required this.totalStudents,
    required this.activeStudents,
    required this.upcomingSessions,
    required this.totalSessionsConducted,
    required this.totalTeachingHours,
  });

  factory TeacherOverview.fromJson(Map<String, dynamic> json) {
    return TeacherOverview(
      totalCourses: json['totalCourses'] ?? 0,
      totalStudents: json['totalStudents'] ?? 0,
      activeStudents: json['activeStudents'] ?? 0,
      upcomingSessions: json['upcomingSessions'] ?? 0,
      totalSessionsConducted: json['totalSessionsConducted'] ?? 0,
      totalTeachingHours: (json['totalTeachingHours'] ?? 0.0).toDouble(),
    );
  }

  factory TeacherOverview.empty() {
    return TeacherOverview(
      totalCourses: 0,
      totalStudents: 0,
      activeStudents: 0,
      upcomingSessions: 0,
      totalSessionsConducted: 0,
      totalTeachingHours: 0.0,
    );
  }
}

/// Recent Session
class RecentSession {
  final String id;
  final String title;
  final String? courseName;
  final DateTime scheduledAt;
  final String status;
  final int duration;

  RecentSession({
    required this.id,
    required this.title,
    this.courseName,
    required this.scheduledAt,
    required this.status,
    required this.duration,
  });

  factory RecentSession.fromJson(Map<String, dynamic> json) {
    return RecentSession(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      courseName: json['courseName'],
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
      status: json['status'] ?? 'scheduled',
      duration: json['duration'] ?? 60,
    );
  }
}

/// Teacher Courses Response
class TeacherCoursesResponse {
  final List<TeacherCourse> courses;
  final int totalPages;
  final int currentPage;
  final int total;

  TeacherCoursesResponse({
    required this.courses,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}

/// Course Students Response
class CourseStudentsResponse {
  final List<StudentPerformance> students;
  final int totalPages;
  final int currentPage;
  final int total;

  CourseStudentsResponse({
    required this.students,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });
}
