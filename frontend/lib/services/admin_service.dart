
import 'dart:convert';

import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/user.dart';
import '../models/enrollment.dart';

/// Service for admin-related API operations using the new professional architecture
class AdminService {
  final ApiClient _apiClient;

  AdminService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get dashboard statistics
  Future<AdminDashboardStats> getDashboardStats() async {
    try {
      // Fetch all required data in parallel
      final futures = [
        _getCourseStats(),
        _getPaymentStats(),
        _getUserStats(),
      ];
      
      final results = await Future.wait(futures);
      
      final courseStats = results[0] as CourseStats;
      final paymentStats = results[1] as PaymentStats;
      final userStats = results[2] as UserStats;
      
      return AdminDashboardStats(
        totalCourses: courseStats.totalCourses,
        activeStudents: userStats.totalStudents,
        totalRevenue: paymentStats.totalRevenue,
        pendingExams: 0, // Will implement when exam stats are available
        recentActivity: _generateRecentActivity(courseStats, paymentStats),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch dashboard statistics: $e');
    }
  }

  /// Get course statistics
  Future<CourseStats> _getCourseStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/course-stats');
      response.validateStatus();
      
      // Parse the response directly since data is a List
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'];
      
      if (data is List) {
        final courses = data.cast<Map<String, dynamic>>();
        
        // Calculate total courses (all courses, not just published)
        final totalCourses = courses.length;
        
        // Calculate published courses
        final publishedCourses = courses.where((course) => 
          course['isPublished'] == true).length;
        
        return CourseStats(
          totalCourses: totalCourses,
          publishedCourses: publishedCourses,
          courses: courses
        );
      } else {
        throw ApiException('Invalid response format: expected List but got ${data.runtimeType}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return CourseStats(totalCourses: 0, publishedCourses: 0, courses: []);
    }
  }

  /// Get payment statistics
  Future<PaymentStats> _getPaymentStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/payment-stats');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return PaymentStats(
        totalRevenue: (data['totalRevenue'] as num?)?.toDouble() ?? 0.0,
        totalPayments: data['totalPayments'] as int? ?? 0,
        recentPayments: data['recentPayments'] is List ? data['recentPayments'] as List : [],
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return PaymentStats(totalRevenue: 0, totalPayments: 0, recentPayments: []);
    }
  }

  /// Get user statistics
  Future<UserStats> _getUserStats() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students?page=1&limit=1&source=firebase');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return UserStats(
        totalStudents: data['total'] as int? ?? 0,
        source: data['source'] as String? ?? 'unknown',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      // Return default values if API fails
      return UserStats(totalStudents: 0, source: 'fallback');
    }
  }

  /// Get students with pagination and search
  Future<StudentListResponse> getStudents({int page = 1, int limit = 10, String? search}) async {
    try {
      final queryParams = {
        'page': page.toString(),
        'limit': limit.toString(),
        if (search != null && search.isNotEmpty) 'search': search,
      };
      
      final response = await _apiClient.get('${ApiConfig.admin}/students', queryParams: queryParams);
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final students = (data['students'] as List)
          .map((item) => User.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return StudentListResponse(
        students: students,
        totalPages: data['totalPages'] as int? ?? 1,
        currentPage: data['currentPage'] as int? ?? 1,
        total: data['total'] as int? ?? 0,
        source: data['source'] as String? ?? 'unknown',
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch students: $e');
    }
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is Map<String, dynamic>) {
      // Handle case where date is stored as an object (e.g., Firestore timestamp)
      try {
        // Check if it's a Firestore Timestamp-like object with seconds and nanoseconds
        if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
          int seconds = dateValue['seconds'] as int? ?? 0;
          int nanoseconds = dateValue['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else if (dateValue.containsKey('_seconds')) {
          // Alternative format with _seconds
          int seconds = dateValue['_seconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        // If conversion fails, return current time
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  /// Get detailed student information including enrollments
  Future<StudentDetail> getStudentDetail(String studentId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students/$studentId/detail');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final enrollments = (data['enrollments'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return StudentDetail(
        user: user,
        enrollments: enrollments,
        totalEnrollments: data['totalEnrollments'] as int? ?? 0,
        completedCourses: data['completedCourses'] as int? ?? 0,
        inProgressCourses: data['inProgressCourses'] as int? ?? 0,
        totalSpent: (data['totalSpent'] as num?)?.toDouble() ?? 0.0,
        lastActive: data['lastActive'] != null 
            ? _parseDateTime(data['lastActive'])
            : null,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student details: $e');
    }
  }

  /// Get student analytics data
  Future<StudentAnalytics> getStudentAnalytics() async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/analytics/students');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return StudentAnalytics(
        totalStudents: data['totalStudents'] as int? ?? 0,
        activeStudents: data['activeStudents'] as int? ?? 0,
        inactiveStudents: data['inactiveStudents'] as int? ?? 0,
        newStudentsThisMonth: data['newStudentsThisMonth'] as int? ?? 0,
        averageEnrollmentsPerStudent: (data['averageEnrollmentsPerStudent'] as num?)?.toDouble() ?? 0.0,
        topPerformingStudents: (data['topPerformingStudents'] as List)
            .map((item) => TopStudent.fromJson(item as Map<String, dynamic>))
            .toList(),
        enrollmentTrends: (data['enrollmentTrends'] as List)
            .map((item) => EnrollmentTrend.fromJson(item as Map<String, dynamic>))
            .toList(),
        studentActivityStats: StudentActivityStats.fromJson(
            data['studentActivityStats'] as Map<String, dynamic>),
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch student analytics: $e');
    }
  }

  /// Delete a student and all related data
  Future<Map<String, dynamic>> deleteStudent(String studentId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.admin}/students/$studentId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete student: $e');
    }
  }

  /// Manual sync all users from Firebase to backend
  Future<Map<String, dynamic>> manualSyncUsers() async {
    try {
      final response = await _apiClient.post('${ApiConfig.admin}/manual-sync-users');
      response.validateStatus();
      
      // Parse the response directly
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Manual sync failed: $e');
    }
  }

  /// Generate recent activity based on fetched data
  List<ActivityItem> _generateRecentActivity(CourseStats courseStats, PaymentStats paymentStats) {
    final List<ActivityItem> activity = [];
    
    // Add recent course activities
    for (var i = 0; i < courseStats.courses.length && i < 3; i++) {
      final course = courseStats.courses[i];
      activity.add(ActivityItem(
        icon: 'school',
        title: 'Course Published',
        subtitle: 'Course is now live',
        time: 'Recently',
      ));
    }
    
    // Add recent payment activities
    for (var i = 0; i < paymentStats.recentPayments.length && i < 2; i++) {
      final payment = paymentStats.recentPayments[i];
      activity.add(ActivityItem(
        icon: 'payment',
        title: 'Payment Received',
        subtitle: 'Payment processed successfully',
        time: 'Recently',
      ));
    }
    
    // Add default activities if no real data
    if (activity.isEmpty) {
      activity.addAll([
        ActivityItem(
          icon: 'school',
          title: 'Platform Ready',
          subtitle: 'Your coaching platform is set up',
          time: 'Just now',
        ),
        ActivityItem(
          icon: 'people',
          title: 'Welcome Admin',
          subtitle: 'Start managing your platform',
          time: 'Just now',
        ),
      ]);
    }
    
    return activity.take(5).toList();
  }

  /// Get user device information and enrolled courses
  Future<UserDeviceInfo> getUserDeviceInfo(String userId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.admin}/students/$userId/device-info');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      final user = User.fromJson(data['user'] as Map<String, dynamic>);
      final enrolledCourses = (data['enrolledCourses'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList();
      
      return UserDeviceInfo(
        user: user,
        enrolledCourses: enrolledCourses,
        totalEnrollments: data['totalEnrollments'] as int? ?? 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch user device info: $e');
    }
  }
  
  /// Reset user device binding
  Future<Map<String, dynamic>> resetUserDevice(String userId, {String? deviceId}) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.admin}/students/$userId/device-reset',
        body: {'deviceId': deviceId},
      );
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      return jsonBody['data'] as Map<String, dynamic>;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reset user device: $e');
    }
  }
  
  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

