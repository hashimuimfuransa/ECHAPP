import 'package:flutter/material.dart';
import 'dart:async';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/models/exam.dart' as exam_model;
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'exam_history_screen.dart';

class ExamTakingScreen extends StatefulWidget {
  final exam_model.Exam exam;

  const ExamTakingScreen({
    super.key,
    required this.exam,
  });

  @override
  State<ExamTakingScreen> createState() => _ExamTakingScreenState();
}

class _ExamTakingScreenState extends State<ExamTakingScreen> {
  List<Question> _questions = [];
  final Map<int, dynamic> _answers = {}; // Stores selectedOption (Number/String) and answerText (String) for each question
  final Map<int, TextEditingController> _textControllers = {}; // Controllers for text input fields
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
    // Dispose all text controllers
    for (var controller in _textControllers.values) {
      controller.dispose();
    }
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
        
        // Initialize text controllers for text input questions
        for (int i = 0; i < _questions.length; i++) {
          final question = _questions[i];
          if (question.type == 'fill_blank' || question.type == 'open') {
            if (!_textControllers.containsKey(i)) {
              // Initialize with existing answer if available
              String initialText = '';
              if (_answers[i] != null) {
                if (_answers[i] is Map) {
                  initialText = _answers[i]['answerText']?.toString() ?? '';
                } else {
                  initialText = _answers[i]?.toString() ?? '';
                }
              }
              _textControllers[i] = TextEditingController(text: initialText);
              
              // Add listener to update answers when text changes
              _textControllers[i]!.addListener(() {
                _updateAnswer(i, _textControllers[i]!.text);
              });
            }
          }
        }
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
      rethrow;
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

  void _selectAnswer(dynamic answer) {
    final currentQuestion = _questions[_currentQuestionIndex];
    
    setState(() {
      if (currentQuestion.type == 'mcq' || currentQuestion.type == 'true_false') {
        // For MCQ and True/False, store the selected option index
        final optionIndex = currentQuestion.options.indexOf(answer);
        _answers[_currentQuestionIndex] = {
          'selectedOption': optionIndex,
          'answerText': answer,
        };
      } else if (currentQuestion.type == 'fill_blank' || currentQuestion.type == 'open') {
        // For fill-in-blank and open questions, store the text answer
        _answers[_currentQuestionIndex] = {
          'selectedOption': answer,
          'answerText': answer,
        };
        
        // Also update the text controller if it exists
        if (_textControllers.containsKey(_currentQuestionIndex)) {
          _textControllers[_currentQuestionIndex]!.text = answer.toString();
        }
      }
    });
  }

  void _updateAnswer(int questionIndex, String text) {
    final question = _questions[questionIndex];
    if (question.type == 'fill_blank' || question.type == 'open') {
      setState(() {
        _answers[questionIndex] = {
          'selectedOption': text,
          'answerText': text,
        };
      });
    }
  }

  void _nextQuestion() {
    if (_currentQuestionIndex < _questions.length - 1) {
      // Ensure text controller exists for the next question if it's a text input type
      final nextQuestion = _questions[_currentQuestionIndex + 1];
      if (nextQuestion.type == 'fill_blank' || nextQuestion.type == 'open') {
        if (!_textControllers.containsKey(_currentQuestionIndex + 1)) {
          String initialText = '';
          if (_answers[_currentQuestionIndex + 1] != null) {
            if (_answers[_currentQuestionIndex + 1] is Map) {
              initialText = _answers[_currentQuestionIndex + 1]['answerText']?.toString() ?? '';
            } else {
              initialText = _answers[_currentQuestionIndex + 1]?.toString() ?? '';
            }
          }
          _textControllers[_currentQuestionIndex + 1] = TextEditingController(text: initialText);
          
          // Add listener to update answers when text changes
          _textControllers[_currentQuestionIndex + 1]!.addListener(() {
            _updateAnswer(_currentQuestionIndex + 1, _textControllers[_currentQuestionIndex + 1]!.text);
          });
        }
      }
      
      setState(() {
        _currentQuestionIndex++;
      });
    }
  }

