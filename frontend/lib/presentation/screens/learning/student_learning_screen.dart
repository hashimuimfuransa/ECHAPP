import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/section_repository.dart' as section_repo;
import 'package:excellence_coaching_hub/data/repositories/lesson_repository.dart' as lesson_repo;
import 'package:excellence_coaching_hub/data/repositories/enrollment_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

class StudentLearningScreen extends ConsumerStatefulWidget {
  final String courseId;

  const StudentLearningScreen({super.key, required this.courseId});

  @override
  ConsumerState<StudentLearningScreen> createState() => _StudentLearningScreenState();
}

class _StudentLearningScreenState extends ConsumerState<StudentLearningScreen> {
  Course? _course;
  List<Section>? _sections;
  Map<String, dynamic>? _enrollmentData;
  final Map<String, bool> _sectionCompletionStatus = {};
  bool _isLoading = true;
  bool _isCompletingSection = false;

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
      // Load course
      final courseRepo = CourseRepository();
      _course = await courseRepo.getCourseById(widget.courseId);

      // Load sections
      final sectionRepo = section_repo.SectionRepository();
      _sections = await sectionRepo.getSectionsByCourse(widget.courseId);
      
      // Sort sections by order
      _sections?.sort((a, b) => a.order.compareTo(b.order));

      // Load enrollment data to get progress
      final enrollmentRepo = EnrollmentRepository();
      final enrolledCourses = await enrollmentRepo.getEnrolledCourses();
      final enrolledCourse = enrolledCourses.firstWhere(
        (course) => course.id == widget.courseId,
        orElse: () => Course(
          id: '',
          title: '',
          description: '',
          price: 0,
          duration: 0,
          level: '',
          isPublished: false,
          createdBy: Course.fromJson({}).createdBy,
          createdAt: DateTime.now(),
        ),
      );
      
      // Create enrollment data map
      _enrollmentData = {
        'progress': enrolledCourse.id.isNotEmpty ? 65 : 0, // Placeholder progress
        'completedLessons': [], // Will be populated from actual enrollment data
        'certificateEligible': false, // Will be checked from actual enrollment
      };
      
      // Initialize section completion status
      _initializeSectionCompletionStatus();

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
  
  void _initializeSectionCompletionStatus() {
    if (_sections == null) return;
    
    // First section is always unlocked
    if (_sections!.isNotEmpty) {
      _sectionCompletionStatus[_sections![0].id] = true;
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
        appBar: AppBar(
          title: const Text('Learning Path'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (_course == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Learning Path'),
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
        ),
        body: const Center(
          child: Text('Course not found'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(_course!.title),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.menu),
            onPressed: () => Scaffold.of(context).openEndDrawer(),
          ),
        ],
      ),
      endDrawer: _buildCourseOutline(context),
      body: _buildLearningContent(context),
    );
  }

