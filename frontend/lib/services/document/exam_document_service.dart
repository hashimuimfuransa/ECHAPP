import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import 'dart:io' show File;
import 'dart:typed_data';
import 'package:http_parser/http_parser.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart' show kIsWeb;

class ExamDocumentException implements Exception {
  final String message;
  ExamDocumentException(this.message);
  
  @override
  String toString() => 'ExamDocumentException: $message';
}

/// Service for uploading documents for exam creation and processing
class ExamDocumentService {
  /// Upload document and create exam from it using AI processing
  Future<Map<String, dynamic>> uploadDocumentForExamCreation({
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
        Uri.parse('${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/documents/upload-for-exam'),
      );

      // Add file to request
      if (kIsWeb) {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              file.bytes!,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else {
          throw ExamDocumentException('File data is not available for web upload');
        }
      } else {
        if (file.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'document',
              file.bytes!,
              filename: file.name,
              contentType: _getMimeType(file.extension),
            ),
          );
        } else {
          throw ExamDocumentException('File bytes not available');
        }
      }

      // Add form fields
      request.fields['courseId'] = courseId;
      request.fields['sectionId'] = sectionId;
      request.fields['examType'] = examType;
      if (title != null) request.fields['title'] = title;
      if (passingScore != null) request.fields['passingScore'] = passingScore.toString();
      if (timeLimit != null) request.fields['timeLimit'] = timeLimit.toString();

      // Add authorization header
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        final token = await user.getIdToken();
        request.headers['Authorization'] = 'Bearer $token';
      }

      // Send request with extended timeout for AI processing
      var client = http.Client();
      var streamedResponse = await client.send(request).timeout(
        const Duration(minutes: 10), // 10 minute timeout for AI processing
      );
      var response = await http.Response.fromStream(streamedResponse);
      client.close();

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          // Return the full response structure to match backend format
          return responseBody;
        } else {
          throw ExamDocumentException(responseBody['message'] ?? 'Upload failed');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw ExamDocumentException(errorBody['message'] ?? 'Upload failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ExamDocumentException) rethrow;
      throw ExamDocumentException('Failed to upload document for exam creation: $e');
    }
  }

  /// Process existing document to create exam
  Future<Map<String, dynamic>> processExistingDocument({
    required String documentKey,
    required String courseId,
    required String sectionId,
    required String examType,
    String? title,
    int? passingScore,
    int? timeLimit,
  }) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/exam-processing/process-document/$documentKey');
      
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': await _getAuthToken(),
        },
        body: json.encode({
          'courseId': courseId,
          'sectionId': sectionId,
          'examType': examType,
          if (title != null) 'title': title,
          if (passingScore != null) 'passingScore': passingScore,
          if (timeLimit != null) 'timeLimit': timeLimit,
        }),
      ).timeout(const Duration(minutes: 5));

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          // Return the full response structure to match backend format
          return responseBody;
        } else {
          throw ExamDocumentException(responseBody['message'] ?? 'Processing failed');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw ExamDocumentException(errorBody['message'] ?? 'Processing failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ExamDocumentException) rethrow;
      throw ExamDocumentException('Failed to process existing document: $e');
    }
  }

  /// Get exam processing status
  Future<Map<String, dynamic>> getProcessingStatus(String examId) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/exam-processing/status/$examId');
      
      final response = await http.get(
        url,
        headers: {
          'Authorization': await _getAuthToken(),
        },
      );

      if (response.statusCode >= 200 && response.statusCode < 300) {
        final responseBody = json.decode(response.body);
        if (responseBody['success'] == true) {
          // Return the full response structure to match backend format
          return responseBody;
        } else {
          throw ExamDocumentException(responseBody['message'] ?? 'Failed to get status');
        }
      } else {
        final errorBody = json.decode(response.body);
        throw ExamDocumentException(errorBody['message'] ?? 'Status check failed with status: ${response.statusCode}');
      }
    } catch (e) {
      if (e is ExamDocumentException) rethrow;
      throw ExamDocumentException('Failed to get processing status: $e');
    }
  }

  /// Get MIME type based on file extension
  MediaType _getMimeType(String? extension) {
    if (extension == null) return MediaType('application', 'octet-stream');
    
    final mimeTypes = {
      'pdf': MediaType('application', 'pdf'),
      'doc': MediaType('application', 'msword'),
      'docx': MediaType('application', 'vnd.openxmlformats-officedocument.wordprocessingml.document'),
      'txt': MediaType('text', 'plain'),
      'ppt': MediaType('application', 'vnd.ms-powerpoint'),
      'pptx': MediaType('application', 'vnd.openxmlformats-officedocument.presentationml.presentation'),
      'xls': MediaType('application', 'vnd.ms-excel'),
      'xlsx': MediaType('application', 'vnd.openxmlformats-officedocument.spreadsheetml.sheet'),
    };
    
    return mimeTypes[extension.toLowerCase()] ?? MediaType('application', 'octet-stream');
  }

  /// Get authentication token
  Future<String> _getAuthToken() async {
    final user = firebase_auth.FirebaseAuth.instance.currentUser;
    if (user != null) {
      final token = await user.getIdToken();
      if (token != null) {
        return token;
      }
    }
    throw ExamDocumentException('User not authenticated');
  }
}