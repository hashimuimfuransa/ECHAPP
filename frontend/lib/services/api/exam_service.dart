import 'dart:convert';
import '../../config/api_config.dart';
import '../infrastructure/api_client.dart';
import '../../models/exam.dart' as exam_model;

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
      print('ExamService: Fetching exams for section: $sectionId');
      final response = await _apiClient.get(
        '${ApiConfig.exams}/section/$sectionId',
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        print('ExamService: Successfully fetched ${data.length} exams for section: $sectionId');
        
        final validExams = <exam_model.Exam>[];
        for (final item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              validExams.add(exam_model.Exam.fromJson(item));
            } catch (e) {
              print('ExamService: Error parsing exam data: $e');
              continue;
            }
          }
        }
        print('ExamService: Converted ${validExams.length} valid exams from ${data.length} total items');
        return validExams;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exams for section');
      }
    } catch (e) {
      print('ExamService: Error fetching exams for section $sectionId: $e');
      if (e is ApiException) {
        // Handle specific error cases
        if (e.statusCode == 403) {
          print('ExamService: User not enrolled in course (403)');
          // Return empty list instead of throwing for 403 - this is expected behavior
          return [];
        }
        if (e.statusCode == 404) {
          print('ExamService: Section not found (404)');
          return [];
        }
        rethrow;
      }
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
      if (response.body.isNotEmpty) {
        final preview = response.body.substring(0, response.body.length > 200 ? 200 : response.body.length);
        print('ExamService: Response preview: $preview');
      }

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        print('ExamService: Successfully parsed ${data.length} exams');
        
        final validExams = <exam_model.Exam>[];
        for (final item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              validExams.add(exam_model.Exam.fromJson(item));
            } catch (e) {
              print('ExamService (admin): Error parsing exam data: $e');
              continue;
            }
          }
        }
        print('ExamService: Converted ${validExams.length} valid exams from ${data.length} total items (admin)');
        return validExams;
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

  /// Get user's exam history
  Future<List<ExamResult>> getUserExamHistory() async {
    try {
      // Use the new independent route for student exam history
      final response = await _apiClient.get('${ApiConfig.exams}/student/history');
      response.validateStatus();
      
      print('ExamService: Raw response status: ${response.statusCode}');
      print('ExamService: Raw response body: ${response.body}');
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List<dynamic>;
        print('ExamService: Successfully parsed ${data.length} exam results');
        
        final validResults = <ExamResult>[];
        for (final item in data) {
          if (item != null && item is Map<String, dynamic>) {
            try {
              validResults.add(ExamResult.fromJson(item));
            } catch (e) {
              print('ExamService: Error parsing exam result: $e');
              continue;
            }
          }
        }
        print('ExamService: Converted ${validResults.length} valid results from ${data.length} total items');
        return validResults;
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exam history');
      }
    } catch (e) {
      print('ExamService: Error fetching exam history: $e');
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exam history: $e');
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
  final String? examId;
  final int score;
  final int totalPoints;
  final double? percentage;
  final bool passed;
  final String message;
  final DateTime? submittedAt;
  final exam_model.Exam? examDetails;
  final List<QuestionResult> questions;
  final ExamStatistics statistics;

  ExamResult({
    required this.resultId,
    this.examId,
    required this.score,
    required this.totalPoints,
    this.percentage,
    required this.passed,
    required this.message,
    this.submittedAt,
    this.examDetails,
    required this.questions,
    required this.statistics,
  });

  factory ExamResult.fromJson(Map<String, dynamic> json) {
    // Handle examId - can be String, Map, or null
    String? examId;
    exam_model.Exam? examDetails;
    
    if (json['examId'] != null) {
      if (json['examId'] is String) {
        examId = json['examId'] as String;
      } else if (json['examId'] is Map<String, dynamic>) {
        final examData = json['examId'] as Map<String, dynamic>;
        examId = examData['_id'] as String?;
        try {
          examDetails = exam_model.Exam.fromJson(examData);
        } catch (e) {
          print('ExamResult: Error parsing exam details: $e');
        }
      }
    }
    
    // Parse questions
    List<QuestionResult> questions = [];
    if (json['questions'] != null && json['questions'] is List) {
      questions = (json['questions'] as List)
          .map((item) => QuestionResult.fromJson(item as Map<String, dynamic>))
          .toList();
    }
    
    // Parse statistics
    ExamStatistics statistics = ExamStatistics(
      totalQuestions: 0,
      correctAnswers: 0,
      incorrectAnswers: 0,
      accuracy: 0.0,
    );
    if (json['statistics'] != null && json['statistics'] is Map<String, dynamic>) {
      statistics = ExamStatistics.fromJson(json['statistics'] as Map<String, dynamic>);
    }
    
    // Safely parse score and totalPoints which can be either int or String
    int parseScore(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value) ?? 0;
      } else if (value is num) {
        return value.toInt();
      }
      return 0;
    }
    
    return ExamResult(
      resultId: json['_id'] ?? json['resultId'] ?? '',
      examId: examId,
      score: parseScore(json['score']),
      totalPoints: parseScore(json['totalPoints']),
      percentage: (json['percentage'] is num) ? json['percentage'].toDouble() : json['percentage']?.toDouble(),
      passed: json['passed'] ?? false,
      message: json['message'] ?? 'Exam completed',
      submittedAt: json['submittedAt'] != null 
          ? DateTime.parse(json['submittedAt'] as String)
          : (json['createdAt'] != null ? DateTime.parse(json['createdAt'] as String) : null),
      examDetails: examDetails,
      questions: questions,
      statistics: statistics,
    );
  }
}

