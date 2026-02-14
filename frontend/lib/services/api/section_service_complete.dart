import 'dart:convert';
import '../../models/section.dart';
import '../../models/lesson.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';
import '../../models/api_exception.dart';

class SectionService {
  final ApiClient _apiClient;

  SectionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Create a new section
  Future<Section> createSection({
    required String courseId,
    required String title,
    int order = 1,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.sections}',
        body: {
          'courseId': courseId,
          'title': title,
          'order': order,
        },
      );
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Section.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create section: $e');
    }
  }

  /// Update section
  Future<Section> updateSection(String sectionId, Map<String, dynamic> data) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.sections}/$sectionId',
        body: data,
      );
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Section.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update section: $e');
    }
  }

  /// Delete section
  Future<void> deleteSection(String sectionId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.sections}/$sectionId');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => json);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete section: $e');
    }
  }

  /// Delete lesson
  Future<void> deleteLesson(String lessonId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.lessons}/$lessonId');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => json);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete lesson: $e');
    }
  }

  /// Reorder sections
  Future<List<Section>> reorderSections(String courseId, List<String> sectionIds) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.sections}/reorder',
        body: {
          'courseId': courseId,
          'sectionIds': sectionIds,
        },
      );
      response.validateStatus();

      final apiResponse = response.toApiResponseList((json) => Section.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reorder sections: $e');
    }
  }

  /// Reorder lessons
  Future<List<Lesson>> reorderLessons(String sectionId, List<String> lessonIds) async {
    try {
      final response = await _apiClient.put(
        '${ApiConfig.lessons}/reorder',
        body: {
          'sectionId': sectionId,
          'lessonIds': lessonIds,
        },
      );
      response.validateStatus();

      final apiResponse = response.toApiResponseList((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reorder lessons: $e');
    }
  }

  /// Get course content (sections with lessons)
  Future<Map<String, dynamic>> getCourseContent(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.lessons}/course/$courseId/content');
      response.validateStatus();

      // Parse the raw response body directly since we need the full structure
      final responseBody = response.body;
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      final data = json['data'] as Map<String, dynamic>? ?? {};
      
      print('SectionService: Raw response data: $data');
      
      return data;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course content: $e');
    }
  }

  // Helper methods to parse lists

  Map<String, dynamic> _parseCourseContent(dynamic json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        // Return the entire data object which contains both 'course' and 'sections'
        return data;
      }
    }
    return {'sections': []}; // Return empty sections array instead of empty map
  }

  void dispose() {
    _apiClient.dispose();
  }
}
