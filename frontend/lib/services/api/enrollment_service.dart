import 'dart:convert';

import '../../models/course.dart';
import '../../models/user.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Service for enrollment-related API operations
class EnrollmentService {
  final ApiClient _apiClient;

  EnrollmentService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Enroll in a course
  Future<void> enrollInCourse(String courseId) async {
    try {
      final requestBody = {
        'courseId': courseId,
      };

      final response = await _apiClient.post(
        ApiConfig.enrollments,
        body: requestBody,
      );

      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to enroll in course');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to enroll in course: $e');
    }
  }

  /// Get user's enrolled courses
  Future<List<Course>> getEnrolledCourses() async {
    try {
      print('Fetching enrolled courses...');
      final response = await _apiClient.get('${ApiConfig.enrollments}/my-courses');
      response.validateStatus();
      
      // Since the backend returns enrollments with course data nested in 'courseId', 
      // we need to create a custom parser
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      print('Enrollment API response: ${jsonBody['success']}, Data length: ${(jsonBody['data'] as List?)?.length ?? 0}');
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List;
        print('Raw enrollment data: $data');
        
        // The backend returns enrollments with populated courseId, so we need to extract the course data
        final courses = data.map((enrollment) {
          final enrollmentMap = enrollment as Map<String, dynamic>;
          final courseData = enrollmentMap['courseId'] as Map<String, dynamic>?;
          
          if (courseData != null) {
            print('Processing enrollment: ${enrollmentMap['_id']}, Course ID: ${courseData['_id']}, Thumbnail: ${courseData['thumbnail'] ?? 'none'}');
            return Course.fromJson(courseData);
          } else {
            print('Warning: No course data found in enrollment: ${enrollmentMap['_id']}');
            // Fallback - create a minimal course object
            return Course(
              id: enrollmentMap['courseId']?.toString() ?? '',
              title: 'Unknown Course',
              description: '',
              price: 0,
              duration: 0,
              level: 'beginner',
              isPublished: false,
              createdBy: User(id: '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
              createdAt: DateTime.now(),
            );
          }
        }).toList();
        
        print('Processed ${courses.length} enrolled courses');
        return courses;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch enrolled courses');
      }
    } catch (e) {
      print('Error in getEnrolledCourses: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch enrolled courses: $e');
    }
  }

  /// Check if user is enrolled in a specific course
  Future<bool> isEnrolledInCourse(String courseId) async {
    try {
      print('Checking if user is enrolled in course: $courseId');
      final enrolledCourses = await getEnrolledCourses();
      print('User has ${enrolledCourses.length} enrolled courses');
      
      final isEnrolled = enrolledCourses.any((course) => course.id.toString() == courseId.toString());
      print('User enrolled in course $courseId: $isEnrolled');
      
      return isEnrolled;
    } catch (e) {
      print('Error checking enrollment for course $courseId: $e');
      // If there's an error checking enrollment, assume not enrolled
      return false;
    }
  }
}