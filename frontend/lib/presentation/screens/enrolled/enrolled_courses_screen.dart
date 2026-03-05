import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

final enrollmentFilterProvider = StateProvider<String>((ref) => 'all');

class EnrolledCoursesScreen extends ConsumerWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filter = ref.watch(enrollmentFilterProvider);
    return _buildEnrolledCoursesContent(context, ref, filter);
  }

  Widget _buildEnrolledCoursesContent(BuildContext context, WidgetRef ref, String filter) {
    return FutureBuilder<List<Enrollment>>(
      future: _fetchEnrollments(),
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

        final allEnrollments = snapshot.data ?? [];

        if (allEnrollments.isEmpty) {
          return _buildEmptyState(context);
        }

        // Apply filter
        final filteredEnrollments = allEnrollments.where((enrollment) {
          if (filter == 'all') return true;
          return enrollment.completionStatus == filter;
        }).toList();

        return _buildEnrolledCoursesGrid(context, ref, filteredEnrollments, filter);
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

  Widget _buildEnrolledCoursesGrid(BuildContext context, WidgetRef ref, List<Enrollment> enrollments, String activeFilter) {
    return Padding(
      padding: ResponsiveBreakpoints.isDesktop(context)
          ? const EdgeInsets.all(32)
          : const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'My Learning (${enrollments.length})',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildFilters(ref, activeFilter),
          const SizedBox(height: 24),
          Expanded(
            child: enrollments.isEmpty 
              ? _buildNoFilteredResults(activeFilter)
              : !ResponsiveBreakpoints.isMobile(context)
                ? GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: ResponsiveBreakpoints.isDesktop(context) ? 3 : 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: ResponsiveBreakpoints.isDesktop(context) ? 0.75 : 0.72,
                    ),
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(context, enrollments[index], true);
                    },
                  )
                : ListView.builder(
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(context, enrollments[index], false),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(WidgetRef ref, String activeFilter) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _filterChip(ref, 'All', 'all', activeFilter == 'all'),
          const SizedBox(width: 8),
          _filterChip(ref, 'In Progress', 'in-progress', activeFilter == 'in-progress'),
          const SizedBox(width: 8),
          _filterChip(ref, 'Completed', 'completed', activeFilter == 'completed'),
        ],
      ),
    );
  }

  Widget _filterChip(WidgetRef ref, String label, String value, bool isSelected) {
    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        ref.read(enrollmentFilterProvider.notifier).state = value;
      },
      selectedColor: AppTheme.primaryGreen.withOpacity(0.2),
      checkmarkColor: AppTheme.primaryGreen,
      labelStyle: TextStyle(
        color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
      backgroundColor: Colors.transparent,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.3),
        ),
      ),
    );
  }

  Widget _buildNoFilteredResults(String filter) {
    String message = 'No courses found';
    if (filter == 'completed') message = 'No completed courses yet';
    if (filter == 'in-progress') message = 'No courses in progress';
    
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.search_off, size: 48, color: AppTheme.greyColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(message, style: TextStyle(color: AppTheme.greyColor, fontSize: 16)),
        ],
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Enrollment enrollment, bool isGrid) {
    final course = enrollment.course;
    if (course == null) return const SizedBox.shrink();

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
        onTap: () => _viewCourse(context, enrollment),
        child: Padding(
          padding: isGrid ? const EdgeInsets.all(16) : const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail
              Stack(
                children: [
                  Container(
                    height: isGrid ? 100 : 120,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              course.thumbnail!,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.play_lesson,
                                color: AppTheme.primaryGreen,
                                size: 40,
                              ),
                            ),
                          )
                        : Icon(
                            Icons.play_lesson,
                            color: AppTheme.primaryGreen,
                            size: 40,
                          ),
                  ),
                  if (enrollment.isCompleted)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppTheme.primaryGreen,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'Completed',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              // Course title
              Text(
                course.title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Instructor
              Text(
                'By ${course.displayInstructor}',
                style: TextStyle(
                  fontSize: 11,
                  color: AppTheme.greyColor,
                ),
              ),
              const Spacer(),
              // Progress Bar
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        enrollment.isCompleted ? 'Completed' : '${enrollment.progress.toInt()}% Complete',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: enrollment.isCompleted ? AppTheme.primaryGreen : AppTheme.greyColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: enrollment.progress / 100,
                      backgroundColor: AppTheme.greyColor.withOpacity(0.1),
                      valueColor: AlwaysStoppedAnimation<Color>(
                        enrollment.isCompleted ? AppTheme.primaryGreen : AppTheme.primaryGreen.withOpacity(0.7),
                      ),
                      minHeight: 6,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => _continueLearning(context, enrollment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enrollment.isCompleted ? Colors.white : AppTheme.primaryGreen,
                    foregroundColor: enrollment.isCompleted ? AppTheme.primaryGreen : Colors.white,
                    elevation: 0,
                    side: enrollment.isCompleted ? BorderSide(color: AppTheme.primaryGreen) : null,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    enrollment.isCompleted ? 'Review Course' : 'Continue Learning',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
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

  Future<List<Enrollment>> _fetchEnrollments() async {
    try {
      final enrollmentRepo = EnrollmentRepository();
      return await enrollmentRepo.getEnrollments();
    } catch (e) {
      print('Error fetching enrollments: $e');
      return [];
    }
  }

  void _viewCourse(BuildContext context, Enrollment enrollment) {
    _continueLearning(context, enrollment);
  }

  void _continueLearning(BuildContext context, Enrollment enrollment) {
    if (enrollment.course == null) return;
    
    context.push('/learning/${enrollment.courseId}', extra: {
      'courseId': enrollment.courseId,
      'course': enrollment.course,
      'enrollment': enrollment,
    });
  }
}
