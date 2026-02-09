import 'package:flutter/material.dart';
import 'dart:async';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/models/exam.dart' as exam_model;
import 'package:excellence_coaching_hub/services/api/exam_service.dart';

class ExamTakingScreen extends StatefulWidget {
  final exam_model.Exam exam;

  const ExamTakingScreen({
    Key? key,
    required this.exam,
  }) : super(key: key);

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  late Future<Map<String, dynamic>> _examDataFuture;
  List<Question> _questions = [];
  Map<int, String?> _answers = {};
  int _currentQuestionIndex = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  bool _isLoading = true;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _examDataFuture = _loadExamData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<Map<String, dynamic>> _loadExamData() async {
    try {
      final examService = ExamService();
      final examData = await examService.getExamQuestions(widget.exam.id);
      
      final questions = (examData['questions'] as List)
          .map((q) => Question.fromJson(q))
          .toList();
      
      setState(() {
        _questions = questions;
        _timeRemaining = widget.exam.timeLimit * 60; // Convert minutes to seconds
        _isLoading = false;
      });

      // Start timer if time limit is set
      if (widget.exam.timeLimit > 0) {
        _startTimer();
      }

      return examData;
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      throw e;
    }
  }

  void _startTimer() {
    if (_timeRemaining <= 0) return;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      setState(() {
        _timeRemaining--;
      });

      if (_timeRemaining <= 0) {
        _submitExam();
      }
    });
  }

  String _formatTime(int seconds) {
    final minutes = (seconds ~/ 60).toString().padLeft(2, '0');
    final secs = (seconds % 60).toString().padLeft(2, '0');
    return '$minutes:$secs';
  }

  void _selectAnswer(String answer) {
    setState(() {
      _answers[_currentQuestionIndex] = answer;
    });
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitExam() async {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      final examService = ExamService();
      
      // Prepare answers in the required format
      final answers = _answers.entries
          .where((entry) => entry.value != null)
          .map((entry) => {
            'questionId': _questions[entry.key].id,
            'selectedOption': entry.value,
          })
          .toList();

      final result = await examService.submitExam(
        examId: widget.exam.id,
        answers: answers,
      );

      if (mounted) {
        // Navigate to results screen
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ExamResultsScreen(
              exam: widget.exam,
              result: result,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit exam: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Loading Exam'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(
          title: Text(widget.exam.title),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.warning,
                size: 64,
                color: Colors.orange.shade300,
              ),
              const SizedBox(height: 16),
              const Text(
                'No questions available for this exam',
                style: TextStyle(fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => Navigator.pop(context),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Go Back'),
              ),
            ],
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = _answers[_currentQuestionIndex];

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.exam.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          if (widget.exam.timeLimit > 0)
            Container(
              margin: const EdgeInsets.all(12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining < 300 ? Colors.red : Colors.orange,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                _formatTime(_timeRemaining),
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Progress indicator
            LinearProgressIndicator(
              value: (_currentQuestionIndex + 1) / _questions.length,
              backgroundColor: Colors.grey.shade200,
              valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            ),
            const SizedBox(height: 8),
            Text(
              'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 16),

            // Question card
            Expanded(
              child: Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        currentQuestion.question,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Options
                      Expanded(
                        child: ListView.builder(
                          itemCount: currentQuestion.options.length,
                          itemBuilder: (context, index) {
                            final option = currentQuestion.options[index];
                            final isSelected = selectedAnswer == option;

                            return Container(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ElevatedButton(
                                onPressed: () => _selectAnswer(option),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: isSelected
                                      ? AppTheme.primaryGreen
                                      : Colors.grey.shade100,
                                  foregroundColor: isSelected
                                      ? Colors.white
                                      : AppTheme.blackColor,
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(16),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                    side: BorderSide(
                                      color: isSelected
                                          ? AppTheme.primaryGreen
                                          : Colors.grey.shade300,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 24,
                                      height: 24,
                                      decoration: BoxDecoration(
                                        color: isSelected
                                            ? Colors.white
                                            : Colors.transparent,
                                        border: Border.all(
                                          color: isSelected
                                              ? Colors.white
                                              : AppTheme.primaryGreen,
                                        ),
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: isSelected
                                          ? Icon(
                                              Icons.check,
                                              size: 16,
                                              color: AppTheme.primaryGreen,
                                            )
                                          : null,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        option,
                                        style: TextStyle(
                                          fontWeight: isSelected
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Navigation controls
            Row(
              children: [
                Expanded(
                  flex: 1,
                  child: ElevatedButton(
                    onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey.shade300,
                      foregroundColor: AppTheme.blackColor,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: const Text('Previous'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: ElevatedButton(
                    onPressed: _isSubmitting
                        ? null
                        : () {
                            if (_currentQuestionIndex < _questions.length - 1) {
                              _nextQuestion();
                            } else {
                              _submitExam();
                            }
                          },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: _currentQuestionIndex < _questions.length - 1
                        ? const Text('Next')
                        : _isSubmitting
                            ? const CircularProgressIndicator(strokeWidth: 2)
                            : const Text('Submit Exam'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// Models for exam questions
class Question {
  final String id;
  final String question;
  final List<String> options;
  final int points;

  Question({
    required this.id,
    required this.question,
    required this.options,
    required this.points,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      question: json['question'] ?? '',
      options: List<String>.from(json['options'] ?? []),
      points: json['points'] ?? 1,
    );
  }
}

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

class ExamResultsScreen extends StatelessWidget {
  final exam_model.Exam exam;
  final ExamResult result;

  const ExamResultsScreen({
    Key? key,
    required this.exam,
    required this.result,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Exam Results'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: result.passed ? Colors.green.shade100 : Colors.red.shade100,
                borderRadius: BorderRadius.circular(60),
                border: Border.all(
                  color: result.passed ? Colors.green : Colors.red,
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  result.passed ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: result.passed ? Colors.green : Colors.red,
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              result.passed ? 'Congratulations!' : 'Exam Not Passed',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: result.passed ? Colors.green : Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              result.message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 24),
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'Your Score',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.greyColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${result.score}/${result.totalPoints}',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${result.percentage.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        color: result.passed ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: result.percentage / 100,
                      backgroundColor: Colors.grey.shade200,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        result.passed ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: const Text('Return to Dashboard'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}