  void _previousQuestion() {
    if (_currentQuestionIndex > 0) {
      // Ensure text controller exists for the previous question if it's a text input type
      final prevQuestion = _questions[_currentQuestionIndex - 1];
      if (prevQuestion.type == 'fill_blank' || prevQuestion.type == 'open') {
        if (!_textControllers.containsKey(_currentQuestionIndex - 1)) {
          String initialText = '';
          if (_answers[_currentQuestionIndex - 1] != null) {
            if (_answers[_currentQuestionIndex - 1] is Map) {
              initialText = _answers[_currentQuestionIndex - 1]['answerText']?.toString() ?? '';
            } else {
              initialText = _answers[_currentQuestionIndex - 1]?.toString() ?? '';
            }
          }
          _textControllers[_currentQuestionIndex - 1] = TextEditingController(text: initialText);
          
          // Add listener to update answers when text changes
          _textControllers[_currentQuestionIndex - 1]!.addListener(() {
            _updateAnswer(_currentQuestionIndex - 1, _textControllers[_currentQuestionIndex - 1]!.text);
          });
        }
      }
      
      setState(() {
        _currentQuestionIndex--;
      });
    }
  }

  void _submitExam() async {
    if (_isSubmitting) return;

    // Ensure all text field values are synced to answers before submitting
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if ((question.type == 'fill_blank' || question.type == 'open') && _textControllers.containsKey(i)) {
        final textValue = _textControllers[i]!.text;
        if (textValue.isNotEmpty) {
          _answers[i] = {
            'selectedOption': textValue,
            'answerText': textValue,
          };
        }
      }
    }

    setState(() {
      _isSubmitting = true;
    });

