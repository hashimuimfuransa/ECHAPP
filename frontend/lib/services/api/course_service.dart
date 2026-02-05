import 'dart:convert';

import '../../models/course.dart';
import '../../models/api_response.dart';

import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Service for course-related API operations
class CourseService {
  final ApiClient _apiClient;

  CourseService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Search courses by query
  Future<List<Course>> searchCourses(String query, {bool showUnpublished = false}) async {
    try {
      final queryParams = <String, dynamic>{
        'search': query,
      };
      if (showUnpublished) {
        queryParams['showUnpublished'] = 'true';
      }

      final response = await _apiClient.get(
        ApiConfig.courses,
        queryParams: queryParams,
      );

      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      final coursesData = data['courses'] as List;
      
      final courses = coursesData
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final apiResponse = ApiResponse<List<Course>>(
        success: jsonBody['success'] as bool? ?? false,
        message: jsonBody['message'] as String? ?? '',
        data: courses,
        error: jsonBody['error'] != null 
            ? ApiError.fromJson(jsonBody['error'] as Map<String, dynamic>)
            : null,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to search courses: $e');
    }
  }

  /// Get all courses with optional category filter
  Future<List<Course>> getAllCourses({String? categoryId, bool showUnpublished = false}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (categoryId != null) {
        queryParams['category'] = categoryId;
      }
      if (showUnpublished) {
        queryParams['showUnpublished'] = 'true';
      }

      final response = await _apiClient.get(
        ApiConfig.courses,
        queryParams: queryParams,
      );

      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      final coursesData = data['courses'] as List;
      
      final courses = coursesData
          .map((item) => Course.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final apiResponse = ApiResponse<List<Course>>(
        success: jsonBody['success'] as bool? ?? false,
        message: jsonBody['message'] as String? ?? '',
        data: courses,
        error: jsonBody['error'] != null 
            ? ApiError.fromJson(jsonBody['error'] as Map<String, dynamic>)
            : null,
      );

      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch courses: $e');
    }
  }

  /// Get course by ID
  Future<Course> getCourseById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.courses}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse(Course.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course: $e');
    }
  }

  /// Create a new course
  Future<Course> createCourse({
    required String title,
    required String description,
    required double price,
    required int duration,
    required String level,
    String? thumbnail,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'description': description,
        'price': price,
        'duration': duration,
        'level': level,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (categoryId != null) 'categoryId': categoryId,
        if (isPublished != null) 'isPublished': isPublished,
        if (learningObjectives != null) 'learningObjectives': learningObjectives,
        if (requirements != null) 'requirements': requirements,
      };

      final response = await _apiClient.post(
        ApiConfig.courses,
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Course.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create course: $e');
    }
  }

  /// Update an existing course
  Future<Course> updateCourse({
    required String id,
    String? title,
    String? description,
    double? price,
    int? duration,
    String? level,
    String? thumbnail,
    String? categoryId,
    bool? isPublished,
    List<String>? learningObjectives,
    List<String>? requirements,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (price != null) 'price': price,
        if (duration != null) 'duration': duration,
        if (level != null) 'level': level,
        if (thumbnail != null) 'thumbnail': thumbnail,
        if (categoryId != null) 'categoryId': categoryId,
        if (isPublished != null) 'isPublished': isPublished,
        if (learningObjectives != null) 'learningObjectives': learningObjectives,
        if (requirements != null) 'requirements': requirements,
      };

      final response = await _apiClient.put(
        '${ApiConfig.courses}/$id',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Course.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update course: $e');
    }
  }

  /// Delete a course
  Future<void> deleteCourse(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.courses}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((_) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete course: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}