import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/course_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/section_repository.dart' as section_repo;
import 'package:excellence_coaching_hub/data/repositories/lesson_repository.dart' as lesson_repo;
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/models/exam.dart' as exam_model;
import 'package:excellence_coaching_hub/services/api/exam_service.dart';
import 'package:excellence_coaching_hub/widgets/lesson_viewer.dart';

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
  final Map<String, bool> _sectionCompletionStatus = {};
  bool _isLoading = true;
  bool _isCompletingSection = false;
  int _currentSectionIndex = 0;

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
        backgroundColor: AppTheme.surface,
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
      backgroundColor: AppTheme.surface,
      appBar: _buildAppBar(),
      body: _buildMainContent(),
    );
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      title: Text(
        _course!.title,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      backgroundColor: Colors.white,
      foregroundColor: AppTheme.blackColor,
      elevation: 0,
      centerTitle: false,
      actions: [
        IconButton(
          icon: const Icon(Icons.notifications_outlined),
          onPressed: () {},
        ),
        const SizedBox(width: 8),
      ],
    );
  }

  Widget _buildMainContent() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Progress header
            _buildProgressHeader(),
            
            const SizedBox(height: 24),
            
            // Sections list
            Expanded(
              child: _buildSectionsList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProgressHeader() {
    final completedSections = _sectionCompletionStatus.values.where((status) => status).length;
    final totalSections = _sections?.length ?? 0;
    final progress = totalSections > 0 ? completedSections / totalSections : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
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
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: LinearProgressIndicator(
                    value: progress,
                    backgroundColor: AppTheme.borderGrey,
                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                    minHeight: 8,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Text(
                '${(progress * 100).toInt()}%',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.primaryGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            '$completedSections of $totalSections sections completed',
            style: TextStyle(
              fontSize: 14,
              color: AppTheme.greyColor,
            ),
          ),
        ],
      ),
    );
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
    return Container(
      decoration: BoxDecoration(
        color: isUnlocked ? Colors.white : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isCurrent 
            ? AppTheme.primaryGreen.withOpacity(0.3) 
            : Colors.transparent,
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.05),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          key: ValueKey(section.id),
          initiallyExpanded: isCurrent,
          enabled: isUnlocked,
          tilePadding: const EdgeInsets.all(20),
          childrenPadding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          leading: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: isUnlocked 
                ? AppTheme.primaryGreen.withOpacity(0.1) 
                : Colors.grey.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Icon(
                isUnlocked ? Icons.lock_open : Icons.lock,
                color: isUnlocked ? AppTheme.primaryGreen : Colors.grey,
                size: 24,
              ),
            ),
          ),
          title: Text(
            section.title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isUnlocked ? AppTheme.blackColor : Colors.grey,
            ),
          ),
          subtitle: FutureBuilder<List<Lesson>>(
            future: _fetchLessonsCount(section.id),
            builder: (context, snapshot) {
              final lessonCount = snapshot.data?.length ?? 0;
              return Text(
                '$lessonCount lessons',
                style: TextStyle(
                  fontSize: 14,
                  color: isUnlocked ? AppTheme.greyColor : Colors.grey,
                ),
              );
            },
          ),
          trailing: isCurrent
            ? Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Text(
                  'Current',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              )
            : null,
          children: [
            const SizedBox(height: 8),
            if (isUnlocked) ...[
              _buildLessonsList(section.id),
              const SizedBox(height: 16),
              _buildCompleteSectionButton(section, index),
            ] else ...[
              Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Complete previous section to unlock',
                    style: TextStyle(
                      color: Colors.grey,
                      fontSize: 14,
                      fontStyle: FontStyle.italic,
                    ),
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
            }).toList(),
            // Add exam button after lessons
            _buildExamButton(sectionId),
          ],
        );
      },
    );
  }

  Widget _buildExamButton(String sectionId) {
    return FutureBuilder<List<exam_model.Exam>>(
      future: ExamService().getExamsBySection(sectionId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting || 
            snapshot.hasError || 
            snapshot.data == null ||
            snapshot.data!.isEmpty) {
          // No exams available for this section
          return const SizedBox.shrink();
        }

        final exams = snapshot.data!;
        
        return Column(
          children: exams.map((exam) {
            Color examColor;
            IconData examIcon;
            
            switch (exam.type?.toLowerCase() ?? '') {
              case 'quiz':
                examColor = Colors.blue;
                examIcon = Icons.quiz_outlined;
                break;
              case 'pastpaper':
                examColor = Colors.orange;
                examIcon = Icons.article_outlined;
                break;
              case 'final':
                examColor = Colors.red;
                examIcon = Icons.school_outlined;
                break;
              default:
                examColor = Colors.grey;
                examIcon = Icons.help_outline;
            }
            
            return Container(
              margin: const EdgeInsets.only(top: 8),
              child: ElevatedButton.icon(
                onPressed: () => _takeExam(exam),
                style: ElevatedButton.styleFrom(
                  backgroundColor: examColor.withOpacity(0.1),
                  foregroundColor: examColor,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                    side: BorderSide(color: examColor.withOpacity(0.3)),
                  ),
                ),
                icon: Icon(examIcon, size: 20),
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Take ${(exam.type ?? '').toUpperCase()} Exam',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: examColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        '${exam.questionsCount} Qs',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        );
      },
    );
  }

  void _takeExam(exam_model.Exam exam) {
    // Navigate to the exam screen
    // TODO: Implement exam taking screen
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Start ${(exam.type ?? '').toUpperCase()} Exam'),
          content: Text('Would you like to start the "${exam.title}" exam? You will have ${exam.timeLimit} minutes to complete it.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // TODO: Navigate to exam taking screen
                _navigateToExamTakingScreen(exam);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Exam'),
            ),
          ],
        );
      },
    );
  }

  void _navigateToExamTakingScreen(exam_model.Exam exam) {
    // Placeholder for exam taking screen navigation
    // In a real implementation, you would navigate to the exam taking screen
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Navigating to ${exam.type ?? ""} exam: ${exam.title}'),
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  Widget _buildLessonItem(Lesson lesson, bool isNext) {
    return InkWell(
      onTap: () => _viewLesson(lesson),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isNext 
            ? AppTheme.primaryGreen.withOpacity(0.05) 
            : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isNext 
              ? AppTheme.primaryGreen.withOpacity(0.2) 
              : Colors.transparent,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: lesson.videoId != null && lesson.videoId!.isNotEmpty
                  ? AppTheme.primaryGreen.withOpacity(0.1)
                  : AppTheme.accent.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Icon(
                  lesson.videoId != null && lesson.videoId!.isNotEmpty
                    ? Icons.play_arrow
                    : Icons.description,
                  color: lesson.videoId != null && lesson.videoId!.isNotEmpty
                    ? AppTheme.primaryGreen
                    : AppTheme.accent,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: isNext ? AppTheme.primaryGreen : AppTheme.blackColor,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${lesson.duration} mins',
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppTheme.greyColor,
                    ),
                  ),
                ],
              ),
            ),
            if (isNext)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Text(
                  'Next',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            Icon(
              Icons.arrow_forward_ios,
              color: AppTheme.greyColor,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  void _viewLesson(Lesson lesson) {
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
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: _isCompletingSection ? null : () => _completeSection(section, index),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppTheme.primaryGreen,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 0,
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
                Text('Completing...'),
              ],
            )
          : const Text(
              'Mark Section as Completed',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
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
}