    try {
      final examService = ExamService();
      
      // Prepare answers in the required format
      final answers = _answers.entries
          .where((entry) => entry.value != null)
          .map((entry) {
            final question = _questions[entry.key];
            final answerData = entry.value;
            
            // Handle the new answer format (Map with selectedOption and answerText)
            if (answerData is Map) {
              return {
                'questionId': question.id,
                'selectedOption': answerData['selectedOption'],
                'answerText': answerData['answerText'],
              };
            } else {
              // Fallback for old format
              if (question.type == 'mcq' || question.type == 'true_false') {
                final answerIndex = question.options.indexOf(answerData.toString());
                return {
                  'questionId': question.id,
                  'selectedOption': answerIndex >= 0 ? answerIndex : 0,
                };
              } else {
                return {
                  'questionId': question.id,
                  'selectedOption': answerData.toString(),
                  'answerText': answerData.toString(),
                };
              }
            }
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
                AppTheme.getBackgroundColor(context),
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
                Text(
                  'Preparing Your Exam',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.getTextColor(context)
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Loading questions and setting up your test environment',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.getTextColor(context).withOpacity(0.7),
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
                AppTheme.getBackgroundColor(context),
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
                  Text(
                    'No Questions Available',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.getTextColor(context)
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
    final selectedAnswerData = _answers[_currentQuestionIndex];
    final selectedAnswer = selectedAnswerData is Map ? selectedAnswerData['answerText'] : selectedAnswerData;
    final progress = (_currentQuestionIndex + 1) / _questions.length;
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              AppTheme.getBackgroundColor(context),
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
              Text(
                'Progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.getTextColor(context)
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

  Widget _buildQuestionCard(Question question, dynamic selectedAnswer) {
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
                  if (question.section != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        question.section!,
                        style: TextStyle(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.w600,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ],
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
            
            // Question text with special handling for fill_blank
            if (question.type == 'fill_blank')
              _buildFillBlankQuestion(question.question, selectedAnswer)
            else
              Text(
                question.question,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  height: 1.4,
                  color: AppTheme.getTextColor(context)
                ),
              ),
            
            const SizedBox(height: 32),
            
            // Different UI for different question types
            if (question.type == 'mcq' || question.type == 'true_false')
              // MCQ and True/False Options
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
              )
            else if (question.type == 'fill_blank')
              // Fill-in-the-blank Text Field
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.text,
                  maxLines: 1,
                  controller: _textControllers[_currentQuestionIndex] ?? TextEditingController(text: selectedAnswer?.toString()),
                  onChanged: (value) => _selectAnswer(value),
                  decoration: InputDecoration(
                    hintText: 'Fill in the blank...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              )
            else
              // Open Question Text Field
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.multiline,
                  maxLines: null,
                  expands: true,
                  controller: _textControllers[_currentQuestionIndex] ?? TextEditingController(text: selectedAnswer?.toString()),
                  onChanged: (value) => _selectAnswer(value),
                  decoration: InputDecoration(
                    hintText: 'Type your answer here...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontStyle: FontStyle.italic,
                    ),
                    filled: true,
                    fillColor: Colors.grey.shade50,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: AppTheme.primary, width: 2),
                    ),
                  ),
                  style: TextStyle(
                    fontSize: 16,
                    height: 1.5,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFillBlankQuestion(String questionText, dynamic selectedAnswer) {
    // Split the question text by underscores or use a placeholder
    final parts = questionText.split('_____');
    
    // Get the current text from the controller if available
    String currentText = '';
    if (_textControllers.containsKey(_currentQuestionIndex)) {
      currentText = _textControllers[_currentQuestionIndex]!.text;
    } else {
      currentText = selectedAnswer?.toString() ?? '';
    }
    
    return RichText(
      text: TextSpan(
        style: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          height: 1.4,
          color: AppTheme.getTextColor(context),
        ),
        children: [
          for (int i = 0; i < parts.length; i++) ...[
            TextSpan(text: parts[i]),
            if (i < parts.length - 1)
              WidgetSpan(
                child: Container(
                  width: 120,
                  height: 30,
                  decoration: BoxDecoration(
                    border: Border(bottom: BorderSide(color: AppTheme.primary, width: 2)),
                  ),
                  child: Text(
                    currentText,
                    style: TextStyle(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ),
          ],
        ],
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
  final String type; // 'mcq', 'true_false', 'fill_blank', or 'open'
  final List<String> options;
  final int points;
  final String? section;

  Question({
    required this.id,
    required this.question,
    required this.type,
    required this.options,
    required this.points,
    this.section,
  });

  factory Question.fromJson(Map<String, dynamic> json) {
    return Question(
      id: json['_id'] ?? json['id'] ?? '',
      question: json['question'] ?? '',
      type: json['type'] ?? 'mcq', // Handle null type explicitly
      options: List<String>.from(json['options'] ?? []),
      points: json['points'] ?? 1,
      section: json['section'],
    );
  }
}



class ExamResultsScreen extends StatelessWidget {
  final exam_model.Exam exam;
  final ExamResult result;

  const ExamResultsScreen({
    super.key,
    required this.exam,
    required this.result,
  });

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
              AppTheme.getBackgroundColor(context),
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
                      icon: Icon(Icons.arrow_back, color: AppTheme.getIconColor(context)),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Exam Results',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.getTextColor(context)
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
                            style: TextStyle(
                              fontSize: 18,
                              color: AppTheme.getTextColor(context).withOpacity(0.7),
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
                color: AppTheme.blackColor
              ),
            ),
            const SizedBox(height: 16),
            
            // Large score display
            Text(
              '${result.score}/${result.totalPoints}',
              style: TextStyle(
                fontSize: 48,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor
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
            Text(
              'Performance Summary',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor
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
              color: AppTheme.greyColor
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
            onPressed: () => context.go('/dashboard'),
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
              // Navigate to exam history screen to review answers
              Navigator.pushReplacement(
                context,
                MaterialPageRoute(
                  builder: (context) => const ExamHistoryScreen(),
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
