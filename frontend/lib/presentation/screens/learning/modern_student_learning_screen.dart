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
import 'package:excellencecoachinghub/widgets/ai_floating_chat_button.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_taking_screen.dart';
import 'package:excellencecoachinghub/presentation/screens/exams/exam_history_screen.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/data/repositories/certificate_repository.dart';
import 'package:excellencecoachinghub/models/certificate.dart';
import 'package:url_launcher/url_launcher.dart';

/// Modern, minimalist student learning screen with clean section navigation
class ModernStudentLearningScreen extends ConsumerStatefulWidget {
  final String courseId;

  const ModernStudentLearningScreen({super.key, required this.courseId});

  @override
  ConsumerState<ModernStudentLearningScreen> createState() => _ModernStudentLearningScreenState();
}

class _ModernStudentLearningScreenState extends ConsumerState<ModernStudentLearningScreen> {
  Course? _course;
  List<Section>? _sections;
  Map<String, dynamic>? _courseAccessData;
  final Map<String, bool> _sectionCompletionStatus = {};
  final Map<String, bool> _lessonCompletionStatus = {};
  bool _isLoading = true;
  bool _isCompletingSection = false;
  int _currentSectionIndex = 0;
  List<Certificate>? _courseCertificates;
  bool _isLoadingCertificates = false;

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

      // Load sections
      final sectionRepo = section_repo.SectionRepository();
      _sections = await sectionRepo.getSectionsByCourse(widget.courseId);
      print('Sections loaded: ${_sections?.length}');
      
      // Sort sections by order
      _sections?.sort((a, b) => a.order.compareTo(b.order));

      // Initialize section completion status
      _initializeSectionCompletionStatus();
      
      // Load course access information
      try {
        final enrollmentRepo = ref.read(enrollmentRepositoryProvider);
        _courseAccessData = await enrollmentRepo.checkCourseAccess(widget.courseId);
      } catch (e) {
        print('Error loading course access data: $e');
        _courseAccessData = null;
      }

      // Load certificates for this course
      await _loadCourseCertificates();

      setState(() {
        _isLoading = false;
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
        backgroundColor: AppTheme.surface,
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
    return AppBar(
      leading: Container(
        margin: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, size: 20),
          onPressed: () {
            context.go('/dashboard');
          },
        ),
      ),
      title: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            fontSize: 18,
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
        // Progress indicator
        Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.primaryGreen,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.primaryGreen.withOpacity(0.3),
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
        const SizedBox(width: 8),
        // History button
        Container(
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: IconButton(
            icon: const Icon(Icons.history_outlined, size: 20),
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
        
        // AI Floating Chat Button
        AIFloatingChatButton(
          currentCourse: _course,
          currentLesson: null,
        ),
      ],
    );
  }