class StudentListResponse {
  final List<User> students;
  final int totalPages;
  final int currentPage;
  final int total;
  final String source;

  StudentListResponse({
    required this.students,
    required this.totalPages,
    required this.currentPage,
    required this.total,
    required this.source,
  });
}

/// Data models for admin statistics
class AdminDashboardStats {
  final int totalCourses;
  final int activeStudents;
  final double totalRevenue;
  final int pendingExams;
  final List<ActivityItem> recentActivity;

  AdminDashboardStats({
    required this.totalCourses,
    required this.activeStudents,
    required this.totalRevenue,
    required this.pendingExams,
    required this.recentActivity,
  });
}

class CourseStats {
  final int totalCourses;
  final int publishedCourses;
  final List<Map<String, dynamic>> courses;

  CourseStats({
    required this.totalCourses,
    required this.publishedCourses,
    required this.courses,
  });
}

class PaymentStats {
  final double totalRevenue;
  final int totalPayments;
  final List<dynamic> recentPayments;

  PaymentStats({
    required this.totalRevenue,
    required this.totalPayments,
    required this.recentPayments,
  });
}

class UserStats {
  final int totalStudents;
  final String source;

  UserStats({
    required this.totalStudents,
    required this.source,
  });
}

class ActivityItem {
  final String icon;
  final String title;
  final String subtitle;
  final String time;

  ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

/// Data models for student management
class StudentDetail {
  final User user;
  final List<Enrollment> enrollments;
  final int totalEnrollments;
  final int completedCourses;
  final int inProgressCourses;
  final double totalSpent;
  final DateTime? lastActive;

