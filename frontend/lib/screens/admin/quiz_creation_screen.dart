import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/models/question.dart';
import 'package:excellencecoachinghub/services/api/quiz_service.dart';

class QuizCreationScreen extends ConsumerStatefulWidget {
  final String? sectionId;
  final String? courseId;
  final String? quizId; // For editing existing quiz

  const QuizCreationScreen({
    super.key,
    this.sectionId,
    this.courseId,
    this.quizId,
  });

  @override
  ConsumerState<QuizCreationScreen> createState() => _QuizCreationScreenState();
}

class _QuizCreationScreenState extends ConsumerState<QuizCreationScreen> 
    with TickerProviderStateMixin {
  late TabController _tabController;
  
  // Quiz details
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _quizType = 'quiz';
  int _passingScore = 70;
  int _timeLimit = 30; // minutes
  bool _isPublished = false;
  
  // Questions
  List<Question> _questions = [];
  List<QuestionTemplate> _questionTemplates = [];
  final Set<int> _editingQuestions = {}; // Track which questions are being edited
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadQuestionTemplates();
    if (widget.quizId != null) {
      _loadExistingQuiz();
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadQuestionTemplates() async {
    // TODO: Load from API
    setState(() {
      _questionTemplates = [
        QuestionTemplate(
          id: 'mcq-basic',
          name: 'Multiple Choice',
          icon: Icons.radio_button_checked,
          description: 'Students select one correct answer',
          questionType: 'mcq',
        ),
        QuestionTemplate(
          id: 'true-false',
          name: 'True/False',
          icon: Icons.check_circle_outline,
          description: 'Students determine if statement is correct',
          questionType: 'true_false',
        ),
        QuestionTemplate(
          id: 'essay',
          name: 'Essay',
          icon: Icons.edit,
          description: 'Students write detailed response',
          questionType: 'essay',
        ),
        QuestionTemplate(
          id: 'drag-drop',
          name: 'Drag & Drop',
          icon: Icons.drag_indicator,
          description: 'Interactive drag and drop exercise',
          questionType: 'drag_drop',
        ),
        QuestionTemplate(
          id: 'matching',
          name: 'Matching',
          icon: Icons.compare_arrows,
          description: 'Match items from two lists',
          questionType: 'matching',
        ),
        QuestionTemplate(
          id: 'ordering',
          name: 'Ordering',
          icon: Icons.format_list_numbered,
          description: 'Arrange items in correct order',
          questionType: 'ordering',
        ),
      ];
    });
  }

  Future<void> _loadExistingQuiz() async {
    try {
      final quiz = await QuizService.getQuiz(widget.quizId!);

      setState(() {
        _titleController.text = quiz['title'] ?? '';
        _descriptionController.text = quiz['description'] ?? '';
        _quizType = quiz['type'] ?? '';
        _passingScore = quiz['passingScore'] ?? 70;
        _timeLimit = quiz['timeLimit'] ?? 30;
        _isPublished = quiz['isPublished'] ?? true;

        // Load questions
        final questionsData = quiz['questions'] as List<dynamic>? ?? [];
        _questions = questionsData.map((q) {
          final questionData = q as Map<String, dynamic>;
          // Copy question-specific data
          List<Option>? copiedOptions;
          if (questionData['options'] != null) {
            final optionsList = questionData['options'] as List<dynamic>;
            copiedOptions = optionsList.map((opt) {
              final optData = opt as Map<String, dynamic>;
              return Option(
                id: optData['id'] ?? '',
                text: optData['text'] ?? '',
                image: optData['image'],
                isCorrect: optData['isCorrect'] ?? false,
              );
            }).toList();
          }

          return Question(
            id: questionData['id'] ?? '',
            examId: questionData['examId'] ?? '',
            question: questionData['question'] ?? '',
            type: questionData['type'] ?? '',
            points: questionData['points'] ?? 1,
            difficulty: questionData['difficulty'] ?? 'medium',
            explanation: questionData['explanation'],
            category: questionData['category'],
            tags: questionData['tags'] != null ? List<String>.from(questionData['tags']) : null,
            timeLimit: questionData['timeLimit'] ?? 0,
            maxAttempts: questionData['maxAttempts'] ?? 1,
            randomizeOptions: questionData['randomizeOptions'] ?? false,
            section: questionData['section'],
            options: copiedOptions,
            dragDropItems: questionData['dragDropItems'] != null 
              ? (questionData['dragDropItems'] as List<dynamic>).map((item) => DragDropItem.fromJson(item as Map<String, dynamic>)).toList()
              : null,
            dropZones: questionData['dropZones'] != null
              ? (questionData['dropZones'] as List<dynamic>).map((zone) => DropZone.fromJson(zone as Map<String, dynamic>)).toList()
              : null,
            partialCredit: questionData['partialCredit'] ?? false,
            matchingPairs: questionData['matchingPairs'] != null
              ? (questionData['matchingPairs'] as List<dynamic>).map((pair) => MatchingPair.fromJson(pair as Map<String, dynamic>)).toList()
              : null,
            correctOrder: questionData['correctOrder'] != null
              ? (questionData['correctOrder'] as List<dynamic>).map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList()
              : null,
            hotspots: questionData['hotspots'] != null
              ? (questionData['hotspots'] as List<dynamic>).map((spot) => Hotspot.fromJson(spot as Map<String, dynamic>)).toList()
              : null,
            hotspotImage: questionData['hotspotImage'],
            questionImage: questionData['questionImage'],
            questionAudio: questionData['questionAudio'],
            questionVideo: questionData['questionVideo'],
            correctAnswer: questionData['correctAnswer'],
          );
        }).toList();
      });
    } catch (e) {
      _showError('Failed to load quiz: $e');
    }
  }

  void _addQuestion(QuestionTemplate template) {
    // Initialize question-specific data
    List<Option>? options;
    dynamic correctAnswer;
    List<DragDropItem>? dragDropItems;
    List<DropZone>? dropZones;
    bool? partialCredit;
    List<MatchingPair>? matchingPairs;
    List<OrderItem>? correctOrder;
    List<Hotspot>? hotspots;
    String? hotspotImage;

    switch (template.questionType) {
      case 'mcq':
        options = [
          Option(id: '1', text: '', isCorrect: false),
          Option(id: '2', text: '', isCorrect: false),
          Option(id: '3', text: '', isCorrect: false),
          Option(id: '4', text: '', isCorrect: false),
        ];
        correctAnswer = null;
        break;
      case 'true_false':
        correctAnswer = true;
        break;
      case 'essay':
        correctAnswer = ''; // Require correct answer for essay questions
        break;
      case 'drag_drop':
        dragDropItems = [];
        dropZones = [];
        partialCredit = true;
        break;
      case 'matching':
        matchingPairs = [];
        partialCredit = true;
        break;
      case 'ordering':
        correctOrder = [];
        partialCredit = true;
        break;
      case 'hotspot':
        hotspots = [];
        hotspotImage = null;
        partialCredit = true;
        break;
    }

    final question = Question(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      examId: '', // Will be set after quiz creation
      question: '',
      type: template.questionType,
      points: 1,
      difficulty: 'medium',
      options: options,
      correctAnswer: correctAnswer,
      dragDropItems: dragDropItems,
      dropZones: dropZones,
      partialCredit: partialCredit ?? false,
      matchingPairs: matchingPairs,
      correctOrder: correctOrder,
      hotspots: hotspots,
      hotspotImage: hotspotImage,
    );

    setState(() {
      _questions.add(question);
    });

    _tabController.animateTo(1); // Switch to questions tab
  }

  void _removeQuestion(int index) {
    setState(() {
      _questions.removeAt(index);
    });
  }

  void _editQuestion(int index) {
    setState(() {
      if (_editingQuestions.contains(index)) {
        _editingQuestions.remove(index);
      } else {
        _editingQuestions.add(index);
      }
    });
  }

  void _duplicateQuestion(int index) {
    final original = _questions[index];

    // Deep copy the question-specific data
    List<Option>? copiedOptions;
    if (original.options != null) {
      copiedOptions = original.options!.map((opt) => Option(
        id: DateTime.now().millisecondsSinceEpoch.toString() + opt.id!,
        text: opt.text,
        isCorrect: opt.isCorrect,
      )).toList();
    }

    final duplicate = original.copyWith(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      options: copiedOptions,
      dragDropItems: original.dragDropItems != null ? List.from(original.dragDropItems!) : null,
      dropZones: original.dropZones != null ? List.from(original.dropZones!) : null,
      matchingPairs: original.matchingPairs != null ? List.from(original.matchingPairs!) : null,
      correctOrder: original.correctOrder != null ? List.from(original.correctOrder!) : null,
      hotspots: original.hotspots != null ? List.from(original.hotspots!) : null,
      tags: original.tags != null ? List.from(original.tags!) : null,
    );

    setState(() {
      _questions.insert(index + 1, duplicate);
    });
  }

  void _moveQuestion(int index, int direction) {
    final newIndex = index + direction;
    if (newIndex < 0 || newIndex >= _questions.length) return;

    setState(() {
      final question = _questions.removeAt(index);
      _questions.insert(newIndex, question);
    });
  }

  Map<String, dynamic> _prepareSingleQuestionForAPI(Question question) {
    final Map<String, dynamic> questionData = question.toJson();
    
    // Remove examId for updates (backend doesn't allow changing it)
    questionData.remove('examId');
    
    // Ensure correctAnswer is properly set for MCQ questions
    if (question.type == 'mcq' && question.options != null) {
      final correctOption = question.options!.firstWhere(
        (opt) => opt.isCorrect,
        orElse: () => Option(id: '', text: '', isCorrect: false),
      );
      if (correctOption.id?.isNotEmpty == true) {
        questionData['correctAnswer'] = correctOption.id;
      }
    }
    
    // Ensure correctAnswer is set for True/False questions
    if (question.type == 'true_false' && question.correctAnswer != null) {
      questionData['correctAnswer'] = question.correctAnswer;
    }
    
    // Remove null fields that might cause issues
    questionData.removeWhere((key, value) => value == null);
    
    return questionData;
  }

  Future<void> _updateQuestion(Question question, int index) async {
    try {
      // Only update if question has an ID that indicates it was saved to backend
      if (question.id.isNotEmpty && !question.id.startsWith(DateTime.now().millisecondsSinceEpoch.toString().substring(0, 6))) {
        final preparedData = _prepareSingleQuestionForAPI(question);
        final updatedQuestion = await QuizService.updateQuestion(question.id, Question.fromJson(preparedData));
        setState(() {
          _questions[index] = updatedQuestion;
        });
        _showSuccess('Question updated successfully!');
      } else {
        // For new questions, just update local state
        setState(() {
          _questions[index] = question;
        });
        _showSuccess('Question saved locally!');
      }
    } catch (e) {
      _showError('Failed to update question: $e');
    }
  }

  List<Map<String, dynamic>> _prepareQuestionsForAPI() {
    debugPrint('=== DEBUG: _prepareQuestionsForAPI() called ===');
    debugPrint('Total questions to process: ${_questions.length}');
    
    if (_questions.isEmpty) {
      debugPrint('ERROR: No questions to process!');
      return [];
    }
    
    return _questions.map((question) {
      debugPrint('=== DEBUG: Processing Question Type: ${question.type} ===');
      debugPrint('Question text: "${question.question}"');
      debugPrint('Question points: ${question.points}');
      
      Map<String, dynamic> questionData = {
        'question': question.question,
        'type': question.type,
        'points': question.points ?? 1,
        'section': question.section,
      };
      
      // Handle MCQ questions
      if (question.type == 'mcq' && question.options != null) {
        debugPrint('Processing MCQ with ${question.options!.length} options');
        final List<String> options = question.options!.map((opt) => opt.text).toList();
        final correctOptionIndex = question.options!.indexWhere((opt) => opt.isCorrect);
        
        questionData['options'] = options;
        questionData['correctAnswer'] = correctOptionIndex >= 0 ? correctOptionIndex : 0;
        
        debugPrint('MCQ Options: $options');
        debugPrint('MCQ Correct Answer Index: $correctOptionIndex');
      }
      
      // Handle True/False questions
      if (question.type == 'true_false') {
        questionData['options'] = ['True', 'False'];
        questionData['correctAnswer'] = question.correctAnswer == true ? 0 : 1;
        
        debugPrint('True/False Correct Answer: ${question.correctAnswer}');
      }
      
      // Handle Essay questions
      if (question.type == 'essay') {
        questionData['explanation'] = question.explanation;
        questionData['correctAnswer'] = question.correctAnswer ?? '';
        debugPrint('Essay Correct Answer: ${question.correctAnswer}');
        debugPrint('Essay Explanation: ${question.explanation}');
      }
      
      // Handle Drag & Drop questions
      if (question.type == 'drag_drop') {
        questionData['dragDropItems'] = question.dragDropItems ?? [];
        questionData['dropZones'] = question.dropZones ?? [];
        questionData['partialCredit'] = question.partialCredit ?? false;
        debugPrint('Drag & Drop Items: ${question.dragDropItems}');
      }
      
      // Add optional fields
      if (question.difficulty != null) {
        questionData['difficulty'] = question.difficulty;
      }
      
      debugPrint('Final prepared data: ${jsonEncode(questionData)}');
      debugPrint('=== END QUESTION PROCESSING ===');
      
      return questionData;
    }).toList();
  }

  Future<void> _saveQuiz() async {
    if (_titleController.text.trim().isEmpty) {
      _showError('Please enter a quiz title');
      return;
    }

    if (_questions.isEmpty) {
      _showError('Please add at least one question');
      return;
    }

    // Validate all questions
    for (int i = 0; i < _questions.length; i++) {
      final question = _questions[i];
      if (question.question.trim().isEmpty) {
        _showError('Question ${i + 1} is empty');
        return;
      }

      // Validate MCQ questions
      if (question.type == 'mcq') {
        if (question.options == null || question.options!.length < 2) {
          _showError('Question ${i + 1} needs at least 2 options');
          return;
        }
        
        bool hasCorrectOption = false;
        bool hasEmptyOption = false;
        for (final option in question.options!) {
          if (option.text.trim().isEmpty) {
            hasEmptyOption = true;
            break;
          }
          if (option.isCorrect) {
            hasCorrectOption = true;
          }
        }
        
        if (hasEmptyOption) {
          _showError('Question ${i + 1} has empty options');
          return;
        }
        
        if (!hasCorrectOption) {
          _showError('Question ${i + 1} needs a correct answer selected');
          return;
        }
      }

      // Validate True/False questions
      if (question.type == 'true_false') {
        if (question.correctAnswer == null) {
          _showError('Question ${i + 1} needs a correct answer selected');
          return;
        }
      }

      // Validate Essay questions
      if (question.type == 'essay') {
        if (question.correctAnswer == null || question.correctAnswer.toString().trim().isEmpty) {
          _showError('Question ${i + 1} needs a correct answer provided for grading');
          return;
        }
      }
    }

    try {
      print('=== DEBUG: Questions Array Check ===');
      print('Original questions count: ${_questions.length}');
      print('Original questions: ${jsonEncode(_questions.map((q) => q.toJson()).toList())}');
      
      // Validate questions exist
      if (_questions.isEmpty) {
        _showError('Please add at least one question before saving');
        return;
      }
      
      final preparedQuestions = _prepareQuestionsForAPI();
      debugPrint('=== DEBUG: Quiz Creation Data ===');
      debugPrint('Title: ${_titleController.text.trim()}');
      debugPrint('Section ID: ${widget.sectionId ?? ''}');
      debugPrint('Course ID: ${widget.courseId ?? ''}');
      debugPrint('Prepared questions count: ${preparedQuestions.length}');
      debugPrint('Questions: ${jsonEncode(preparedQuestions)}');
      debugPrint('Quiz Type: $_quizType');
      debugPrint('Base URL: ${ApiConfig.baseUrl}/exams');
      
      // Validate prepared questions
      if (preparedQuestions.isEmpty) {
        _showError('Questions preparation failed. Please check question data.');
        return;
      }
      
      // Test API connectivity first
      debugPrint('=== TESTING API CONNECTIVITY ===');
      try {
        final testResponse = await http.get(
          Uri.parse('${ApiConfig.baseUrl}/health'),
        );
        debugPrint('Health check status: ${testResponse.statusCode}');
      } catch (e) {
        debugPrint('Health check failed: $e');
      }
      
      // Simple test - ensure we have questions
      debugPrint('=== SIMPLE QUESTIONS CHECK ===');
      debugPrint('Questions list length: ${_questions.length}');
      if (_questions.isNotEmpty) {
        debugPrint('First question type: ${_questions.first.type}');
        debugPrint('First question text: "${_questions.first.question}"');
        if (_questions.first.options != null) {
          debugPrint('First question options count: ${_questions.first.options!.length}');
        }
      } else {
        print('ERROR: Questions list is empty!');
        _showError('Please add at least one question before saving');
        return;
      }
      
      // Force debug output to verify questions exist
      debugPrint('=== FORCED DEBUG: Questions Array ===');
      for (int i = 0; i < _questions.length; i++) {
        debugPrint('Question $i RAW: ${_questions[i].toJson()}');
      }
      
      // Check if questions are actually being sent to API
      debugPrint('=== FINAL CHECK: Questions being sent to API ===');
      debugPrint('Raw questions count: ${_questions.length}');
      debugPrint('Prepared questions count: ${preparedQuestions.length}');
      debugPrint('Prepared questions sample: ${preparedQuestions.isNotEmpty ? preparedQuestions.first : "EMPTY"}');
      
      if (preparedQuestions.isEmpty) {
        debugPrint('CRITICAL: No prepared questions to send!');
      } else {
        debugPrint('SUCCESS: ${preparedQuestions.length} questions will be sent');
        debugPrint('First prepared question: ${preparedQuestions.first}');
      }
      
      // Add immediate test to verify questions data
      print('=== IMMEDIATE VERIFICATION ===');
      if (_questions.isNotEmpty) {
        final firstQuestion = _questions.first;
        print('First question exists: ${firstQuestion.question.isNotEmpty}');
        print('First question type: ${firstQuestion.type}');
        if (firstQuestion.type == 'mcq') {
          print('MCQ options exist: ${firstQuestion.options != null && firstQuestion.options!.isNotEmpty}');
          if (firstQuestion.options != null) {
            final hasCorrectOption = firstQuestion.options!.any((opt) => opt.isCorrect);
            print('MCQ has correct option: $hasCorrectOption');
          }
        }
      }
      
      // Check if this is the issue - questions might not be persisting
      // Mobile-friendly debugging
      debugPrint('=== DEBUGGING QUESTION PERSISTENCE ===');
      debugPrint('Questions in state: ${_questions.length}');
      debugPrint('Questions in UI: Are they showing up in the interface?');
      debugPrint('If questions count > 0 but not appearing in debug, there might be a state issue.');
      
      // Force print questions data for debugging
      debugPrint('=== FORCE PRINTING ALL QUESTIONS ===');
      for (int i = 0; i < _questions.length; i++) {
        debugPrint('Question $i RAW: ${_questions[i].toJson()}');
      }
      
      // Check if questions are properly initialized
      debugPrint('=== QUESTION INITIALIZATION CHECK ===');
      if (_questions.isEmpty) {
        debugPrint('ERROR: No questions in _questions array!');
        _showError('Please add at least one question');
        return;
      }
      
      // Check if questions have proper data
      for (int i = 0; i < _questions.length; i++) {
        final q = _questions[i];
        if (q.question.trim().isEmpty) {
          debugPrint('ERROR: Question $i has empty text!');
        }
        if (q.type == 'mcq' && (q.options == null || q.options!.isEmpty)) {
          debugPrint('ERROR: Question $i has no options!');
        }
        if (q.type == 'true_false' && q.correctAnswer == null) {
          debugPrint('ERROR: Question $i has no correct answer!');
        }
      }
      
      debugPrint('=== FINAL QUESTIONS SUMMARY ===');
      debugPrint('Total questions: ${_questions.length}');
      debugPrint('Valid questions: ${_questions.where((q) => 
        q.question.trim().isNotEmpty && 
        (q.type != 'mcq' || (q.options != null && q.options!.isNotEmpty)) && 
        (q.type != 'true_false' || q.correctAnswer != null)
      ).length}');
      
      if (_questions.isEmpty) {
        print('CRITICAL: No valid questions to save!');
        _showError('Please add at least one valid question');
        return;
      }
      
      final result = await QuizService.createQuiz(
        sectionId: widget.sectionId ?? '',
        courseId: widget.courseId ?? '',
        title: _titleController.text.trim(),
        type: _quizType,
        passingScore: _passingScore,
        timeLimit: _timeLimit,
        preparedQuestions: preparedQuestions,
        isPublished: _isPublished,
      );

      _showSuccess('Quiz saved successfully!');
      context.pop();
    } catch (e) {
      print('=== ERROR: Quiz Creation Failed ===');
      print('Error: $e');
      _showError('Failed to save quiz: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildQuizSettings() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title
          Text(
            'Quiz Settings',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 24),

          // Basic Information
          _buildSectionTitle('Basic Information'),
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _titleController,
            label: 'Quiz Title',
            hint: 'Enter quiz title',
            required: true,
          ),
          
          const SizedBox(height: 16),
          
          _buildTextField(
            controller: _descriptionController,
            label: 'Description',
            hint: 'Optional description for students',
            maxLines: 3,
          ),

          const SizedBox(height: 24),

          // Quiz Configuration
          _buildSectionTitle('Quiz Configuration'),
          const SizedBox(height: 16),

          // Quiz Type
          _buildQuizTypeDropdown(),

          const SizedBox(height: 16),

          // Passing Score
          _buildSliderField(
            label: 'Passing Score (%)',
            value: _passingScore.toDouble(),
            min: 0,
            max: 100,
            divisions: 20,
            onChanged: (value) => setState(() => _passingScore = value.round()),
          ),

          const SizedBox(height: 16),

          // Time Limit
          _buildSliderField(
            label: 'Time Limit (minutes)',
            value: _timeLimit.toDouble(),
            min: 5,
            max: 180,
            divisions: 35,
            onChanged: (value) => setState(() => _timeLimit = value.round()),
          ),

          const SizedBox(height: 24),

          // Publishing
          _buildSectionTitle('Publishing'),
          const SizedBox(height: 16),

          _buildSwitchField(
            label: 'Publish Quiz',
            subtitle: 'Make this quiz available to students',
            value: _isPublished,
            onChanged: (value) => setState(() => _isPublished = value),
          ),

          const SizedBox(height: 32),

          // Save Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveQuiz,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Save Quiz',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionsTab() {
    return Column(
      children: [
        // Add Question Section
        Container(
          padding: const EdgeInsets.all(20),
          color: Colors.grey[50],
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Add Questions',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 16),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: _questionTemplates.map((template) {
                  return _buildQuestionTemplate(template);
                }).toList(),
              ),
            ],
          ),
        ),

        // Questions List
        Expanded(
          child: _questions.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.quiz_outlined,
                      size: 64,
                      color: Colors.grey[400],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'No questions added yet',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.grey[600],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Select a question type above to get started',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              )
            : ListView.builder(
                padding: const EdgeInsets.all(20),
                itemCount: _questions.length,
                itemBuilder: (context, index) {
                  return _buildQuestionCard(_questions[index], index);
                },
              ),
        ),
      ],
    );
  }

  Widget _buildQuestionTemplate(QuestionTemplate template) {
    return SizedBox(
      width: 160,
      height: 120,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => _addQuestion(template),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey[300]!),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  template.icon,
                  size: 32,
                  color: AppTheme.primaryGreen,
                ),
                const SizedBox(height: 8),
                Text(
                  template.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 4),
                Text(
                  template.description,
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.grey[600],
                  ),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCard(Question question, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[300]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Question Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: _getQuestionTypeColor(question.type),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _getQuestionTypeName(question.type),
                    style: const TextStyle(
                      fontSize: 11,
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  'Question ${index + 1}',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                Text(
                  '${question.points} pts',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(width: 8),
                PopupMenuButton<String>(
                  onSelected: (value) {
                    switch (value) {
                      case 'edit':
                        _editQuestion(index);
                        break;
                      case 'duplicate':
                        _duplicateQuestion(index);
                        break;
                      case 'move_up':
                        _moveQuestion(index, -1);
                        break;
                      case 'move_down':
                        _moveQuestion(index, 1);
                        break;
                      case 'delete':
                        _removeQuestion(index);
                        break;
                    }
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'edit',
                      child: Row(
                        children: [
                          Icon(Icons.edit, size: 18),
                          SizedBox(width: 8),
                          Text('Edit'),
                        ],
                      ),
                    ),
                    const PopupMenuItem(
                      value: 'duplicate',
                      child: Row(
                        children: [
                          Icon(Icons.copy, size: 18),
                          SizedBox(width: 8),
                          Text('Duplicate'),
                        ],
                      ),
                    ),
                    if (index > 0)
                      const PopupMenuItem(
                        value: 'move_up',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_upward, size: 18),
                            SizedBox(width: 8),
                            Text('Move Up'),
                          ],
                        ),
                      ),
                    if (index < _questions.length - 1)
                      const PopupMenuItem(
                        value: 'move_down',
                        child: Row(
                          children: [
                            Icon(Icons.arrow_downward, size: 18),
                            SizedBox(width: 8),
                            Text('Move Down'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete, size: 18, color: Colors.red),
                          SizedBox(width: 8),
                          Text('Delete', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Question Content
          Padding(
            padding: const EdgeInsets.all(16),
            child: _editingQuestions.contains(index)
                ? _buildQuestionEditor(question, index)
                : _buildQuestionPreview(question),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestionPreview(Question question) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          question.question.isNotEmpty ? question.question : 'Question text not set',
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        
        // Show question-specific preview
        if (question.type == 'mcq' && question.options != null) ...[
          Text(
            'Options:',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...question.options!.asMap().entries.map((entry) {
            final index = entry.key;
            final option = entry.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: [
                  Icon(
                    option.isCorrect ? Icons.check_circle : Icons.radio_button_unchecked,
                    size: 16,
                    color: option.isCorrect ? Colors.green : Colors.grey,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${String.fromCharCode(65 + index)}. ${option.text.isNotEmpty ? option.text : 'Empty option'}',
                      style: TextStyle(
                        color: option.text.isNotEmpty ? Colors.black : Colors.red,
                        fontWeight: option.isCorrect ? FontWeight.w600 : FontWeight.normal,
                      ),
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
        
        if (question.type == 'true_false') ...[
          Text(
            'Correct Answer: ${question.correctAnswer == true ? 'True' : question.correctAnswer == false ? 'False' : 'Not set'}',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: question.correctAnswer != null ? Colors.green : Colors.red,
            ),
          ),
        ],
        
        if (question.type == 'essay') ...[
          if (question.explanation != null && question.explanation!.isNotEmpty) ...[
            Text(
              'Grading Rubric:',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.grey[700],
              ),
            ),
            const SizedBox(height: 4),
            Text(question.explanation!),
          ],
        ],
        
        if (question.type == 'drag_drop') ...[
          Text(
            'Drag & Drop Question',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          if (question.dragDropItems != null && question.dragDropItems!.isNotEmpty)
            Text('${question.dragDropItems!.length} items configured'),
        ],
        
        // Show common metadata
        const SizedBox(height: 12),
        Row(
          children: [
            Text(
              'Difficulty: ${question.difficulty ?? 'medium'}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(width: 16),
            Text(
              'Points: ${question.points}',
              style: TextStyle(
                fontSize: 12,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuestionEditor(Question question, int index) {
    switch (question.type) {
      case 'mcq':
        return _buildMCQEditor(question, index);
      case 'true_false':
        return _buildTrueFalseEditor(question, index);
      case 'essay':
        return _buildEssayEditor(question, index);
      case 'drag_drop':
        return _buildDragDropEditor(question, index);
      case 'matching':
        return _buildMatchingEditor(question, index);
      case 'ordering':
        return _buildOrderingEditor(question, index);
      default:
        return Text('Question type ${question.type} not yet supported');
    }
  }

  Widget _buildMCQEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Question',
              hintText: 'Enter your question here',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Randomize Options toggle
          SwitchListTile(
            title: const Text('Randomize Options'),
            subtitle: const Text('Shuffle answer options for each student'),
            value: question.randomizeOptions,
            onChanged: (value) {
              setState(() {
                _questions[index] = question.copyWith(randomizeOptions: value);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Explanation field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain the correct answer to students',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Answer Options',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          ...List.generate(question.options?.length ?? 0, (optionIndex) {
            final option = question.options![optionIndex];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Radio<bool>(
                    value: true,
                    groupValue: option.isCorrect,
                    onChanged: (value) {
                      setState(() {
                        // Clear all other options
                        for (int i = 0; i < question.options!.length; i++) {
                          question.options![i] = Option(
                            id: question.options![i].id,
                            text: question.options![i].text,
                            isCorrect: i == optionIndex,
                          );
                        }
                      });
                    },
                  ),
                  Expanded(
                    child: TextField(
                      decoration: InputDecoration(
                        labelText: 'Option ${String.fromCharCode(65 + optionIndex)}',
                        hintText: 'Enter option text',
                        border: const OutlineInputBorder(),
                      ),
                      onChanged: (value) {
                        question.options![optionIndex] = Option(
                          id: option.id,
                          text: value,
                          isCorrect: option.isCorrect,
                        );
                      },
                      controller: TextEditingController(text: option.text),
                    ),
                  ),
                  if (question.options!.length > 2)
                    IconButton(
                      icon: const Icon(Icons.delete, color: Colors.red),
                      onPressed: () {
                        setState(() {
                          question.options!.removeAt(optionIndex);
                        });
                      },
                    ),
                ],
              ),
            );
          }),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: question.options != null && question.options!.length < 6
              ? () {
                  setState(() {
                    question.options!.add(
                      Option(
                        id: DateTime.now().millisecondsSinceEpoch.toString(),
                        text: '',
                        isCorrect: false,
                      ),
                    );
                  });
                }
              : null,
            icon: const Icon(Icons.add),
            label: const Text('Add Option'),
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrueFalseEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Statement',
              hintText: 'Enter the statement to be evaluated',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Explanation field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain the correct answer to students',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          Text(
            'Correct Answer',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('True'),
                  value: true,
                  groupValue: question.correctAnswer,
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(correctAnswer: value);
                    });
                  },
                ),
              ),
              Expanded(
                child: RadioListTile<bool>(
                  title: const Text('False'),
                  value: false,
                  groupValue: question.correctAnswer,
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(correctAnswer: value);
                    });
                  },
                ),
              ),
            ],
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildEssayEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Essay Question',
              hintText: 'Enter the essay question here',
              border: OutlineInputBorder(),
            ),
            maxLines: 4,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Grading Rubric (Optional)',
              hintText: 'Describe how this essay will be graded',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          TextField(
            decoration: const InputDecoration(
              labelText: 'Correct Answer (Required)',
              hintText: 'Provide the model answer for grading reference',
              border: OutlineInputBorder(),
              helperText: 'This will be used for automated grading and as a reference for manual grading',
            ),
            maxLines: 4,
            onChanged: (value) {
              _questions[index] = question.copyWith(correctAnswer: value);
            },
            controller: TextEditingController(text: question.correctAnswer?.toString() ?? ''),
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDragDropEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Instructions',
              hintText: 'Explain what students should drag and where',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Partial credit toggle
          SwitchListTile(
            title: const Text('Allow Partial Credit'),
            subtitle: const Text('Give points for partially correct answers'),
            value: question.partialCredit ?? false,
            onChanged: (value) {
              setState(() {
                _questions[index] = question.copyWith(partialCredit: value);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Explanation field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain correct answer to students',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Drag & Drop Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        _showDragDropConfigDialog(question);
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Builder(
                  builder: (context) {
                    final zones = question.dropZones ?? [];
                    final items = question.dragDropItems ?? [];
                    return Text(
                      zones.isEmpty && items.isEmpty 
                        ? 'Click "Configure" to set up drop zones and draggable items.'
                        : 'Configured: ${zones.length} zone(s), ${items.length} item(s)',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: const OutlineInputBorder(),
      ),
      maxLines: maxLines,
    );
  }

  Widget _buildQuizTypeDropdown() {
    final quizTypes = [
      {'value': 'quiz', 'label': 'Quiz'},
      {'value': 'midterm', 'label': 'Midterm Exam'},
      {'value': 'final', 'label': 'Final Exam'},
      {'value': 'pastpaper', 'label': 'Past Paper'},
    ];
    
    return DropdownButtonFormField<String>(
      initialValue: _quizType,
      decoration: const InputDecoration(
        labelText: 'Quiz Type',
        border: OutlineInputBorder(),
      ),
      items: quizTypes.map((type) {
        return DropdownMenuItem(
          value: type['value'],
          child: Text(type['label']!),
        );
      }).toList(),
      onChanged: (value) {
        setState(() {
          _quizType = value!;
        });
      },
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
      ),
      items: items.map((item) {
        return DropdownMenuItem(
          value: item,
          child: Text(item.toUpperCase()),
        );
      }).toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildSliderField({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required Function(double) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
            Text(
              value.round().toString(),
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppTheme.primaryGreen,
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          divisions: divisions,
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildSwitchField({
    required String label,
    required String subtitle,
    required bool value,
    required Function(bool) onChanged,
  }) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                ),
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        ),
        Switch(
          value: value,
          onChanged: onChanged,
          activeThumbColor: AppTheme.primaryGreen,
        ),
      ],
    );
  }

  Color _getQuestionTypeColor(String type) {
    switch (type) {
      case 'mcq':
        return Colors.blue;
      case 'true_false':
        return Colors.green;
      case 'essay':
        return Colors.purple;
      case 'drag_drop':
        return Colors.orange;
      case 'matching':
        return Colors.teal;
      case 'ordering':
        return Colors.indigo;
      default:
        return Colors.grey;
    }
  }

  String _getQuestionTypeName(String type) {
    switch (type) {
      case 'mcq':
        return 'MCQ';
      case 'true_false':
        return 'T/F';
      case 'essay':
        return 'ESSAY';
      case 'drag_drop':
        return 'DRAG';
      case 'matching':
        return 'MATCH';
      case 'ordering':
        return 'ORDER';
      default:
        return type.toUpperCase();
    }
  }

  Widget _buildMatchingEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Instructions',
              hintText: 'Explain how students should match items',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Partial credit toggle
          SwitchListTile(
            title: const Text('Allow Partial Credit'),
            subtitle: const Text('Give points for partially correct matches'),
            value: question.partialCredit ?? false,
            onChanged: (value) {
              setState(() {
                _questions[index] = question.copyWith(partialCredit: value);
              });
            },
          ),
          const SizedBox(height: 16),
          
          // Explanation field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain the correct matches to students',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Matching Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement matching configuration dialog
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Advanced matching configuration will be available in the next update.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildOrderingEditor(Question question, int index) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            decoration: const InputDecoration(
              labelText: 'Instructions',
              hintText: 'Explain how students should order items',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(question: value);
            },
            controller: TextEditingController(text: question.question),
          ),
          const SizedBox(height: 16),
          
          // Additional fields row
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: question.difficulty ?? 'medium',
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                  ),
                  items: ['easy', 'medium', 'hard'].map((level) {
                    return DropdownMenuItem(
                      value: level,
                      child: Text(level.toUpperCase()),
                    );
                  }).toList(),
                  onChanged: (value) {
                    setState(() {
                      _questions[index] = question.copyWith(difficulty: value);
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(points: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.points.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Category field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Category (Optional)',
              hintText: 'e.g., Mathematics, Physics, etc.',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(category: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.category ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Tags field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Tags (Optional)',
              hintText: 'Separate tags with commas',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) {
              _questions[index] = question.copyWith(tags: value.isEmpty ? null : value.split(',').map((t) => t.trim()).toList());
            },
            controller: TextEditingController(text: question.tags?.join(', ') ?? ''),
          ),
          const SizedBox(height: 16),
          
          // Time Limit and Max Attempts
          Row(
            children: [
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Time Limit (seconds, 0 for unlimited)',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(timeLimit: int.tryParse(value) ?? 0);
                  },
                  controller: TextEditingController(text: question.timeLimit.toString()),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: TextField(
                  decoration: const InputDecoration(
                    labelText: 'Max Attempts',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                  onChanged: (value) {
                    _questions[index] = question.copyWith(maxAttempts: int.tryParse(value) ?? 1);
                  },
                  controller: TextEditingController(text: question.maxAttempts.toString()),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Explanation field
          TextField(
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain the correct order to students',
              border: OutlineInputBorder(),
            ),
            maxLines: 3,
            onChanged: (value) {
              _questions[index] = question.copyWith(explanation: value.isEmpty ? null : value);
            },
            controller: TextEditingController(text: question.explanation ?? ''),
          ),
          const SizedBox(height: 16),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Ordering Configuration',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey[700],
                      ),
                    ),
                    TextButton.icon(
                      onPressed: () {
                        // TODO: Implement ordering configuration dialog
                      },
                      icon: const Icon(Icons.settings),
                      label: const Text('Configure'),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Advanced ordering configuration will be available in the next update.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey[600],
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ],
            ),
          ),
          
          // Save/Cancel buttons
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () async {
                    await _updateQuestion(question, index);
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                  ),
                  child: const Text('Save Changes'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _editingQuestions.remove(index);
                    });
                  },
                  child: const Text('Cancel'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: Text(widget.quizId != null ? 'Edit Quiz' : 'Create Quiz'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Settings', icon: Icon(Icons.settings)),
            Tab(text: 'Questions', icon: Icon(Icons.quiz)),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildQuizSettings(),
          _buildQuestionsTab(),
        ],
      ),
    );
  }

  void _showDragDropConfigDialog(Question question) {
    final TextEditingController zoneController = TextEditingController();
    final TextEditingController itemController = TextEditingController();
    String? selectedZoneId;
    
    List<DropZone> zones = List.from(question.dropZones ?? []);
    List<DragDropItem> items = List.from(question.dragDropItems ?? []);
    
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configure Drag & Drop'),
              content: SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('Drop Zones:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...zones.asMap().entries.map((entry) {
                        final index = entry.key;
                        final zone = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${zone.label} (${zone.id})'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    zones.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: zoneController,
                              decoration: const InputDecoration(
                                labelText: 'Zone Label',
                                hintText: 'e.g., Fruits',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (zoneController.text.isNotEmpty) {
                                setDialogState(() {
                                  final zoneId = 'zone_${zones.length + 1}';
                                  zones.add(DropZone(
                                    id: zoneId,
                                    label: zoneController.text.trim(),
                                    correctItems: [],
                                  ));
                                  debugPrint('=== ZONE ADDED ===');
                                  debugPrint('Zone ID: $zoneId');
                                  debugPrint('Zone Label: ${zoneController.text.trim()}');
                                  debugPrint('Total zones: ${zones.length}');
                                  zoneController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                      
                      const SizedBox(height: 16),
                      
                      const Text('Drag Items:', style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ...items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text('${item.content} → ${item.targetZone}'),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete, color: Colors.red),
                                onPressed: () {
                                  setDialogState(() {
                                    items.removeAt(index);
                                  });
                                },
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: itemController,
                              decoration: const InputDecoration(
                                labelText: 'Item Content',
                                hintText: 'e.g., Apple',
                                border: OutlineInputBorder(),
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          DropdownButton<String>(
                            value: selectedZoneId,
                            hint: const Text('Zone'),
                            items: zones.map((zone) {
                              return DropdownMenuItem(
                                value: zone.id,
                                child: Text(zone.label),
                              );
                            }).toList(),
                            onChanged: (value) {
                              setDialogState(() {
                                selectedZoneId = value;
                              });
                            },
                          ),
                          IconButton(
                            icon: const Icon(Icons.add),
                            onPressed: () {
                              if (itemController.text.isNotEmpty && selectedZoneId != null) {
                                setDialogState(() {
                                  final itemId = 'item_${items.length + 1}';
                                  items.add(DragDropItem(
                                    id: itemId,
                                    content: itemController.text.trim(),
                                    targetZone: selectedZoneId!,
                                  ));
                                  debugPrint('=== ITEM ADDED ===');
                                  debugPrint('Item ID: $itemId');
                                  debugPrint('Item Content: ${itemController.text.trim()}');
                                  debugPrint('Target Zone: $selectedZoneId');
                                  debugPrint('Total items: ${items.length}');
                                  itemController.clear();
                                });
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      final questionIndex = _questions.indexOf(question);
                      if (questionIndex != -1) {
                        _questions[questionIndex] = question.copyWith(
                          dropZones: zones,
                          dragDropItems: items,
                        );
                        debugPrint('=== DRAG DROP CONFIG SAVED ===');
                        debugPrint('Zones saved: ${zones.length}');
                        debugPrint('Items saved: ${items.length}');
                        debugPrint('Question dropZones: ${_questions[questionIndex].dropZones}');
                        debugPrint('Question dragDropItems: ${_questions[questionIndex].dragDropItems}');
                      }
                    });
                    Navigator.of(context).pop();
                  },
                  child: const Text('Save'),
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class QuestionTemplate {
  final String id;
  final String name;
  final IconData icon;
  final String description;
  final String questionType;

  QuestionTemplate({
    required this.id,
    required this.name,
    required this.icon,
    required this.description,
    required this.questionType,
  });
}