  Widget _buildProgressHeader() {
    final completedSections = _sectionCompletionStatus.values.where((status) => status).length;
    final totalSections = _sections?.length ?? 0;
    final progress = totalSections > 0 ? completedSections / totalSections : 0.0;
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
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
              const Text(
                'Learning Progress',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  '${(progress * 100).toInt()}% Complete',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: Colors.white.withOpacity(0.3),
              valueColor: const AlwaysStoppedAnimation<Color>(Colors.white),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildProgressStat('Sections', '$completedSections/$totalSections', Icons.library_books),
              _buildProgressStat('Lessons', '24/36', Icons.play_circle),
              _buildProgressStat('Hours', '12/18', Icons.access_time),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProgressStat(String label, String value, IconData icon) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 20,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.white70,
          ),
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
      itemCount: _sections!.length,
      separatorBuilder: (context, index) => const SizedBox(height: 12),
      itemBuilder: (context, index) {
        final section = _sections![index];
        final isUnlocked = _sectionCompletionStatus[section.id] ?? false;
        final isCurrent = index == _currentSectionIndex;
        
        return _buildSectionCard(section, isUnlocked, isCurrent, index);
      },
    );
  }

  Widget _buildSectionCard(Section section, bool isUnlocked, bool isCurrent, int index) {
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        gradient: isUnlocked
          ? const LinearGradient(
              colors: [Color(0xFFF8FAFC), Color(0xFFFFFFFF)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            )
          : const LinearGradient(
              colors: [Color(0xFFF1F5F9), Color(0xFFE2E8F0)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isCurrent 
            ? AppTheme.primaryGreen 
            : (isUnlocked ? Colors.grey.shade200 : Colors.grey.shade300),
          width: isCurrent ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
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
          tilePadding: EdgeInsets.all(isSmallScreen ? 20 : 24),
          childrenPadding: EdgeInsets.fromLTRB(
            isSmallScreen ? 20 : 24, 
            0, 
            isSmallScreen ? 20 : 24, 
            isSmallScreen ? 20 : 24
          ),
          leading: Container(
            width: isSmallScreen ? 48 : 56,
            height: isSmallScreen ? 48 : 56,
            decoration: BoxDecoration(
              gradient: isUnlocked
                ? const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF047857)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFF9CA3AF), Color(0xFF6B7280)],
                  ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: isUnlocked 
                    ? const Color(0xFF10B981).withOpacity(0.3)
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
                size: isSmallScreen ? 24 : 28,
              ),
            ),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              fontSize: isSmallScreen ? 18 : 20,
              fontWeight: FontWeight.bold,
              color: isUnlocked 
                ? const Color(0xFF1F2937)
                : const Color(0xFF6B7280),
            ),
          ),
          subtitle: FutureBuilder<List<Lesson>>(
            future: _fetchLessonsCount(section.id),
            builder: (context, snapshot) {
              final lessonCount = snapshot.data?.length ?? 0;
              return Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  children: [
                    Icon(
                      Icons.school,
                      size: 14,
                      color: isUnlocked ? AppTheme.primaryGreen : Colors.grey,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$lessonCount lessons',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 13 : 15,
                        color: isUnlocked ? AppTheme.greyColor : Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isCurrent) ...[
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 12 : 16, 
                    vertical: isSmallScreen ? 6 : 8
                  ),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF10B981), Color(0xFF047857)],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF10B981).withOpacity(0.3),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_circle,
                        color: Colors.white,
                        size: 16,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Active',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: isSmallScreen ? 11 : 13,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
              ],
              Icon(
                Icons.arrow_forward_ios,
                color: isUnlocked ? AppTheme.primaryGreen : Colors.grey,
                size: 16,
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
                  padding: EdgeInsets.all(isSmallScreen ? 20 : 24),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.grey.shade200,
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.lock_clock,
                        size: 32,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Locked',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Complete the previous section to unlock',
                        style: TextStyle(
                          color: Colors.grey,
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
    return FutureBuilder<List<Lesson>>(
      future: _fetchLessonsBySection(sectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Center(child: Text('Unable to load lessons'));
        }

        final lessons = snapshot.data!;
        if (lessons.isEmpty) {
          return const Center(child: Text('No lessons in this section'));
        }

        return Column(
          children: [
            ...lessons.asMap().entries.map((entry) {
              final index = entry.key;
              final lesson = entry.value;
              return _buildLessonItem(lesson, index == 0); // First lesson marked as next
            }),
            // Add exam button after lessons
            _buildExamButton(sectionId),
            // Add certificate display if available
            if (_courseCertificates != null && _courseCertificates!.isNotEmpty)
              _buildCertificateSection(),
          ],
        );
      },
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
        
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FutureBuilder<List<exam_model.Exam>>(
              future: ExamService().getExamsBySection(sectionId),
              builder: (context, snapshot) {
                if (snapshot.hasData && snapshot.data != null && snapshot.data!.isNotEmpty) {
                  final exams = snapshot.data!;
                  final isSmallScreen = MediaQuery.of(context).size.width < 600;
                  
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
                  
                  return Padding(
                    padding: EdgeInsets.only(top: isSmallScreen ? 12 : 16, bottom: 8, left: 4),
                    child: Row(
                      children: [
                        Container(
                          padding: EdgeInsets.all(isSmallScreen ? 4 : 6),
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
                            size: isSmallScreen ? 16 : 18,
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        Text(
                          sectionTitle,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.getTextColor(context),
                          ),
                        ),
                        SizedBox(width: isSmallScreen ? 6 : 8),
                        if (exams.length > 1)
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 4 : 6, 
                              vertical: isSmallScreen ? 1 : 2
                            ),
                            decoration: BoxDecoration(
                              color: sectionColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '${exams.length}',
                              style: TextStyle(
                                color: sectionColor,
                                fontSize: isSmallScreen ? 10 : 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                      ],
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
            ...exams.map((exam) {
              final isSmallScreen = MediaQuery.of(context).size.width < 600;
              Color examColor;
              IconData examIcon;
              String examTypeLabel;
              
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
                  contentPadding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                  leading: Container(
                    width: isSmallScreen ? 40 : 48,
                    height: isSmallScreen ? 40 : 48,
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
                      size: isSmallScreen ? 20 : 24,
                    ),
                  ),
                  title: Text(
                    exam.title,
                    style: TextStyle(
                      fontSize: isSmallScreen ? 14 : 16,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: isSmallScreen ? 2 : 4),
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.symmetric(
                              horizontal: isSmallScreen ? 6 : 8, 
                              vertical: isSmallScreen ? 1 : 2
                            ),
                            decoration: BoxDecoration(
                              color: examColor.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              examTypeLabel,
                              style: TextStyle(
                                color: examColor,
                                fontSize: isSmallScreen ? 9 : 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          SizedBox(width: isSmallScreen ? 4 : 8),
                          Icon(Icons.question_mark, size: isSmallScreen ? 12 : 14, color: AppTheme.greyColor),
                          SizedBox(width: isSmallScreen ? 2 : 4),
                          Text(
                            '${exam.questionsCount} questions',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                          if (exam.timeLimit > 0) ...[
                            SizedBox(width: isSmallScreen ? 4 : 8),
                            Icon(Icons.timer, size: isSmallScreen ? 12 : 14, color: AppTheme.greyColor),
                            SizedBox(width: isSmallScreen ? 2 : 4),
                            Text(
                              '${exam.timeLimit} min',
                              style: TextStyle(
                                fontSize: isSmallScreen ? 10 : 12,
                                color: AppTheme.greyColor,
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (exam.passingScore > 0)
                        Padding(
                          padding: EdgeInsets.only(top: isSmallScreen ? 2 : 4),
                          child: Text(
                            'Passing score: ${exam.passingScore}%',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 10 : 12,
                              color: AppTheme.greyColor,
                            ),
                          ),
                        ),
                    ],
                  ),
                  trailing: Icon(
                    Icons.arrow_forward_ios,
                    color: examColor,
                    size: isSmallScreen ? 14 : 16,
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
    final isSmallScreen = MediaQuery.of(context).size.width < 600;
    
    // Determine lesson type and styling
    final bool isVideoLesson = lesson.videoId != null && lesson.videoId!.isNotEmpty;
    final Color lessonTypeColor = isVideoLesson ? AppTheme.primaryGreen : AppTheme.accent;
    final Color lessonBgColor = isCompleted
        ? Colors.grey.withOpacity(0.1)
        : (isVideoLesson 
            ? AppTheme.primaryGreen.withOpacity(0.08) 
            : AppTheme.accent.withOpacity(0.08));
    final IconData lessonIcon = isVideoLesson ? Icons.play_circle_fill : Icons.article;
    final String lessonTypeLabel = isVideoLesson ? 'Video' : 'Notes';
    
    return InkWell(
      onTap: () => _viewLesson(lesson),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
        decoration: BoxDecoration(
          color: isNext 
            ? AppTheme.primaryGreen.withOpacity(0.1) 
            : lessonBgColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isCompleted
              ? Colors.grey.withOpacity(0.3)
              : (isNext 
                  ? AppTheme.primaryGreen.withOpacity(0.3) 
                  : lessonTypeColor.withOpacity(0.2)),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isNext 
                ? AppTheme.primaryGreen.withOpacity(0.1) 
                : (isCompleted 
                    ? Colors.grey.withOpacity(0.05)
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
              width: isSmallScreen ? 40 : 48,
              height: isSmallScreen ? 40 : 48,
              decoration: BoxDecoration(
                color: isCompleted
                  ? Colors.grey.withOpacity(0.3)
                  : lessonTypeColor.withOpacity(0.15),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isCompleted
                    ? Colors.grey.withOpacity(0.4)
                    : lessonTypeColor.withOpacity(0.3),
                  width: 2,
                ),
              ),
              child: Center(
                child: Icon(
                  isCompleted ? Icons.check : lessonIcon,
                  color: isCompleted ? Colors.grey : lessonTypeColor,
                  size: isSmallScreen ? 20 : 24,
                ),
              ),
            ),
            SizedBox(width: isSmallScreen ? 12 : 16),
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
                            fontSize: isSmallScreen ? 14 : 16,
                            fontWeight: isCompleted ? FontWeight.normal : FontWeight.w600,
                            color: isCompleted
                              ? Colors.grey
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
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: isSmallScreen ? 2 : 4
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
                                size: isSmallScreen ? 10 : 12,
                              ),
                              SizedBox(width: isSmallScreen ? 2 : 4),
                              Text(
                                'Completed',
                                style: TextStyle(
                                  color: Colors.green,
                                  fontSize: isSmallScreen ? 8 : 10,
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
                            horizontal: isSmallScreen ? 6 : 8, 
                            vertical: isSmallScreen ? 2 : 4
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
                              fontSize: isSmallScreen ? 8 : 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 6),
                  // Duration and additional info
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: isSmallScreen ? 12 : 14,
                        color: isCompleted ? Colors.grey : AppTheme.greyColor,
                      ),
                      SizedBox(width: isSmallScreen ? 2 : 4),
                      Text(
                        '${lesson.duration} mins',
                        style: TextStyle(
                          fontSize: isSmallScreen ? 10 : 12,
                          color: isCompleted ? Colors.grey : AppTheme.greyColor,
                        ),
                      ),
                      SizedBox(width: isSmallScreen ? 8 : 12),
                      if (isVideoLesson && !isCompleted) ...[
                        Icon(
                          Icons.hd_outlined,
                          size: isSmallScreen ? 12 : 14,
                          color: AppTheme.greyColor,
                        ),
                        SizedBox(width: isSmallScreen ? 2 : 4),
                        Text(
                          'HD Video',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ] else if (!isVideoLesson && !isCompleted) ...[
                        Icon(
                          Icons.text_snippet_outlined,
                          size: isSmallScreen ? 12 : 14,
                          color: AppTheme.greyColor,
                        ),
                        SizedBox(width: isSmallScreen ? 2 : 4),
                        Text(
                          'Text Content',
                          style: TextStyle(
                            fontSize: isSmallScreen ? 10 : 12,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(width: isSmallScreen ? 8 : 12),
            // Next indicator and arrow
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isNext && !isCompleted) ...[
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 8 : 10, 
                      vertical: isSmallScreen ? 4 : 6
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primaryGreen.withOpacity(0.3),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      'NEXT',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isSmallScreen ? 8 : 10,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                  SizedBox(height: isSmallScreen ? 4 : 8),
                ],
                Icon(
                  isCompleted ? Icons.check_circle : Icons.arrow_forward_ios,
                  color: isCompleted ? Colors.green : (isNext ? AppTheme.primaryGreen : AppTheme.greyColor),
                  size: isSmallScreen ? 16 : 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewLesson(Lesson lesson) {
    // Mark lesson as completed
    setState(() {
      _lessonCompletionStatus[lesson.id] = true;
    });
    
    // Navigate to the lesson viewer
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => LessonViewer(
          lesson: lesson,
          courseId: widget.courseId,
        ),
      ),
    );
  }

  Widget _buildCompleteSectionButton(Section section, int index) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(0.3),
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
      // Simulate API call to mark section as completed
      await Future.delayed(const Duration(seconds: 1));
      
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('🎉 "${section.title}" completed! Next section unlocked.'),
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

  Widget _buildCertificateSection() {
    if (_courseCertificates == null || _courseCertificates!.isEmpty) {
      return const SizedBox.shrink();
    }

    final certificate = _courseCertificates!.first; // Take the first certificate
    final isSmallScreen = MediaQuery.of(context).size.width < 600;

    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: EdgeInsets.all(isSmallScreen ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF10B981), Color(0xFF047857)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
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
                    fontSize: isSmallScreen ? 18 : 20,
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
              fontSize: isSmallScreen ? 12 : 14,
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
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => _downloadCertificate(certificate.id),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: const Color(0xFF10B981),
                padding: EdgeInsets.symmetric(vertical: isSmallScreen ? 12 : 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
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
                      fontSize: isSmallScreen ? 14 : 16,
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
      final downloadUrl = await certificateRepo.downloadCertificate(certificateId);
      
      // Launch the download URL
      final Uri url = Uri.parse(downloadUrl);
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        throw 'Could not launch $downloadUrl';
      }
    } catch (e) {
      print('Error downloading certificate: $e');
      if (mounted) {
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