  Widget _buildLearningContent(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Course Header
          _buildCourseHeader(),
          
          const SizedBox(height: 30),
          
          // Daily Learning Choice
          _buildDailyChoice(context),
          
          const SizedBox(height: 30),
          
          // Progress Overview
          _buildProgressOverview(),
          
          const SizedBox(height: 30),
          
          // Course Sections
          _buildCourseSections(context),
        ],
      ),
    );
  }

  Widget _buildCourseHeader() {
    if (_course == null) return const SizedBox.shrink();
    
    double progress = _enrollmentData?['progress']?.toDouble() ?? 0.0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: _course!.thumbnail != null && _course!.thumbnail!.isNotEmpty
              ? ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    _course!.thumbnail!,
                    width: 60,
                    height: 60,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.school,
                        color: AppTheme.primaryGreen,
                        size: 30,
                      );
                    },
                    loadingBuilder: (context, child, loadingProgress) {
                      if (loadingProgress == null) return child;
                      return Icon(
                        Icons.school,
                        color: AppTheme.primaryGreen,
                        size: 30,
                      );
                    },
                  ),
                )
              : Icon(
                  Icons.school,
                  color: AppTheme.primaryGreen,
                  size: 30,
                ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _course!.title,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.getTextColor(context)
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _course!.description,
                  style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 10),
                LinearProgressIndicator(
                  value: progress / 100,
                  backgroundColor: AppTheme.borderGrey,
                  valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                ),
                const SizedBox(height: 5),
                Text(
                  '\${progress.toInt()}% Complete',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyChoice(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'What would you like to learn today?',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: AppTheme.getTextColor(context)
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Choose your preferred learning method',
          style: TextStyle(
            color: AppTheme.greyColor,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 20),
        if (ResponsiveBreakpoints.isDesktop(context))
          Row(
            children: [
              Expanded(
                child: _buildLearningOption(
                  context,
                  'Watch Video',
                  'Visual learning with expert instructors',
                  Icons.video_library,
                  AppTheme.primaryGreen,
                  () => _startVideoLearning(context),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: _buildLearningOption(
                  context,
                  'Read Notes',
                  'Detailed written explanations',
                  Icons.description,
                  AppTheme.accent,
                  () => _startNotesLearning(context),
                ),
              ),
            ],
          )
        else
          Column(
            children: [
              _buildLearningOption(
                context,
                'Watch Video',
                'Visual learning with expert instructors',
                Icons.video_library,
                AppTheme.primaryGreen,
                () => _startVideoLearning(context),
              ),
              const SizedBox(height: 15),
              _buildLearningOption(
                context,
                'Read Notes',
                'Detailed written explanations',
                Icons.description,
                AppTheme.accent,
                () => _startNotesLearning(context),
              ),
              const SizedBox(height: 15),
            ],
          ),
        _buildLearningOption(
          context,
          'Take Practice Exam',
          'Test your knowledge with quizzes',
          Icons.quiz,
          Colors.orange,
          () => _startExam(context),
          isFullWidth: true,
        ),
      ],
    );
  }

  Widget _buildLearningOption(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    VoidCallback onTap, {
    bool isFullWidth = false,
  }) {
    Widget content = Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.3)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: 28,
            ),
          ),
          const SizedBox(height: 15),
          Text(
            title,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 5),
          Text(
            subtitle,
            style: const TextStyle(
              color: AppTheme.greyColor,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );

    if (isFullWidth) {
      return GestureDetector(
        onTap: onTap,
        child: content,
      );
    }

    return GestureDetector(
      onTap: onTap,
      child: content,
    );
  }

  Widget _buildProgressOverview() {
    if (_enrollmentData == null) return const SizedBox.shrink();
    
    // Calculate progress based on actual enrollment data
    final progress = _enrollmentData!['progress']?.toDouble() ?? 0.0;
    final completedLessons = _enrollmentData!['completedLessons']?.length ?? 0;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Your Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 20),
          _buildProgressItem('Overall Progress', '\${progress.toInt()}%', progress / 100, AppTheme.primaryGreen),
          const SizedBox(height: 15),
          _buildProgressItem('Completed Lessons', '\${completedLessons} lessons', completedLessons / 10.0, AppTheme.accent),
          const SizedBox(height: 15),
          // Add more progress items based on real data
          _buildProgressItem('Time Spent', '12h 30m', 0.7, Colors.orange),
          const SizedBox(height: 15),
          _buildProgressItem('Assignments Done', '8/10', 0.8, Colors.purple),
        ],
      ),
    );
  }

  Widget _buildProgressItem(String title, String value, double progress, Color color) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getTextColor(context)
                ),
              ),
              const SizedBox(height: 5),
              Text(
                value,
                style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 15),
        SizedBox(
          width: 100,
          child: LinearProgressIndicator(
            value: progress,
            backgroundColor: AppTheme.borderGrey,
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSections(BuildContext context) {
    if (_sections == null || _sections!.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
            ),
          ],
        ),
        child: const Center(
          child: Text('No sections available'),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 5,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Course Sections',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context)
            ),
          ),
          const SizedBox(height: 20),
          Column(
            children: _sections!.map((section) {
              final isUnlocked = _sectionCompletionStatus[section.id] ?? false;
              return _buildSectionItem(context, section, isUnlocked);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionItem(BuildContext context, Section section, bool isUnlocked) {
    final isCurrentSection = _sectionCompletionStatus[section.id] == true && 
                           (_sections!.indexOf(section) == 0 || 
                            _sectionCompletionStatus[_sections![_sections!.indexOf(section) - 1].id] == true);
    
    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isUnlocked ? AppTheme.primaryGreen : Colors.grey.shade300,
          width: isCurrentSection ? 2 : 1,
        ),
      ),
      child: ExpansionTile(
        initiallyExpanded: isCurrentSection,
        enabled: isUnlocked,
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isUnlocked ? AppTheme.primaryGreen : Colors.grey,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            isUnlocked ? Icons.lock_open : Icons.lock,
            color: Colors.white,
            size: 20,
          ),
        ),
        title: Text(
          'Section ${section.order + 1}: ${section.title}',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isUnlocked ? AppTheme.blackColor : Colors.grey,
          ),
        ),
        subtitle: Text(
          '${_getLessonCountForSection(section.id)} lessons',
          style: TextStyle(
            color: isUnlocked ? AppTheme.greyColor : Colors.grey,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: _buildLessonsForSection(context, section, isUnlocked),
          ),
          if (isUnlocked && isCurrentSection)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isCompletingSection ? null : () => _completeSection(section),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
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
                          SizedBox(width: 10),
                          Text('Completing...', style: TextStyle(color: Colors.white)),
                        ],
                      )
                    : const Text(
                        'Mark Section as Completed',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLessonsForSection(BuildContext context, Section section, bool isUnlocked) {
    if (!isUnlocked) {
      return const Center(
        child: Text(
          'Complete previous section to unlock lessons',
          style: TextStyle(
            color: Colors.grey,
            fontStyle: FontStyle.italic,
          ),
        ),
      );
    }

    return FutureBuilder<List<Lesson>>(
      future: _fetchLessonsBySection(section.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
          return const Text('No lessons available');
        }

        final lessons = snapshot.data!;
        if (lessons.isEmpty) {
          return const Text('No lessons in this section');
        }

        return Column(
          children: lessons.map((lesson) {
            return _buildLessonItem(
              lesson.title,
              lesson.videoId != null && lesson.videoId!.isNotEmpty ? 'video' : 'notes',
              lesson.duration,
              false, // Not showing next indicator in section view
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _completeSection(Section section) async {
    if (_isCompletingSection) return;
    
    setState(() {
      _isCompletingSection = true;
    });
    
    try {
      // Simulate API call to mark section as completed
      await Future.delayed(const Duration(seconds: 2));
      
      // Find next section and unlock it
      final currentIndex = _sections!.indexOf(section);
      if (currentIndex < _sections!.length - 1) {
        final nextSection = _sections![currentIndex + 1];
        setState(() {
          _sectionCompletionStatus[nextSection.id] = true;
        });
      }
      
      // Show success message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Section "${section.title}" completed! Next section unlocked.'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error completing section: $e'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 3),
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

  


  Future<List<Lesson>> _fetchLessonsBySection(String sectionId) async {
    try {
      final lessonRepo = lesson_repo.LessonRepository();
      return await lessonRepo.getLessonsBySection(sectionId);
    } catch (e) {
      print('Error fetching lessons for section $sectionId: $e');
      return [];
    }
  }

  Widget _buildLessonItem(String title, String type, int duration, bool isNext) {
    IconData getIconForType(String type) {
      switch (type) {
        case 'video': return Icons.video_library;
        case 'notes': return Icons.description;
        default: return Icons.article;
      }
    }

    Color getColorForType(String type) {
      switch (type) {
        case 'video': return AppTheme.primaryGreen;
        case 'notes': return AppTheme.accent;
        default: return AppTheme.greyColor;
      }
    }

    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: isNext ? AppTheme.primaryGreen.withOpacity(0.1) : AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isNext ? AppTheme.primaryGreen : AppTheme.borderGrey,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: getColorForType(type).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              getIconForType(type),
              color: getColorForType(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 15),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: isNext ? AppTheme.primaryGreen : AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '$duration mins • ${type.capitalize()}',
                  style: const TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (isNext)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Text(
                'Next',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCourseOutline(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const Text(
                  'Course Outline',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _course?.title ?? 'Loading...',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _sections != null && _sections!.isNotEmpty
              ? ListView(
                  padding: EdgeInsets.zero,
                  children: _sections!.asMap().entries.map((entry) {
                    Section section = entry.value;
                    return ListTile(
                      leading: Icon(Icons.numbers, color: AppTheme.primaryGreen),
                      title: Text('Section \${index + 1}: \${section.title}'),
                      subtitle: Text('\\${_getLessonCountForSection(section.id)} lessons'),
                      onTap: () {
                        Navigator.of(context).pop();
                        // Navigate to section
                        context.push('/learning/\${widget.courseId}/section/\${section.id}');
                      },
                    );
                  }).toList(),
                )
              : const Center(
                  child: Text('No sections available'),
                ),
          ),
        ],
      ),
    );
  }

  int _getLessonCountForSection(String sectionId) {
    // This would be implemented with a proper API call
    // For now, return a placeholder value
    return 3;
  }

  void _startVideoLearning(BuildContext context) {
    context.push('/learning/${widget.courseId}/video');
  }

  void _startNotesLearning(BuildContext context) {
    context.push('/learning/${widget.courseId}/notes');
  }

  void _startExam(BuildContext context) {
    context.push('/learning/${widget.courseId}/exam');
  }
}

// Extension to capitalize first letter
extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1).toLowerCase()}";
  }
}