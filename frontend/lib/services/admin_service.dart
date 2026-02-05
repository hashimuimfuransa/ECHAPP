
import 'dart:convert';

import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/user.dart';

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