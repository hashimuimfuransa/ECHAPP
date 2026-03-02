import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:http/http.dart' as http;
import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';
import '../../models/certificate.dart';

/// Service for certificate-related API operations
class CertificateService {
  final ApiClient _apiClient;

  CertificateService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get user's certificates
  Future<List<Certificate>> getCertificates() async {
    try {
      final response = await _apiClient.get('${ApiConfig.enrollments}/certificates');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        final data = jsonBody['data'] as List;
        
        return data
            .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        final message = jsonBody['message'];
        final errorMessage = (message is String) 
            ? message 
            : (message is Map ? (message['message'] ?? message.toString()) : 'Failed to fetch certificates');
        throw ApiException(errorMessage.toString());
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch certificates: $e');
    }
  }

  /// Download a specific certificate and save it to disk
  /// Returns the saved file path if successful
  Future<String?> downloadAndSaveCertificate(String certificateId, {String? fileName}) async {
    try {
      // Construct the direct download URL
      final downloadUrl = '${ApiConfig.baseUrl}/enrollments/certificates/$certificateId/download-file';
      
      // Get the certificate data as bytes
      final response = await _apiClient.getBytes(downloadUrl);
      response.validateStatus();
      
      final bytes = response.bodyBytes;
      final defaultFileName = fileName ?? 'certificate_$certificateId.pdf';
      
      if (kIsWeb) {
        // Handle web download if needed, but for now we focus on Windows
        return null;
      }
      
      String? savePath;
      
      if (Platform.isWindows || Platform.isMacOS || Platform.isLinux) {
        // Desktop platforms: use file picker for a robust "Save As" experience
        savePath = await FilePicker.platform.saveFile(
          dialogTitle: 'Save Certificate',
          fileName: defaultFileName,
          type: FileType.custom,
          allowedExtensions: ['pdf'],
        );
      } else {
        // Mobile platforms: save to downloads or documents
        Directory? directory;
        if (Platform.isAndroid) {
          directory = Directory('/storage/emulated/0/Download');
          if (!await directory.exists()) {
            directory = await getExternalStorageDirectory();
          }
        } else {
          directory = await getApplicationDocumentsDirectory();
        }
        
        if (directory != null) {
          savePath = p.join(directory.path, defaultFileName);
        }
      }
      
      if (savePath != null) {
        final file = File(savePath);
        await file.writeAsBytes(bytes);
        print('Certificate saved to: $savePath');
        return savePath;
      }
      
      return null;
    } catch (e) {
      print('Error in downloadAndSaveCertificate: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to download and save certificate: $e');
    }
  }

  /// Download a specific certificate (returns URL)
  Future<String> downloadCertificate(String certificateId) async {
    try {
      // Construct the direct download URL
      final downloadUrl = '${ApiConfig.baseUrl}/enrollments/certificates/$certificateId/download-file';
      
      // Return the download URL so the UI can handle the download
      return downloadUrl;
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to prepare certificate download: $e');
    }
  }

  /// Get certificates by course ID
  Future<List<Certificate>> getCertificatesByCourse(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.enrollments}/certificates');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        final data = jsonBody['data'] as List;
        
        // Filter certificates by course ID
        final filteredCertificates = data
            .where((cert) => cert['courseId'] == courseId)
            .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
            .toList();
            
        return filteredCertificates;
      } else {
        final message = jsonBody['message'];
        final errorMessage = (message is String) 
            ? message 
            : (message is Map ? (message['message'] ?? message.toString()) : 'Failed to fetch certificates');
        throw ApiException(errorMessage.toString());
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch certificates: $e');
    }
  }

  /// Check if user is eligible for a certificate for a specific course
  Future<bool> isCertificateEligible(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.enrollments}/$courseId/certificate-eligibility');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        return jsonBody['data']['eligible'] as bool? ?? false;
      } else {
        return false;
      }
    } catch (e) {
      print('Error checking certificate eligibility: $e');
      return false;
    }
  }
}