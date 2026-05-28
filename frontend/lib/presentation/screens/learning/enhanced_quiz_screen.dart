import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';
import 'package:url_launcher/url_launcher.dart';

/// Enhanced quiz taking screen supporting all interactive question types
class EnhancedQuizScreen extends ConsumerStatefulWidget {
  final String quizId;
  final String lessonTitle;

  const EnhancedQuizScreen({
    super.key,
    required this.quizId,
    required this.lessonTitle,
  });

  @override
  ConsumerState<EnhancedQuizScreen> createState() => _EnhancedQuizScreenState();
}

class _EnhancedQuizScreenState extends ConsumerState<EnhancedQuizScreen> 
    with TickerProviderStateMixin {
  Map<String, dynamic>? _quizData;
  List<Map<String, dynamic>> _questions = [];
  int _currentQuestionIndex = 0;
  Map<String, dynamic>? _currentQuestion;
  Map<String, dynamic> _userAnswers = {};
  bool _isLoading = true;
  bool _isSubmitting = false;
  bool _quizCompleted = false;
  int _score = 0;
  int _totalPossibleScore = 0;
  int _timeRemaining = 0;
  Timer? _timer;
  
  // Programming question specific
  final Map<String, TextEditingController> _codeControllers = {};
  final Map<String, String> _codeOutputs = {};

  @override
  void initState() {
    super.initState();
    _loadQuizData();
  }

  @override
  void dispose() {
    _timer?.cancel();
    for (final controller in _codeControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadQuizData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      // Load quiz data using QuizService
      final quizResponse = await QuizService.getQuiz(widget.quizId);
      
      if (quizResponse['success'] == true) {
        final quiz = quizResponse['data']['quiz'];
        setState(() {
          _quizData = quiz;
          _questions = List<Map<String, dynamic>>.from(quiz['questions'] ?? []);
          _totalPossibleScore = _questions.fold(0, (sum, question) {
            final points = (question['points'] as num?)?.toInt() ?? 1;
            return sum + points;
          });
          _timeRemaining = quiz['timeLimit'] ?? 30;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to load quiz: ${quizResponse['message'] ?? 'Unknown error'}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error loading quiz: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeRemaining > 0) {
        setState(() {
          _timeRemaining--;
        });
      } else {
        _timer?.cancel();
      }
    });
  }

  void _submitAnswer() {
    if (_currentQuestion == null || _isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    // Save answer based on question type
    _saveAnswerForQuestion(_currentQuestion!);

    // Move to next question or complete quiz
    Future.delayed(const Duration(milliseconds: 500), () {
      setState(() {
        _isSubmitting = false;
      });

      if (_currentQuestionIndex < _questions.length - 1) {
        _nextQuestion();
      } else {
        _completeQuiz();
      }
    });
  }

  void _saveAnswerForQuestion(Map<String, dynamic> question) {
    final questionType = question['type'] as String;
    final questionId = question['id'] as String;

    switch (questionType) {
      case 'mcq':
      case 'true_false':
        _userAnswers[questionId] = _currentQuestion!['selectedOption'];
        break;
      case 'fill_blank':
        _userAnswers[questionId] = _currentQuestion!['textAnswer'];
        break;
      case 'essay':
        _userAnswers[questionId] = _currentQuestion!['essayAnswer'];
        break;
      case 'drag_drop':
        _userAnswers[questionId] = _currentQuestion!['dragAnswers'] ?? {};
        break;
      case 'matching':
        _userAnswers[questionId] = _currentQuestion!['matchingAnswers'] ?? {};
        break;
      case 'ordering':
        _userAnswers[questionId] = _currentQuestion!['orderedItems'] ?? [];
        break;
      case 'hotspot':
        _userAnswers[questionId] = _currentQuestion!['selectedHotspots'] ?? [];
        break;
      case 'programming':
        _userAnswers[questionId] = {
          'code': _codeControllers[questionId]?.text ?? '',
          'output': _codeOutputs[questionId] ?? '',
        };
        break;
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      setState(() {
        _currentQuestionIndex++;
        _currentQuestion = _questions[_currentQuestionIndex];
        _userAnswers.remove(_currentQuestion!['id']);
        
        // Initialize code controller for programming questions
        if (_currentQuestion!['type'] == 'programming') {
          final questionId = _currentQuestion!['id'] as String;
          if (!_codeControllers.containsKey(questionId)) {
            _codeControllers[questionId] = TextEditingController(
              text: _currentQuestion!['starterCode'] ?? ''
            );
          }
          _codeOutputs[questionId] = '';
        }
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      setState(() {
        _currentQuestionIndex--;
        _currentQuestion = _questions[_currentQuestionIndex];
      });
    }
  }

  void _completeQuiz() {
    _timer?.cancel();
    setState(() {
      _quizCompleted = true;
      _timeRemaining = 0;
    });

    // Calculate final score
    _calculateFinalScore();

    // Show results
    _showQuizResults();
  }

  void _calculateFinalScore() {
    _score = 0;
    
    for (final question in _questions) {
      final questionId = question['id'] as String;
      final userAnswer = _userAnswers[questionId];
      final questionType = question['type'] as String;
      final points = question['points'] ?? 1;

      bool isCorrect = false;

      switch (questionType) {
        case 'mcq':
        isCorrect = userAnswer == question['correctAnswer'];
          break;
        case 'true_false':
          isCorrect = userAnswer == question['correctAnswer'];
          break;
        case 'fill_blank':
          isCorrect = userAnswer?.toString().toLowerCase().trim() == 
                   question['correctAnswer']?.toString().toLowerCase().trim();
          break;
        case 'essay':
        case 'programming':
          // Programming questions are graded based on test case results
          final codeAnswer = userAnswer as Map<String, dynamic>?;
          if (codeAnswer != null) {
            isCorrect = _evaluateProgrammingAnswer(question, codeAnswer!);
          }
          break;
        default:
          isCorrect = false;
      }

      if (isCorrect) {
        _score += (points as num).toInt();
      }
    }
  }

  bool _evaluateProgrammingAnswer(Map<String, dynamic> question, Map<String, dynamic> userAnswer) {
    final testCases = question['testCases'] as List<Map<String, dynamic>>? ?? [];
    final userCode = userAnswer['code'] as String? ?? '';
    final userOutput = userAnswer['output'] as String? ?? '';

    if (testCases.isEmpty) return false;

    // Simple evaluation - in real implementation, this would use a code execution service
    for (final testCase in testCases) {
      final input = testCase['input'] as String? ?? '';
      final expectedOutput = testCase['expectedOutput'] as String? ?? '';
      
      // For demonstration, we'll do basic string matching
      // In production, this would execute the code and compare actual output
      if (userCode.toLowerCase().contains(input.toLowerCase()) && 
          userOutput.toLowerCase().contains(expectedOutput.toLowerCase())) {
        return true;
      }
    }

    return false;
  }

  void _showQuizResults() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        title: Text('Quiz Results'),
        content: SizedBox(
          width: double.maxFinite,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Score: $_score/$_totalPossibleScore',
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${(_totalPossibleScore > 0 ? ((_score / _totalPossibleScore) * 100) : 0).isFinite ? (_totalPossibleScore > 0 ? ((_score / _totalPossibleScore) * 100) : 0).toInt() : 0}%',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: _score >= (_totalPossibleScore / 2) ? Colors.green : Colors.orange,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                Text(
                  _getPerformanceMessage(),
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Optionally: retake quiz
                      },
                      child: const Text('Close'),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                        // Optionally: review answers
                      },
                      child: const Text('Review Answers'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _getPerformanceMessage() {
    final percentage = _totalPossibleScore > 0 ? (_score / _totalPossibleScore) : 0.0;
    
    if (percentage >= 0.9) {
      return 'Excellent! You mastered this material perfectly.';
    } else if (percentage >= 0.8) {
      return 'Great work! You have a strong understanding of the material.';
    } else if (percentage >= 0.7) {
      return 'Good job! You understand most of the material.';
    } else if (percentage >= 0.6) {
      return 'Nice effort! Keep practicing to improve your understanding.';
    } else {
      return 'Keep learning! Review the material and try again.';
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppTheme.primaryGreen),
        ),
      );
    }

    if (_quizCompleted) {
      return _buildQuizCompletedView();
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _buildQuizContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: AppTheme.primaryGreen,
      foregroundColor: Colors.white,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back),
        onPressed: () => Navigator.pop(context),
      ),
      title: Text(widget.lessonTitle),
      centerTitle: true,
      actions: [
        if (_timeRemaining > 0 && !_quizCompleted)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                const Icon(Icons.timer, color: AppTheme.primaryGreen, size: 16),
                const SizedBox(width: 8),
                Text(
                  '$_timeRemaining:00',
                  style: const TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _buildQuizContent() {
    if (_currentQuestion == null) return const SizedBox.shrink();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Progress indicator
          _buildProgressIndicator(),
          const SizedBox(height: 20),
          
          // Question content
          _buildQuestionContent(),
          
          const SizedBox(height: 20),
          
          // Navigation buttons
          _buildNavigationButtons(),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Question ${_currentQuestionIndex + 1} of ${_questions.length}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${(_questions.isNotEmpty ? ((_currentQuestionIndex / _questions.length) * 100) : 0).isFinite ? (_questions.isNotEmpty ? ((_currentQuestionIndex / _questions.length) * 100) : 0).toInt() : 0}% Complete',
                style: const TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LinearProgressIndicator(
            value: (_currentQuestionIndex + 1) / _questions.length,
            backgroundColor: AppTheme.greyColor.withOpacity(0.2),
            valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionContent() {
    final question = _currentQuestion!;
    final questionType = question['type'] as String;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Question header with type indicator
          _buildQuestionHeader(question, questionType),
          const SizedBox(height: 16),
          
          // Question type specific renderer
          _buildQuestionRenderer(question, questionType),
        ],
      ),
    );
  }

  Widget _buildQuestionHeader(Map<String, dynamic> question, String questionType) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: _getQuestionTypeColor(questionType),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            _getQuestionTypeLabel(questionType),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            'Question ${_currentQuestionIndex + 1}',
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildQuestionRenderer(Map<String, dynamic> question, String questionType) {
    switch (questionType) {
      case 'mcq':
        return _buildMCQQuestion(question);
      case 'true_false':
        return _buildTrueFalseQuestion(question);
      case 'fill_blank':
        return _buildFillBlankQuestion(question);
      case 'essay':
        return _buildEssayQuestion(question);
      case 'drag_drop':
        return _buildDragDropQuestion(question);
      case 'matching':
        return _buildMatchingQuestion(question);
      case 'ordering':
        return _buildOrderingQuestion(question);
      case 'hotspot':
        return _buildHotspotQuestion(question);
      case 'programming':
        return _buildProgrammingQuestion(question);
      default:
        return _buildDefaultQuestion(question);
    }
  }

  Widget _buildMCQQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        ...List.generate((question['options'] as List).length, (index) {
          final option = (question['options'] as List)[index];
          final isCorrect = option['isCorrect'] as bool;
          final optionText = option['text'] as String;
          final optionKey = option['id'] as String? ?? 'option_$index';
          
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _currentQuestion!['selectedOption'] = optionKey;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: _currentQuestion!['selectedOption'] == optionKey 
                    ? AppTheme.primaryGreen.withOpacity(0.1) 
                    : Colors.white,
                  border: Border.all(
                    color: _currentQuestion!['selectedOption'] == optionKey 
                      ? AppTheme.primaryGreen 
                      : AppTheme.getBorderColor(context),
                    width: 2,
                  ),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppTheme.getBorderColor(context)),
                        color: Colors.white,
                      ),
                      child: Center(
                        child: isCorrect 
                          ? Icon(Icons.check, color: AppTheme.primaryGreen, size: 16)
                          : Text(String.fromCharCode(65 + index), style: const TextStyle(fontWeight: FontWeight.bold)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        optionText,
                        style: TextStyle(
                          color: _currentQuestion!['selectedOption'] == optionKey 
                            ? AppTheme.primaryGreen 
                            : AppTheme.getTextColor(context),
                          fontWeight: _currentQuestion!['selectedOption'] == optionKey 
                            ? FontWeight.w600 
                            : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildTrueFalseQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 24),
        Row(
          children: [
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentQuestion!['selectedOption'] = 'true';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _currentQuestion!['selectedOption'] == 'true' 
                      ? AppTheme.primaryGreen.withOpacity(0.1) 
                      : Colors.white,
                    border: Border.all(
                      color: _currentQuestion!['selectedOption'] == 'true' 
                        ? AppTheme.primaryGreen 
                        : AppTheme.getBorderColor(context),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.check_circle,
                        color: _currentQuestion!['selectedOption'] == 'true' 
                          ? AppTheme.primaryGreen 
                          : AppTheme.greyColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'TRUE',
                        style: TextStyle(
                          color: _currentQuestion!['selectedOption'] == 'true' 
                            ? AppTheme.primaryGreen 
                            : AppTheme.getTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _currentQuestion!['selectedOption'] = 'false';
                  });
                },
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: _currentQuestion!['selectedOption'] == 'false' 
                      ? AppTheme.primaryGreen.withOpacity(0.1) 
                      : Colors.white,
                    border: Border.all(
                      color: _currentQuestion!['selectedOption'] == 'false' 
                        ? AppTheme.primaryGreen 
                        : AppTheme.getBorderColor(context),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.cancel,
                        color: _currentQuestion!['selectedOption'] == 'false' 
                          ? AppTheme.primaryGreen 
                          : AppTheme.greyColor,
                        size: 24,
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'FALSE',
                        style: TextStyle(
                          color: _currentQuestion!['selectedOption'] == 'false' 
                            ? AppTheme.primaryGreen 
                            : AppTheme.getTextColor(context),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildFillBlankQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(
            text: _currentQuestion!['textAnswer'] as String? ?? '',
          ),
          decoration: InputDecoration(
            hintText: 'Type your answer here...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          style: const TextStyle(fontSize: 16),
          onChanged: (value) {
            setState(() {
              _currentQuestion!['textAnswer'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildEssayQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        TextField(
          controller: TextEditingController(
            text: _currentQuestion!['essayAnswer'] as String? ?? '',
          ),
          decoration: InputDecoration(
            hintText: 'Write your answer here...',
            border: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen),
            ),
            focusedBorder: OutlineInputBorder(
              borderSide: BorderSide(color: AppTheme.primaryGreen, width: 2),
            ),
            filled: true,
            fillColor: Colors.white,
            contentPadding: const EdgeInsets.all(16),
          ),
          maxLines: 5,
          style: const TextStyle(fontSize: 16),
          onChanged: (value) {
            setState(() {
              _currentQuestion!['essayAnswer'] = value;
            });
          },
        ),
      ],
    );
  }

  Widget _buildDragDropQuestion(Map<String, dynamic> question) {
    final dragItems = question['dragItems'] as List<Map<String, dynamic>>? ?? [];
    final dropZones = question['dropZones'] as List<Map<String, dynamic>>? ?? [];
    final userAnswers = _currentQuestion!['dragAnswers'] as Map<String, String>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'Drag items to their matching zones:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Drag items
        ...dragItems.map((item) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue),
            ),
            child: Text(
              item['content'] as String,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        )),
        const SizedBox(height: 16),
        Text(
          'Drop zones:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        // Drop zones
        ...dropZones.map((zone) => Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: userAnswers.containsKey(zone['id'] as String) 
                ? Colors.green.withOpacity(0.1) 
                : Colors.white,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: userAnswers.containsKey(zone['id'] as String) 
                  ? Colors.green 
                  : AppTheme.getBorderColor(context),
                width: 2,
              ),
            ),
            child: Text(
              zone['label'] as String,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        )),
      ],
    );
  }

  Widget _buildMatchingQuestion(Map<String, dynamic> question) {
    final matchingPairs = question['matchingPairs'] as List<Map<String, dynamic>>? ?? [];
    final userAnswers = _currentQuestion!['matchingAnswers'] as Map<String, String>? ?? {};

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'Match items from left column with right column:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...matchingPairs.asMap().entries.map((entry) {
          final index = entry.key;
          final pair = entry.value;
          final leftItem = pair['leftItem'] as Map<String, dynamic>;
          final rightItem = pair['rightItem'] as Map<String, dynamic>;
          final leftId = leftItem['id'] as String;
          final rightId = rightItem['id'] as String;
          final userLeftAnswer = userAnswers[leftId];
          final userRightAnswer = userAnswers[rightId];

          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                // Left item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: userLeftAnswer != null && userLeftAnswer == rightId 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: userLeftAnswer != null && userLeftAnswer == rightId 
                          ? Colors.green 
                          : AppTheme.getBorderColor(context),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      leftItem['text'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Right item
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: userRightAnswer != null && userRightAnswer == leftId 
                        ? Colors.green.withOpacity(0.1) 
                        : Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: userRightAnswer != null && userRightAnswer == leftId 
                          ? Colors.green 
                          : AppTheme.getBorderColor(context),
                        width: 2,
                      ),
                    ),
                    child: Text(
                      rightItem['text'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildOrderingQuestion(Map<String, dynamic> question) {
    final correctOrder = question['correctOrder'] as List<Map<String, dynamic>>? ?? [];
    final userOrder = _currentQuestion!['orderedItems'] as List<String>? ?? [];
    final questionId = question['id'] as String;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'Arrange items in correct order:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        ...correctOrder.asMap().entries.map((entry) {
          final index = entry.key;
          final item = entry.value;
          final itemId = item['id'] as String;
          final isCorrectPosition = userOrder.contains(itemId);

          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isCorrectPosition 
                  ? Colors.green.withOpacity(0.1) 
                  : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isCorrectPosition 
                    ? Colors.green 
                    : AppTheme.getBorderColor(context),
                  width: 2,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 30,
                    height: 30,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: Center(
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      item['content'] as String,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildHotspotQuestion(Map<String, dynamic> question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question['question'] ?? 'No question text',
          style: const TextStyle(fontSize: 16),
        ),
        const SizedBox(height: 16),
        Text(
          'Click on the correct areas of the image:',
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Stack(
            children: [
              // Image placeholder
              if (question['hotspotImage'] != null)
                Container(
                  height: 200,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.image, size: 48, color: AppTheme.greyColor),
                        const SizedBox(height: 8),
                        Text(
                          'Image would be displayed here',
                          style: const TextStyle(fontSize: 12, color: AppTheme.greyColor),
                        ),
                      ],
                    ),
                  ),
                ),
              
              // Hotspots
              ...(question['hotspots'] as List<Map<String, dynamic>>? ?? []).map((hotspot) {
                final isSelected = (_currentQuestion!['selectedHotspots'] as List<String>?)
                    ?.contains(hotspot['label'] as String) ?? false;
                
                return Positioned(
                  left: (hotspot['x'] as double?) ?? 0.0,
                  top: (hotspot['y'] as double?) ?? 0.0,
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        final selected = _currentQuestion!['selectedHotspots'] as List<String>? ?? [];
                        if (isSelected) {
                          selected.remove(hotspot['label'] as String);
                        } else {
                          selected.add(hotspot['label'] as String);
                        }
                        _currentQuestion!['selectedHotspots'] = selected;
                      });
                    },
                    child: Container(
                      width: (hotspot['width'] as double?) ?? 50.0,
                      height: (hotspot['height'] as double?) ?? 50.0,
                      decoration: BoxDecoration(
                        color: isSelected 
                          ? Colors.green.withOpacity(0.3) 
                          : Colors.red.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isSelected ? Colors.green : Colors.red,
                          width: 2,
                        ),
                      ),
                      child: Center(
                        child: Text(
                          hotspot['label'] as String,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildProgrammingQuestion(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final programmingLanguage = question['programmingLanguage'] as String? ?? 'python';
    final starterCode = question['starterCode'] as String? ?? '';
    final userAnswer = _userAnswers[questionId] as Map<String, dynamic>? ?? {};
    final userCode = userAnswer['code'] as String? ?? '';
    final userOutput = userAnswer['output'] as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Question and language info
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(Icons.code, color: AppTheme.primaryGreen, size: 24),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      question['question'] ?? 'No question text',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Language: $programmingLanguage',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        
        // Instructions
        if (question['instructions'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Instructions:',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 8),
                Text(
                  question['instructions'] as String,
                  style: const TextStyle(fontSize: 14),
                ),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Code editor
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppTheme.getBorderColor(context)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Text(
                    'Code Editor:',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.black,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      programmingLanguage.toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _codeControllers[questionId] ?? TextEditingController(text: starterCode),
                maxLines: 12,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 14,
                ),
                decoration: const InputDecoration(
                  hintText: 'Write your code here...',
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(16),
                ),
                onChanged: (value) {
                  setState(() {
                    _userAnswers[questionId] = {
                      ...(_userAnswers[questionId] as Map<String, dynamic>? ?? {}),
                      'code': value
                    };
                  });
                },
              ),
              const SizedBox(height: 16),
              
              // Run code button
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () => _runCode(question),
                    icon: const Icon(Icons.play_arrow, size: 16),
                    label: const Text('Run Code'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green,
                      foregroundColor: Colors.white,
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () => _resetCode(question),
                    icon: const Icon(Icons.refresh, size: 16),
                    label: const Text('Reset'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.orange,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Test cases
        if (question['testCases'] != null)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Test Cases:',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                const SizedBox(height: 12),
                ...(question['testCases'] as List<Map<String, dynamic>>).asMap().entries.map((entry) {
                  final index = entry.key;
                  final testCase = entry.value;
                  final input = testCase['input'] as String? ?? '';
                  final expectedOutput = testCase['expectedOutput'] as String? ?? '';
                  
                  return Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppTheme.getBorderColor(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Test Case ${index + 1}:',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                        ),
                        const SizedBox(height: 4),
                        if (input.isNotEmpty)
                          Text(
                            'Input: $input',
                            style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                          ),
                        const SizedBox(height: 4),
                        Text(
                          'Expected: $expectedOutput',
                          style: const TextStyle(fontSize: 11, fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        
        const SizedBox(height: 16),
        
        // Output display
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: userOutput.isNotEmpty 
              ? Colors.blue.withOpacity(0.1) 
              : Colors.grey.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: userOutput.isNotEmpty 
                ? Colors.blue 
                : AppTheme.getBorderColor(context),
              width: 2,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Output:',
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: TextEditingController(text: userOutput),
                maxLines: 6,
                readOnly: true,
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                  backgroundColor: Colors.white,
                ),
                decoration: const InputDecoration(
                  border: InputBorder.none,
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.all(12),
                ),
                onChanged: (value) {
                  setState(() {
                    _userAnswers[questionId] = {
                      ...(_userAnswers[questionId] as Map<String, dynamic>? ?? {}),
                      'output': value
                    };
                  });
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDefaultQuestion(Map<String, dynamic> question) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Text(
        'Question type "${question['type']}" is not yet supported.',
        style: const TextStyle(fontSize: 16),
      ),
    );
  }

  String _getQuestionTypeLabel(String questionType) {
    switch (questionType) {
      case 'mcq': return 'MCQ';
      case 'true_false': return 'T/F';
      case 'fill_blank': return 'Fill';
      case 'essay': return 'Essay';
      case 'drag_drop': return 'Drag';
      case 'matching': return 'Match';
      case 'ordering': return 'Order';
      case 'hotspot': return 'Hotspot';
      case 'programming': return 'Code';
      default: return questionType.toUpperCase();
    }
  }

  Color _getQuestionTypeColor(String questionType) {
    switch (questionType) {
      case 'mcq': return Colors.blue;
      case 'true_false': return Colors.green;
      case 'fill_blank': return Colors.purple;
      case 'essay': return Colors.orange;
      case 'drag_drop': return Colors.teal;
      case 'matching': return Colors.indigo;
      case 'ordering': return Colors.purple;
      case 'hotspot': return Colors.red;
      case 'programming': return Colors.black;
      default: return Colors.grey;
    }
  }

  Widget _buildNavigationButtons() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentQuestionIndex > 0 ? _previousQuestion : null,
            icon: const Icon(Icons.arrow_back),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.grey,
              foregroundColor: Colors.white,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _isSubmitting ? null : _submitAnswer,
            icon: _isSubmitting 
              ? const Icon(Icons.hourglass_empty) 
              : const Icon(Icons.check),
            label: Text(_isSubmitting ? 'Submitting...' : 'Submit'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuizCompletedView() {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        title: Text(widget.lessonTitle),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(60),
              ),
              child: const Icon(
                Icons.check_circle,
                color: Colors.white,
                size: 60,
              ),
            ),
            const SizedBox(height: 32),
            Text(
              'Quiz Completed!',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.primaryGreen,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Score: $_score/$_totalPossibleScore',
              style: const TextStyle(fontSize: 18),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Back to Lesson'),
            ),
          ],
        ),
      ),
    );
  }

  void _runCode(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final userCode = _codeControllers[questionId]?.text ?? '';
    final testCases = question['testCases'] as List<Map<String, dynamic>>? ?? [];
    
    if (userCode.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please write some code before running'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    // Simulate code execution (in real implementation, this would call a code execution service)
    String output = '';
    for (final testCase in testCases) {
      final input = testCase['input'] as String? ?? '';
      final expectedOutput = testCase['expectedOutput'] as String? ?? '';
      
      // Simple simulation - just check if code contains expected output
      if (userCode.toLowerCase().contains(expectedOutput.toLowerCase())) {
        output = 'Test case ${testCase['description']}: PASSED ✓';
      } else {
        output = 'Test case ${testCase['description']}: FAILED ✗';
      }
    }

    setState(() {
      _userAnswers[questionId] = {
        ...(_userAnswers[questionId] as Map<String, dynamic>? ?? {}),
        'output': output
      };
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Code executed. Check output below.'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  void _resetCode(Map<String, dynamic> question) {
    final questionId = question['id'] as String;
    final starterCode = question['starterCode'] as String? ?? '';
    
    setState(() {
      _codeControllers[questionId]?.text = starterCode;
      _userAnswers[questionId] = {
        ...(_userAnswers[questionId] as Map<String, dynamic>? ?? {}),
        'output': ''
      };
    });
  }
}
