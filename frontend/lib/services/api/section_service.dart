import 'dart:convert';
import '../../models/section.dart';
import '../../models/lesson.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

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
        '${ApiConfig.sections}/course/$courseId',
        body: {
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

  /// Get sections by course
  Future<List<Section>> getSectionsByCourse(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.sections}/course/$courseId');
      response.validateStatus();

      final apiResponse = response.toApiResponseList((json) => Section.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch sections: $e');
    }
  }

  /// Update section
  Future<Section> updateSection({
    required String sectionId,
    String? title,
    int? order,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (order != null) data['order'] = order;

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
  Future<List<Section>> reorderSections(String courseId, List<Map<String, dynamic>> newOrder) async {
    try {
      // Extract section IDs from the newOrder list
      final sectionIds = newOrder.map((item) => item['_id'] as String).toList();

      final response = await _apiClient.post(
        '${ApiConfig.sections}/course/$courseId/reorder',
        body: {
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
  Future<List<Lesson>> reorderLessons(String sectionId, List<Map<String, dynamic>> newOrder) async {
    try {
      // Extract lesson IDs from the newOrder list
      final lessonIds = newOrder.map((item) => item['_id'] as String).toList();

      final response = await _apiClient.post(
        '${ApiConfig.lessons}/section/$sectionId/reorder',
        body: {
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

  /// Get lessons by section
  Future<List<Lesson>> getLessonsBySection(String sectionId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.lessons}/section/$sectionId');
      response.validateStatus();

      final apiResponse = response.toApiResponseList((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch lessons: $e');
    }
  }

  /// Create lesson
  Future<Lesson> createLesson({
    required String sectionId,
    required String courseId,
    required String title,
    String? description,
    String? videoId,
    String? notes,
    int order = 1,
    int duration = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.lessons}/section/$sectionId',
        body: {
          'courseId': courseId,
          'title': title,
          'description': description,
          'videoId': videoId,
          'notes': notes,
          'order': order,
          'duration': duration,
        },
      );
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create lesson: $e');
    }
  }

  /// Update lesson
  Future<Lesson> updateLesson({
    required String lessonId,
    String? title,
    String? description,
    String? videoId,
    String? notes,
    int? order,
    int? duration,
  }) async {
    try {
      final Map<String, dynamic> data = {};
      if (title != null) data['title'] = title;
      if (description != null) data['description'] = description;
      if (videoId != null) data['videoId'] = videoId;
      if (notes != null) data['notes'] = notes;
      if (order != null) data['order'] = order;
      if (duration != null) data['duration'] = duration;

      final response = await _apiClient.put(
        '${ApiConfig.lessons}/$lessonId',
        body: data,
      );
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update lesson: $e');
    }
  }

  /// Upload document and create lesson
  Future<Lesson> createLessonWithDocument({
    required String sectionId,
    required String courseId,
    required String title,
    String? description,
    String? documentPath,
    int order = 1,
    int duration = 0,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.lessons}/section/$sectionId',
        body: {
          'courseId': courseId,
          'title': title,
          'description': description,
          'videoId': null, // No video for document-based lesson
          'notes': documentPath, // Store document path as notes
          'order': order,
          'duration': duration,
        },
      );
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => Lesson.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create lesson with document: $e');
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
