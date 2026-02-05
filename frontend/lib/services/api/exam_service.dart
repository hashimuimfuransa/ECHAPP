import 'dart:convert';
import '../../models/api_response.dart';
import '../infrastructure/api_client.dart';
import '../../config/api_config.dart';

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
  Future<Exam> getExamById(String id) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/$id');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return Exam.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch exam');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch exam: $e');
    }
  }

  /// Create exam (admin only)
  Future<Exam> createExam({
    required String courseId,
    required String title,
    required String type,
    required int passingScore,
    required int timeLimit,
    List<Map<String, dynamic>>? questions,
  }) async {
    try {
      final requestBody = {
        'courseId': courseId,
        'title': title,
        'type': type,
        'passingScore': passingScore,
        'timeLimit': timeLimit,
        if (questions != null) 'questions': questions,
      };

      final response = await _apiClient.post(
        ApiConfig.exams,
        body: requestBody,
      );

      response.validateStatus();
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as Map<String, dynamic>;
        return Exam.fromJson(data);
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to create exam');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to create exam: $e');
    }
  }

  /// Update exam (admin only)
  Future<Exam> updateExam({
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
        return Exam.fromJson(data);
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
  Future<List<Exam>> getCourseExams(String courseId) async {
    try {
      final response = await _apiClient.get('${ApiConfig.exams}/course/$courseId');
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      if (jsonBody['success'] == true) {
        final data = jsonBody['data'] as List;
        return data.map((item) => Exam.fromJson(item as Map<String, dynamic>)).toList();
      } else {
        throw ApiException(jsonBody['message'] as String? ?? 'Failed to fetch course exams');
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch course exams: $e');
    }
  }

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}

// Data models
class ExamListResponse {
  final List<Exam> exams;
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
          .map((item) => Exam.fromJson(item as Map<String, dynamic>))
          .toList(),
      totalPages: json['totalPages'] as int,
      currentPage: json['currentPage'] as int,
      total: json['total'] as int,
    );
  }
}

class Exam {
  final String id;
  final String courseId;
  final String title;
  final String type;
  final int passingScore;
  final int timeLimit;
  final bool isPublished;
  final int questionsCount;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getters for compatibility with existing UI
  int get questions => questionsCount;
  int get duration => timeLimit;

  Exam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.passingScore,
    required this.timeLimit,
    required this.isPublished,
    required this.questionsCount,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'] as String,
      courseId: json['courseId'] is String 
          ? json['courseId'] as String
          : (json['courseId'] as Map<String, dynamic>)['_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      passingScore: json['passingScore'] as int,
      timeLimit: json['timeLimit'] as int,
      isPublished: json['isPublished'] as bool? ?? false,
      questionsCount: json['questionsCount'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'title': title,
      'type': type,
      'passingScore': passingScore,
      'timeLimit': timeLimit,
      'isPublished': isPublished,
      'questionsCount': questionsCount,
      'attempts': attempts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}