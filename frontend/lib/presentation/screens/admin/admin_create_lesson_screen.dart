import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../../../config/app_theme.dart';
import '../../../config/api_config.dart';
import '../../../data/repositories/lesson_repository.dart';
import '../../../data/repositories/video_repository.dart';
import '../../../models/video.dart';
import '../../../models/question.dart';
import '../../../presentation/providers/content_management_provider.dart';
import '../../../services/document/lesson_document_service.dart';
import '../../../services/infrastructure/api_client.dart';
import '../../../services/api/quiz_service.dart';

class AdminCreateLessonScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String sectionId;
  final String? lessonId;

  const AdminCreateLessonScreen({
    super.key,
    required this.courseId,
    required this.sectionId,
    this.lessonId,
  });

  @override
  ConsumerState<AdminCreateLessonScreen> createState() => _AdminCreateLessonScreenState();
}

class _AdminCreateLessonScreenState extends ConsumerState<AdminCreateLessonScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  
  String? _selectedVideoId;
  String? _documentPath; // Store document path from S3 for AI notes
  String? _notesPdfUrl; // Store direct PDF path from S3
  bool _processNotesWithAI = false; // Whether to process notes with AI
  int _duration = 0;
  bool _isLoading = false;
  bool _isUploadingVideo = false;
  bool _isUploadingDocument = false; // Track document upload status (for AI notes)
  bool _isUploadingPdf = false; // Track direct PDF upload status
  String? _errorMessage;
  List<Video> _videos = [];
  final ImagePicker _picker = ImagePicker();
  final ApiClient _apiClient = ApiClient();
  
  // Quiz creation fields
  bool _includeQuiz = false;
  String _selectedQuizType = 'quiz'; // quiz, exam, final, assessment
  final _quizTitleController = TextEditingController();
  final _quizDescriptionController = TextEditingController();
  int _quizTimeLimit = 30; // minutes
  int _quizNumberOfQuestions = 5;
  bool _shuffleQuestions = false; // Whether to shuffle questions for students
  bool _shuffleOptions = false; // Whether to shuffle options within questions
  final List<Map<String, dynamic>> _quizQuestions = [];
  final bool _isCreatingQuiz = false;
  
  // Question creation fields
  bool _showQuestionForm = false;
  final _questionController = TextEditingController();
  String _selectedQuestionType = 'mcq';
  int _editingQuestionIndex = -1; // -1 means new question, >=0 means editing
  final List<TextEditingController> _optionControllers = [TextEditingController(), TextEditingController(), TextEditingController(), TextEditingController()];
  final List<bool> _correctAnswers = [false, false, false, false];
  final _fillBlankController = TextEditingController();
  final _trueFalseController = TextEditingController();
  bool _trueFalseAnswer = false;
  final _essayController = TextEditingController();
  int _questionPoints = 1;
  String _questionDifficulty = 'medium';
  final _explanationController = TextEditingController();
  
  // Interactive question type fields
  final List<TextEditingController> _dragItemControllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  final List<TextEditingController> _dragTargetControllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  final List<String> _dragItemTargets = ['', '', ''];
  
  final List<TextEditingController> _matchingLeftControllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  final List<TextEditingController> _matchingRightControllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  
  final List<TextEditingController> _orderingItemControllers = [TextEditingController(), TextEditingController(), TextEditingController()];
  final List<String> _orderingCorrectOrder = ['', '', ''];
  
  final _hotspotImageController = TextEditingController();
  final List<TextEditingController> _hotspotControllers = [TextEditingController(), TextEditingController()];
  final List<Map<String, double>> _hotspotPositions = [ {'x': 0.0, 'y': 0.0, 'width': 10.0, 'height': 10.0}, {'x': 0.0, 'y': 0.0, 'width': 10.0, 'height': 10.0} ];
  
  // Programming question fields
  String _selectedProgrammingLanguage = 'python';
  final _programmingLanguageController = TextEditingController();
  final _starterCodeController = TextEditingController();
  final _expectedOutputController = TextEditingController();
  final List<TextEditingController> _testCaseInputControllers = [TextEditingController(), TextEditingController()];
  final List<TextEditingController> _testCaseOutputControllers = [TextEditingController(), TextEditingController()];
  final _programmingInstructionsController = TextEditingController();
  bool _allowMultipleAttempts = true;
  int _maxAttempts = 3;

  @override
  void initState() {
    super.initState();
    // Validate required parameters
    if (widget.courseId.isEmpty || widget.sectionId.isEmpty) {
      throw ArgumentError('Course ID and Section ID must not be empty');
    }
    _loadVideos();
    // Load lesson data if editing
    if (widget.lessonId != null && widget.lessonId!.isNotEmpty) {
      _loadLessonData();
    }
  }

  Future<void> _loadLessonData() async {
    try {
      final lessonRepo = LessonRepository();
      final lesson = await lessonRepo.getLessonById(widget.lessonId!);
      
      if (lesson != null) {
        setState(() {
          // Populate form fields with existing lesson data
          _titleController.text = lesson.title;
          _descriptionController.text = lesson.description ?? '';
          _selectedVideoId = lesson.videoId;
          _notesPdfUrl = lesson.notesPdfUrl;
          _duration = lesson.duration;
          
          // Load materials if they exist
          if (lesson.materials != null && lesson.materials!.isNotEmpty) {
            _documentPath = lesson.materials!.first;
          }
          
          // Handle lesson type
          if (lesson.lessonType != null) {
            // You might need to map this to your lesson type selection
          }
          
          // Handle quiz data if exists
          if (lesson.quizId != null && lesson.quizId!.isNotEmpty) {
            _includeQuiz = true;
          }
        });
        
        // Load quiz data outside setState
        if (lesson.quizId != null && lesson.quizId!.isNotEmpty) {
          await _loadQuizData(lesson.quizId!);
        }
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load lesson data: ${e.toString()}';
      });
    }
  }

  Future<void> _loadQuizData(String quizId) async {
    try {
      print('Loading quiz data for quizId: $quizId');
      final quizResponse = await QuizService.getQuiz(quizId);
      print('Quiz response: $quizResponse');
      
      // Handle different response structures
      Map<String, dynamic>? quiz;
      List<dynamic>? questions;
      
      // Try different possible response structures
      if (quizResponse['data'] != null) {
        final quizData = quizResponse['data'];
        if (quizData['quiz'] != null) {
          quiz = quizData['quiz'] as Map<String, dynamic>?;
          questions = quizData['questions'] as List<dynamic>?;
        } else if (quizData is Map<String, dynamic>) {
          quiz = quizData;
          questions = quizData['questions'] as List<dynamic>?;
        }
      } else if (quizResponse['quiz'] != null) {
        quiz = quizResponse['quiz'] as Map<String, dynamic>?;
        questions = quizResponse['questions'] as List<dynamic>?;
      } else      quiz = quizResponse;
      questions = quizResponse['questions'] as List<dynamic>?;
    
      
      if (quiz != null) {
        print('Extracted quiz data: $quiz');
        print('Found questions: $questions');
        
        setState(() {
          // Load quiz basic info
          _quizTitleController.text = quiz!['title'] ?? '';
          _quizDescriptionController.text = quiz['description'] ?? '';
          _selectedQuizType = quiz['type'] ?? 'quiz';
          _quizTimeLimit = quiz['timeLimit'] ?? 30;
          _quizNumberOfQuestions = quiz['questionsCount'] ?? quiz['numberOfQuestions'] ?? questions?.length ?? 5;
          _maxAttempts = quiz['maxAttempts'] ?? 3;
          _shuffleQuestions = quiz['shuffleQuestions'] ?? false;
          _shuffleOptions = quiz['shuffleOptions'] ?? false;
          
          // Clear existing questions
          _quizQuestions.clear();
          
          // Load questions if available
          if (questions != null && questions.isNotEmpty) {
            print('Processing ${questions.length} questions');
            
            for (final questionData in questions) {
              if (questionData != null) {
                final question = questionData as Map<String, dynamic>;
                print('Processing question: ${question['text'] ?? question['question']}');
                
                // Handle different question structures
                Map<String, dynamic> questionMap = {
                  'question': question['question'] ?? question['text'] ?? '',
                  'type': question['type'] ?? 'mcq',
                  'options': question['options'] ?? [],
                  'correctAnswer': question['correctAnswer'] ?? question['answer'] ?? [],
                  'points': question['points'] ?? 1,
                  'difficulty': question['difficulty'] ?? 'medium',
                  'explanation': question['explanation'] ?? '',
                  // Add other question fields as needed
                  'fillBlankAnswer': question['fillBlankAnswer'] ?? '',
                  'trueFalseAnswer': question['trueFalseAnswer'] ?? false,
                  'essayAnswer': question['essayAnswer'] ?? '',
                  // Add drag-drop and interactive question fields
                  'dragDropItems': question['dragDropItems'] ?? [],
                  'dropZones': question['dropZones'] ?? [],
                  'matchingPairs': question['matchingPairs'] ?? [],
                  'correctOrder': question['correctOrder'] ?? [],
                  'hotspots': question['hotspots'] ?? [],
                  'hotspotImage': question['hotspotImage'],
                  'partialCredit': question['partialCredit'] ?? false,
                };
                
                _quizQuestions.add(questionMap);
              }
            }
            
            print('Loaded ${_quizQuestions.length} questions into _quizQuestions');
          } else {
            print('No questions found in quiz response');
          }
        });
      } else {
        print('Could not extract quiz data from response');
      }
    } catch (e) {
      print('Error loading quiz data: $e');
      // Don't show error to user for quiz loading, just log it
    }
  }

  Future<void> _loadVideos() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final videoRepo = VideoRepository();
      // Load videos specifically for this course
      final videos = await videoRepo.getVideosByCourse(widget.courseId);
      // Deduplicate videos by videoId/url to prevent dropdown errors
      final uniqueVideos = <String, Video>{};
      for (final video in videos) {
        final key = video.videoId ?? video.url ?? video.id;
        if (key.isNotEmpty) {
          uniqueVideos[key] = video;
        }
      }
      setState(() {
        _videos = uniqueVideos.values.toList();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _saveLesson() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      String? createdQuizId;
      
      // Create quiz first if included
      if (_includeQuiz) {
        createdQuizId = await _createQuizForLesson();
      }

      if (mounted) {
        final lessonRepo = LessonRepository();
        final isEditing = widget.lessonId != null && widget.lessonId!.isNotEmpty;
        
        if (isEditing) {
          // Update existing lesson
          await lessonRepo.updateLesson(
            lessonId: widget.lessonId!,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            videoId: _selectedVideoId,
            notesPdfUrl: _notesPdfUrl,
            duration: _duration,
            quizId: createdQuizId,
            lessonType: _determineLessonType(),
            materials: _documentPath != null ? [_documentPath!] : null,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson updated successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          // Create new lesson
          // Get the next order number by counting existing lessons in this section
          final lessonsInSection = await lessonRepo.getLessonsBySection(widget.sectionId);
          final nextOrder = lessonsInSection.length + 1;
          
          await lessonRepo.createLesson(
            courseId: widget.courseId,
            sectionId: widget.sectionId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            videoId: _selectedVideoId,
            notes: null,
            notesPdfUrl: _notesPdfUrl,
            processNotes: _processNotesWithAI,
            order: nextOrder,
            duration: _duration,
            quizId: createdQuizId, // Associate quiz with lesson
            lessonType: _determineLessonType(),
            materials: _documentPath != null ? [_documentPath!] : null,
          );
          
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Lesson created successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
        
        // Refresh the content management provider
        ref.read(contentManagementProvider.notifier).loadSections(widget.courseId);
        
        // Navigate back to course content
        context.pop();
      }
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }
  
  Future<String?> _createQuizForLesson() async {
    if (_quizQuestions.isEmpty) {
      // Show error if no questions are created
      throw Exception('Please add at least one question to the quiz before creating the lesson.');
    }
    
    try {
      final quizTitle = _quizTitleController.text.isNotEmpty 
        ? _quizTitleController.text.trim()
        : '${_titleController.text.trim()} Quiz';
      
      final quizData = {
        'title': quizTitle,
        'type': _selectedQuizType,
        'passingScore': 70,
        'timeLimit': _quizTimeLimit,
        'shuffleQuestions': _shuffleQuestions,
        'shuffleOptions': _shuffleOptions,
        'preparedQuestions': _convertToQuestionModels().map((question) {
          // Ensure options are properly formatted without newlines
          final Map<String, dynamic> questionJson = question.toJson();
          
          // Add shuffle options to each question
          questionJson['randomizeOptions'] = _shuffleOptions;
          
          // Clean up options text to remove newlines and extra spaces
          if (questionJson['options'] != null) {
            final options = questionJson['options'] as List;
            for (int i = 0; i < options.length; i++) {
              final option = options[i];
              if (option is Map && option['text'] != null) {
                option['text'] = (option['text'] as String).replaceAll(RegExp(r'\s+'), ' ').trim();
              }
            }
          }
          
          return questionJson;
        }).toList(),
        'isPublished': true,
      };
      
      // Create the quiz using QuizService
      final quizResponse = await QuizService.createQuiz(
        sectionId: widget.sectionId ?? '',
        courseId: widget.courseId ?? '',
        title: quizTitle,
        type: _selectedQuizType,
        category: 'lesson_quiz',
        passingScore: 70,
        timeLimit: _quizTimeLimit,
        isPublished: true,
        preparedQuestions: quizData['preparedQuestions'] as List<Map<String, dynamic>>,
      );
      
      // Store quiz ID to associate with lesson
      // Handle different response structures
      String quizId;
      if (quizResponse.containsKey('data')) {
        if (quizResponse['data'].containsKey('quiz')) {
          quizId = quizResponse['data']['quiz']['_id'];
        } else if (quizResponse['data'].containsKey('exam')) {
          quizId = quizResponse['data']['exam']['_id'];
        } else if (quizResponse['data'].containsKey('_id')) {
          quizId = quizResponse['data']['_id'];
        } else {
          // Extract ID from message if not in data
          final message = quizResponse['message'] ?? '';
          final idMatch = RegExp(r':([a-f0-9]{24})$').firstMatch(message);
          quizId = idMatch?.group(1) ?? '';
        }
      } else if (quizResponse.containsKey('_id')) {
        quizId = quizResponse['_id'];
      } else {
        // Extract ID from message if not at top level
        final message = quizResponse['message'] ?? '';
        final idMatch = RegExp(r':([a-f0-9]{24})$').firstMatch(message);
        quizId = idMatch?.group(1) ?? '';
      }
      
      if (quizId.isEmpty) {
        throw Exception('Could not extract quiz ID from response');
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Quiz "$quizTitle" created successfully with ${_quizQuestions.length} questions!'),
          backgroundColor: Colors.green,
        ),
      );
      
      return quizId;
    } catch (e) {
      throw Exception('Failed to create quiz: $e');
    }
  }
  
  List<Question> _convertToQuestionModels() {
    return _quizQuestions.map((question) {
      // Convert options to proper Option objects
      List<Option>? options;
      if (question['options'] != null) {
        options = (question['options'] as List).map((option) {
          if (option is Map<String, dynamic>) {
            return Option(
              text: option['text']?.toString() ?? '',
              isCorrect: option['isCorrect'] ?? false,
            );
          } else {
            return Option(
              text: option.toString(),
              isCorrect: false,
            );
          }
        }).toList();
      }
      
      // Determine correctAnswer based on question type
      dynamic correctAnswer;
      if (question['correctAnswer'] != null) {
        correctAnswer = question['correctAnswer'];
      } else if (question['type'] == 'mcq' && options != null) {
        // For MCQ, find the correct option text
        final correctOption = options.firstWhere(
          (option) => option.isCorrect,
          orElse: () => options!.first,
        ) ?? Option(text: '', isCorrect: false);
        correctAnswer = correctOption.text;
      } else {
        // Default fallback
        correctAnswer = '';
      }
      
      return Question(
        id: '', // Will be set by backend
        examId: '', // Will be set by backend
        question: question['question'] ?? '',
        type: question['type'] ?? 'mcq',
        options: options,
        correctAnswer: correctAnswer,
        points: question['points'] ?? 1,
        difficulty: question['difficulty'] ?? 'medium',
        explanation: question['explanation'] ?? '',
        // Add drag-drop and interactive question fields
        dragDropItems: question['dragDropItems'] != null 
          ? (question['dragDropItems'] as List).map((item) => DragDropItem.fromJson(item as Map<String, dynamic>)).toList()
          : null,
        dropZones: question['dropZones'] != null 
          ? (question['dropZones'] as List).map((zone) => DropZone.fromJson(zone as Map<String, dynamic>)).toList()
          : null,
        matchingPairs: question['matchingPairs'] != null 
          ? (question['matchingPairs'] as List).map((pair) => MatchingPair.fromJson(pair as Map<String, dynamic>)).toList()
          : null,
        correctOrder: question['correctOrder'] != null 
          ? (question['correctOrder'] as List).map((item) => OrderItem.fromJson(item as Map<String, dynamic>)).toList()
          : null,
        hotspots: question['hotspots'] != null 
          ? (question['hotspots'] as List).map((hotspot) => Hotspot.fromJson(hotspot as Map<String, dynamic>)).toList()
          : null,
        hotspotImage: question['hotspotImage'],
        partialCredit: question['partialCredit'] ?? false,
      );
    }).toList();
  }
  
  String _determineLessonType() {
    final hasVideo = _selectedVideoId != null;
    final hasNotes = _documentPath != null || _notesPdfUrl != null;
    final hasQuiz = _includeQuiz;
    
    if (hasVideo && hasNotes && hasQuiz) return 'Mixed';
    if (hasVideo && hasNotes) return 'Video + Notes';
    if (hasVideo && hasQuiz) return 'Video + Quiz';
    if (hasNotes && hasQuiz) return 'Notes + Quiz';
    if (hasVideo) return 'Video';
    if (hasNotes) return 'Notes';
    if (hasQuiz) return 'Quiz';
    return 'Content';
  }
  
  void _createDefaultQuizQuestions() {
    _quizQuestions.clear();
    final lessonTitle = _titleController.text.trim();
    
    // Create a variety of question types based on the lesson title
    for (int i = 0; i < _quizNumberOfQuestions; i++) {
      final questionType = _getQuestionTypeByIndex(i);
      final question = _createQuestionByType(i + 1, lessonTitle, questionType);
      _quizQuestions.add(question);
    }
  }
  
  void _resetQuestionForm() {
    _questionController.clear();
    _selectedQuestionType = 'mcq';
    _editingQuestionIndex = -1;
    
    // Clear all controller lists
    for (final controller in _optionControllers) {
      controller.clear();
    }
    for (final controller in _dragItemControllers) {
      controller.clear();
    }
    for (final controller in _dragTargetControllers) {
      controller.clear();
    }
    for (final controller in _matchingLeftControllers) {
      controller.clear();
    }
    for (final controller in _matchingRightControllers) {
      controller.clear();
    }
    for (final controller in _orderingItemControllers) {
      controller.clear();
    }
    for (final controller in _hotspotControllers) {
      controller.clear();
    }
    
    _correctAnswers.fillRange(0, _correctAnswers.length, false);
    _fillBlankController.clear();
    _trueFalseController.clear();
    _trueFalseAnswer = false;
    _essayController.clear();
    _hotspotImageController.clear();
    _dragItemTargets.fillRange(0, _dragItemTargets.length, '');
    
    // Reset programming fields
    _selectedProgrammingLanguage = 'python';
    _programmingLanguageController.clear();
    _starterCodeController.clear();
    _expectedOutputController.clear();
    _programmingInstructionsController.clear();
    _allowMultipleAttempts = true;
    _maxAttempts = 3;
    for (final controller in _testCaseInputControllers) {
      controller.clear();
    }
    for (final controller in _testCaseOutputControllers) {
      controller.clear();
    }
    
    _questionPoints = 1;
    _questionDifficulty = 'medium';
    _explanationController.clear();
  }
  
  void _addQuestion() {
    setState(() {
      _showQuestionForm = true;
      _resetQuestionForm();
    });
  }
  
  void _editQuestion(int index) {
    final question = _quizQuestions[index];
    setState(() {
      _showQuestionForm = true;
      _editingQuestionIndex = index;
      _selectedQuestionType = question['type'] ?? 'mcq';
      _questionController.text = question['question'] ?? '';
      _questionPoints = question['points'] ?? 1;
      _questionDifficulty = question['difficulty'] ?? 'medium';
      _explanationController.text = question['explanation'] ?? '';
      
      // Load question-specific data
      if (_selectedQuestionType == 'mcq') {
        final options = question['options'] as List? ?? [];
        for (int i = 0; i < 4 && i < options.length; i++) {
          final option = options[i];
          if (option is Map<String, dynamic>) {
            _optionControllers[i].text = option['text'] ?? '';
            _correctAnswers[i] = option['isCorrect'] ?? false;
          }
        }
      } else if (_selectedQuestionType == 'true_false') {
        _trueFalseController.text = question['question'] ?? '';
        _trueFalseAnswer = question['correctAnswer'] ?? false;
      } else if (_selectedQuestionType == 'fill_blank') {
        _fillBlankController.text = question['correctAnswer'] ?? '';
      }
    });
  }
  
  void _deleteQuestion(int index) {
    setState(() {
      _quizQuestions.removeAt(index);
    });
  }
  
  void _saveQuestion() {
    if (!_questionController.text.trim().isNotEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a question'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }
    
    final question = _createQuestionFromForm();
    if (question == null) return;
    
    setState(() {
      if (_editingQuestionIndex >= 0) {
        _quizQuestions[_editingQuestionIndex] = question;
      } else {
        _quizQuestions.add(question);
      }
      _showQuestionForm = false;
      _resetQuestionForm();
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(_editingQuestionIndex >= 0 ? 'Question updated!' : 'Question added!'),
        backgroundColor: Colors.green,
      ),
    );
  }
  
  Map<String, dynamic>? _createQuestionFromForm() {
    switch (_selectedQuestionType) {
      case 'mcq':
        // Validate MCQ options
        int correctCount = _correctAnswers.where((isCorrect) => isCorrect).length;
        if (correctCount != 1) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please select exactly one correct answer'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
        
        final options = <Map<String, dynamic>>[];
        for (int i = 0; i < 4; i++) {
          if (_optionControllers[i].text.trim().isNotEmpty) {
            options.add({
              'text': _optionControllers[i].text.trim(),
              'isCorrect': _correctAnswers[i],
            });
          }
        }
        
        if (options.length < 2) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide at least 2 options'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
        
        return {
          'question': _questionController.text.trim(),
          'type': 'mcq',
          'options': options,
          'points': _questionPoints,
          'difficulty': _questionDifficulty,
          'explanation': _explanationController.text.trim(),
        };
        
      case 'true_false':
        return {
          'question': _trueFalseController.text.trim().isNotEmpty 
            ? _trueFalseController.text.trim()
            : _questionController.text.trim(),
          'type': 'true_false',
          'correctAnswer': _trueFalseAnswer,
          'points': _questionPoints,
          'difficulty': _questionDifficulty,
          'explanation': _explanationController.text.trim(),
        };
        
      case 'fill_blank':
        if (_fillBlankController.text.trim().isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Please provide the correct answer'),
              backgroundColor: Colors.red,
            ),
          );
          return null;
        }
        
        return {
          'question': _questionController.text.trim(),
          'type': 'fill_blank',
          'correctAnswer': _fillBlankController.text.trim(),
          'points': _questionPoints,
          'difficulty': _questionDifficulty,
          'explanation': _explanationController.text.trim(),
        };
        
      case 'essay':
        return {
          'question': _questionController.text.trim(),
          'type': 'essay',
          'points': _questionPoints,
          'difficulty': _questionDifficulty,
          'explanation': _explanationController.text.trim(),
        };
        
      case 'drag_drop':
        return _createDragDropQuestion();
        
      case 'matching':
        return _createMatchingQuestion();
        
      case 'ordering':
        return _createOrderingQuestion();
        
      case 'hotspot':
        return _createHotspotQuestion();
        
      case 'programming':
        return _createProgrammingQuestion();
        
      default:
        return null;
    }
  }
  
  Map<String, dynamic>? _createDragDropQuestion() {
    // Validate drag drop items
    final dragItems = <Map<String, dynamic>>[];
    final dropZones = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 3; i++) {
      if (_dragItemControllers[i].text.trim().isNotEmpty) {
        dragItems.add({
          'id': 'item${i + 1}',
          'content': _dragItemControllers[i].text.trim(),
          'targetZone': _dragItemTargets[i],
        });
      }
      
      if (_dragTargetControllers[i].text.trim().isNotEmpty) {
        dropZones.add({
          'id': 'zone${i + 1}',
          'label': _dragTargetControllers[i].text.trim(),
          'correctItems': dragItems
              .where((item) => item['targetZone'] == 'zone${i + 1}')
              .map((item) => item['id'] as String)
              .toList(),
        });
      }
    }
    
    if (dragItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one drag item'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    return {
      'question': _questionController.text.trim(),
      'type': 'drag_drop',
      'dragDropItems': dragItems,
      'dropZones': dropZones,
      'points': _questionPoints,
      'difficulty': _questionDifficulty,
      'explanation': _explanationController.text.trim(),
    };
  }
  
  Map<String, dynamic>? _createMatchingQuestion() {
    final matchingPairs = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 3; i++) {
      if (_matchingLeftControllers[i].text.trim().isNotEmpty && 
          _matchingRightControllers[i].text.trim().isNotEmpty) {
        matchingPairs.add({
          'leftItem': {
            'text': _matchingLeftControllers[i].text.trim(),
            'id': 'left${i + 1}',
          },
          'rightItem': {
            'text': _matchingRightControllers[i].text.trim(),
            'id': 'right${i + 1}',
          },
        });
      }
    }
    
    if (matchingPairs.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one matching pair'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    return {
      'question': _questionController.text.trim(),
      'type': 'matching',
      'matchingPairs': matchingPairs,
      'points': _questionPoints,
      'difficulty': _questionDifficulty,
      'explanation': _explanationController.text.trim(),
    };
  }
  
  Map<String, dynamic>? _createOrderingQuestion() {
    final orderItems = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 3; i++) {
      if (_orderingItemControllers[i].text.trim().isNotEmpty) {
        orderItems.add({
          'id': 'item${i + 1}',
          'content': _orderingItemControllers[i].text.trim(),
        });
      }
    }
    
    if (orderItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one ordering item'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    return {
      'question': _questionController.text.trim(),
      'type': 'ordering',
      'correctOrder': orderItems,
      'points': _questionPoints,
      'difficulty': _questionDifficulty,
      'explanation': _explanationController.text.trim(),
    };
  }
  
  Map<String, dynamic>? _createHotspotQuestion() {
    if (_hotspotImageController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide an image URL'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    final hotspots = <Map<String, dynamic>>[];
    for (int i = 0; i < 2; i++) {
      if (_hotspotControllers[i].text.trim().isNotEmpty) {
        hotspots.add({
          'x': _hotspotPositions[i]['x']!,
          'y': _hotspotPositions[i]['y']!,
          'width': _hotspotPositions[i]['width']!,
          'height': _hotspotPositions[i]['height']!,
          'label': _hotspotControllers[i].text.trim(),
        });
      }
    }
    
    if (hotspots.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one hotspot area'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    return {
      'question': _questionController.text.trim(),
      'type': 'hotspot',
      'hotspotImage': _hotspotImageController.text.trim(),
      'hotspots': hotspots,
      'points': _questionPoints,
      'difficulty': _questionDifficulty,
      'explanation': _explanationController.text.trim(),
    };
  }
  
  Map<String, dynamic>? _createProgrammingQuestion() {
    if (_programmingInstructionsController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please provide programming instructions'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    // Create test cases
    final testCases = <Map<String, dynamic>>[];
    for (int i = 0; i < 2; i++) {
      if (_testCaseOutputControllers[i].text.trim().isNotEmpty) {
        testCases.add({
          'input': _testCaseInputControllers[i].text.trim(),
          'expectedOutput': _testCaseOutputControllers[i].text.trim(),
          'description': 'Test Case ${i + 1}',
        });
      }
    }
    
    if (testCases.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one test case with expected output'),
          backgroundColor: Colors.red,
        ),
      );
      return null;
    }
    
    return {
      'question': _questionController.text.trim(),
      'type': 'programming',
      'programmingLanguage': _selectedProgrammingLanguage,
      'instructions': _programmingInstructionsController.text.trim(),
      'starterCode': _starterCodeController.text.trim(),
      'expectedOutput': _expectedOutputController.text.trim(),
      'testCases': testCases,
      'allowMultipleAttempts': _allowMultipleAttempts,
      'maxAttempts': _maxAttempts,
      'points': _questionPoints,
      'difficulty': _questionDifficulty,
      'explanation': _explanationController.text.trim(),
    };
  }
  
  String _getQuestionTypeByIndex(int index) {
    final types = ['mcq', 'true_false', 'fill_blank', 'essay'];
    return types[index % types.length];
  }
  
  Map<String, dynamic> _createQuestionByType(int questionNumber, String lessonTitle, String type) {
    switch (type) {
      case 'mcq':
        return {
          'question': 'Question $questionNumber: What is the main concept of $lessonTitle?',
          'type': 'mcq',
          'options': [
            {'text': 'Option A: Core principle', 'isCorrect': false},
            {'text': 'Option B: Fundamental concept', 'isCorrect': true},
            {'text': 'Option C: Basic idea', 'isCorrect': false},
            {'text': 'Option D: Simple notion', 'isCorrect': false}
          ],
          'points': 2,
          'difficulty': 'medium',
          'explanation': 'The fundamental concept is the correct answer as it encompasses the core principles.'
        };
      case 'true_false':
        return {
          'question': 'Question $questionNumber: $lessonTitle is essential for advanced learning.',
          'type': 'true_false',
          'correctAnswer': true,
          'points': 1,
          'difficulty': 'easy',
          'explanation': 'This statement is true as the topic builds foundational knowledge.'
        };
      case 'fill_blank':
        return {
          'question': 'Question $questionNumber: The key principle of $lessonTitle is _____.',
          'type': 'fill_blank',
          'correctAnswer': 'understanding',
          'points': 2,
          'difficulty': 'medium',
          'explanation': 'Understanding is the key principle that drives this topic.'
        };
      case 'essay':
        return {
          'question': 'Question $questionNumber: Explain the importance of $lessonTitle in practical applications.',
          'type': 'essay',
          'points': 5,
          'difficulty': 'hard',
          'explanation': 'This essay should demonstrate comprehensive understanding of practical applications.'
        };
      default:
        return {
          'question': 'Question $questionNumber about $lessonTitle',
          'type': 'mcq',
          'options': [
            {'text': 'Option A', 'isCorrect': false},
            {'text': 'Option B', 'isCorrect': true},
            {'text': 'Option C', 'isCorrect': false},
            {'text': 'Option D', 'isCorrect': false}
          ],
          'points': 1,
          'difficulty': 'medium'
        };
    }
  }

  Future<void> _handleVideoUpload() async {
    try {
      final XFile? videoFile = await _picker.pickVideo(source: ImageSource.gallery);
      
      if (videoFile == null) return;

      setState(() {
        _isUploadingVideo = true;
        _errorMessage = null;
      });

      final videoRepo = VideoRepository();
      final video = await videoRepo.uploadVideo(
        videoFile: videoFile,
        courseId: widget.courseId,
        sectionId: widget.sectionId,
        title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : null,
        description: _descriptionController.text.trim().isNotEmpty ? _descriptionController.text.trim() : null,
        createLesson: false, // Disable automatic lesson creation during upload
        onProgress: (progress) {
          // Handle progress updates if needed
          print('Upload progress: $progress%');
        },
      );

      setState(() {
        _isUploadingVideo = false;
        _selectedVideoId = video.id;
        // Update the videos list with the newly uploaded video
        _videos = [..._videos, video];
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Video uploaded successfully!'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _isUploadingVideo = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Video upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleDocumentUpload() async {
    try {
      // Pick a document file
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'txt', 'ppt', 'pptx', 'xls', 'xlsx'],
      );
      
      if (result == null) return;

      final file = result.files.single;
      setState(() {
        _isUploadingDocument = true;
        _errorMessage = null;
      });

      // Upload the document to the backend (this will create a lesson automatically)
      // Handle web vs mobile platform differences
      print('=== PLATFORM CHECK ===');
      print('Is web: $kIsWeb');
      print('File path: ${file.path}');
      print('File bytes available: ${file.bytes != null}');
      print('=====================');
      
      Map<String, dynamic> responseData;
      
      if (kIsWeb) {
        print('=== WEB UPLOAD PATH ===');
        // On web, use LessonDocumentService with PlatformFile
        try {
          final lessonDocumentService = LessonDocumentService();
          print('Calling LessonDocumentService with file: ${file.name}');
          responseData = await lessonDocumentService.uploadDocumentForLessonNotes(
            file: file,
            courseId: widget.courseId,
            sectionId: widget.sectionId,
            title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
            description: _descriptionController.text.trim(),
            createLesson: false, // Ensure we don't auto-create lesson during upload
            processNotes: false, // Don't process AI notes during initial upload
          );
          print('Web upload successful, response: $responseData');
        } catch (e) {
          print('=== WEB UPLOAD ERROR ===');
          print('Error type: ${e.runtimeType}');
          print('Error message: $e');
          print('Stack trace: ${e is Error ? (e).stackTrace : 'No stack trace'}');
          print('=======================');
          rethrow;
        }
      } else {
        // On mobile, use the existing API client method
        final response = await _apiClient.postFile(
          '${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/documents/upload',
          filePath: file.path!,
          fieldName: 'document',
          additionalFields: {
            'courseId': widget.courseId,
            'sectionId': widget.sectionId,
            'createLesson': 'false', // Ensure we don't auto-create lesson
            'processNotes': 'false', // Don't process AI notes yet
            'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
            'description': _descriptionController.text.trim(),
            'duration': _duration.toString(),
          },
        );
        responseData = jsonDecode(response.body);
      }

      print('=== RESPONSE HANDLING ===');
      print('Response data: $responseData');
      print('Success: ${responseData['success']}');
      print('Data keys: ${responseData['data']?.keys?.toList()}');
      print('========================');
      
      if (responseData['success'] == true) {
        // Just store the document path if lesson wasn't created automatically
        final documentPath = responseData['data']['s3Key'];
        setState(() {
          _documentPath = documentPath;
          _processNotesWithAI = true; // Flag for processing notes with AI when lesson is saved
          _isUploadingDocument = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Document uploaded successfully for AI processing!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to upload document');
      }
    } catch (e) {
      setState(() {
        _isUploadingDocument = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Document upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handleNotesPdfUpload() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf'],
      );
      
      if (result == null) return;

      final file = result.files.single;
      setState(() {
        _isUploadingPdf = true;
        _errorMessage = null;
      });

      Map<String, dynamic> responseData;
      
      if (kIsWeb) {
        final lessonDocumentService = LessonDocumentService();
        responseData = await lessonDocumentService.uploadDocumentForLessonNotes(
          file: file,
          courseId: widget.courseId,
          sectionId: widget.sectionId,
          title: _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
          description: _descriptionController.text.trim(),
          createLesson: false, // Ensure we don't auto-create lesson during upload
          processNotes: false, // Don't process AI notes for direct PDF
        );
      } else {
        final response = await _apiClient.postFile(
          '${ApiConfig.baseUrl.replaceFirst('/api', '')}/api/documents/upload',
          filePath: file.path!,
          fieldName: 'document',
          additionalFields: {
            'courseId': widget.courseId,
            'sectionId': widget.sectionId,
            'createLesson': 'false', // Ensure we don't auto-create lesson
            'processNotes': 'false', // Don't process AI notes for direct PDF
            'title': _titleController.text.trim().isNotEmpty ? _titleController.text.trim() : file.name,
          },
        );
        responseData = jsonDecode(response.body);
      }

      if (responseData['success'] == true) {
        final s3Key = responseData['data']['s3Key'];
        
        setState(() {
          _notesPdfUrl = s3Key;
          _processNotesWithAI = false; // Disable AI processing flag if they chose direct PDF
          _isUploadingPdf = false;
        });

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Notes PDF uploaded successfully!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('Failed to upload PDF');
      }
    } catch (e) {
      setState(() {
        _isUploadingPdf = false;
        _errorMessage = e.toString();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PDF upload failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: context.canPop() ? IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded),
          onPressed: () => context.pop(),
          tooltip: 'Back',
        ) : null,
        title: Text(widget.lessonId != null && widget.lessonId!.isNotEmpty ? 'Edit Lesson' : 'Create Lesson'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.save),
            onPressed: _isLoading ? null : _saveLesson,
            tooltip: 'Save Lesson',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isSmallScreen = constraints.maxWidth < 768;
          
          return Padding(
            padding: EdgeInsets.all(isSmallScreen ? 15 : 20),
            child: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeaderSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildFormFields(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildVideoSelectionSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildNotesSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildQuizSection(isSmallScreen),
                    const SizedBox(height: 20),
                    _buildErrorMessage(),
                    const SizedBox(height: 20),
                    _buildSubmitButton(isSmallScreen),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildHeaderSection(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Create New Lesson',
          style: TextStyle(
            fontSize: isSmallScreen ? 20 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Add a new lesson to this section. You can attach a video and add notes.',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildFormFields(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Title Field
          TextFormField(
            controller: _titleController,
            decoration: const InputDecoration(
              labelText: 'Lesson Title *',
              hintText: 'Enter lesson title',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.title),
            ),
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a title';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),

          // Description Field
          TextFormField(
            controller: _descriptionController,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Description',
              hintText: 'Enter lesson description',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.description),
            ),
          ),
          const SizedBox(height: 15),

          // Duration Field
          TextFormField(
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Duration (minutes)',
              hintText: 'Enter duration in minutes',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.schedule),
            ),
            onChanged: (value) {
              setState(() {
                _duration = int.tryParse(value ?? '0') ?? 0;
              });
            },
          ),
        ],
      ),
    );
  }

  Widget _buildVideoSelectionSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.accent,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.video_library,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Attach Video',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Select an existing video or upload a new one:',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ),
              if (_isUploadingVideo)
                const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    SizedBox(width: 8),
                    Text('Uploading...', style: TextStyle(fontSize: 12)),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 15),
          if (_isLoading && _videos.isEmpty)
            const Center(child: CircularProgressIndicator())
          else
            Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _selectedVideoId,
                        decoration: const InputDecoration(
                          labelText: 'Select Existing Video',
                          border: OutlineInputBorder(),
                          prefixIcon: Icon(Icons.videocam),
                        ),
                        items: _videos.map((video) {
                          return DropdownMenuItem(
                            value: video.videoId ?? video.url,
                            child: Text(video.title),
                          );
                        }).toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedVideoId = value;
                          });
                        },
                        hint: const Text('Choose from existing videos'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton.icon(
                      onPressed: _isUploadingVideo ? null : _handleVideoUpload,
                      icon: const Icon(Icons.upload, size: 18),
                      label: const Text('Upload Video'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                const Text(
                  'Tip: You can upload a new video or select from existing ones for this course',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          const SizedBox(height: 10),
          if (_selectedVideoId != null)
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.check_circle,
                    color: AppTheme.primaryGreen,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Selected: ${_videos.firstWhere((v) => (v.videoId ?? v.url) == _selectedVideoId, orElse: () => _videos.first).title}',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNotesSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: AppTheme.primaryGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.note_add,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lesson Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Add notes to your lesson. You can upload a document to be processed by AI into organized notes, and/or upload a PDF for direct viewing.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // AI Organized Notes Section
          const Text(
            'Option 1: AI Organized Notes',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _documentPath != null 
                        ? 'Document attached for AI processing' 
                        : 'No document for AI processing yet',
                      style: TextStyle(
                        color: _documentPath != null ? AppTheme.primaryGreen : AppTheme.greyColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isUploadingDocument ? null : _handleDocumentUpload,
                icon: _isUploadingDocument 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.psychology, size: 18),
                label: Text(_isUploadingDocument ? 'Processing...' : 'Upload & Organize'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.accent,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          const Divider(height: 30),
          
          // Direct PDF Section
          const Text(
            'Option 2: Direct PDF (Unorganized)',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _notesPdfUrl != null 
                        ? 'PDF attached for direct viewing' 
                        : 'No PDF attached yet',
                      style: TextStyle(
                        color: _notesPdfUrl != null ? AppTheme.primaryGreen : AppTheme.greyColor,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
              ElevatedButton.icon(
                onPressed: _isUploadingPdf ? null : _handleNotesPdfUpload,
                icon: _isUploadingPdf 
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.picture_as_pdf, size: 18),
                label: Text(_isUploadingPdf ? 'Uploading...' : 'Upload PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primaryGreen,
                  foregroundColor: Colors.white,
                ),
              ),
            ],
          ),
          
          if (_documentPath != null || _notesPdfUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 15),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.check_circle, color: AppTheme.primaryGreen, size: 20),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Notes will be added when you save the lesson.',
                        style: TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.w500),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSubmitButton(bool isSmallScreen) {
    bool isAnyUploading = _isLoading || _isUploadingVideo || _isUploadingDocument || _isUploadingPdf;
    
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isAnyUploading ? null : _saveLesson,
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        child: isAnyUploading
            ? Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                  ),
                  const SizedBox(width: 10),
                  Text(_isUploadingVideo 
                    ? 'Uploading Video...' 
                    : (_isUploadingDocument ? 'Processing Document...' : (_isUploadingPdf ? 'Uploading PDF...' : 'Creating Lesson...'))),
                ],
              )
            : Text(
                widget.lessonId != null && widget.lessonId!.isNotEmpty ? 'Update Lesson' : 'Create Lesson',
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
      ),
    );
  }

  Widget _buildQuizSection(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: const BoxDecoration(
                  color: Colors.orange,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.quiz,
                  color: Colors.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              const Text(
                'Lesson Quiz',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          const Text(
            'Add a quiz to test student understanding of this lesson.',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 20),
          
          // Include Quiz Toggle
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange.withOpacity(0.3)),
            ),
            child: Row(
              children: [
                Icon(
                  _includeQuiz ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: Colors.orange,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Include Quiz with this Lesson',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.orange,
                        ),
                      ),
                      const Text(
                        'Students will be able to take this quiz after completing the lesson',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.orange,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch(
                  value: _includeQuiz,
                  onChanged: (value) {
                    setState(() {
                      _includeQuiz = value;
                    });
                  },
                  activeThumbColor: Colors.orange,
                ),
              ],
            ),
          ),
          
          if (_includeQuiz) ...[
            const SizedBox(height: 20),
            
            // Quiz Title
            TextFormField(
              controller: _quizTitleController,
              decoration: const InputDecoration(
                labelText: 'Quiz Title',
                hintText: 'Enter quiz title (optional)',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.title),
              ),
            ),
            const SizedBox(height: 15),
            
            // Quiz Description
            TextFormField(
              controller: _quizDescriptionController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Quiz Description',
                hintText: 'Describe what this quiz covers',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.description),
              ),
            ),
            const SizedBox(height: 15),
            
            // Quiz Type
            DropdownButtonFormField<String>(
              initialValue: _selectedQuizType,
              decoration: const InputDecoration(
                labelText: 'Quiz Type',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.category),
              ),
              items: const [
                DropdownMenuItem(value: 'quiz', child: Text('Quiz')),
                DropdownMenuItem(value: 'exam', child: Text('Exam')),
                DropdownMenuItem(value: 'final', child: Text('Final Exam')),
                DropdownMenuItem(value: 'assessment', child: Text('Assessment')),
              ],
              onChanged: (value) {
                setState(() {
                  _selectedQuizType = value ?? 'quiz';
                });
              },
            ),
            const SizedBox(height: 15),
            
            // Quiz Settings Row
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: _quizTimeLimit.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Time Limit (minutes)',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.schedule),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _quizTimeLimit = int.tryParse(value ?? '0') ?? 30;
                      });
                    },
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: TextFormField(
                    keyboardType: TextInputType.number,
                    initialValue: _quizNumberOfQuestions.toString(),
                    decoration: const InputDecoration(
                      labelText: 'Number of Questions',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.help),
                    ),
                    onChanged: (value) {
                      setState(() {
                        _quizNumberOfQuestions = int.tryParse(value ?? '0') ?? 5;
                      });
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 15),
            
            // Shuffle Options
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blue.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Shuffle Options',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.blue,
                    ),
                  ),
                  const SizedBox(height: 12),
                  
                  // Shuffle Questions
                  SwitchListTile(
                    title: const Text('Shuffle Questions'),
                    subtitle: const Text('Randomize question order for students'),
                    value: _shuffleQuestions,
                    onChanged: (value) {
                      setState(() {
                        _shuffleQuestions = value;
                      });
                    },
                    activeThumbColor: Colors.blue,
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Shuffle Options
                  SwitchListTile(
                    title: const Text('Shuffle Options'),
                    subtitle: const Text('Randomize option order within questions'),
                    value: _shuffleOptions,
                    onChanged: (value) {
                      setState(() {
                        _shuffleOptions = value;
                      });
                    },
                    activeThumbColor: Colors.blue,
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 20),
            
            // Questions Management Section
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.greyColor.withOpacity(0.05),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Quiz Questions',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            '${_quizQuestions.length} questions',
                            style: const TextStyle(
                              fontSize: 14,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          const SizedBox(width: 10),
                          ElevatedButton.icon(
                            onPressed: _addQuestion,
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Add Question'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.orange,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Question List
                  if (_quizQuestions.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange, size: 20),
                          const SizedBox(width: 8),
                          const Expanded(
                            child: Text(
                              'No questions added yet. Click "Add Question" to create questions for your quiz.',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.orange,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: _quizQuestions.asMap().entries.map((entry) {
                        final index = entry.key;
                        final question = entry.value;
                        return _buildQuestionItem(index, question);
                      }).toList(),
                    ),
                ],
              ),
            ),
            
            // Question Form (shown when adding/editing)
            if (_showQuestionForm) ...[
              const SizedBox(height: 20),
              _buildQuestionForm(isSmallScreen),
            ],
          ],
        ],
      ),
    );
  }
  
  Widget _buildQuestionItem(int index, Map<String, dynamic> question) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppTheme.borderGrey),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getQuestionTypeColor(question['type'] ?? 'mcq'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            _getQuestionTypeLabel(question['type'] ?? 'mcq'),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: _getDifficultyColor(question['difficulty'] ?? 'medium'),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${question['points'] ?? 1} pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      question['question'] ?? 'No question text',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (question['explanation'] != null && question['explanation'].toString().isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Explanation: ${question['explanation']}',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
                            fontStyle: FontStyle.italic,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                  ],
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    onPressed: () => _editQuestion(index),
                    icon: const Icon(Icons.edit, size: 18),
                    color: Colors.blue,
                    tooltip: 'Edit Question',
                  ),
                  IconButton(
                    onPressed: () => _deleteQuestion(index),
                    icon: const Icon(Icons.delete, size: 18),
                    color: Colors.red,
                    tooltip: 'Delete Question',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionForm(bool isSmallScreen) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.orange, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.quiz, color: Colors.orange, size: 24),
              const SizedBox(width: 10),
              Text(
                _editingQuestionIndex >= 0 ? 'Edit Question' : 'Add New Question',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          
          // Question Type Selection
          DropdownButtonFormField<String>(
            initialValue: _selectedQuestionType,
            decoration: const InputDecoration(
              labelText: 'Question Type',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.category),
            ),
            items: const [
              DropdownMenuItem(value: 'mcq', child: Text('Multiple Choice')),
              DropdownMenuItem(value: 'true_false', child: Text('True/False')),
              DropdownMenuItem(value: 'fill_blank', child: Text('Fill in the Blank')),
              DropdownMenuItem(value: 'essay', child: Text('Essay')),
              DropdownMenuItem(value: 'drag_drop', child: Text('Drag and Drop')),
              DropdownMenuItem(value: 'matching', child: Text('Matching Columns')),
              DropdownMenuItem(value: 'ordering', child: Text('Ordering/Sequencing')),
              DropdownMenuItem(value: 'hotspot', child: Text('Hotspot/Image Click')),
              DropdownMenuItem(value: 'programming', child: Text('Programming/Coding')),
            ],
            onChanged: (value) {
              setState(() {
                _selectedQuestionType = value ?? 'mcq';
              });
            },
          ),
          const SizedBox(height: 15),
          
          // Question Text
          TextFormField(
            controller: _questionController,
            decoration: const InputDecoration(
              labelText: 'Question *',
              hintText: 'Enter your question',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.help_outline),
            ),
            maxLines: 3,
            validator: (value) {
              if (value == null || value.trim().isEmpty) {
                return 'Please enter a question';
              }
              return null;
            },
          ),
          const SizedBox(height: 15),
          
          // Question Type Specific Fields
          _buildQuestionTypeFields(),
          
          const SizedBox(height: 15),
          
          // Points and Difficulty
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  keyboardType: TextInputType.number,
                  initialValue: _questionPoints.toString(),
                  decoration: const InputDecoration(
                    labelText: 'Points',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.star),
                  ),
                  onChanged: (value) {
                    setState(() {
                      _questionPoints = int.tryParse(value ?? '1') ?? 1;
                    });
                  },
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: DropdownButtonFormField<String>(
                  initialValue: _questionDifficulty,
                  decoration: const InputDecoration(
                    labelText: 'Difficulty',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.signal_cellular_alt),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'easy', child: Text('Easy')),
                    DropdownMenuItem(value: 'medium', child: Text('Medium')),
                    DropdownMenuItem(value: 'hard', child: Text('Hard')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _questionDifficulty = value ?? 'medium';
                    });
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 15),
          
          // Explanation
          TextFormField(
            controller: _explanationController,
            decoration: const InputDecoration(
              labelText: 'Explanation (Optional)',
              hintText: 'Explain the correct answer',
              border: OutlineInputBorder(),
              prefixIcon: Icon(Icons.lightbulb_outline),
            ),
            maxLines: 2,
          ),
          const SizedBox(height: 20),
          
          // Form Actions
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () {
                    setState(() {
                      _showQuestionForm = false;
                      _resetQuestionForm();
                    });
                  },
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: const Text('Cancel'),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: ElevatedButton(
                  onPressed: _saveQuestion,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 15),
                  ),
                  child: Text(_editingQuestionIndex >= 0 ? 'Update Question' : 'Add Question'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildQuestionTypeFields() {
    switch (_selectedQuestionType) {
      case 'mcq':
        return Column(
          children: [
            const Text(
              'Options (Select one correct answer)',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            ...List.generate(4, (index) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextFormField(
                      controller: _optionControllers[index],
                      decoration: InputDecoration(
                        labelText: 'Option ${String.fromCharCode(65 + index)}',
                        border: const OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  GestureDetector(
                    onTap: () {
                      setState(() {
                        // Uncheck all other options when one is selected
                        for (int i = 0; i < _correctAnswers.length; i++) {
                          _correctAnswers[i] = (i == index);
                        }
                      });
                    },
                    child: Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.orange),
                        color: _correctAnswers[index] ? Colors.orange : Colors.white,
                      ),
                      child: Center(
                        child: Icon(
                          Icons.check,
                          color: _correctAnswers[index] ? Colors.white : Colors.transparent,
                          size: 16,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )),
          ],
        );
        
      case 'true_false':
        return Column(
          children: [
            const Text(
              'Select the correct answer',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _trueFalseAnswer = true;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: _trueFalseAnswer ? Colors.green : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: _trueFalseAnswer ? Colors.green.withOpacity(0.1) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            _trueFalseAnswer ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: _trueFalseAnswer ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('True'),
                        ],
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                Expanded(
                  child: GestureDetector(
                    onTap: () {
                      setState(() {
                        _trueFalseAnswer = false;
                      });
                    },
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        border: Border.all(color: !_trueFalseAnswer ? Colors.red : Colors.grey),
                        borderRadius: BorderRadius.circular(8),
                        color: !_trueFalseAnswer ? Colors.red.withOpacity(0.1) : Colors.white,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            !_trueFalseAnswer ? Icons.check_circle : Icons.radio_button_unchecked,
                            color: !_trueFalseAnswer ? Colors.red : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('False'),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        );
        
      case 'fill_blank':
        return TextFormField(
          controller: _fillBlankController,
          decoration: const InputDecoration(
            labelText: 'Correct Answer *',
            hintText: 'Enter the correct answer',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.text_fields),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please enter the correct answer';
            }
            return null;
          },
        );
        
      case 'essay':
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Essay questions will require manual grading after students submit their answers.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        );
        
      case 'drag_drop':
        return _buildDragDropFields();
        
      case 'matching':
        return _buildMatchingFields();
        
      case 'ordering':
        return _buildOrderingFields();
        
      case 'hotspot':
        return _buildHotspotFields();
        
      case 'programming':
        return _buildProgrammingFields();
        
      default:
        return const SizedBox.shrink();
    }
  }
  
  Widget _buildDragDropFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Drag and Drop Items (Match items to target zones)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        const Text(
          'Items to Drag:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: TextFormField(
                  controller: _dragItemControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Item ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                flex: 2,
                child: DropdownButtonFormField<String>(
                  initialValue: _dragItemTargets[index].isEmpty ? null : _dragItemTargets[index],
                  decoration: InputDecoration(
                    labelText: 'Target Zone',
                    border: const OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'zone1', child: Text('Zone 1')),
                    DropdownMenuItem(value: 'zone2', child: Text('Zone 2')),
                    DropdownMenuItem(value: 'zone3', child: Text('Zone 3')),
                  ],
                  onChanged: (value) {
                    setState(() {
                      _dragItemTargets[index] = value ?? '';
                    });
                  },
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 10),
        const Text(
          'Target Zones:',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: TextFormField(
            controller: _dragTargetControllers[index],
            decoration: InputDecoration(
              labelText: 'Zone ${index + 1} Description',
              border: const OutlineInputBorder(),
            ),
          ),
        )),
      ],
    );
  }
  
  Widget _buildMatchingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Matching Columns (Match left items with right items)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 15),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _matchingLeftControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Left Item ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              const Icon(Icons.arrow_forward, color: Colors.grey),
              const SizedBox(width: 15),
              Expanded(
                child: TextFormField(
                  controller: _matchingRightControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Right Item ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        )),
      ],
    );
  }
  
  Widget _buildOrderingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Ordering Items (Arrange in correct sequence)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        ...List.generate(3, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Text(
                    '${index + 1}',
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  controller: _orderingItemControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Item ${index + 1}',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 10),
        const Text(
          'Note: Items will be shown in random order to students',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      ],
    );
  }
  
  Widget _buildHotspotFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Hotspot/Image Click (Click on specific areas of an image)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        TextFormField(
          controller: _hotspotImageController,
          decoration: const InputDecoration(
            labelText: 'Image URL/Path',
            hintText: 'Enter image URL or upload path',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.image),
          ),
        ),
        const SizedBox(height: 15),
        const Text(
          'Clickable Areas (Hotspots):',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
        ),
        const SizedBox(height: 5),
        ...List.generate(2, (index) => Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Expanded(
                child: TextFormField(
                  controller: _hotspotControllers[index],
                  decoration: InputDecoration(
                    labelText: 'Area ${index + 1} Description',
                    border: const OutlineInputBorder(),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                  border: Border.all(color: Colors.red),
                ),
                child: Text(
                  'Position: ${index == 0 ? 'Top-Left' : 'Bottom-Right'}',
                  style: const TextStyle(
                    fontSize: 10,
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.orange, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Students will click on the specified areas of the image to answer.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.orange,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  Widget _buildProgrammingFields() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Programming/Coding Question',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 10),
        
        // Programming Language Selection
        DropdownButtonFormField<String>(
          initialValue: _selectedProgrammingLanguage,
          decoration: const InputDecoration(
            labelText: 'Programming Language',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.code),
          ),
          items: const [
            DropdownMenuItem(value: 'python', child: Text('Python')),
            DropdownMenuItem(value: 'javascript', child: Text('JavaScript')),
            DropdownMenuItem(value: 'java', child: Text('Java')),
            DropdownMenuItem(value: 'cpp', child: Text('C++')),
            DropdownMenuItem(value: 'c', child: Text('C')),
            DropdownMenuItem(value: 'php', child: Text('PHP')),
            DropdownMenuItem(value: 'ruby', child: Text('Ruby')),
            DropdownMenuItem(value: 'go', child: Text('Go')),
            DropdownMenuItem(value: 'rust', child: Text('Rust')),
            DropdownMenuItem(value: 'sql', child: Text('SQL')),
          ],
          onChanged: (value) {
            setState(() {
              _selectedProgrammingLanguage = value ?? 'python';
            });
          },
        ),
        const SizedBox(height: 15),
        
        // Programming Instructions
        TextFormField(
          controller: _programmingInstructionsController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Programming Instructions *',
            hintText: 'Describe what the student should code',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.description),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return 'Please provide programming instructions';
            }
            return null;
          },
        ),
        const SizedBox(height: 15),
        
        // Starter Code
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.code, color: Colors.blue, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Starter Code (Optional)',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.blue,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              TextFormField(
                controller: _starterCodeController,
                maxLines: 8,
                decoration: InputDecoration(
                  hintText: 'Provide starter code to help students begin...',
                  border: const OutlineInputBorder(),
                  filled: true,
                  fillColor: Colors.grey[50],
                ),
                style: const TextStyle(
                  fontFamily: 'monospace',
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // Expected Output
        TextFormField(
          controller: _expectedOutputController,
          maxLines: 3,
          decoration: const InputDecoration(
            labelText: 'Expected Output (Optional)',
            hintText: 'What should the correct code output?',
            border: OutlineInputBorder(),
            prefixIcon: Icon(Icons.output),
          ),
          style: const TextStyle(
            fontFamily: 'monospace',
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 15),
        
        // Test Cases
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.bug_report, color: Colors.green, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Test Cases',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.green,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              const Text(
                'Define test cases to validate student code:',
                style: TextStyle(fontSize: 12),
              ),
              const SizedBox(height: 10),
              ...List.generate(2, (index) => Padding(
                padding: const EdgeInsets.only(bottom: 15),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Test Case ${index + 1}',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            controller: _testCaseInputControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Input',
                              hintText: 'Test input (if any)',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextFormField(
                            controller: _testCaseOutputControllers[index],
                            decoration: InputDecoration(
                              labelText: 'Expected Output',
                              hintText: 'Expected result',
                              border: const OutlineInputBorder(),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                            style: const TextStyle(
                              fontFamily: 'monospace',
                              fontSize: 11,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              )),
            ],
          ),
        ),
        const SizedBox(height: 15),
        
        // Execution Settings
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.05),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.purple.withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.settings, color: Colors.purple, size: 20),
                  const SizedBox(width: 8),
                  const Text(
                    'Execution Settings',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Colors.purple,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      initialValue: _maxAttempts,
                      decoration: const InputDecoration(
                        labelText: 'Max Attempts',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.refresh),
                      ),
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1')),
                        DropdownMenuItem(value: 3, child: Text('3')),
                        DropdownMenuItem(value: 5, child: Text('5')),
                        DropdownMenuItem(value: 10, child: Text('10')),
                        DropdownMenuItem(value: 999, child: Text('Unlimited')),
                      ],
                      onChanged: (value) {
                        setState(() {
                          _maxAttempts = value ?? 3;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 15),
                  Expanded(
                    child: Row(
                      children: [
                        const Text('Allow Multiple Attempts:'),
                        const SizedBox(width: 8),
                        Switch(
                          value: _allowMultipleAttempts,
                          onChanged: (value) {
                            setState(() {
                              _allowMultipleAttempts = value;
                            });
                          },
                          activeThumbColor: Colors.purple,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue.withOpacity(0.3)),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline, color: Colors.blue, size: 20),
              const SizedBox(width: 8),
              const Expanded(
                child: Text(
                  'Students will write and execute code in a live editor. The system will test their code against the provided test cases.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.blue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
  
  String _getQuestionTypeLabel(String type) {
    switch (type) {
      case 'mcq': return 'MCQ';
      case 'true_false': return 'T/F';
      case 'fill_blank': return 'Fill';
      case 'essay': return 'Essay';
      case 'drag_drop': return 'Drag';
      case 'matching': return 'Match';
      case 'ordering': return 'Order';
      case 'hotspot': return 'Hotspot';
      case 'programming': return 'Code';
      default: return type.toUpperCase();
    }
  }
  
  Color _getQuestionTypeColor(String type) {
    switch (type) {
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
  
  Color _getDifficultyColor(String difficulty) {
    switch (difficulty) {
      case 'easy': return Colors.green;
      case 'medium': return Colors.orange;
      case 'hard': return Colors.red;
      default: return Colors.grey;
    }
  }

  Widget _buildErrorMessage() {
    if (_errorMessage == null) return const SizedBox.shrink();
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Row(
        children: [
          const Icon(Icons.error, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _errorMessage!,
              style: const TextStyle(color: Colors.red),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close, color: Colors.red),
            onPressed: () => setState(() => _errorMessage = null),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _quizTitleController.dispose();
    _quizDescriptionController.dispose();
    _questionController.dispose();
    _fillBlankController.dispose();
    _trueFalseController.dispose();
    _essayController.dispose();
    _explanationController.dispose();
    _hotspotImageController.dispose();
    
    // Dispose all controller lists
    for (final controller in _optionControllers) {
      controller.dispose();
    }
    for (final controller in _dragItemControllers) {
      controller.dispose();
    }
    for (final controller in _dragTargetControllers) {
      controller.dispose();
    }
    for (final controller in _matchingLeftControllers) {
      controller.dispose();
    }
    for (final controller in _matchingRightControllers) {
      controller.dispose();
    }
    for (final controller in _orderingItemControllers) {
      controller.dispose();
    }
    for (final controller in _hotspotControllers) {
      controller.dispose();
    }
    
    // Dispose programming controllers
    _programmingLanguageController.dispose();
    _starterCodeController.dispose();
    _expectedOutputController.dispose();
    _programmingInstructionsController.dispose();
    for (final controller in _testCaseInputControllers) {
      controller.dispose();
    }
    for (final controller in _testCaseOutputControllers) {
      controller.dispose();
    }
    
    _apiClient.dispose();
    super.dispose();
  }
}
