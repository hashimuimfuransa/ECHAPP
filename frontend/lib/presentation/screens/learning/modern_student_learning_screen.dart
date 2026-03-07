import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/data/repositories/section_repository.dart' as section_repo;
import 'package:excellencecoachinghub/data/repositories/lesson_repository.dart' as lesson_repo;
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/section.dart';
import 'package:excellencecoachinghub/models/lesson.dart';
import 'package:excellencecoachinghub/models/exam.dart' as exam_model;
import 'package:excellencecoachinghub/services/api/exam_service.dart';
import 'package:excellencecoachinghub/widgets/lesson_viewer.dart';
import 'package:excellencecoachinghub/widgets/ai_chat_dialog.dart';
import 'package:excellencecoachinghub/services/ai_chat_service.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_history_screen.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/widgets/student_guide_widget.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

/// Modern, minimalist student learning screen with clean section navigation
class ModernStudentLearningScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ModernStudentLearningScreen({super.key, required this.courseId});

  @override
  ConsumerState<ModernStudentLearningScreen> createState() => _ModernStudentLearningScreenState();
}

class _ModernStudentLearningScreenState extends ConsumerState<ModernStudentLearningScreen> {
  final GlobalKey<StudentGuideWidgetState> _guideKey = GlobalKey<StudentGuideWidgetState>();
  Course? _course;
  List<Section>? _sections;
  Map<String, dynamic>? _courseAccessData;
  final Map<String, bool> _sectionCompletionStatus = {};
  final Map<String, bool> _lessonCompletionStatus = {};
  final Map<String, List<Lesson>> _sectionLessons = {};
  bool _isLoading = true;
  bool _isCompletingSection = false;
  int _currentSectionIndex = 0;
  List<Certificate>? _courseCertificates;
  bool _isLoadingCertificates = false;
  double _userRating = 0.0;
  final TextEditingController _feedbackController = TextEditingController();
  
  bool _hasSubmittedFeedback = false;
  
  // AI Chat state
  bool _isChatExpanded = false;
  final RealAIChatService _aiChatService = RealAIChatService();
  final String _conversationId = 'conversation_${DateTime.now().millisecondsSinceEpoch}';
  
  // Progress statistics
  int _totalLessons = 0;
  int _completedLessonsCount = 0;
  int _totalDurationMinutes = 0;
  int _completedDurationMinutes = 0;

  @override
  void initState() {
    super.initState();
    _loadCourseData();
  }