// Question result model
class QuestionResult {
  final String questionId;
  final String questionText;
  final List<String> options;
  final int selectedOption;
  final String selectedOptionText;
  final dynamic correctAnswer;
  final String correctAnswerText;
  final bool isCorrect;
  final int points;
  final int earnedPoints;

  QuestionResult({
    required this.questionId,
    required this.questionText,
    required this.options,
    required this.selectedOption,
    required this.selectedOptionText,
    required this.correctAnswer,
    required this.correctAnswerText,
    required this.isCorrect,
    required this.points,
    required this.earnedPoints,
  });

  factory QuestionResult.fromJson(Map<String, dynamic> json) {
    // Safely parse selectedOption which can be either int or String
    int parseSelectedOption(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        // Try to parse string to int, fallback to 0 if invalid
        return int.tryParse(value) ?? 0;
      } else if (value is num) {
        return value.toInt();
      }
      return 0;
    }
    
    // Safely parse points which can be either int or String
    int parsePoints(dynamic value) {
      if (value is int) {
        return value;
      } else if (value is String) {
        return int.tryParse(value) ?? 0;
      } else if (value is num) {
        return value.toInt();
      }
      return 0;
    }
    
    return QuestionResult(
      questionId: json['questionId'] as String? ?? '',
      questionText: json['questionText'] as String? ?? '',
      options: (json['options'] as List?)?.map((e) => e as String).toList() ?? [],
      selectedOption: parseSelectedOption(json['selectedOption']),
      selectedOptionText: json['selectedOptionText'] as String? ?? '',
      correctAnswer: json['correctAnswer'],
      correctAnswerText: json['correctAnswerText'] as String? ?? '',
      isCorrect: json['isCorrect'] as bool? ?? false,
      points: parsePoints(json['points']),
      earnedPoints: parsePoints(json['earnedPoints']),
    );
  }
}

// Exam statistics model
class ExamStatistics {
  final int totalQuestions;
  final int correctAnswers;
  final int incorrectAnswers;
  final double accuracy;

  ExamStatistics({
    required this.totalQuestions,
    required this.correctAnswers,
    required this.incorrectAnswers,
    required this.accuracy,
  });

  factory ExamStatistics.fromJson(Map<String, dynamic> json) {
    return ExamStatistics(
      totalQuestions: json['totalQuestions'] as int? ?? 0,
      correctAnswers: json['correctAnswers'] as int? ?? 0,
      incorrectAnswers: json['incorrectAnswers'] as int? ?? 0,
      accuracy: (json['accuracy'] is num) ? json['accuracy'].toDouble() : json['accuracy']?.toDouble() ?? 0.0,
    );
  }
}
