import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class EnrolledCoursesScreen extends ConsumerWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Learning'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: _buildEnrolledCoursesContent(context),
    );
  }

  Widget _buildEnrolledCoursesContent(BuildContext context) {
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

        final enrolledCourses = snapshot.data ?? [];

        if (enrolledCourses.isEmpty) {
          return _buildEmptyState(context);
        }

        return _buildEnrolledCoursesGrid(context, enrolledCourses);
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
            Text(
              'No Enrolled Courses',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor
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

  Widget _buildEnrolledCoursesGrid(BuildContext context, List<Course> enrolledCourses) {
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
              'My Learning (${enrolledCourses.length})',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w600,
                color: AppTheme.blackColor,
              ),
            ),
          ),
          Expanded(
            child: ResponsiveBreakpoints.isDesktop(context)
                ? GridView.builder(
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: enrolledCourses.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(context, enrolledCourses[index], true);
                    },
                  )
                : ListView.builder(
                    itemCount: enrolledCourses.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(context, enrolledCourses[index], false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course, bool isGrid) {
    return Card(
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
        onTap: () => _viewCourse(context, course),
        child: Padding(
          padding: isGrid ? const EdgeInsets.all(16) : const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail
              Container(
                height: isGrid ? 120 : 140,
                width: double.infinity,
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
                            return Container(
                              color: AppTheme.primaryGreen.withOpacity(0.1),
                              child: Icon(
                                Icons.play_lesson,
                                color: AppTheme.primaryGreen,
                                size: 40,
                              ),
                            );
                          },
                          loadingBuilder: (context, child, loadingProgress) {
                            if (loadingProgress == null) return child;
                            return Container(
                              color: AppTheme.greyColor.withOpacity(0.1),
                              child: const Center(
                                child: CircularProgressIndicator(strokeWidth: 2),
                              ),
                            );
                          },
                        ),
                      )
                    : Container(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        child: Icon(
                          Icons.play_lesson,
                          color: AppTheme.primaryGreen,
                          size: 40,
                        ),
                      ),
              ),
              const SizedBox(height: 12),
              // Course title
              Text(
                course.title ?? 'Untitled Course',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: AppTheme.blackColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Course description
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
              // Course metadata
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.level,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppTheme.greyColor,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${course.duration}h • ${course.price == 0 ? 'Free' : 'Paid'}',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.greyColor,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      'Enrolled',
                      style: TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 10,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Continue learning button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continueLearning(context, course),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'Continue Learning',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
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

  void _viewCourse(BuildContext context, Course course) {
    // Navigate to course detail page
    context.push('/course/${course.id}', extra: course);
  }

  void _continueLearning(BuildContext context, Course course) {
    // Navigate to the student learning screen for this course
    context.pushReplacement('/learning/${course.id}', extra: {
      'courseId': course.id,
      'course': course,
    });
  }
}
