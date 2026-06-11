import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/data/repositories/enrollment_repository.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/widgets/enhanced_course_navigation.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';

final enrollmentFilterProvider = StateProvider<String>((ref) => 'all');

class EnrolledCoursesScreen extends ConsumerStatefulWidget {
  const EnrolledCoursesScreen({super.key});

  @override
  ConsumerState<EnrolledCoursesScreen> createState() => _EnrolledCoursesScreenState();
}

class _EnrolledCoursesScreenState extends ConsumerState<EnrolledCoursesScreen> {
  final LiveSessionService _liveSessionService = LiveSessionService();
  final Map<String, List<LiveSession>> _courseUpcomingSessions = {};
  Future<void>? _loadUpcomingSessionsFuture;

  @override
  Widget build(BuildContext context) {
    final filter = ref.watch(enrollmentFilterProvider);
    return _buildEnrolledCoursesContent(context, ref, filter);
  }

  Future<void> _loadUpcomingSessionsForEnrolledCourses(List<Enrollment> enrollments) async {
    if (enrollments.isEmpty) return;
    
    _courseUpcomingSessions.clear();
    
    for (final enrollment in enrollments) {
      final course = enrollment.course;
      if (course == null) continue;
      
      try {
        final response = await _liveSessionService.getCourseSessions(
          course.id,
          status: 'scheduled',
          limit: 5,
        );
        final now = DateTime.now();
        final upcoming = response.sessions.where((s) {
          return !s.isEnded &&
              !s.isCancelled &&
              s.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5)));
        }).toList();
        
        if (upcoming.isNotEmpty) {
          _courseUpcomingSessions[course.id] = upcoming;
        }
      } catch (e) {
        debugPrint('Error loading sessions for course ${course.id}: $e');
      }
    }
    
    if (mounted) {
      setState(() {});
    }
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

        // Load upcoming sessions for enrolled courses
        if (_loadUpcomingSessionsFuture == null) {
          _loadUpcomingSessionsFuture = _loadUpcomingSessionsForEnrolledCourses(allEnrollments);
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
                color: AppTheme.getTextColor(context)
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Start learning by enrolling in courses',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.getSecondaryTextColor(context),
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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Padding(
      padding: ResponsiveBreakpoints.getPadding(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Back Button
          SafeArea(
            child: Container(
              padding: EdgeInsets.symmetric(vertical: isMobile ? 12 : 16, horizontal: 4),
              child: Row(
                children: [
                  // Back Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        if (context.canPop()) {
                          context.pop();
                        } else {
                          context.go('/dashboard');
                        }
                      },
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: AppTheme.getCardColor(context),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppTheme.getSecondaryTextColor(context).withOpacity(0.15),
                            width: 1.5,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.05),
                              blurRadius: 8,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.arrow_back_ios_new_rounded,
                          color: AppTheme.getTextColor(context),
                          size: isMobile ? 18 : 20,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'My Learning',
                          style: TextStyle(
                            fontSize: isMobile ? 24 : 30,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getTextColor(context),
                            letterSpacing: -0.8,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${enrollments.length} ${enrollments.length == 1 ? 'Course' : 'Courses'}',
                            style: TextStyle(
                              fontSize: isMobile ? 12 : 13,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.primaryGreen,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildFilters(ref, activeFilter),
          const SizedBox(height: 24),
          Expanded(
            child: enrollments.isEmpty 
              ? _buildNoFilteredResults(activeFilter)
              : isMobile
                // Use ListView for all mobile screens for better responsiveness
                ? ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: _buildCourseCard(context, enrollments[index], true),
                      );
                    },
                  )
                // Use GridView for tablet and desktop only
                : GridView.builder(
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: isDesktop ? 3 : 2,
                      crossAxisSpacing: 24,
                      mainAxisSpacing: 24,
                      childAspectRatio: isDesktop ? 1.0 : 0.9,
                    ),
                    itemCount: enrollments.length,
                    itemBuilder: (context, index) {
                      return _buildCourseCard(context, enrollments[index], true);
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

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final cardPadding = isMobile ? 10.0 : 14.0;
    // Image height - compact to fit all content including button
    final imageHeight = isSmallMobile ? 90.0 : (isTablet ? 85.0 : 80.0);
    final upcomingSessions = _courseUpcomingSessions[course.id] ?? [];
    final hasUpcomingSessions = upcomingSessions.isNotEmpty;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.getCardColor(context),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.08),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppTheme.primaryGreen.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(
            color: hasUpcomingSessions 
                ? Colors.orange.withOpacity(0.5)
                : (isDark
                    ? AppTheme.darkTextSecondary.withOpacity(0.1)
                    : AppTheme.greyColor.withOpacity(0.15)),
            width: hasUpcomingSessions ? 2 : 1,
          ),
        ),
        child: Padding(
          padding: EdgeInsets.all(cardPadding),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Course thumbnail
              Stack(
                children: [
                  Container(
                    height: imageHeight,
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: NetworkImageWidget(
                              imageUrl: course.thumbnail!,
                              fit: BoxFit.cover,
                              errorWidget: Icon(
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
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (hasUpcomingSessions)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(8),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.schedule, color: Colors.white, size: 10),
                                const SizedBox(width: 3),
                                Text(
                                  '${upcomingSessions.length}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 8,
                                    fontWeight: FontWeight.w800),
                                ),
                              ],
                            ),
                          ),
                        if (hasUpcomingSessions && enrollment.isCompleted)
                          const SizedBox(width: 4),
                        if (enrollment.isCompleted)
                          Container(
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
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              // Course title
              Text(
                course.title,
                style: TextStyle(
                  fontSize: isMobile ? 14 : 16,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.getTextColor(context),
                  height: 1.2,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              // Instructor
              Text(
                course.displayInstructor,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),
              // Progress Bar
              Row(
                children: [
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: enrollment.progress / 100,
                        backgroundColor: AppTheme.greyColor.withOpacity(0.15),
                        valueColor: AlwaysStoppedAnimation<Color>(
                          enrollment.isCompleted ? AppTheme.primaryGreen : AppTheme.primaryGreen,
                        ),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${enrollment.progress.toInt()}%',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: enrollment.isCompleted
                          ? AppTheme.primaryGreen
                          : AppTheme.getTextColor(context),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Action Button
              SizedBox(
                width: double.infinity,
                height: 40,
                child: ElevatedButton(
                  onPressed: () => _continueLearning(context, enrollment),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: enrollment.isCompleted
                        ? (isDark ? AppTheme.darkCard : Colors.white)
                        : AppTheme.primaryGreen,
                    foregroundColor: enrollment.isCompleted ? AppTheme.primaryGreen : Colors.white,
                    elevation: enrollment.isCompleted ? 0 : 2,
                    side: enrollment.isCompleted 
                        ? BorderSide(color: AppTheme.primaryGreen.withOpacity(0.5), width: 1.5)
                        : null,
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    enrollment.isCompleted ? 'Review Course' : 'Continue Learning',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
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
