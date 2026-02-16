import 'dart:convert';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Video API Service for handling video streaming and lesson content
class VideoApiService {
  final ApiClient _apiClient;

  VideoApiService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get signed streaming URL for a lesson's video content
  /// This verifies enrollment and generates a secure, time-limited URL
  Future<String> getVideoStreamUrl(String lessonId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.baseUrl}/videos/$lessonId/stream-url',
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return data['streamingUrl'] as String;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to get video stream URL');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get video stream URL: $e');
    }
  }

  /// Get lesson content (video URL and notes)
  Future<LessonContent> getLessonContent(String lessonId) async {
    try {
      // First get the lesson details
      final lessonResponse = await _apiClient.get(
        '${ApiConfig.baseUrl}/lessons/$lessonId',
      );

      lessonResponse.validateStatus();
      final lessonJson = jsonDecode(lessonResponse.body) as Map<String, dynamic>;
      
      if (lessonJson['success'] != true) {
        throw ApiException(lessonJson['message'] as String? ?? 'Failed to get lesson details');
      }
      
      final lessonData = lessonJson['data'] as Map<String, dynamic>;
      
      // If lesson has video content, get the streaming URL
      String? videoUrl;
      if (lessonData['videoId'] != null) {
        try {
          final videoResponse = await _apiClient.get(
            '${ApiConfig.baseUrl}/videos/$lessonId/stream-url',
          );
          
          videoResponse.validateStatus();
          final videoJson = jsonDecode(videoResponse.body) as Map<String, dynamic>;
          
          if (videoJson['success'] == true) {
            final videoData = videoJson['data'] as Map<String, dynamic>;
            videoUrl = videoData['streamingUrl'] as String?;
          }
        } catch (e) {
          // If video URL fails, continue with just notes
          print('Warning: Failed to get video URL: $e');
        }
      }
      
      return LessonContent(
        videoUrl: videoUrl,
        notes: lessonData['notes'] as String?,
        title: lessonData['title'] as String?,
        description: lessonData['description'] as String?,
        duration: lessonData['duration'] as int? ?? 0,
      );
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to get lesson content: $e');
    }
  }
}

/// Model for lesson content including both video and notes
class LessonContent {
  final String? videoUrl;
  final String? notes;
  final String? title;
  final String? description;
  final int duration;

  LessonContent({
    this.videoUrl,
    this.notes,
    this.title,
    this.description,
    required this.duration,
  });

  factory LessonContent.fromJson(Map<String, dynamic> json) {
    return LessonContent(
      videoUrl: json['videoUrl'] as String?,
      notes: json['notes'] as String?,
      title: json['title'] as String?,
      description: json['description'] as String?,
      duration: json['duration'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'videoUrl': videoUrl,
      'notes': notes,
      'title': title,
      'description': description,
      'duration': duration,
    };
  }
}

/// Custom exception for API errors
class ApiException implements Exception {
  final String message;
  
  ApiException(this.message);
  
  @override
  String toString() => 'ApiException: $message';
}
