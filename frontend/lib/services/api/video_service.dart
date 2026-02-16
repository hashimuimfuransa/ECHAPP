import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/video.dart';
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
    bool createLesson = true, // New parameter to control automatic lesson creation
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
      request.fields['createLesson'] = createLesson.toString(); // Add createLesson parameter
      
      // Add file
      final multipartFile = http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: videoFile.name,
      );
      request.files.add(multipartFile);
      
      // Send request and track progress
      final response = await request.send();
      
      // Track progress in a separate stream if callback is provided
      if (onProgress != null) {
        // Listen for upload progress updates
        // First, we need to get the uploadId from the response
        final responseBody = await response.stream.bytesToString();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = json.decode(responseBody);
          
          if (jsonResponse['success'] == true) {
            final data = jsonResponse['data'];
            
            // If an uploadId is provided in the response, track the progress
            final uploadId = data['uploadId'];
            if (uploadId != null) {
              // Start tracking progress in the background
              _trackUploadProgress(uploadId, onProgress);
            }
            
            // If a lesson was created during upload, return video info from the lesson
            if (data['lesson'] != null) {
              final lesson = data['lesson'];
              return Video(
                id: lesson['videoId'] ?? lesson['_id'] ?? data['videoId'] ?? data['s3Key'] ?? '',
                title: lesson['title'] ?? title ?? 'Untitled Video',
                description: lesson['description'] ?? description,
                url: data['videoUrl'] ?? '',
                duration: lesson['duration'] ?? 0,
                courseId: lesson['courseId'] ?? courseId,
                sectionId: lesson['sectionId'] ?? sectionId,
                videoId: lesson['videoId'] ?? data['videoId'],
                thumbnail: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            } else {
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
            }
          } else {
            throw Exception('Upload failed: ${jsonResponse['message']}');
          }
        } else {
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      } else {
        // If no progress callback, just wait for the response normally
        final responseBody = await response.stream.bytesToString();
        
        if (response.statusCode == 200 || response.statusCode == 201) {
          final jsonResponse = json.decode(responseBody);
          
          if (jsonResponse['success'] == true) {
            final data = jsonResponse['data'];
            
            // If a lesson was created during upload, return video info from the lesson
            if (data['lesson'] != null) {
              final lesson = data['lesson'];
              return Video(
                id: lesson['videoId'] ?? lesson['_id'] ?? data['videoId'] ?? data['s3Key'] ?? '',
                title: lesson['title'] ?? title ?? 'Untitled Video',
                description: lesson['description'] ?? description,
                url: data['videoUrl'] ?? '',
                duration: lesson['duration'] ?? 0,
                courseId: lesson['courseId'] ?? courseId,
                sectionId: lesson['sectionId'] ?? sectionId,
                videoId: lesson['videoId'] ?? data['videoId'],
                thumbnail: null,
                createdAt: DateTime.now(),
                updatedAt: DateTime.now(),
              );
            } else {
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
            }
          } else {
            throw Exception('Upload failed: ${jsonResponse['message']}');
          }
        } else {
          throw Exception('Upload failed with status: ${response.statusCode}');
        }
      }
    } catch (e) {
      throw Exception('Video upload failed: $e');
    }
  }

  /// Track upload progress in the background
  Future<void> _trackUploadProgress(String uploadId, Function(double) onProgress) async {
    try {
      final currentUser = firebase_auth.FirebaseAuth.instance.currentUser;
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }
      
      final idToken = await currentUser.getIdToken(true);
      final uri = Uri.parse('${ApiConfig.upload}/progress/$uploadId');
      
      // Poll for progress updates
      while (true) {
        final response = await http.get(
          uri,
          headers: {'Authorization': 'Bearer $idToken'},
        );
        
        if (response.statusCode == 200) {
          final responseData = json.decode(response.body);
          if (responseData['success']) {
            final data = responseData['data'];
            final progress = data['progress'].toDouble();
            onProgress(progress);
            
            // If upload is complete or failed, stop tracking
            final status = data['status'];
            if (status == 'completed' || status == 'error') {
              break;
            }
          }
        } else {
          // If there's an error getting progress, report as error
          onProgress(-1);
          break;
        }
        
        // Wait 1 second before checking progress again
        await Future.delayed(const Duration(seconds: 1));
      }
    } catch (e) {
      print('Error tracking upload progress: $e');
      // Report error through the callback
      onProgress(-1);
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
      
      print('Video Service: getAllVideos raw response: ${response.body}');
      print('Video Service: getAllVideos status code: ${response.statusCode}');
      
      // Parse the response manually to see what's happening
      final responseBody = response.body;
      final json = jsonDecode(responseBody) as Map<String, dynamic>;
      print('Video Service: getAllVideos parsed JSON: $json');
      print('Video Service: getAllVideos data field type: ${json['data']?.runtimeType}');
      print('Video Service: getAllVideos data field value: ${json['data']}');
      
      final apiResponse = response.toApiResponseList(Video.fromJson);

      print('Video Service: getAllVideos parsed response - Success: ${apiResponse.success}, Data type: ${apiResponse.data?.runtimeType}, Length: ${apiResponse.data?.length}');
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      print('Video Service: Error in getAllVideos: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch videos: $e');
    }
  }

  /// Get all videos for a specific course
  Future<List<Video>> getVideosByCourse(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.videos}/course/$courseId');
      response.validateStatus();
      
      print('Video Service: Raw response body: ${response.body}');
      
      final apiResponse = response.toApiResponseList(Video.fromJson);
      
      print('Video Service: Parsed response - Success: ${apiResponse.success}, Data type: ${apiResponse.data?.runtimeType}, Length: ${apiResponse.data?.length}');
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      print('Video Service: Error fetching videos: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch videos: $e');
    }
  }

  /// Delete a video
  Future<void> deleteVideo(String videoId) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.videos}/delete/$videoId');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((_) => null);
      
      if (!apiResponse.success) {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete video: $e');
    }
  }

  void dispose() {
    _apiClient.dispose();
  }
}
