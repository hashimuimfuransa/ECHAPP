import '../../services/api/exam_service.dart';
import '../../models/exam.dart';

class ExamRepository {
  final ExamService _examService;

  ExamRepository({ExamService? examService}) 
      : _examService = examService ?? ExamService();

  /// Get all exams for a section
  Future<List<Exam>> getExamsBySection(String sectionId) async {
    try {
      // Since there's no direct endpoint for section exams in the service,
      // we'll get all exams and filter by sectionId
      final response = await _examService.getAllExams();
      return response.exams.where((exam) => exam.sectionId == sectionId).toList();
    } catch (e) {
      throw Exception('Failed to fetch exams for section: $e');
    }
  }

  /// Create exam
  Future<Exam> createExam({
    required String courseId,
    required String sectionId,
    required String title,
    required String type,
    required int passingScore,
    int? timeLimit,
    bool? isPublished,
  }) async {
    try {
      return await _examService.createExam(
        courseId: courseId,
        sectionId: sectionId,
        title: title,
        type: type,
        passingScore: passingScore,
        timeLimit: timeLimit,
        isPublished: isPublished,
      );
    } catch (e) {
      throw Exception('Failed to create exam: $e');
    }
  }

  /// Update exam
  Future<Exam> updateExam({
    required String examId,
    String? title,
    String? type,
    int? passingScore,
    int? timeLimit,
    bool? isPublished,
  }) async {
    try {
      return await _examService.updateExam(
        id: examId,
        title: title,
        type: type,
        passingScore: passingScore,
        timeLimit: timeLimit,
        isPublished: isPublished,
      );
    } catch (e) {
      throw Exception('Failed to update exam: $e');
    }
  }

  /// Delete exam
  Future<void> deleteExam(String examId) async {
    try {
      await _examService.deleteExam(examId);
    } catch (e) {
      throw Exception('Failed to delete exam: $e');
    }
  }

  /// Toggle exam publish status
  Future<Exam> toggleExamPublish(String examId, bool currentStatus) async {
    try {
      return await _examService.updateExam(
        id: examId,
        isPublished: !currentStatus,
      );
    } catch (e) {
      throw Exception('Failed to toggle exam publish status: $e');
    }
  }

  /// Delete a specific exam result for the authenticated user
  Future<void> deleteExamResult(String resultId) async {
    try {
      await _examService.deleteExamResult(resultId);
    } catch (e) {
      throw Exception('Failed to delete exam result: $e');
    }
  }

  /// Delete all exam results for the authenticated user
  Future<Map<String, int>> deleteAllExamResults() async {
    try {
      return await _examService.deleteAllExamResults();
    } catch (e) {
      throw Exception('Failed to delete exam results: $e');
    }
  }
}
