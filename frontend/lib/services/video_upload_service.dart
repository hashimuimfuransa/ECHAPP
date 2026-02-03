import 'dart:io';
import 'dart:convert';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:http_parser/http_parser.dart';
import 'package:flutter/services.dart';
import '../config/api_config.dart';

class VideoUploadService {
  static final ImagePicker _picker = ImagePicker();

  /// Pick a video from gallery or camera
  static Future<File?> pickVideo({
    ImageSource source = ImageSource.gallery,
    int maxDuration = 300, // 5 minutes default
  }) async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: source,
        maxDuration: Duration(seconds: maxDuration),
      );
      
      if (pickedFile != null) {
        return File(pickedFile.path);
      }
      return null;
    } on PlatformException catch (e) {
      if (e.code == 'camera_access_denied') {
        throw Exception('Camera access denied. Please enable camera permission in settings.');
      } else if (e.code == 'video_access_denied') {
        throw Exception('Video library access denied. Please enable video library permission in settings.');
      } else if (e.code == 'no_available_camera') {
        throw Exception('No camera available on this device.');
      } else {
        throw Exception('Failed to pick video: ${e.message}');
      }
    } catch (e) {
      throw Exception('Failed to pick video: $e');
    }
  }

  /// Upload video to backend
  static Future<Map<String, dynamic>> uploadVideo(File videoFile) async {
    try {
      // Determine content type
      final mimeType = lookupMimeType(videoFile.path) ?? 'video/mp4';
      
      // Read file as bytes
      final bytes = await videoFile.readAsBytes();
      
      // Create multipart request
      final uri = Uri.parse('${ApiConfig.baseUrl}/upload/video');
      final request = http.MultipartRequest('POST', uri);
      
      // Add file to request
      final multipartFile = http.MultipartFile.fromBytes(
        'video',
        bytes,
        filename: path.basename(videoFile.path),
        contentType: MediaType.parse(mimeType),
      );
      
      request.files.add(multipartFile);
      
      // Send request
      final response = await request.send();
      
      if (response.statusCode == 200) {
        final responseBody = await response.stream.bytesToString();
        // Parse JSON response
        final jsonResponse = json.decode(responseBody);
        
        if (jsonResponse['success'] == true) {
          return jsonResponse['data'];
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

  /// Pick and upload video in one step
  static Future<Map<String, dynamic>?> pickAndUploadVideo({
    ImageSource source = ImageSource.gallery,
    int maxDuration = 300,
  }) async {
    try {
      final videoFile = await pickVideo(
        source: source,
        maxDuration: maxDuration,
      );
      
      if (videoFile != null) {
        return await uploadVideo(videoFile);
      }
      return null;
    } catch (e) {
      throw Exception('Pick and upload failed: $e');
    }
  }
}