import 'dart:convert';
import 'package:excellence_coaching_hub/models/course.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

/// Service for certificate-related API operations
class CertificateService {
  final ApiClient _apiClient;

  CertificateService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get user's certificates
  Future<List<Course>> getCertificates() async {
    try {
      final response = await _apiClient.get('${ApiConfig.enrollments}/certificates');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        final data = jsonBody['data'] as List;
        
        // The backend should return enrollment data with course information
        // where certificateEligible is true
        final certificates = data.map((enrollment) {
          final enrollmentMap = enrollment as Map<String, dynamic>;
          final courseData = enrollmentMap['courseId'] as Map<String, dynamic>?;
          
          if (courseData != null) {
            return Course.fromJson(courseData);
          } else {
            // Fallback for malformed data
            return Course(
              id: enrollmentMap['courseId']?.toString() ?? '',
              title: 'Unknown Course',
              description: '',
              price: 0,
              duration: 0,
              level: 'beginner',
              isPublished: false,
              createdBy: Course.fromJson(enrollmentMap).createdBy,
              createdAt: DateTime.now(),
            );
          }
        }).toList();
        
        return certificates;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch certificates');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch certificates: $e');
    }
  }

  /// Download a specific certificate
  Future<String> downloadCertificate(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.enrollments}/$courseId/certificate/download');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true && jsonBody['data'] != null) {
        return jsonBody['data']['downloadUrl'] as String;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to download certificate');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to download certificate: $e');
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