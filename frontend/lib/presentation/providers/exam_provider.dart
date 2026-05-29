import 'package:flutter/foundation.dart';
import '../../../models/quiz_submission.dart';
import '../../../services/api/quiz_service.dart';

class ExamProvider with ChangeNotifier {
  List<QuizSubmission> _examHistory = [];
  List<QuizSubmission> _filteredExamHistory = [];
  bool _isLoading = false;
  String? _error;
  String _searchQuery = '';

  List<QuizSubmission> get examHistory => _examHistory;
  List<QuizSubmission> get filteredExamHistory => _filteredExamHistory;
  bool get isLoading => _isLoading;
  String? get error => _error;
  String get searchQuery => _searchQuery;

  Future<void> loadExamHistory() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      // For now, we'll load all attempts from different exams
      // In a real implementation, you might want a dedicated endpoint for all user's exam history
      // For now, we'll return empty list since there's no single endpoint for all exam history
      _examHistory = [];
      _applyFilter();
      
      debugPrint('Exam history loaded: ${_examHistory.length} exams');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading exam history: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadExamHistoryForQuiz(String examId) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final attempts = await QuizService.getStudentQuizAttempts(examId);
      
      _examHistory = attempts.map((attempt) {
        return QuizSubmission.fromJson(attempt);
      }).toList();
      
      _applyFilter();
      
      debugPrint('Exam history loaded for quiz $examId: ${_examHistory.length} attempts');
    } catch (e) {
      _error = e.toString();
      debugPrint('Error loading exam history for quiz: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void setSearchQuery(String query) {
    _searchQuery = query.toLowerCase();
    _applyFilter();
    notifyListeners();
  }

  void _applyFilter() {
    if (_searchQuery.isEmpty) {
      _filteredExamHistory = _examHistory;
    } else {
      _filteredExamHistory = _examHistory.where((exam) {
        final title = exam.examTitle?.toLowerCase() ?? '';
        return title.contains(_searchQuery);
      }).toList();
    }
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