  StudentDetail({
    required this.user,
    required this.enrollments,
    required this.totalEnrollments,
    required this.completedCourses,
    required this.inProgressCourses,
    required this.totalSpent,
    this.lastActive,
  });
}

class StudentAnalytics {
  final int totalStudents;
  final int activeStudents;
  final int inactiveStudents;
  final int newStudentsThisMonth;
  final double averageEnrollmentsPerStudent;
  final List<TopStudent> topPerformingStudents;
  final List<EnrollmentTrend> enrollmentTrends;
  final StudentActivityStats studentActivityStats;

  StudentAnalytics({
    required this.totalStudents,
    required this.activeStudents,
    required this.inactiveStudents,
    required this.newStudentsThisMonth,
    required this.averageEnrollmentsPerStudent,
    required this.topPerformingStudents,
    required this.enrollmentTrends,
    required this.studentActivityStats,
  });
}

class TopStudent {
  final String id;
  final String name;
  final String email;
  final int totalEnrollments;
  final int completedCourses;
  final double averageProgress;
  final double totalSpent;

  TopStudent({
    required this.id,
    required this.name,
    required this.email,
    required this.totalEnrollments,
    required this.completedCourses,
    required this.averageProgress,
    required this.totalSpent,
  });

  factory TopStudent.fromJson(Map<String, dynamic> json) {
    return TopStudent(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      totalEnrollments: json['totalEnrollments'] as int,
      completedCourses: json['completedCourses'] as int,
      averageProgress: (json['averageProgress'] as num).toDouble(),
      totalSpent: (json['totalSpent'] as num).toDouble(),
    );
  }
}

class EnrollmentTrend {
  final String date;
  final int enrollments;
  final int completions;

  EnrollmentTrend({
    required this.date,
    required this.enrollments,
    required this.completions,
  });

  factory EnrollmentTrend.fromJson(Map<String, dynamic> json) {
    return EnrollmentTrend(
      date: json['date'] as String,
      enrollments: json['enrollments'] as int,
      completions: json['completions'] as int,
    );
  }
}

class StudentActivityStats {
  final int dailyActiveStudents;
  final int weeklyActiveStudents;
  final int monthlyActiveStudents;
  final double avgSessionDuration;
  final int totalStudyHours;

  StudentActivityStats({
    required this.dailyActiveStudents,
    required this.weeklyActiveStudents,
    required this.monthlyActiveStudents,
    required this.avgSessionDuration,
    required this.totalStudyHours,
  });

  factory StudentActivityStats.fromJson(Map<String, dynamic> json) {
    return StudentActivityStats(
      dailyActiveStudents: json['dailyActiveStudents'] as int,
      weeklyActiveStudents: json['weeklyActiveStudents'] as int,
      monthlyActiveStudents: json['monthlyActiveStudents'] as int,
      avgSessionDuration: (json['avgSessionDuration'] as num).toDouble(),
      totalStudyHours: json['totalStudyHours'] as int,
    );
  }
}

/// Model for user device information
class UserDeviceInfo {
  final User user;
  final List<Enrollment> enrolledCourses;
  final int totalEnrollments;

  UserDeviceInfo({
    required this.user,
    required this.enrolledCourses,
    required this.totalEnrollments,
  });

  factory UserDeviceInfo.fromJson(Map<String, dynamic> json) {
    return UserDeviceInfo(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      enrolledCourses: (json['enrolledCourses'] as List)
          .map((item) => Enrollment.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalEnrollments: json['totalEnrollments'] as int? ?? 0,
    );
  }
}
