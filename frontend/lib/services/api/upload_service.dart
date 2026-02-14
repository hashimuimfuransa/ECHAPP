import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'dart:io';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UploadService {
  /// Upload document and create exam from it using AI processing
  Future<Map<String, dynamic>> uploadDocumentWithExamCreation({
    required PlatformFile file,
    required String courseId,
    required String sectionId,
    required String examType,
    String? title,
    int? passingScore,
    int? timeLimit,
  }) async {
    try {
      // Create multipart request
      var request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.upload}/document'),
      );

      // Add file to request
      if (file.bytes == null) {
        // If bytes is null, try to read from path if available
        if (file.path != null) {
          final fileData = await File(file.path!).readAsBytes();
          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              fileData,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else {
          throw ApiException('File data is unavailable');
        }
      } else {
        request.files.add(
          http.MultipartFile.fromBytes(
            'document',
            file.bytes!,
            filename: file.name,
            contentType: _getMimeType(file.extension),
          ),
        );
      }

      // Add form fields
      request.fields['courseId'] = courseId;
      request.fields['sectionId'] = sectionId;
      request.fields['examType'] = examType;
      request.fields['createExamFromDocument'] = 'true';
      if (title != null) request.fields['title'] = title;
      if (passingScore != null) request.fields['passingScore'] = passingScore.toString();
      if (timeLimit != null) request.fields['timeLimit'] = timeLimit.toString();

      // Add authorization header
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Send request
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          return responseBody['data'] ?? {};
        } else {
          throw ApiException(responseBody['message'] ?? 'Upload failed');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw ApiException(errorBody['message'] ?? 'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to upload document: $e');
    }
  }

  /// Get MIME type from file extension
  MediaType? _getMimeType(String? extension) {
    if (extension == null) return null;
    
    switch (extension.toLowerCase()) {
      case 'pdf':
        return MediaType('application', 'pdf');
      case 'doc':
        return MediaType('application', 'msword');
      case 'docx':
        return MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document');
      case 'txt':
        return MediaType('text', 'plain');
      default:
        return MediaType('application', 'octet-stream');
    }
  }
}

class ApiException implements Exception {
  final String message;

  ApiException(this.message);

  @override
  String toString() => 'ApiException: $message';
}
