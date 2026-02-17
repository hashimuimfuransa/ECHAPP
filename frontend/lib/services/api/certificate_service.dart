import 'dart:convert';
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
      final response = await _apiClient.get('/enrollments/certificates');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        final data = jsonBody['data'] as List;
        
        return data
            .map((json) => Certificate.fromJson(json as Map<String, dynamic>))
            .toList();
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch certificates');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch certificates: $e');
    }
  }

  /// Download a specific certificate
  Future<String> downloadCertificate(String certificateId) async {
    try {
      // Construct the direct download URL
      final downloadUrl = '${ApiConfig.baseUrl}/api/enrollments/certificates/$certificateId/download-file';
      
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
      final response = await _apiClient.get('/enrollments/certificates');
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
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch certificates');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch certificates: $e');
    }
  }

  /// Check if user is eligible for a certificate for a specific course
  Future<bool> isCertificateEligible(String courseId) async {
    try {
      final response = await _apiClient.get('/enrollments/$courseId/certificate-eligibility');
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