import 'dart:convert';
import 'package:http/http.dart' as http;
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
      // Parallelize lesson details and video URL fetch to reduce wait time
      // The video URL fetch is started immediately but only used if lessonData['videoId'] is present
      final results = await Future.wait([
        _apiClient.get('${ApiConfig.baseUrl}/lessons/$lessonId'),
        _apiClient.get('${ApiConfig.baseUrl}/videos/$lessonId/stream-url').catchError((e) {
          // If video URL fetch fails, return a mock error response
          return http.Response(jsonEncode({'success': false, 'message': 'Video fetch failed'}), 404);
        }),
      ]);

      final lessonResponse = results[0];
      final videoResponse = results[1];

      lessonResponse.validateStatus();
      final lessonJson = jsonDecode(lessonResponse.body) as Map<String, dynamic>;
      
      if (lessonJson['success'] != true) {
        throw ApiException(lessonJson['message'] as String? ?? 'Failed to get lesson details');
      }
      
      final lessonData = lessonJson['data'] as Map<String, dynamic>;
      
      // If lesson has video content, extract the streaming URL from the parallelized request
      String? videoUrl;
      if (lessonData['videoId'] != null && videoResponse.statusCode == 200) {
        try {
          final videoJson = jsonDecode(videoResponse.body) as Map<String, dynamic>;
          if (videoJson['success'] == true) {
            final videoData = videoJson['data'] as Map<String, dynamic>;
            videoUrl = videoData['streamingUrl'] as String?;
          }
        } catch (e) {
          // If video URL parsing fails, continue with just notes
          print('Warning: Failed to parse video URL response: $e');
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
