import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:excellence_coaching_hub/config/api_config.dart';

class AdminService {
  static String get baseUrl => ApiConfig.admin;
  
  // Get authorization header with Firebase ID token
  static Future<Map<String, String>> _getHeaders() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final idToken = await user.getIdToken();
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $idToken',
        };
      } else {
        throw Exception('No authenticated user found');
      }
    } catch (e) {
      throw Exception('Failed to get Firebase ID token: $e');
    }
  }
  
  // Get dashboard statistics
  static Future<Map<String, dynamic>> getDashboardStats() async {
    try {
      final headers = await _getHeaders();
      
      // Fetch all required data in parallel
      final futures = [
        _getCourseStats(headers),
        _getPaymentStats(headers),
        _getUserStats(headers),
      ];
      
      final results = await Future.wait(futures);
      
      final courseStats = results[0];
      final paymentStats = results[1];
      final userStats = results[2];
      
      return {
        'totalCourses': courseStats['totalCourses'] ?? 0,
        'activeStudents': userStats['totalStudents'] ?? 0,
        'totalRevenue': paymentStats['totalRevenue'] ?? 0,
        'pendingExams': 0, // Will implement when exam stats are available
        'recentActivity': _generateRecentActivity(courseStats, paymentStats),
      };
    } catch (e) {
      throw Exception('Failed to fetch dashboard statistics: $e');
    }
  }
  
  // Get course statistics
  static Future<Map<String, dynamic>> _getCourseStats(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/course-stats'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final courseStats = data['data'] as List;
        
        return {
          'totalCourses': courseStats.length,
          'courses': courseStats,
        };
      } else {
        throw Exception('Failed to fetch course stats: ${response.statusCode}');
      }
    } catch (e) {
      // Return default values if API fails
      return {
        'totalCourses': 0,
        'courses': [],
      };
    }
  }
  
  // Get payment statistics
  static Future<Map<String, dynamic>> _getPaymentStats(Map<String, String> headers) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/admin/payment-stats'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final paymentData = data['data'];
        
        return {
          'totalRevenue': paymentData['totalRevenue'] ?? 0,
          'totalPayments': paymentData['totalPayments'] ?? 0,
          'recentPayments': paymentData['recentPayments'] ?? [],
        };
      } else {
        throw Exception('Failed to fetch payment stats: ${response.statusCode}');
      }
    } catch (e) {
      // Return default values if API fails
      return {
        'totalRevenue': 0,
        'totalPayments': 0,
        'recentPayments': [],
      };
    }
  }
  
  // Get user statistics
  static Future<Map<String, dynamic>> _getUserStats(Map<String, String> headers) async {
    try {
      // Get total students count from Firebase source
      final response = await http.get(
        Uri.parse('${ApiConfig.baseUrl}/admin/students?page=1&limit=1&source=firebase'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'totalStudents': data['data']['total'] ?? 0,
          'source': data['data']['source'] ?? 'unknown',
        };
      } else {
        throw Exception('Failed to fetch user stats: ${response.statusCode}');
      }
    } catch (e) {
      // Return default values if API fails
      return {
        'totalStudents': 0,
        'source': 'fallback',
      };
    }
  }
  
  // Manual sync all users from Firebase to backend
  static Future<Map<String, dynamic>> manualSyncUsers() async {
    try {
      final headers = await _getHeaders();
      
      final response = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/admin/manual-sync-users'),
        headers: headers,
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['data'];
      } else {
        throw Exception('Sync failed: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Manual sync failed: $e');
    }
  }
  
  // Generate recent activity based on fetched data
  static List<Map<String, dynamic>> _generateRecentActivity(
    Map<String, dynamic> courseStats,
    Map<String, dynamic> paymentStats,
  ) {
    final List<Map<String, dynamic>> activity = [];
    
    // Add recent course activities
    final courses = courseStats['courses'] as List;
    for (var i = 0; i < courses.length && i < 3; i++) {
      final course = courses[i];
      activity.add({
        'icon': 'school',
        'title': 'Course Published',
        'subtitle': '${course['title']} is now live',
        'time': 'Recently',
      });
    }
    
    // Add recent payment activities
    final recentPayments = paymentStats['recentPayments'] as List;
    for (var i = 0; i < recentPayments.length && i < 2; i++) {
      final payment = recentPayments[i];
      activity.add({
        'icon': 'payment',
        'title': 'Payment Received',
        'subtitle': 'Payment for ${payment['courseId']?['title'] ?? 'course'}',
        'time': 'Recently',
      });
    }
    
    // Add default activities if no real data
    if (activity.isEmpty) {
      activity.addAll([
        {
          'icon': 'school',
          'title': 'Platform Ready',
          'subtitle': 'Your coaching platform is set up',
          'time': 'Just now',
        },
        {
          'icon': 'people',
          'title': 'Welcome Admin',
          'subtitle': 'Start managing your platform',
          'time': 'Just now',
        },
      ]);
    }
    
    return activity.take(5).toList();
  }
}