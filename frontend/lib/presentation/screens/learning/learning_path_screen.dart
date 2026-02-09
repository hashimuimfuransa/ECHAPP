import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/enrollment_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/section_repository.dart' as section_repo;
import 'package:excellence_coaching_hub/data/repositories/lesson_repository.dart' as lesson_repo;
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/models/lesson.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';
import 'package:excellence_coaching_hub/widgets/lesson_viewer.dart';

class LearningPathScreen extends ConsumerStatefulWidget {
  const LearningPathScreen({super.key});

  @override
  ConsumerState<LearningPathScreen> createState() => _LearningPathScreenState();
}

class _LearningPathScreenState extends ConsumerState<LearningPathScreen> {
  final lesson_repo.LessonRepository _lessonRepository = lesson_repo.LessonRepository();
  final section_repo.SectionRepository _sectionRepository = section_repo.SectionRepository();
  String? _selectedLessonId;
  Lesson? _selectedLesson;
  String? _selectedCourseId;
  bool _showLessonViewer = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Path'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (_showLessonViewer)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _closeLessonViewer,
            ),
        ],
      ),
      body: _showLessonViewer && _selectedLessonId != null
          ? _buildLessonViewer(_selectedLessonId!)
          : _buildLearningPathContent(context),
    );
  }

  void _closeLessonViewer() {
    setState(() {
      _showLessonViewer = false;
      _selectedLessonId = null;
    });
  }

  void _openLessonViewer(String lessonId, Lesson lesson, String courseId) {
    setState(() {
      _selectedLessonId = lessonId;
      _selectedLesson = lesson;
      _selectedCourseId = courseId;
      _showLessonViewer = true;
    });
  }

  Widget _buildLearningPathContent(BuildContext context) {
    return FutureBuilder<List<Course>>(
      future: _fetchEnrolledCourses(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: CircularProgressIndicator(),
          );
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        final courses = snapshot.data ?? [];

        if (courses.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildSummarizedLearningPath(context, courses);
      },
    );
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.school_outlined,
              size: 80,
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Active Courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start learning by enrolling in courses',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () => context.push('/courses'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGreen,
                padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                'Browse Courses',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSummarizedLearningPath(BuildContext context, List<Course> courses) {
    return Padding(
      padding: ResponsiveBreakpoints.isDesktop(context)
          ? const EdgeInsets.all(32)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Learning Path',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.blackColor,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${courses.length} courses enrolled',
                  style: TextStyle(
                    fontSize: 16,
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: FutureBuilder<List<Section>>(
              future: _fetchAllSections(courses),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                
                final allSections = snapshot.data ?? [];
                
                if (allSections.isEmpty) {
                  return _buildEmptySectionsState(context);
                }
                
                return _buildSectionsSummaryList(context, allSections, courses);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: AppTheme.greyColor.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _viewCourseDetails(context, course),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  // Course thumbnail
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        width: 1,
                      ),
                    ),
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(11),
                            child: Image.network(
                              course.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.play_lesson,
                                  color: AppTheme.primaryGreen,
                                  size: 32,
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: AppTheme.greyColor.withOpacity(0.1),
                                  child: Icon(
                                    Icons.play_lesson,
                                    color: AppTheme.primaryGreen,
                                    size: 32,
                                  ),
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.play_lesson,
                            color: AppTheme.primaryGreen,
                            size: 32,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title ?? 'Untitled Course',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.blackColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          course.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: AppTheme.greyColor,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _buildCourseProgress(course),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              _buildCourseSections(course),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCourseProgress(Course course) {
    // In a real implementation, this would come from enrollment data
    double progress = 0.0;
    String progressText = 'Not started';
    
    // For now, simulate progress based on course title
    if (course.title.toLowerCase().contains('beginner')) {
      progress = 0.2;
      progressText = '20% Complete';
    } else if (course.title.toLowerCase().contains('intermediate')) {
      progress = 0.5;
      progressText = '50% Complete';
    } else if (course.title.toLowerCase().contains('advanced')) {
      progress = 0.8;
      progressText = '80% Complete';
    } else if (course.title.toLowerCase().contains('master')) {
      progress = 1.0;
      progressText = 'Completed';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LinearProgressIndicator(
          value: progress,
          backgroundColor: AppTheme.borderGrey,
          valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
        ),
        const SizedBox(height: 4),
        Text(
          progressText,
          style: TextStyle(
            fontSize: 12,
            color: progress >= 1.0 ? AppTheme.primaryGreen : AppTheme.greyColor,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildCourseSections(Course course) {
    return FutureBuilder<List<Section>>(
      future: _fetchCourseSections(course.id),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 20,
            child: LinearProgressIndicator(),
          );
        }

        final sections = snapshot.data ?? [];
        if (sections.isEmpty) {
          return const SizedBox();
        }

        return Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sections.take(3).map((section) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  section.title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              );
            }).toList()
              ..addAll([
                if (sections.length > 3)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppTheme.greyColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '+${sections.length - 3} more',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppTheme.greyColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  )
              ]),
          ),
        );
      },
    );
  }

  Future<List<Course>> _fetchEnrolledCourses() async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      return await enrollmentRepo.getEnrolledCourses();
    } catch (e) {
      print('Error fetching enrolled courses: $e');
      return [];
    }
  }

  Future<List<Section>> _fetchCourseSections(String courseId) async {
    try {
      return await _sectionRepository.getSectionsByCourse(courseId);
    } catch (e) {
      print('Error fetching sections for course $courseId: $e');
      return [];
    }
  }

  void _viewCourseDetails(BuildContext context, Course course) {
    // Navigate to the student learning screen for this course
    context.push('/learning/${course.id}', extra: {
      'courseId': course.id,
      'course': course,
    });
  }

  Future<List<Section>> _fetchAllSections(List<Course> courses) async {
    try {
      final allSections = <Section>[];
      
      for (var course in courses) {
        final sections = await _sectionRepository.getSectionsByCourse(course.id);
        allSections.addAll(sections);
      }
      
      // Sort sections by course and order
      allSections.sort((a, b) {
        final courseComparison = courses.indexWhere((c) => c.id == a.courseId)
            .compareTo(courses.indexWhere((c) => c.id == b.courseId));
        if (courseComparison != 0) return courseComparison;
        return a.order.compareTo(b.order);
      });
      
      return allSections;
    } catch (e) {
      print('Error fetching all sections: $e');
      return [];
    }
  }

  Widget _buildEmptySectionsState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_books_outlined,
              size: 80,
              color: AppTheme.greyColor.withOpacity(0.3),
            ),
            const SizedBox(height: 24),
            const Text(
              'No Course Sections',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Your enrolled courses don\'t have any sections yet',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionsSummaryList(BuildContext context, List<Section> sections, List<Course> courses) {
    return ListView.builder(
      itemCount: sections.length,
      itemBuilder: (context, index) {
        final section = sections[index];
        final course = courses.firstWhere((c) => c.id == section.courseId, orElse: () => Course(
          id: '',
          title: '',
          description: '',
          price: 0,
          duration: 0,
          level: '',
          isPublished: false,
          createdBy: Course.fromJson({}).createdBy,
          createdAt: DateTime.now(),
        ));
        
        return _buildSectionSummaryItem(context, section, course);
      },
    );
  }

  Widget _buildSectionSummaryItem(BuildContext context, Section section, Course course) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: AppTheme.greyColor.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section header
          InkWell(
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            onTap: () => _navigateToSection(context, section, course),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Course thumbnail
                  Container(
                    width: 50,
                    height: 50,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(9),
                            child: Image.network(
                              course.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Icon(
                                  Icons.play_lesson,
                                  color: AppTheme.primaryGreen,
                                  size: 24,
                                );
                              },
                            ),
                          )
                        : Icon(
                            Icons.play_lesson,
                            color: AppTheme.primaryGreen,
                            size: 24,
                          ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title ?? 'Untitled Course',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.greyColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          section.title,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.blackColor,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        FutureBuilder<List<Lesson>>(
                          future: _getSectionLessons(section.id),
                          builder: (context, snapshot) {
                            final lessons = snapshot.data ?? [];
                            return Text(
                              '${lessons.length} lessons',
                              style: TextStyle(
                                fontSize: 12,
                                color: AppTheme.greyColor,
                              ),
                            );
                          },
                        ),
                      ],
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
          ),
          // Lessons list
          FutureBuilder<List<Lesson>>(
            future: _getSectionLessons(section.id),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.all(16),
                  child: LinearProgressIndicator(),
                );
              }
              
              final lessons = snapshot.data ?? [];
              if (lessons.isEmpty) {
                return const SizedBox.shrink();
              }
              
              return Container(
                decoration: BoxDecoration(
                  color: AppTheme.greyColor.withOpacity(0.03),
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                ),
                child: Column(
                  children: lessons.map((lesson) => _buildLessonItem(context, lesson, section, course)).toList(),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildLessonItem(BuildContext context, Lesson lesson, Section section, Course course) {
    return InkWell(
      onTap: () => _openLessonViewer(lesson.id, lesson, course.id),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Lesson type icon
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                lesson.videoId != null ? Icons.play_circle : Icons.article,
                color: AppTheme.primaryGreen,
                size: 20,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    lesson.title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.blackColor,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (lesson.description != null && lesson.description!.isNotEmpty)
                    Text(
                      lesson.description!,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.greyColor,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            // Duration if available
            if (lesson.duration > 0)
              Text(
                '${(lesson.duration ~/ 60)}:${(lesson.duration % 60).toString().padLeft(2, '0')}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppTheme.greyColor,
                ),
              ),
            const SizedBox(width: 8),
            Icon(
              Icons.play_arrow,
              color: AppTheme.primaryGreen,
              size: 16,
            ),
          ],
        ),
      ),
    );
  }

  Future<List<Lesson>> _getSectionLessons(String sectionId) async {
    try {
      return await _lessonRepository.getLessonsBySection(sectionId);
    } catch (e) {
      print('Error fetching lessons for section $sectionId: $e');
      return [];
    }
  }

  void _navigateToSection(BuildContext context, Section section, Course course) {
    // Navigate to the specific section in the learning screen
    context.push('/learning/${course.id}', extra: {
      'courseId': course.id,
      'sectionId': section.id,
      'course': course,
    });
  }

  Widget _buildLessonViewer(String lessonId) {
    if (_selectedLesson == null || _selectedCourseId == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return LessonViewer(
      lesson: _selectedLesson!,
      courseId: _selectedCourseId!,
    );
  }
}