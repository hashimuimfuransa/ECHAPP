import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/data/repositories/enrollment_repository.dart';
import 'package:excellence_coaching_hub/data/repositories/section_repository.dart';
import 'package:excellence_coaching_hub/models/course.dart';
import 'package:excellence_coaching_hub/models/section.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

class LearningPathScreen extends ConsumerWidget {
  const LearningPathScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning Path'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildLearningPathContent(context),
    );
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

        return _buildLearningPathGrid(context, courses);
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

  Widget _buildLearningPathGrid(BuildContext context, List<Course> courses) {
    return Padding(
      padding: ResponsiveBreakpoints.isDesktop(context)
          ? const EdgeInsets.all(32)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Text(
              'My Learning Path (${courses.length})',
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return _buildCourseCard(context, courses[index]);
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
    if (course.title!.toLowerCase().contains('beginner')) {
      progress = 0.2;
      progressText = '20% Complete';
    } else if (course.title!.toLowerCase().contains('intermediate')) {
      progress = 0.5;
      progressText = '50% Complete';
    } else if (course.title!.toLowerCase().contains('advanced')) {
      progress = 0.8;
      progressText = '80% Complete';
    } else if (course.title!.toLowerCase().contains('master')) {
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
      final sectionRepo = SectionRepository();
      return await sectionRepo.getSectionsByCourse(courseId);
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
}