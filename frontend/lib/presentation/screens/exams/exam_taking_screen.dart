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
    _loadExamData();
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
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primary.withOpacity(0.1),
                AppTheme.surface,
              ],
            ),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppTheme.primary,
                    borderRadius: BorderRadius.circular(40),
                  ),
                  child: const Icon(
                    Icons.quiz,
                    size: 40,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Preparing Your Exam',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Loading questions and setting up your test environment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyColor,
                  ),
                ),
                const SizedBox(height: 32),
                const CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primary),
                  strokeWidth: 4,
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (_questions.isEmpty) {
      return Scaffold(
        body: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.surface,
                AppTheme.primary.withOpacity(0.05),
              ],
            ),
          ),
          child: Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(50),
                    ),
                    child: Icon(
                      Icons.warning_amber,
                      size: 50,
                      color: Colors.orange.shade600,
                    ),
                  ),
                  const SizedBox(height: 24),
                  const Text(
                    'No Questions Available',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'This exam doesn\'t have any questions configured yet. Please contact your instructor or try again later.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 16,
                      color: AppTheme.greyColor,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: 200,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: () => Navigator.pop(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(25),
                        ),
                      ),
                      child: const Text(
                        'Go Back',
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    final currentQuestion = _questions[_currentQuestionIndex];
    final selectedAnswer = _answers[_currentQuestionIndex];
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.surface,
              AppTheme.primary.withOpacity(0.03),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Custom App Bar
              _buildModernAppBar(context),
              
              // Progress Section
              _buildProgressSection(progress),
              
              // Question Section
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildQuestionCard(currentQuestion, selectedAnswer),
                ),
              ),
              
              // Navigation Section
              _buildNavigationSection(),
            ],
          ),
        ),
      ),
    );
  }

  // Helper methods for building UI components
  Widget _buildModernAppBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.primary,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withOpacity(0.2),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Back button
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: const Icon(Icons.arrow_back, color: Colors.white),
          ),
          
          // Exam title
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.exam.title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '${widget.exam.type.toUpperCase()} EXAM',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          
          // Timer
          if (widget.exam.timeLimit > 0)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: _timeRemaining < 300 
                  ? Colors.red.shade500 
                  : _timeRemaining < 600 
                    ? Colors.orange.shade500 
                    : Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    _timeRemaining < 300 ? Icons.timer : Icons.access_time,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    _formatTime(_timeRemaining),
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildProgressSection(double progress) {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress bar with percentage
          Row(
            children: [
              const Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blackColor,
                ),
              ),
              const Spacer(),
              Text(
                '${(_currentQuestionIndex + 1)}/${_questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Stack(
            children: [
              LinearProgressIndicator(
                value: progress,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                borderRadius: BorderRadius.circular(6),
              ),
              Positioned.fill(
                child: Center(
                  child: Text(
                    '${(progress * 100).toInt()}%',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          // Question navigation dots
          const SizedBox(height: 16),
          SizedBox(
            height: 40,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _questions.length,
              itemBuilder: (context, index) {
                final isCurrent = index == _currentQuestionIndex;
                final isAnswered = _answers[index] != null;
                final isVisited = index <= _currentQuestionIndex;
                
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      if (isVisited) {
                        setState(() {
                          _currentQuestionIndex = index;
                        });
                      }
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: isCurrent 
                          ? AppTheme.primary 
                          : isAnswered 
                            ? Colors.green 
                            : isVisited 
                              ? Colors.grey.shade300 
                              : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: isCurrent ? AppTheme.primary : Colors.transparent,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          '${index + 1}',
                          style: TextStyle(
                            color: isCurrent || isAnswered 
                              ? Colors.white 
                              : AppTheme.blackColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionCard(Question question, String? selectedAnswer) {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.primary.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.question_mark,
                    size: 20,
                    color: AppTheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Question ${_currentQuestionIndex + 1}',
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '${question.points} pts',
                      style: TextStyle(
                        color: Colors.orange.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Question text
            Text(
              question.question,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                height: 1.4,
                color: AppTheme.blackColor,
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Options
            Expanded(
              child: ListView.separated(
                itemCount: question.options.length,
                separatorBuilder: (context, index) => const SizedBox(height: 12),
                itemBuilder: (context, index) {
                  final option = question.options[index];
                  final isSelected = selectedAnswer == option;
                  
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected 
                          ? AppTheme.primary 
                          : Colors.grey.shade300,
                        width: isSelected ? 2 : 1,
                      ),
                      color: isSelected 
                        ? AppTheme.primary.withOpacity(0.1) 
                        : Colors.white,
                      boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withOpacity(0.2),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            )
                          ]
                        : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: () => _selectAnswer(option),
                        borderRadius: BorderRadius.circular(16),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              // Option indicator
                              AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                width: 28,
                                height: 28,
                                decoration: BoxDecoration(
                                  color: isSelected 
                                    ? AppTheme.primary 
                                    : Colors.grey.shade300,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isSelected 
                                      ? AppTheme.primary 
                                      : Colors.grey.shade400,
                                    width: 2,
                                  ),
                                ),
                                child: isSelected
                                  ? const Icon(
                                      Icons.check,
                                      size: 18,
                                      color: Colors.white,
                                    )
                                  : null,
                              ),
                              const SizedBox(width: 16),
                              
                              // Option text
                              Expanded(
                                child: Text(
                                  option,
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: isSelected 
                                      ? FontWeight.w600 
                                      : FontWeight.normal,
                                    color: isSelected 
                                      ? AppTheme.primary 
                                      : AppTheme.blackColor,
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavigationSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Previous button
          Expanded(
            child: SizedBox(
              height: 50,
              child: OutlinedButton(
                onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _currentQuestionIndex > 0 
                      ? AppTheme.greyColor 
                      : Colors.grey.shade300,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: const Text(
                  'Previous',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
          
          const SizedBox(width: 16),
          
          // Next/Submit button
          Expanded(
            flex: 2,
            child: SizedBox(
              height: 50,
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
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: _isSubmitting ? 0 : 4,
                ),
                child: _isSubmitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          _currentQuestionIndex < _questions.length - 1 
                            ? Icons.arrow_forward 
                            : Icons.check_circle,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _currentQuestionIndex < _questions.length - 1
                            ? 'Next Question'
                            : 'Submit Exam',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
              ),
            ),
          ),
        ],
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
    final isPassed = result.passed;
    final percentage = (result.percentage ?? 0.0);
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              isPassed 
                ? AppTheme.primary.withOpacity(0.1) 
                : Colors.red.shade50.withOpacity(0.3),
              AppTheme.surface,
            ],
          ),
        ),
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Header with back button
                Row(
                  children: [
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: const Icon(Icons.arrow_back, color: AppTheme.blackColor),
                    ),
                    const SizedBox(width: 8),
                    const Text(
                      'Exam Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.blackColor,
                      ),
                    ),
                  ],
                ),
                
                const SizedBox(height: 20),
                
                // Main result card
                Expanded(
                  child: Center(
                    child: SingleChildScrollView(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Result status icon
                          _buildResultIcon(isPassed),
                          
                          const SizedBox(height: 24),
                          
                          // Result title
                          Text(
                            isPassed ? 'Congratulations!' : 'Keep Practicing!',
                            style: TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.bold,
                              color: isPassed ? AppTheme.primary : Colors.red.shade600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Result message
                          Text(
                            result.message,
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 18,
                              color: AppTheme.greyColor,
                              height: 1.5,
                            ),
                          ),
                          
                          const SizedBox(height: 32),
                          
                          // Score card
                          _buildScoreCard(isPassed, percentage),
                          
                          const SizedBox(height: 24),
                          
                          // Performance breakdown
                          _buildPerformanceBreakdown(isPassed, percentage),
                          
                          const SizedBox(height: 32),
                          
                          // Action buttons
                          _buildActionButtons(context),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResultIcon(bool isPassed) {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        gradient: RadialGradient(
          colors: [
            isPassed 
              ? AppTheme.primary.withOpacity(0.3) 
              : Colors.red.shade200.withOpacity(0.5),
            isPassed 
              ? AppTheme.primary.withOpacity(0.1) 
              : Colors.red.shade100.withOpacity(0.3),
          ],
        ),
        borderRadius: BorderRadius.circular(70),
      ),
      child: Container(
        margin: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isPassed ? AppTheme.primary : Colors.red.shade500,
          borderRadius: BorderRadius.circular(58),
          boxShadow: [
            BoxShadow(
              color: isPassed 
                ? AppTheme.primary.withOpacity(0.4) 
                : Colors.red.withOpacity(0.4),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Center(
          child: Icon(
            isPassed ? Icons.celebration : Icons.tips_and_updates,
            size: 70,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildScoreCard(bool isPassed, double percentage) {
    return Card(
      elevation: 8,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            Text(
              'Your Score',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.greyColor,
              ),
            ),
            const SizedBox(height: 16),
            
            // Large score display
            Text(
              '${result.score}/${result.totalPoints}',
              style: const TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Percentage
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
              decoration: BoxDecoration(
                color: isPassed 
                  ? AppTheme.primary.withOpacity(0.1) 
                  : Colors.red.shade100,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '${percentage.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 24,
                  color: isPassed ? AppTheme.primary : Colors.red.shade600,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Progress bar
            Stack(
              children: [
                Container(
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                LayoutBuilder(
                  builder: (context, constraints) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 1000),
                      height: 16,
                      width: (percentage / 100) * constraints.maxWidth,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            isPassed ? AppTheme.primary : Colors.red.shade500,
                            isPassed ? AppTheme.primaryDark : Colors.red.shade700,
                          ],
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                    );
                  }
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Status message
            Text(
              isPassed 
                ? 'You passed the exam! Great job!' 
                : 'You need ${((exam.passingScore - percentage).clamp(0, 100)).toStringAsFixed(1)}% more to pass',
              style: TextStyle(
                fontSize: 16,
                color: isPassed ? AppTheme.primary : Colors.red.shade600,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPerformanceBreakdown(bool isPassed, double percentage) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 16),
            
            _buildStatRow('Total Points', '${result.totalPoints}', Icons.star),
            const SizedBox(height: 12),
            _buildStatRow('Your Score', '${result.score}', Icons.emoji_events, isGood: isPassed),
            const SizedBox(height: 12),
            _buildStatRow('Percentage', '${percentage.toStringAsFixed(1)}%', Icons.percent, isGood: isPassed),
            const SizedBox(height: 12),
            _buildStatRow('Status', isPassed ? 'Passed' : 'Not Passed', 
              isPassed ? Icons.check_circle : Icons.cancel, isGood: isPassed),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, {bool? isGood}) {
    Color? valueColor;
    if (isGood != null) {
      valueColor = isGood ? AppTheme.primary : Colors.red.shade600;
    }
    
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Icon(icon, size: 20, color: AppTheme.primary),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: valueColor ?? AppTheme.blackColor,
          ),
        ),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 55,
          child: ElevatedButton(
            onPressed: () => Navigator.popUntil(context, ModalRoute.withName('/')),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primary,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 4,
            ),
            child: const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.home, size: 24),
                SizedBox(width: 12),
                Text(
                  'Return to Dashboard',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        SizedBox(
          width: double.infinity,
          height: 50,
          child: OutlinedButton(
            onPressed: () {
              // TODO: Implement review functionality
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Review feature coming soon!'),
                  backgroundColor: AppTheme.primary,
                ),
              );
            },
            style: OutlinedButton.styleFrom(
              side: const BorderSide(color: AppTheme.greyColor),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: const Text(
              'Review Answers',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ],
    );
  }
}