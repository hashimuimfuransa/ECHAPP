import 'dart:convert';
import '../../models/section.dart';
import '../../models/lesson.dart';
import '../../models/api_response.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

class SectionService {
  final ApiClient _apiClient;

  SectionService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get all sections for a course
  Future<List<Section>> getSectionsByCourse(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.sections}/course/$courseId');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => _parseSectionList(json));
      
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

  /// Create a new section
  Future<Section> createSection({
    required String courseId,
    required String title,
    required int order,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'order': order,
      };

      final response = await _apiClient.post(
        '${ApiConfig.sections}/course/$courseId',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Section.fromJson);
      
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

  /// Update a section
  Future<Section> updateSection({
    required String sectionId,
    String? title,
    int? order,
  }) async {
    try {
      final requestBody = <String, dynamic>{};
      if (title != null) requestBody['title'] = title;
      if (order != null) requestBody['order'] = order;

      final response = await _apiClient.put(
        '${ApiConfig.sections}/$sectionId',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Section.fromJson);
      
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

  /// Delete a section
  Future<void> deleteSection(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.sections}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((_) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete section: $e');
    }
  }

  /// Reorder sections
  Future<void> reorderSections(String courseId, List<Map<String, dynamic>> newOrder) async {
    try {
      final requestBody = {
        'sections': newOrder,
      };

      final response = await _apiClient.post(
        '${ApiConfig.sections}/course/$courseId/reorder',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse((json) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reorder sections: $e');
    }
  }

  /// Get course content (sections with lessons)
  Future<Map<String, dynamic>> getCourseContent(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.lessons}/course/$courseId/content');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => _parseCourseContent(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course content: $e');
    }
  }

  /// Get all lessons for a section
  Future<List<Lesson>> getLessonsBySection(String sectionId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.lessons}/section/$sectionId');
      response.validateStatus();

      final apiResponse = response.toApiResponse((json) => _parseLessonList(json));
      
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

  /// Create a new lesson
  Future<Lesson> createLesson({
    required String sectionId,
    required String title,
    String? description,
    String? videoId,
    String? notes,
    required int order,
    required int duration,
  }) async {
    try {
      final requestBody = {
        'title': title,
        'order': order,
        'duration': duration,
      };
      if (description != null) requestBody['description'] = description;
      if (videoId != null) requestBody['videoId'] = videoId;
      if (notes != null) requestBody['notes'] = notes;

      final response = await _apiClient.post(
        '${ApiConfig.lessons}/section/$sectionId',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Lesson.fromJson);
      
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

  /// Update a lesson
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
      final requestBody = <String, dynamic>{};
      if (title != null) requestBody['title'] = title;
      if (description != null) requestBody['description'] = description;
      if (videoId != null) requestBody['videoId'] = videoId;
      if (notes != null) requestBody['notes'] = notes;
      if (order != null) requestBody['order'] = order;
      if (duration != null) requestBody['duration'] = duration;

      final response = await _apiClient.put(
        '${ApiConfig.lessons}/$lessonId',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(Lesson.fromJson);
      
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

  /// Delete a lesson
  Future<void> deleteLesson(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.lessons}/$id');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((_) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete lesson: $e');
    }
  }

  /// Reorder lessons in a section
  Future<void> reorderLessons(String sectionId, List<Map<String, dynamic>> newOrder) async {
    try {
      final requestBody = {
        'lessons': newOrder,
      };

      final response = await _apiClient.post(
        '${ApiConfig.lessons}/section/$sectionId/reorder',
        body: requestBody,
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse((json) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to reorder lessons: $e');
    }
  }

  // Helper methods to parse lists
  List<Section> _parseSectionList(dynamic json) {
    if (json is List) {
      return json.map((item) => Section.fromJson(item)).toList();
    } else if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        final sectionsData = data['sections'];
        if (sectionsData is List) {
          return sectionsData.map((item) => Section.fromJson(item)).toList();
        }
      }
    }
    return [];
  }

  List<Lesson> _parseLessonList(dynamic json) {
    if (json is List) {
      return json.map((item) => Lesson.fromJson(item)).toList();
    } else if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is List) {
        return data.map((item) => Lesson.fromJson(item)).toList();
      }
    }
    return [];
  }

  Map<String, dynamic> _parseCourseContent(dynamic json) {
    if (json is Map<String, dynamic>) {
      final data = json['data'];
      if (data is Map<String, dynamic>) {
        return data;
      }
    }
    return {};
  }

  void dispose() {
    _apiClient.dispose();
  }
}