  Future<void> _loadCourseData() async {
    setState(() {
      _isLoading = true;
    });

    try {
      print('Loading course data for course ID: ${widget.courseId}');
      
      // Load course
      final courseRepo = CourseRepository();
      _course = await courseRepo.getCourseById(widget.courseId);
      print('Course loaded: ${_course?.title}');

      // Load course content (sections and lessons) in one call
      final sectionRepo = section_repo.SectionRepository();
      final courseContent = await sectionRepo.getCourseContent(widget.courseId);
      
      if (courseContent['sections'] != null) {
        final sectionsData = courseContent['sections'] as List;
        _sections = sectionsData.map((s) => Section.fromJson(s as Map<String, dynamic>)).toList();
        
        // Sort sections by order
        _sections?.sort((a, b) => a.order.compareTo(b.order));
        print('Sections loaded: ${_sections?.length}');
        
        // Calculate total lessons and duration from the content
        _totalLessons = 0;
        _totalDurationMinutes = 0;
        _sectionLessons.clear();
        
        for (var sectionData in sectionsData) {
          final sData = sectionData as Map<String, dynamic>;
          final sectionId = (sData['_id'] ?? sData['id']).toString();
          final lessonsData = sData['lessons'] as List?;
          if (lessonsData != null) {
            final lessons = lessonsData.map((l) => Lesson.fromJson(l as Map<String, dynamic>)).toList();
            _sectionLessons[sectionId] = lessons;
            _totalLessons += lessons.length;
            for (var lesson in lessons) {
              _totalDurationMinutes += lesson.duration;
            }
          }
        }
      }

      // Initialize section completion status
      _initializeSectionCompletionStatus();
      
      // Load course access information
      try {
        final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
        _courseAccessData = await enrollmentRepo.checkCourseAccess(widget.courseId);
        
        // Initialize lesson completion status from backend data
        if (_courseAccessData != null && _courseAccessData!['completedLessons'] != null) {
          final completedList = _courseAccessData!['completedLessons'] as List;
          _completedLessonsCount = completedList.length;
          _completedDurationMinutes = 0;
          
          final completedSet = completedList.map((e) => e.toString()).toSet();
          
          for (var lessonId in completedList) {
            _lessonCompletionStatus[lessonId.toString()] = true;
          }
          print('Loaded ${_lessonCompletionStatus.length} completed lessons from backend');
          
          // Calculate completed duration from actual lesson data
          if (courseContent['sections'] != null) {
            final sectionsData = courseContent['sections'] as List;
            for (var sectionData in sectionsData) {
              final lessonsData = (sectionData as Map<String, dynamic>)['lessons'] as List?;
              if (lessonsData != null) {
                for (var lessonData in lessonsData) {
                  if (completedSet.contains(lessonData['_id'].toString())) {
                    _completedDurationMinutes += (lessonData['duration'] as num?)?.toInt() ?? 0;
                  }
                }
              }
            }
          }
        }
        
        // Initialize section completion status from backend data
        if (_courseAccessData != null && _courseAccessData!['completedSections'] != null) {
          final completedSectionsList = _courseAccessData!['completedSections'] as List;
          final completedSet = completedSectionsList.map((e) => e.toString()).toSet();
          
          for (var sectionId in completedSectionsList) {
            _sectionCompletionStatus[sectionId.toString()] = true;
          }
          print('Loaded ${completedSectionsList.length} completed sections from backend');
          
          // If a section is completed, the NEXT one should be unlocked
          if (_sections != null) {
            for (int i = 0; i < _sections!.length; i++) {
              if (completedSet.contains(_sections![i].id)) {
                if (i + 1 < _sections!.length) {
                  _sectionCompletionStatus[_sections![i+1].id] = true;
                }
              }
            }
            
            // Set current section index based on the first incomplete section
            for (int i = 0; i < _sections!.length; i++) {
              if (!completedSet.contains(_sections![i].id)) {
                _currentSectionIndex = i;
                break;
              }
              // If all sections are completed, set to the last one
              _currentSectionIndex = _sections!.length - 1;
            }
          }
        }
        
        // Load feedback if exists
        if (_courseAccessData != null && _courseAccessData!['rating'] != null) {
          _userRating = (_courseAccessData!['rating'] as num).toDouble();
          _feedbackController.text = _courseAccessData!['feedback'] ?? '';
          _hasSubmittedFeedback = true;
        }
      } catch (e) {
        print('Error loading course access data: $e');
        _courseAccessData = null;
      }

      // Load certificates for this course
      await _loadCourseCertificates();

      setState(() {
        _isLoading = false;
      });

      // Show welcome message from AI coach
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _guideKey.currentState != null) {
          _guideKey.currentState!.updateState(
            StudentGuideState.greeting,
            message: "Welcome to ${_course?.title}! I'm your AI Coach, and I'm here to help you master this course. Click me anytime if you have questions! 👋",
          );
        }
      });
    } catch (e) {
      print('Error loading course data: $e');
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCourseCertificates() async {
    try {
      final certificateRepo = CertificateRepository();
      final certificates = await certificateRepo.getCertificatesByCourse(widget.courseId);
      
      setState(() {
        _courseCertificates = certificates;
      });
    } catch (e) {
      print('Error loading certificates: $e');
      setState(() {
        _courseCertificates = [];
      });
    }
  }
  
  void _initializeSectionCompletionStatus() {
    if (_sections == null) return;
    
    // First section is always unlocked
    if (_sections!.isNotEmpty) {
      _sectionCompletionStatus[_sections![0].id] = true;
      _currentSectionIndex = 0;
    }
    
    // Other sections are locked initially
    for (int i = 1; i < _sections!.length; i++) {
      _sectionCompletionStatus[_sections![i].id] = false;
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

    if (_course == null) {
      return Scaffold(
        backgroundColor: AppTheme.getBackgroundColor(context),
        appBar: AppBar(
          title: const Text('Learning'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Course not found'),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: _buildAppBar(),
      body: _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: isDark 
                ? Colors.black.withOpacity(0.3) 
                : Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new, 
            size: 20,
            color: AppTheme.getTextColor(context),
          ),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/dashboard');
            }
          },
        ),
      ),
      title: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isSmallMobile ? 8 : 16, 
          vertical: 6
        ),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppTheme.primaryGreen.withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Text(
          _course!.title,
          style: TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: isSmallMobile ? 14 : 16,
            color: AppTheme.primaryGreen,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ),
      backgroundColor: AppTheme.getBackgroundColor(context),
      foregroundColor: AppTheme.getTextColor(context),
      elevation: 0,
      centerTitle: true,
      actions: [
        if (!isSmallMobile)
          // Progress indicator
          Container(
            margin: const EdgeInsets.all(8),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(isDark ? 0.1 : 0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.auto_graph, color: Colors.white, size: 16),
                SizedBox(width: 4),
                Text(
                  'Learning',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(width: 4),
        // History button
        Container(
          margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: isDark 
                  ? Colors.black.withOpacity(0.3) 
                  : Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: Icon(
              Icons.history_outlined, 
              size: 20,
              color: AppTheme.getTextColor(context),
            ),
            onPressed: _navigateToExamHistory,
            tooltip: 'Exam History',
          ),
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainContent() {
    return Stack(
      children: [
        SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Progress header
                _buildProgressHeader(),
                
                const SizedBox(height: 16),
                
                // Course expiration countdown
                _buildCourseExpirationCounter(),
                
                const SizedBox(height: 16),
                
                // Sections list
                Expanded(
                  child: _buildSectionsList(),
                ),
              ],
            ),
          ),
        ),
        
        // Student Guide Character + AI integration
        Positioned(
          bottom: 20, // Moved back to original bottom area as it replaces AI button
          right: 20,
          child: StudentGuideWidget(
            key: _guideKey,
            initialState: StudentGuideState.greeting,
            config: const GuideConfig(
              character: GuideCharacter.guide,
              isAiMode: true, // Enable AI features (glow, etc)
            ),
            message: 'Let\'s master this course together!',
            autoDismiss: false,
            onTap: () {
              setState(() {
                _isChatExpanded = !_isChatExpanded;
              });
            },
          ),
        ),

        // AI Chat overlay (appears when expanded)
        if (_isChatExpanded)
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _isChatExpanded = false), // Close when tapping outside
              child: Container(
                color: Colors.black.withOpacity(0.5),
                child: Center(
                  child: GestureDetector(
                    onTap: () {}, // Prevent closing when tapping on dialog
                    child: ModernAIChatDialog(
                      currentCourse: _course,
                      currentLesson: null, // No lesson selected at course level
                      allSections: _sections,
                      sectionLessons: _sectionLessons,
                      chatService: _aiChatService,
                      conversationId: _conversationId,
                      guideKey: _guideKey,
                      onClose: () => setState(() => _isChatExpanded = false),
                    ),
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final completedSections = _sectionCompletionStatus.values.where((status) => status).length;
    final totalSections = _sections?.length ?? 0;
    
    // Calculate progress based on lessons for more granularity
    final progress = _totalLessons > 0 ? _completedLessonsCount / _totalLessons : 0.0;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.auto_graph_outlined,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Learning Progress',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 18 : 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(progress * 100).toInt()}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 20),
          // Stats Row
          LayoutBuilder(
            builder: (context, constraints) {
              final itemWidth = (constraints.maxWidth - 20) / 3;
              return Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  SizedBox(
                    width: itemWidth,
                    child: _buildProgressStat('Sections', '$completedSections/$totalSections', Icons.library_books),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildProgressStat('Lessons', '$_completedLessonsCount/$_totalLessons', Icons.play_circle),
                  ),
                  SizedBox(
                    width: itemWidth,
                    child: _buildProgressStat('Hours', '${(_completedDurationMinutes / 60).toStringAsFixed(1)}/${(_totalDurationMinutes / 60).toStringAsFixed(1)}', Icons.access_time),
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          icon,
          color: Colors.white.withOpacity(0.9),
          size: isSmallMobile ? 18 : 22,
        ),
        const SizedBox(height: 4),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: isSmallMobile ? 14 : 16,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: isSmallMobile ? 10 : 12,
            color: Colors.white.withOpacity(0.7),
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildCourseExpirationCounter() {
    if (_courseAccessData != null) {
      print('Course access data: $_courseAccessData');
      
      if (_courseAccessData!['accessExpirationDate'] != null) {
        try {
          final expirationDateString = _courseAccessData!['accessExpirationDate'];
          print('Expiration date string: $expirationDateString');
          
          // Parse the date string to a DateTime object
          DateTime expirationDate;
          
          // Handle different date formats
          if (expirationDateString is String) {
            expirationDate = DateTime.parse(expirationDateString);
          } else if (expirationDateString is int) {
            // Handle timestamp format
            expirationDate = DateTime.fromMillisecondsSinceEpoch(expirationDateString);
          } else {
            print('Unexpected expiration date format: ${expirationDateString.runtimeType}');
            return const SizedBox.shrink();
          }
          
          print('Parsed expiration date: $expirationDate');
          
          return CountdownTimer(
            expirationDate: expirationDate,
            showSeconds: true,
            onExpiration: () {
              // Handle expiration if needed
              print('Course access has expired');
            },
          );
        } catch (e) {
          print('Error parsing expiration date: $e');
          return const SizedBox.shrink();
        }
      }
    }
    
    // If no expiration date or access data, don't show the counter
    return const SizedBox.shrink();
  }

  Widget _buildSectionsList() {
    if (_sections == null || _sections!.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 64,
              color: AppTheme.greyColor.withOpacity(0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No sections available',
              style: TextStyle(
                fontSize: 18,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      itemCount: _sections!.length + 1,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        if (index == _sections!.length) {
          return _buildRatingSection();
        }
        final section = _sections![index];
        final isUnlocked = _sectionCompletionStatus[section.id] ?? false;
        final isCurrent = index == _currentSectionIndex;
        
        return _buildSectionCard(section, isUnlocked, isCurrent, index);
      },
    );
  }

  Widget _buildRatingSection() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppTheme.primaryGreen.withOpacity(isDark ? 0.3 : 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _hasSubmittedFeedback ? 'Your Rating' : 'Enjoying this course?',
            style: TextStyle(
              fontSize: 18, 
              fontWeight: FontWeight.bold, 
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            _hasSubmittedFeedback 
              ? 'Thank you for your feedback! It helps us improve.'
              : 'Your feedback helps us improve and helps other students.',
            style: TextStyle(
              fontSize: 14, 
              color: AppTheme.getSecondaryTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return IconButton(
                icon: Icon(
                  index < _userRating ? Icons.star : Icons.star_border,
                  color: Colors.amber,
                  size: 32,
                ),
                onPressed: _hasSubmittedFeedback ? null : () {
                  setState(() {
                    _userRating = index + 1.0;
                  });
                },
              );
            }),
          ),
          if (_userRating > 0) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _feedbackController,
              enabled: !_hasSubmittedFeedback,
              style: TextStyle(color: AppTheme.getTextColor(context)),
              decoration: InputDecoration(
                hintText: 'Share your feedback (optional)',
                hintStyle: TextStyle(color: AppTheme.getSecondaryTextColor(context)),
                fillColor: isDark ? AppTheme.darkSurface : Colors.grey.shade50,
                filled: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: AppTheme.primaryGreen.withOpacity(0.2)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: AppTheme.primaryGreen, width: 2),
                ),
              ),
              maxLines: 3,
            ),
            if (!_hasSubmittedFeedback) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () async {
                    if (_userRating == 0) return;
                    
                    try {
                      final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
                      await enrollmentRepo.submitCourseFeedback(
                        widget.courseId, 
                        _userRating, 
                        _feedbackController.text
                      );
                      
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Thank you for your rating!'),
                            backgroundColor: AppTheme.primaryGreen,
                          ),
                        );
                        setState(() {
                          _hasSubmittedFeedback = true;
                        });
                      }
                    } catch (e) {
                      if (mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Failed to submit feedback: $e'),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text('Submit Rating', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(Section section, bool isUnlocked, bool isCurrent, int index) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: EdgeInsets.only(bottom: isSmallMobile ? 12 : 16),
      decoration: BoxDecoration(
        gradient: isUnlocked
          ? LinearGradient(
              colors: isDark ? AppTheme.darkCardGradient : AppTheme.modernCardGradient,
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : LinearGradient(
              colors: isDark 
                ? [const Color(0xFF1E293B).withOpacity(0.5), const Color(0xFF0F172A).withOpacity(0.5)] 
                : [const Color(0xFFF1F5F9), const Color(0xFFE2E8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent 
            ? AppTheme.primaryGreen 
            : (isUnlocked 
                ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200) 
                : (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade300)),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.grey.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: AppTheme.primaryGreen.withOpacity(0.1),
        ),
        child: ExpansionTile(
          key: ValueKey(section.id),
          initiallyExpanded: isCurrent,
          enabled: isUnlocked,
          tilePadding: EdgeInsets.symmetric(
            horizontal: isSmallMobile ? 16 : 24, 
            vertical: isSmallMobile ? 8 : 12
          ),
          childrenPadding: EdgeInsets.fromLTRB(
            isSmallMobile ? 16 : 24, 
            0, 
            isSmallMobile ? 16 : 24, 
            isSmallMobile ? 16 : 24
          ),
          leading: Container(
            width: isSmallMobile ? 40 : 48,
            height: isSmallMobile ? 40 : 48,
            decoration: BoxDecoration(
              gradient: isUnlocked
                ? const LinearGradient(
                    colors: AppTheme.primaryGradient,
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: isDark 
                      ? [const Color(0xFF475569), const Color(0xFF334155)]
                      : [const Color(0xFF9CA3AF), const Color(0xFF6B7280)],
                  ),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked 
                    ? AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.3)
                    : Colors.grey.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                color: Colors.white,
                size: isSmallMobile ? 20 : 24,
              ),
            ),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              fontSize: isSmallMobile ? 16 : 18,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                ? AppTheme.getTextColor(context)
                : AppTheme.getSecondaryTextColor(context),
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Row(
              children: [
                Icon(
                  Icons.school,
                  size: 13,
                  color: isUnlocked ? AppTheme.primaryGreen : AppTheme.getSecondaryTextColor(context),
                ),
                const SizedBox(width: 4),
                Text(
                  '${_sectionLessons[section.id]?.length ?? 0} lessons',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 12 : 14,
                    color: isUnlocked ? AppTheme.getSecondaryTextColor(context) : AppTheme.getSecondaryTextColor(context).withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent && !isSmallMobile) ...[
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10, 
                    vertical: 4
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: AppTheme.primaryGradient,
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.play_circle,
                        color: Colors.white,
                        size: 14,
                      ),
                      SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Icon(
                Icons.arrow_forward_ios,
                color: isUnlocked ? AppTheme.primaryGreen : AppTheme.getSecondaryTextColor(context).withOpacity(0.5),
                size: 14,
              ),
            ],
          ),
          children: [
            const SizedBox(height: 12),
            if (isUnlocked) ...[
              _buildLessonsList(section.id),
              const SizedBox(height: 20),
              _buildCompleteSectionButton(section, index),
            ] else ...[
              Center(
                child: Container(
                  padding: EdgeInsets.all(isMobile ? 16 : 24),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.white.withOpacity(0.1) : Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.lock_clock,
                        size: 32,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.getTextColor(context).withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete the previous section to unlock',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                          fontStyle: FontStyle.italic,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLessonsList(String sectionId) {
    final lessons = _sectionLessons[sectionId] ?? [];
    
    if (lessons.isEmpty) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 16),
        child: Center(
          child: Text(
            'No lessons in this section',
            style: TextStyle(
              color: AppTheme.greyColor,
              fontStyle: FontStyle.italic,
            ),
          ),
        ),
      );
    }

    return Column(
      children: [
        ...lessons.asMap().entries.map((entry) {
          final index = entry.key;
          final lesson = entry.value;
          
          // Determine if this is the next lesson to take
          bool isNext = false;
          if (_lessonCompletionStatus[lesson.id] != true) {
            // Check if all previous lessons in this section are completed
            bool previousCompleted = true;
            for (int i = 0; i < index; i++) {
              if (_lessonCompletionStatus[lessons[i].id] != true) {
                previousCompleted = false;
                break;
              }
            }
            if (previousCompleted) isNext = true;
          }
          
          return _buildLessonItem(lesson, isNext);
        }),
        // Add exam button after lessons
        _buildExamButton(sectionId),
      ],
    );
  }

  Widget _buildExamButton(String sectionId) {
    return FutureBuilder<List<exam_model.Exam>>(
      future: ExamService().getExamsBySection(sectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 12),
                const Text(
                  'Loading exams...',
                  style: TextStyle(
                    fontSize: 14,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
          );
        }
        
        if (snapshot.hasError) {
          print('Error loading exams for section $sectionId: ${snapshot.error}');
          return Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(
                'Unable to load exams',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.red.shade600,
                ),
              ),
            ),
          );
        }
        
        if (snapshot.data == null || snapshot.data!.isEmpty) {
          // No exams available for this section
          return const SizedBox.shrink();
        }

        final exams = snapshot.data!;
        final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
        
        // Get the first exam type to determine section title
        final firstExam = exams.first;
        String sectionTitle;
        Color sectionColor;
        IconData sectionIcon;
        
        switch (firstExam.type.toLowerCase() ?? '') {
          case 'quiz':
            sectionTitle = 'Quiz Section';
            sectionColor = Colors.blue;
            sectionIcon = Icons.quiz_outlined;
            break;
          case 'pastpaper':
            sectionTitle = 'Past Paper Section';
            sectionColor = Colors.orange;
            sectionIcon = Icons.article_outlined;
            break;
          case 'final':
            sectionTitle = 'Final Exam Section';
            sectionColor = Colors.red;
            sectionIcon = Icons.school_outlined;
            break;
          default:
            sectionTitle = 'Exam Section';
            sectionColor = Colors.grey;
            sectionIcon = Icons.help_outline;
        }
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: EdgeInsets.only(top: isSmallMobile ? 12 : 16, bottom: 8, left: 4),
              child: Row(
                children: [
                  Container(
                    padding: EdgeInsets.all(isSmallMobile ? 4 : 6),
                          decoration: BoxDecoration(
                            color: sectionColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: sectionColor.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Icon(
                            sectionIcon,
                            color: sectionColor,
                            size: isSmallMobile ? 16 : 18,
                          ),
                        ),
                        SizedBox(width: isSmallMobile ? 6 : 8),
                        Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        SizedBox(width: isSmallMobile ? 6 : 8),
                        if (exams.length > 1)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 4 : 6, 
                              vertical: isSmallMobile ? 1 : 2
                            ),
                            decoration: BoxDecoration(
                              color: sectionColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${exams.length}',
                              style: TextStyle(
                                color: sectionColor,
                                fontSize: isSmallMobile ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        
                        // Check if any exam in this section has a certificate
                        if (_courseCertificates != null && _courseCertificates!.any((cert) => 
                          exams.any((exam) => exam.id == cert.examId)
                        ))
                          Padding(
                            padding: const EdgeInsets.only(left: 8.0),
                            child: Tooltip(
                              message: 'Certificate available in this section',
                              child: Icon(
                                Icons.workspace_premium,
                                color: Colors.amber,
                                size: isSmallMobile ? 16 : 18,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
            ...exams.map((exam) {
              final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
              Color examColor;
              IconData examIcon;
              String examTypeLabel;
              
              // Check if this specific exam has a certificate
              final examCertificate = _courseCertificates?.where((c) => c.examId == exam.id).firstOrNull;
              
              switch (exam.type.toLowerCase() ?? '') {
                case 'quiz':
                  examColor = Colors.blue;
                  examIcon = Icons.quiz_outlined;
                  examTypeLabel = 'Quiz';
                  break;
                case 'pastpaper':
                  examColor = Colors.orange;
                  examIcon = Icons.article_outlined;
                  examTypeLabel = 'Past Paper';
                  break;
                case 'final':
                  examColor = Colors.red;
                  examIcon = Icons.school_outlined;
                  examTypeLabel = 'Final Exam';
                  break;
                default:
                  examColor = Colors.grey;
                  examIcon = Icons.help_outline;
                  examTypeLabel = 'Exam';
              }
              
              return Container(
                margin: const EdgeInsets.only(top: 8),
                decoration: BoxDecoration(
                  color: examColor.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: examColor.withOpacity(0.2),
                    width: 1,
                  ),
                ),
                child: ListTile(
                  contentPadding: EdgeInsets.all(isSmallMobile ? 12 : 16),
                  leading: Container(
                    width: isSmallMobile ? 40 : 48,
                    height: isSmallMobile ? 40 : 48,
                    decoration: BoxDecoration(
                      color: examColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: examColor.withOpacity(0.3),
                        width: 1,
                      ),
                    ),
                    child: Icon(
                      examIcon,
                      color: examColor,
                      size: isSmallMobile ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: isSmallMobile ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallMobile ? 2 : 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallMobile ? 6 : 8, 
                              vertical: isSmallMobile ? 1 : 2
                            ),
                            decoration: BoxDecoration(
                              color: examColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              examTypeLabel,
                              style: TextStyle(
                                color: examColor,
                                fontSize: isSmallMobile ? 9 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallMobile ? 4 : 8),
                          Icon(Icons.question_mark, size: isSmallMobile ? 12 : 14, color: AppTheme.greyColor),
                          SizedBox(width: isSmallMobile ? 2 : 4),
                          Text(
                            '${exam.questionsCount} qns',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          if (exam.timeLimit > 0) ...[
                            SizedBox(width: isSmallMobile ? 4 : 8),
                            Icon(Icons.timer, size: isSmallMobile ? 12 : 14, color: AppTheme.greyColor),
                            SizedBox(width: isSmallMobile ? 2 : 4),
                            Text(
                              '${exam.timeLimit}m',
                              style: TextStyle(
                                fontSize: isSmallMobile ? 10 : 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (exam.passingScore > 0)
                        Padding(
                          padding: EdgeInsets.only(top: isSmallMobile ? 2 : 4),
                          child: Text(
                            'Pass: ${exam.passingScore}%',
                            style: TextStyle(
                              fontSize: isSmallMobile ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ),
                        if (examCertificate != null)
                          Padding(
                            padding: EdgeInsets.only(top: isSmallMobile ? 6 : 8),
                            child: OutlinedButton.icon(
                              onPressed: () => _viewCertificate(examCertificate),
                              icon: const Icon(Icons.workspace_premium, size: 14),
                              label: const Text('View Certificate'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.amber.shade800,
                                side: BorderSide(color: Colors.amber.shade400),
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 0),
                                minimumSize: const Size(0, 28),
                                textStyle: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                          ),
                      ],
                    ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: examColor,
                    size: isSmallMobile ? 14 : 16,
                  ),
                  onTap: () => _takeExam(exam),
                ),
              );
            }),
          ],
        );
      },
    );
  }

  void _takeExam(exam_model.Exam exam) {
    // Show confirmation dialog with exam details
    showDialog(
      context: context,
      builder: (BuildContext context) {
        String examTypeLabel;
        Color examColor;
        IconData examIcon;
        
        switch (exam.type.toLowerCase() ?? '') {
          case 'quiz':
            examTypeLabel = 'Quiz';
            examColor = Colors.blue;
            examIcon = Icons.quiz_outlined;
            break;
          case 'pastpaper':
            examTypeLabel = 'Past Paper';
            examColor = Colors.orange;
            examIcon = Icons.article_outlined;
            break;
          case 'final':
            examTypeLabel = 'Final Exam';
            examColor = Colors.red;
            examIcon = Icons.school_outlined;
            break;
          default:
            examTypeLabel = 'Exam';
            examColor = Colors.grey;
            examIcon = Icons.help_outline;
        }
        
        return AlertDialog(
          title: Row(
            children: [
              Icon(examIcon, color: examColor, size: 24),
              const SizedBox(width: 12),
              Text('$examTypeLabel: ${exam.title}'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'You are about to start the "${exam.title}" exam.',
                style: const TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: examColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: examColor.withOpacity(0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildExamInfoRow(Icons.question_mark, '${exam.questionsCount} Questions'),
                    if (exam.timeLimit > 0)
                      _buildExamInfoRow(Icons.timer, '${exam.timeLimit} Minutes'),
                    if (exam.passingScore > 0)
                      _buildExamInfoRow(Icons.check_circle, '${exam.passingScore}% to Pass'),
                    _buildExamInfoRow(Icons.repeat, '${exam.attempts} Attempts Allowed'),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Important:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 4),
              const Text(
                '• Make sure you have a stable internet connection\n'
                '• Close other applications to avoid distractions\n'
                '• Once started, the timer cannot be paused',
                style: TextStyle(fontSize: 12, color: AppTheme.greyColor),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                _navigateToExamTakingScreen(exam);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: examColor,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Exam'),
            ),
          ],
        );
      },
    );
  }

  void _viewCertificate(Certificate certificate) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Certificate Details'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Score: ${certificate.score.toStringAsFixed(1)}/${certificate.percentage.toStringAsFixed(1)}%'),
            Text('Date: ${certificate.issuedDate.day}/${certificate.issuedDate.month}/${certificate.issuedDate.year}'),
            Text('Serial: ${certificate.serialNumber}'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
  
  Widget _buildExamInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppTheme.greyColor),
          const SizedBox(width: 8),
          Text(
            text,
            style: const TextStyle(fontSize: 13),
          ),
        ],
      ),
    );
  }

  void _navigateToExamTakingScreen(exam_model.Exam exam) {
    // Navigate to the exam taking screen
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ExamTakingScreen(exam: exam),
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson, bool isNext) {
    // Check if lesson is completed
    final isCompleted = _lessonCompletionStatus[lesson.id] ?? false;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Determine lesson type and styling
    final bool isVideoLesson = lesson.videoId != null && lesson.videoId!.isNotEmpty;
    final Color lessonTypeColor = isVideoLesson ? AppTheme.primaryGreen : AppTheme.accent;
    final Color lessonBgColor = isCompleted
        ? (isDark ? Colors.white.withOpacity(0.05) : Colors.grey.withOpacity(0.1))
        : (isVideoLesson 
            ? AppTheme.primaryGreen.withOpacity(isDark ? 0.12 : 0.08) 
            : AppTheme.accent.withOpacity(isDark ? 0.12 : 0.08));
    final IconData lessonIcon = isVideoLesson ? Icons.play_circle_fill : Icons.article;
    final String lessonTypeLabel = isVideoLesson ? 'Video' : 'Notes';
    
    return InkWell(
      onTap: () => _viewLesson(lesson),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmallMobile ? 12 : 16),
        decoration: BoxDecoration(
          color: isNext 
            ? AppTheme.primaryGreen.withOpacity(isDark ? 0.15 : 0.1) 
            : lessonBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
              ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3))
              : (isNext 
                  ? AppTheme.primaryGreen.withOpacity(0.3) 
                  : lessonTypeColor.withOpacity(0.2)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isNext 
                ? AppTheme.primaryGreen.withOpacity(isDark ? 0.05 : 0.1) 
                : (isCompleted 
                    ? (isDark ? Colors.black.withOpacity(0.2) : Colors.grey.withOpacity(0.05))
                    : lessonTypeColor.withOpacity(0.05)),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // Lesson type indicator circle
            Container(
              width: isSmallMobile ? 36 : 44,
              height: isSmallMobile ? 36 : 44,
              decoration: BoxDecoration(
                color: isCompleted
                  ? (isDark ? Colors.white.withOpacity(0.1) : Colors.grey.withOpacity(0.3))
                  : lessonTypeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isCompleted
                    ? (isDark ? Colors.white.withOpacity(0.2) : Colors.grey.withOpacity(0.4))
                    : lessonTypeColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : lessonIcon,
                  color: isCompleted ? (isDark ? Colors.white60 : Colors.grey) : lessonTypeColor,
                  size: isSmallMobile ? 18 : 22,
                ),
              ),
            ),
            SizedBox(width: isSmallMobile ? 10 : 16),
            // Lesson content
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Lesson title with type badge
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lesson.title,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 13 : 15,
                            fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
                            color: isCompleted
                              ? (isDark ? Colors.white60 : Colors.grey)
                              : (isNext 
                                  ? AppTheme.primaryGreen 
                                  : AppTheme.getTextColor(context)),
                            decoration: isCompleted ? TextDecoration.lineThrough : null,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      // Completion status badge
                      if (isCompleted) ...[
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallMobile ? 6 : 8, 
                            vertical: isSmallMobile ? 2 : 4
                          ),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.check,
                                color: Colors.green,
                                size: isSmallMobile ? 10 : 12,
                              ),
                              SizedBox(width: isSmallMobile ? 2 : 4),
                              Text(
                                'Done',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: isSmallMobile ? 8 : 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        // Type badge
                        Container(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallMobile ? 6 : 8, 
                            vertical: isSmallMobile ? 2 : 4
                          ),
                          decoration: BoxDecoration(
                            color: lessonTypeColor.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(
                              color: lessonTypeColor.withOpacity(0.4),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            lessonTypeLabel,
                            style: TextStyle(
                              color: lessonTypeColor,
                              fontSize: isSmallMobile ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isSmallMobile ? 4 : 6),
                  // Duration and additional info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isSmallMobile ? 11 : 13,
                        color: isCompleted ? (isDark ? Colors.white60 : Colors.grey) : AppTheme.getSecondaryTextColor(context),
                      ),
                      SizedBox(width: isSmallMobile ? 2 : 4),
                      Text(
                        '${lesson.duration}m',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 10 : 12,
                          color: isCompleted ? (isDark ? Colors.white60 : Colors.grey) : AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      SizedBox(width: isSmallMobile ? 8 : 12),
                      if (isVideoLesson && !isCompleted) ...[
                        Icon(
                          Icons.hd_outlined,
                          size: isSmallMobile ? 11 : 13,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: isSmallMobile ? 2 : 4),
                        Text(
                          'HD',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 10 : 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ] else if (!isVideoLesson && !isCompleted) ...[
                        Icon(
                          Icons.text_snippet_outlined,
                          size: isSmallMobile ? 11 : 13,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                        SizedBox(width: isSmallMobile ? 2 : 4),
                        Text(
                          'Text',
                          style: TextStyle(
                            fontSize: isSmallMobile ? 10 : 12,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmallMobile ? 8 : 12),
            // Next indicator and arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNext && !isCompleted) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallMobile ? 6 : 8, 
                      vertical: isSmallMobile ? 3 : 5
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallMobile ? 7 : 9,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallMobile ? 4 : 8),
                ],
                Icon(
                  isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isCompleted ? Colors.green : (isNext ? AppTheme.primaryGreen : AppTheme.getSecondaryTextColor(context)),
                  size: isSmallMobile ? 14 : 16,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewLesson(Lesson lesson) async {
    // Navigate to the lesson viewer
    if (mounted) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (context) => LessonViewer(
            lesson: lesson,
            courseId: widget.courseId,
            allSections: _sections,
            sectionLessons: _sectionLessons,
            certificates: _courseCertificates,
            onComplete: () => _markLessonAsComplete(lesson),
          ),
        ),
      );
    }
    
    // Also mark as complete when viewing (as per existing logic, but refactored)
    _markLessonAsComplete(lesson);
  }

  void _markLessonAsComplete(Lesson lesson) async {
    // Only update if not already completed
    if (_lessonCompletionStatus[lesson.id] != true) {
      // Mark lesson as completed locally first for better UX
      setState(() {
        _lessonCompletionStatus[lesson.id] = true;
        _completedLessonsCount++;
        _completedDurationMinutes += lesson.duration;
      });

      // Show student guide cheer
      _guideKey.currentState?.updateState(
        StudentGuideState.cheer,
        message: 'Great job! Lesson completed!',
        autoDismiss: true,
      );
      
      // Call backend to update progress if enrollment is found
      if (_courseAccessData != null && _courseAccessData!['enrollmentId'] != null) {
        final enrollmentId = _courseAccessData!['enrollmentId'].toString();
        try {
          print('Updating enrollment $enrollmentId progress for lesson: ${lesson.title}');
          final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
          final result = await enrollmentRepo.updateEnrollmentProgress(enrollmentId, lesson.id, true);
          print('Progress updated successfully in backend: ${result['progress']}%');
          
          // Update local progress from backend to ensure accuracy
          if (result['progress'] != null) {
            // If backend returns updated progress, we could update our local state
            // But we already calculate it locally for immediate feedback
          }
        } catch (e) {
          print('Error updating enrollment progress in backend: $e');
        }
      }
    }
  }

  Widget _buildCompleteSectionButton(Section section, int index) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: AppTheme.primaryGradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withOpacity(isDark ? 0.2 : 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ElevatedButton(
        onPressed: _isCompletingSection ? null : () => _completeSection(section, index),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
          side: BorderSide.none,
        ),
        child: _isCompletingSection
          ? const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
                SizedBox(width: 12),
                Text(
                  'Completing...',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            )
          : const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  color: Colors.white,
                  size: 20,
                ),
                SizedBox(width: 8),
                Text(
                  'Mark Section as Completed',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
      ),
    );
  }

  Future<List<Lesson>> _fetchLessonsBySection(String sectionId) async {
    try {
      final lessonRepo = lesson_repo.LessonRepository();
      return await lessonRepo.getLessonsBySection(sectionId);
    } catch (e) {
      print('Error fetching lessons for section $sectionId: $e');
      return [];
    }
  }

  Future<List<Lesson>> _fetchLessonsCount(String sectionId) async {
    try {
      final lessonRepo = lesson_repo.LessonRepository();
      return await lessonRepo.getLessonsBySection(sectionId);
    } catch (e) {
      return [];
    }
  }

  Future<void> _completeSection(Section section, int index) async {
    if (_isCompletingSection) return;
    
    setState(() {
      _isCompletingSection = true;
    });
    
    try {
      // Call backend to mark section as completed
      if (_courseAccessData != null && _courseAccessData!['enrollmentId'] != null) {
        final enrollmentId = _courseAccessData!['enrollmentId'].toString();
        final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
        
        print('Completing section ${section.title} for enrollment $enrollmentId');
        await enrollmentRepo.completeSection(enrollmentId, section.id);
        
        // Update all lessons in this section as completed locally
        final lessons = _sectionLessons[section.id] ?? [];
        setState(() {
          for (var lesson in lessons) {
            if (_lessonCompletionStatus[lesson.id] != true) {
              _lessonCompletionStatus[lesson.id] = true;
              _completedLessonsCount++;
              _completedDurationMinutes += lesson.duration;
            }
          }
          _sectionCompletionStatus[section.id] = true;
        });
      } else {
        // Fallback if no enrollment found (should not happen if they are on this screen)
        setState(() {
          _sectionCompletionStatus[section.id] = true;
        });
      }
      
      // Unlock next section if exists
      if (index < _sections!.length - 1) {
        final nextSection = _sections![index + 1];
        setState(() {
          _sectionCompletionStatus[nextSection.id] = true;
          _currentSectionIndex = index + 1;
        });
      }
      
      // Show success message
      if (mounted) {
        _guideKey.currentState?.updateState(
          StudentGuideState.success,
          message: 'Amazing! You finished "${section.title}"!',
          autoDismiss: true,
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "${section.title}" completed! ${index < _sections!.length - 1 ? "Next section unlocked." : "Course completed!"}'),
            backgroundColor: AppTheme.primaryGreen,
            duration: const Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    } catch (e) {
      print('Error completing section: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing section: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 2),
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCompletingSection = false;
        });
      }
    }
  }

  void _navigateToExamHistory() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const ExamHistoryScreen(),
      ),
    );
  }

  Widget _buildCertificateSection(Certificate certificate) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.school,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Certificate of Completion',
                  style: TextStyle(
                    fontSize: isSmallMobile ? 16 : 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Congratulations! You have completed the final exam and earned a certificate.',
            style: TextStyle(
              fontSize: isSmallMobile ? 12 : 13,
              color: Colors.white.withOpacity(0.9),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Score: ${certificate.score.toStringAsFixed(1)}/${certificate.percentage.toStringAsFixed(1)}%',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _downloadCertificate(certificate.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                padding: EdgeInsets.symmetric(vertical: isSmallMobile ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.download, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    'Download Certificate',
                    style: TextStyle(
                      fontSize: isSmallMobile ? 13 : 15,
                      fontWeight: FontWeight.bold,
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

  Future<void> _downloadCertificate(String certificateId) async {
    try {
      final certificateRepo = CertificateRepository();
      
      // Show loading indicator
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Row(
              children: [
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                ),
                SizedBox(width: 12),
                Text('Preparing certificate download...'),
              ],
            ),
            duration: Duration(seconds: 2),
          ),
        );
      }

      final savePath = await certificateRepo.downloadAndSaveCertificate(
        certificateId,
        fileName: 'certificate_$certificateId.pdf',
      );
      
      if (mounted) {
        if (savePath != null) {
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Certificate saved to: $savePath'),
              backgroundColor: Colors.green,
              action: SnackBarAction(
                label: 'Open',
                textColor: Colors.white,
                onPressed: () async {
                  final Uri uri = Uri.file(savePath);
                  if (await canLaunchUrl(uri)) {
                    await launchUrl(uri);
                  }
                },
              ),
            ),
          );
        } else {
          // Download was cancelled by user (e.g., closed file picker)
          ScaffoldMessenger.of(context).clearSnackBars();
        }
      }
    } catch (e) {
      print('Error downloading certificate: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).clearSnackBars();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error downloading certificate: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
