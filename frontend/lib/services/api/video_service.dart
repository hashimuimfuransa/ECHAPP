import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/video.dart';
import '../../models/api_response.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

class VideoService {
  final ApiClient _apiClient;

  VideoService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Upload a video file directly to the upload endpoint
  Future<Video> uploadVideo({
    required XFile videoFile,
    required String courseId,
    String? sectionId,
    String? title,
    String? description,
    Function(double)? onProgress,
  }) async {
    try {
      // Get Firebase auth token
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await currentUser.getIdToken(true);
      
      // Read file as bytes
      final bytes = await videoFile.readAsBytes();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConfig.upload}/video');
      final request = http.MultipartRequest('POST', uri);
      
      // Add authentication header
      request.headers.addAll({
        'Authorization': 'Bearer $idToken',
      });
      
      // Add form fields
      request.fields['courseId'] = courseId;
      if (sectionId != null) request.fields['sectionId'] = sectionId;
      request.fields['title'] = title ?? 'Untitled Video';
      if (description != null) request.fields['description'] = description;
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: videoFile.name,
      );
      request.files.add(multipartFile);
      
      // Send request and track progress
      final response = await request.send();
      
      // If the response includes an uploadId, we can track progress
      final responseBody = await response.stream.bytesToString();
      
      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonResponse = json.decode(responseBody);
        
        if (jsonResponse['success'] == true) {
          final data = jsonResponse['data'];
          
          return Video(
            id: data['videoId'] ?? data['s3Key'] ?? '',
            title: title ?? 'Untitled Video',
            description: description,
            url: data['videoUrl'] ?? '',
            duration: 0,
            courseId: courseId,
            sectionId: sectionId,
            thumbnail: null,
            createdAt: DateTime.now(),
            updatedAt: DateTime.now(),
          );
        } else {
          throw Exception('Upload failed: ${jsonResponse['message']}');
        }
      } else {
        throw Exception('Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Video upload failed: $e');
    }
  }

  /// Track upload progress using the upload ID
  Stream<double> trackUploadProgress(String uploadId) async* {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await currentUser.getIdToken(true);
      final uri = Uri.parse('${ApiConfig.upload}/progress/$uploadId');
      
      while (true) {
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $idToken'},
        );
        
        if (response.statusCode == 200) {
          final data = json.decode(response.body)['data'];
          final progress = data['progress'].toDouble();
          yield progress;
          
          // If upload is complete or failed, stop tracking
          final status = data['status'];
          if (status == 'completed' || status == 'error') {
            break;
          }
        } else {
          yield -1; // Error indicator
          break;
        }
        
        // Wait 1 second before checking progress again
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Error tracking upload progress: $e');
      yield -1; // Error indicator
    }
  }

  /// Get all videos (admin only)
  Future<List<Video>> getAllVideos({int page = 1, int limit = 10}) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };

      final response = await _apiClient.get(
        '${ApiConfig.videos}/all',
        queryParams: queryParams,
      );

      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as List;
      
      final videos = data
          .map((item) => Video.fromJson(item as Map<String, dynamic>))
          .toList();
      
      final apiResponse = ApiResponse<List<Video>>(
        success: jsonBody['success'] as bool? ?? false,
        message: jsonBody['message'] as String? ?? '',
        data: videos,
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
      throw ApiException('Failed to fetch videos: $e');
    }
  }

  /// Get all videos for a specific course
  Future<List<Video>> getVideosByCourse(String courseId) async {
    try {
      // For now, return empty list since we don't have a dedicated endpoint
      // This would need to be implemented in the backend
      return [];
    } catch (e) {
      throw Exception('Failed to fetch videos: $e');
    }
  }

  /// Delete a video (stub implementation)
  Future<void> deleteVideo(String videoId) async {
    try {
      // This would need backend implementation
      // For now, just simulate success
    } catch (e) {
      throw Exception('Failed to delete video: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}