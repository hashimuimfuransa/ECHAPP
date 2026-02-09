import 'dart:convert';
import 'package:excellence_coaching_hub/config/api_config.dart';
import '../infrastructure/api_client.dart';
import 'package:excellence_coaching_hub/models/exam.dart' as exam_model;

/// Service for exam-related API operations
class ExamService {
  final ApiClient _apiClient;

  ExamService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get all exams (admin only)
  Future<ExamListResponse> getAllExams({ 
    String? courseId,
    int page = 1,
    int limit = 10,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      
      if (courseId != null) queryParams['courseId'] = courseId;

      final response = await _apiClient.get(
        ApiConfig.exams,
        queryParams: queryParams,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return ExamListResponse.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exams');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exams: $e');
    }
  }

  /// Get exam by ID
  Future<exam_model.Exam> getExamById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/$id');
      response.validateStatus();

      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return exam_model.Exam.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exam');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exam: $e');
    }
  }

  /// Update exam (admin only)
  Future<exam_model.Exam> updateExam({
    required String id,
    String? title,
    String? type,
    int? passingScore,
    int? timeLimit,
    bool? isPublished,
  }) async {
    try {
      final requestBody = <String, dynamic>{
        if (title != null) 'title': title,
        if (type != null) 'type': type,
        if (passingScore != null) 'passingScore': passingScore,
        if (timeLimit != null) 'timeLimit': timeLimit,
        if (isPublished != null) 'isPublished': isPublished,
      };

      final response = await _apiClient.put(
        '${ApiConfig.exams}/$id',
        body: requestBody,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return exam_model.Exam.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to update exam');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update exam: $e');
    }
  }

  /// Delete exam (admin only)
  Future<void> deleteExam(String id) async {
    try {
      final response = await _apiClient.delete('${ApiConfig.exams}/$id');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] != true) {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to delete exam');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to delete exam: $e');
    }
  }

  /// Get exams for a course (student route)
  Future<List<exam_model.Exam>> getCourseExams(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/course/$courseId');
      response.validateStatus();
      
      final apiResponse = response.toApiResponseList(exam_model.Exam.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course exams: $e');
    }
  }

  /// Get exams by section
  Future<List<exam_model.Exam>> getExamsBySection(String sectionId) async {
    try {
      final response = await _apiClient.get(
        '${ApiConfig.exams}/section/$sectionId',
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        return data.map((json) => exam_model.Exam.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exams for section');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exams for section: $e');
    }
  }

  /// Get all exams for a section (admin only - includes unpublished exams)
  Future<List<exam_model.Exam>> getSectionExamsAdmin(String sectionId) async {
    print('ExamService: getSectionExamsAdmin called for section: $sectionId');
    try {
      final url = '${ApiConfig.exams}/section/$sectionId/admin';
      print('ExamService: Making request to: $url');
      
      final response = await _apiClient.get(url);
      print('ExamService: Response status: ${response.statusCode}');
      print('ExamService: Response headers: ${response.headers}');
      print('ExamService: Response body length: ${response.body.length}');
      
      // Log first 200 characters of response for debugging
      if (response.body.length > 0) {
        final preview = response.body.substring(0, response.body.length > 200 ? 200 : response.body.length);
        print('ExamService: Response preview: $preview');
      }

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        print('ExamService: Successfully parsed ${data.length} exams');
        return data.map((json) => exam_model.Exam.fromJson(json as Map<String, dynamic>)).toList();
      } else {
        print('ExamService: API returned error: ${jsonBody['message']}');
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch section exams');
      }
    } catch (e) {
      print('ExamService: Error in getSectionExamsAdmin: $e');
      if (e is ApiException) {
        print('ExamService: ApiException details - Status: ${e.statusCode}, Message: ${e.message}');
        rethrow;
      }
      throw ApiException('Failed to fetch section exams: $e');
    }
  }

  /// Get exam questions
  Future<Map<String, dynamic>> getExamQuestions(String examId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/$examId/questions');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((json) => json);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exam questions: $e');
    }
  }

  /// Get exam results
  Future<ExamResult> getExamResults(String examId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/$examId/results');
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((json) => ExamResult.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exam results: $e');
    }
  }

  /// Create exam (admin only)
  Future<exam_model.Exam> createExam({
    required String courseId,
    required String sectionId,
    required String title,
    required String type,
    required int passingScore,
    int? timeLimit,
    bool? isPublished,
  }) async {
    try {
      final requestBody = {
        'courseId': courseId,
        'sectionId': sectionId,
        'title': title,
        'type': type,
        'passingScore': passingScore,
        if (timeLimit != null) 'timeLimit': timeLimit,
        if (isPublished != null) 'isPublished': isPublished,
      };

      final response = await _apiClient.post(ApiConfig.exams, body: requestBody);
      response.validateStatus();
      
      final apiResponse = response.toApiResponse(exam_model.Exam.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create exam: $e');
    }
  }

  /// Submit exam answers
  Future<ExamResult> submitExam({
    required String examId,
    required List<Map<String, dynamic>> answers,
  }) async {
    try {
      final response = await _apiClient.post(
        '${ApiConfig.exams}/$examId/submit',
        body: {'answers': answers},
      );
      response.validateStatus();
      
      final apiResponse = response.toApiResponse((json) => ExamResult.fromJson(json));
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to submit exam: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

// Data models
class ExamListResponse {
  final List<exam_model.Exam> exams;
  final int totalPages;
  final int currentPage;
  final int total;

  ExamListResponse({
    required this.exams,
    required this.totalPages,
    required this.currentPage,
    required this.total,
  });

  factory ExamListResponse.fromJson(Map<String, dynamic> json) {
    return ExamListResponse(
      exams: (json['exams'] as List)
          .map((item) => exam_model.Exam.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      total: json['total'] as int,
    );
  }
}

// Exam result model
class ExamResult {
  final String resultId;
  final int score;
  final int totalPoints;
  final double percentage;
  final bool passed;
  final String message;

  ExamResult({
    required this.resultId,
    required this.score,
    required this.totalPoints,
    required this.percentage,
    required this.passed,
    required this.message,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    return ExamResult(
      resultId: json['resultId'] ?? '',
      score: json['score'] ?? 0,
      totalPoints: json['totalPoints'] ?? 0,
      percentage: (json['percentage'] ?? 0.0).toDouble(),
      passed: json['passed'] ?? false,
      message: json['message'] ?? 'Exam completed',
    );
  }
}