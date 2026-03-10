import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX #11: Added for Clipboard.setData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/wishlist_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/models/payment_status.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/widgets/downloads_section.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  _DashboardScreenState createState() => _DashboardScreenState();
}

// Device binding policy widget for dashboard
class _DashboardDeviceBindingPolicy extends StatelessWidget {
  const _DashboardDeviceBindingPolicy();
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF431407).withOpacity(0.3) : const Color(0xFFFFF7ED), // Very light orange/cream
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF7C2D12).withOpacity(0.4) : const Color(0xFFFFEDD5), // Light orange border
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.error_outline_rounded,
            color: isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316), // Orange icon
            size: 22,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Device Security: Your account is secured to this device for your protection. Contact support to change devices.',
              style: TextStyle(
                color: isDark ? const Color(0xFFFFEDD5).withOpacity(0.9) : const Color(0xFF92400E), // Brownish orange text
                fontSize: 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Stat item widget for statistics dialog
class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  
  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: color.withOpacity(0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, color: color, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.getSecondaryTextColor(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> with SingleTickerProviderStateMixin {
  bool _hasCheckedRole = false;
  Timer? _autoRefreshTimer;
  AnimationController? _animationController;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void initState() {
    super.initState();
    // Clear notifications and badges when app is opened
    PushNotificationService.clearNotifications();
    
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    // Start auto-refresh timer to check payment status periodically
    _startAutoRefresh();
    
    // Play entrance animation
    _animationController?.forward();
  }

  void _startAutoRefresh() {
    // Check payment status every 10 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 10), (timer) {
      _refreshPaymentStatus();
    });
  }

  void _refreshPaymentStatus() {
    // Refresh user payments to check for status updates
    ref.read(paymentProvider.notifier).loadUserPayments();
    // Also refresh enrolled courses to update UI if payment was approved
    ref.invalidate(enrolledCoursesProvider);
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _animationController?.dispose();
    super.dispose();
  }

  // FIX #10: Removed duplicate _checkUserRole call from didUpdateWidget.
  // didChangeDependencies already handles re-checks; calling it from
  // didUpdateWidget too caused redundant checks on every widget rebuild.

  void _checkUserRole() {
    if (!_hasCheckedRole) {
      final authState =
          ref.read(authProvider); // use read, not watch, outside build
      if (authState.user != null && !authState.isLoading) {
        _hasCheckedRole = true;
        debugPrint(
            'DashboardScreen: Checking user role - ${authState.user?.role}');

        if (authState.user?.role == 'admin') {
          debugPrint(
              'DashboardScreen: Admin detected, redirecting to admin dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/admin');
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authProvider).user;
    final enrolledCoursesAsync = ref.watch(enrolledCoursesProvider);
    final userEnrollmentsAsync = ref.watch(userEnrollmentsProvider);
    final popularCoursesAsync = ref.watch(popularCoursesProvider);
    final recommendedCoursesAsync = ref.watch(recommendedCoursesProvider);

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop 
        ? const EdgeInsets.fromLTRB(40, 24, 40, 40)
        : ResponsiveBreakpoints.getPadding(context);

    return Scaffold(
      backgroundColor: Colors.transparent, // Let MainLayout background show through
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: SingleChildScrollView(
              padding: padding,
              child: Center(
                child: Container(
                  constraints: BoxConstraints(
                    maxWidth: isDesktop ? 1300 : double.infinity,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildCategoryFilters(context),
                      userEnrollmentsAsync.when(
                        data: (enrollments) => _buildWelcomeCard(context, user, enrollments),
                        loading: () => _buildWelcomeCard(context, user, []),
                        error: (_, __) => _buildWelcomeCard(context, user, []),
                      ),
                      const SizedBox(height: 24),
                      const _DashboardDeviceBindingPolicy(),
                      const SizedBox(height: 32),
                      if (ref.watch(authProvider.notifier).isAdmin) ...[
                        _buildAdminAccessButton(context),
                        const SizedBox(height: 32),
                      ],
                      userEnrollmentsAsync.when(
                        data: (enrollments) =>
                            _buildLearningAndOnboarding(context, enrollments),
                        loading: () => _buildLoadingCard(context, 'Continue Learning'),
                        error: (error, stack) => _buildErrorCard(
                            context, 'Continue Learning', error.toString()),
                      ),
                      const SizedBox(height: 32),
                      _buildResponsiveQuickActions(context),
                      const SizedBox(height: 32),
                      recommendedCoursesAsync.when(
                        data: (recommendedCourses) => enrolledCoursesAsync.when(
                          data: (enrolledCourses) => _buildRecommendedCourses(
                            context, 
                            recommendedCourses.isNotEmpty 
                                ? recommendedCourses 
                                : (popularCoursesAsync.value ?? []), 
                            enrolledCourses
                          ),
                          loading: () => _buildRecommendedCourses(context, recommendedCourses, []),
                          error: (_, __) => _buildRecommendedCourses(context, recommendedCourses, []),
                        ),
                        loading: () => _buildLoadingCard(context, 'Recommended Courses'),
                        error: (error, stack) => _buildErrorCard(
                            context, 'Recommended Courses', error.toString()),
                      ),
                      const SizedBox(height: 32),
                      popularCoursesAsync.when(
                        data: (popularCourses) => enrolledCoursesAsync.when(
                          data: (enrolledCourses) => _buildResponsivePopularCourses(context, popularCourses, enrolledCourses),
                          loading: () => _buildResponsivePopularCourses(context, popularCourses, []),
                          error: (_, __) => _buildResponsivePopularCourses(context, popularCourses, []),
                        ),
                        loading: () => _buildLoadingCard(context, 'Popular Courses'),
                        error: (error, stack) => _buildErrorCard(
                            context, 'Popular Courses', error.toString()),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showContactInfoDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 8,
        icon: const Icon(Icons.contact_support, size: 24),
        label: const Text('Contact Us',
            style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
    );
  }

  // FIX #6: Extracted refresh logic into a dedicated method to cleanly
  // discard provider refresh futures without the warning-suppression no-op pattern.
  Future<void> _refreshDashboard() async {
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(userEnrollmentsProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(recommendedCoursesProvider);
  }

  void _showStatsDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Row(
            children: [
              Icon(Icons.auto_graph, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text('Learning Statistics'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatItem(
                icon: Icons.school,
                label: 'Courses Enrolled',
                value: '5',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.play_circle,
                label: 'Lessons Completed',
                value: '24',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.quiz,
                label: 'Exams Taken',
                value: '8',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.access_time,
                label: 'Hours Learned',
                value: '12.5',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  Color _getCategoryColor(String categoryId) {
    switch (categoryId) {
      case 'academic_coaching':
        return const Color(0xFF10B981); // Emerald/Green
      case 'language_coaching':
        return const Color(0xFF8B5CF6); // Purple
      case 'business_entrepreneurship':
        return const Color(0xFFEF4444); // Red
      case 'technical_digital':
        return const Color(0xFF06B6D4); // Cyan
      case 'professional_coaching':
      case 'job_seeker':
        return const Color(0xFF3B82F6); // Blue
      case 'personal_corporate':
        return const Color(0xFFF59E0B); // Amber
      case 'all':
        return const Color(0xFF10B981);
      default:
        return AppTheme.primary;
    }
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);

    return Container(
      height: 44,
      margin: const EdgeInsets.only(bottom: 20),
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          padding: EdgeInsets.zero,
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final category = isFirst ? null : categories[index - 1];
            final color = _getCategoryColor(isFirst ? 'all' : category!.id);
            final name = isFirst ? 'All Courses' : category!.name;
            final icon = isFirst ? '📚' : (category!.icon ?? '📚');

            return Padding(
              padding: const EdgeInsets.only(right: 12),
              child: InkWell(
                onTap: () {
                  context.push('/courses', extra: {
                    'categoryId': isFirst ? 'all' : category!.id,
                    'categoryName': name,
                  });
                },
                borderRadius: BorderRadius.circular(10),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.15),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(icon, style: const TextStyle(fontSize: 16)),
                      const SizedBox(width: 10),
                      Text(
                        name,
                        style: TextStyle(
                          color: color.withOpacity(0.9),
                          fontWeight: FontWeight.w600,
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final lastEnrollment = enrollments.isNotEmpty ? enrollments.first : null;
    final lastCourse = lastEnrollment?.course;
    
    // Calculate average progress
    double averageProgress = 0;
    if (enrollments.isNotEmpty) {
      double totalProgress = enrollments.fold(0, (sum, e) => sum + e.progress);
      averageProgress = totalProgress / enrollments.length;
    }
    
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF10B981), // Emerald
            Color(0xFF0EA5E9), // Sky Blue
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(isMobile ? 20 : 24),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF10B981).withOpacity(isDark ? 0.3 : 0.2),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Decorative shapes
          Positioned(
            right: -20,
            top: -20,
            child: Container(
              width: isMobile ? 100 : 150,
              height: isMobile ? 100 : 150,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(isDesktop ? 24 : (isSmallMobile ? 16 : 20)),
            child: Row(
              children: [
                Expanded(
                  flex: isDesktop ? 2 : 1,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: EdgeInsets.all(isSmallMobile ? 8 : 12),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(isSmallMobile ? 12 : 16),
                            ),
                            child: Icon(
                              Icons.school_rounded, 
                              color: Colors.white, 
                              size: isSmallMobile ? 22 : 28
                            ),
                          ),
                          SizedBox(width: isSmallMobile ? 12 : 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Hello, ${user?.fullName?.split(" ")[0].toLowerCase() ?? 'student'}!',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: isSmallMobile ? 20 : (isMobile ? 24 : 28),
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -0.5,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                Text(
                                  'Ready to continue your learning journey?',
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.9),
                                    fontSize: isSmallMobile ? 12 : 14,
                                    fontWeight: FontWeight.w500,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      // Expiration Countdown for current course
                      if (lastEnrollment != null && lastEnrollment.accessExpirationDate != null)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16),
                          child: CountdownTimer(
                            expirationDate: lastEnrollment.accessExpirationDate,
                            textColor: Colors.white,
                            backgroundColor: Colors.white.withOpacity(0.2),
                            showSeconds: true,
                          ),
                        ),
                      // Last Lesson Widget
                      if (lastCourse != null)
                        InkWell(
                          onTap: () => CourseNavigationUtils.navigateToCourseWithContext(context, ref, lastCourse),
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_fill, color: Colors.white, size: 18),
                                const SizedBox(width: 8),
                                Flexible(
                                  child: Text(
                                    'Last lesson: ${lastCourse.title}',
                                    style: const TextStyle(
                                      color: Colors.white, 
                                      fontSize: 13, 
                                      fontWeight: FontWeight.w600
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.7), size: 18),
                              ],
                            ),
                          ),
                        )
                      else
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lightbulb_rounded, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Flexible(
                                child: Text(
                                  'Start a new course today!',
                                  style: const TextStyle(
                                    color: Colors.white, 
                                    fontSize: 13, 
                                    fontWeight: FontWeight.w600
                                  ),
                                  maxLines: 2,
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 24),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          ElevatedButton(
                            onPressed: () => context.push('/my-courses'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF0F766E),
                              elevation: 0,
                              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                            ),
                            child: const Text('My Courses', style: TextStyle(fontWeight: FontWeight.w800)),
                          ),
                          TextButton(
                            onPressed: () => context.push('/courses'),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
                            ),
                            child: const Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Browse All', style: TextStyle(fontWeight: FontWeight.w700)),
                                SizedBox(width: 4),
                                Icon(Icons.chevron_right_rounded, size: 20),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (isDesktop) ...[
                  const SizedBox(width: 24),
                  Container(
                    width: 280,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [
                        BoxShadow(color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.05), blurRadius: 10),
                      ],
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${averageProgress.toInt()}% Completed',
                                style: TextStyle(
                                  fontSize: 15, 
                                  fontWeight: FontWeight.w700, 
                                  color: isDark ? Colors.white : const Color(0xFF333333),
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildWelcomeStatItem(context, Icons.school, '${enrollments.length} Courses', 'Enrolled', const Color(0xFF10B981)),
                              const SizedBox(height: 12),
                              _buildWelcomeStatItem(context, Icons.access_time_filled, '0h 00m', 'Hours Learned', const Color(0xFF06B6D4)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 16),
                        _buildCircularProgress(context, averageProgress),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeStatItem(BuildContext context, IconData icon, String value, String label, Color color) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
          child: Icon(icon, color: color, size: 16),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                fontSize: 13, 
                fontWeight: FontWeight.w800, 
                color: isDark ? Colors.white : const Color(0xFF333333), 
                height: 1.1,
              )),
              Text(label, style: TextStyle(
                fontSize: 11, 
                color: isDark ? Colors.white70 : const Color(0xFF9CA3AF), 
                height: 1.1,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context, double progress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 70,
          height: 70,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: 8,
            backgroundColor: isDark ? Colors.white.withOpacity(0.1) : const Color(0xFFF3F4F6),
            valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF10B981)),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${progress.toInt()}%', style: TextStyle(
              fontSize: 16, 
              fontWeight: FontWeight.w800, 
              color: isDark ? Colors.white : const Color(0xFF333333),
            )),
            Text('Completed', style: TextStyle(
              fontSize: 8, 
              color: isDark ? Colors.white70 : const Color(0xFF9CA3AF),
            )),
          ],
        ),
      ],
    );
  }


  Widget _buildAdminAccessButton(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primaryGreen, Color(0xFF00cdac)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00cdac).withValues(alpha: 0.3), // FIX #8
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.2), // FIX #8
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.admin_panel_settings,
                  color: AppTheme.whiteColor, size: 28),
            ),
            const SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Admin Panel',
                      style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 5),
                  Text('Manage courses, students, and platform settings',
                      style: TextStyle(
                          color: AppTheme.whiteColor.withValues(alpha: 0.9),
                          fontSize: 14)), // FIX #8
                ],
              ),
            ),
            Container(
              decoration: BoxDecoration(
                  color: AppTheme.whiteColor,
                  borderRadius: BorderRadius.circular(12)),
              child: IconButton(
                icon: Icon(Icons.arrow_forward, color: AppTheme.primaryGreen),
                onPressed: () => context.push('/admin'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // FIX #4: Removed unused _buildQuickActions (non-responsive version).
  // Only _buildResponsiveQuickActions is kept since it's the only one referenced.

  Widget _buildResponsiveQuickActions(BuildContext context) {
    final actions = [
      {
        'title': 'My Learning',
        'subtitle': 'Continue learning',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981), // Solid Emerald
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': 'Downloaded',
        'subtitle': 'Offline videos',
        'icon': Icons.file_download_done_rounded,
        'color': const Color(0xFF3B82F6), // Solid Blue
        'onTap': () => context.push('/downloads'),
      },
      {
        'title': 'Exams History',
        'subtitle': 'View results',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF8B5CF6), // Solid Purple
        'onTap': () => context.push('/exams/history'),
      },
      {
        'title': 'Certificates',
        'subtitle': 'Your awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFFF59E0B), // Solid Amber
        'onTap': () => context.push('/certificates'),
      },
    ];

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 2 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'New',
                style: TextStyle(
                  color: AppTheme.primaryGreen,
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isDesktop ? 20 : 16,
            mainAxisSpacing: isDesktop ? 20 : 16,
            childAspectRatio: isDesktop ? 1.6 : 1.4,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            
            // Staggered entrance animation with safe controller access
            final animation = _animationController != null 
              ? CurvedAnimation(
                  parent: _animationController!,
                  curve: Interval(
                    (index / actions.length) * 0.5,
                    0.5 + (index / actions.length) * 0.5,
                    curve: Curves.easeOutBack,
                  ),
                )
              : const AlwaysStoppedAnimation(1.0);

            return ScaleTransition(
              scale: animation,
              child: FadeTransition(
                opacity: animation,
                child: _buildResponsiveActionCard(
                  context,
                  action['title'] as String,
                  action['subtitle'] as String,
                  action['icon'] as IconData,
                  action['color'] as Color,
                  action['onTap'] as Function,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveActionCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, Function onTap) {
    return _QuickAccessCard(
      title: title,
      subtitle: subtitle,
      icon: icon,
      color: color,
      onTap: onTap,
    );
  }

  Widget _buildLearningAndOnboarding(BuildContext context, List<Enrollment> enrollments) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    if (isDesktop) {
      return Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: _buildContinueLearning(context, enrollments)),
          const SizedBox(width: 32),
          Expanded(child: _buildGetStarted(context)),
        ],
      );
    } else {
      return Column(
        children: [
          _buildContinueLearning(context, enrollments),
          const SizedBox(height: 32),
          _buildGetStarted(context),
        ],
      );
    }
  }

  Widget _buildGetStarted(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = !isDesktop && !ResponsiveBreakpoints.isTablet(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Get Started',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          height: 200,
          decoration: BoxDecoration(
            color: AppTheme.getCardColor(context),
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: isDark 
                  ? Colors.white.withOpacity(0.1) 
                  : const Color(0xFFF3F4F6),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark 
                    ? Colors.black.withOpacity(0.3) 
                    : Colors.black.withOpacity(0.02),
                blurRadius: 10,
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                right: isMobile ? -20 : 0,
                bottom: isMobile ? -10 : 0,
                top: isMobile ? null : 0,
                child: Opacity(
                  opacity: isMobile ? 0.4 : 1.0,
                  child: Image.asset(
                    'assets/get started.png',
                    height: isMobile ? 140 : null,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Start learning today',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: isMobile ? double.infinity : 200,
                      child: Text(
                        'Begin your learning journey with one of our recommended courses.',
                        style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context),
                          height: 1.4,
                        ),
                      ),
                    ),
                    const Spacer(),
                    ElevatedButton(
                      onPressed: () => context.push('/courses'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor:
                            isDark ? const Color(0xFF334155) : Colors.white,
                        foregroundColor:
                            isDark ? Colors.white : const Color(0xFF1F2937),
                        elevation: 0,
                        side: BorderSide(
                            color: isDark
                                ? const Color(0xFF475569)
                                : const Color(0xFFE5E7EB)),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('Browse Courses',
                              style: TextStyle(fontWeight: FontWeight.w700)),
                          SizedBox(width: 8),
                          Icon(Icons.chevron_right_rounded, size: 18),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildContinueLearning(
      BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isMobile = !isDesktop && !isTablet;
    
    if (enrollments.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Learning',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            width: double.infinity,
            height: 200,
            decoration: BoxDecoration(
              color: AppTheme.getCardColor(context),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isDark 
                    ? Colors.white.withOpacity(0.1) 
                    : const Color(0xFFF3F4F6),
              ),
              boxShadow: [
                BoxShadow(
                  color: isDark 
                      ? Colors.black.withOpacity(0.3) 
                      : Colors.black.withOpacity(0.02), 
                  blurRadius: 10,
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  right: isMobile ? -20 : 0,
                  bottom: isMobile ? -10 : 0,
                  top: isMobile ? null : 0,
                  child: Opacity(
                    opacity: isMobile ? 0.4 : 1.0,
                    child: Image.asset(
                      'assets/continue learning.png',
                      height: isMobile ? 140 : null,
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'No active courses yet',
                        style: TextStyle(
                          fontSize: 18, 
                          fontWeight: FontWeight.w700, 
                          color: AppTheme.getTextColor(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: isMobile ? double.infinity : 200,
                        child: Text(
                          'Enroll in a course to start learning.',
                          style: TextStyle(
                            color: AppTheme.getSecondaryTextColor(context), 
                            fontSize: 14, 
                            height: 1.4,
                          ),
                        ),
                      ),
                      const Spacer(),
                      ElevatedButton(
                        onPressed: () => context.push('/courses'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text('Browse Courses', style: TextStyle(fontWeight: FontWeight.w700)),
                            SizedBox(width: 8),
                            Icon(Icons.chevron_right_rounded, size: 18),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {

      // Adjusted grid counts for better responsiveness when split with Get Started on desktop
      // and when full width on tablet/mobile
      final crossAxisCount = isDesktop ? 2 : (isTablet ? 3 : 2);
      
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Continue Learning',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              TextButton(
                onPressed: () => context.push('/my-courses'),
                child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isDesktop || isTablet)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: isDesktop ? 1.0 : (isTablet ? 0.85 : 0.75), // Increased height for all versions
              ),
              itemCount: enrollments.take(isDesktop ? 2 : crossAxisCount).length,
              itemBuilder: (context, index) {
                return _buildEnrolledCourseCard(context, enrollments[index]);
              },
            )
          else
            SizedBox(
              height: 280, // Slightly increased height for mobile scrolling list
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: enrollments.length,
                itemBuilder: (context, index) {
                  return Container(
                    width: 280,
                    margin: const EdgeInsets.only(right: 16),
                    child: _buildEnrolledCourseCard(context, enrollments[index]),
                  );
                },
              ),
            ),
        ],
      );
    }
  }
  
  Widget _buildEnrolledCourseCard(BuildContext context, Enrollment enrollment) {
    final course = enrollment.course;
    if (course == null) return const SizedBox.shrink();
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    // Adjust dimensions based on device
    final imageHeight = isDesktop ? 110.0 : 100.0;
    final cardPadding = isMobile ? 12.0 : 16.0;
    final titleSize = isDesktop ? 15.0 : 14.0;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.4) : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark 
              ? Colors.white.withOpacity(0.1) 
              : AppTheme.borderGrey.withOpacity(0.2),
        ),
      ),

      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CourseNavigationUtils.navigateToCourseWithContext(context, ref, course),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: EdgeInsets.all(cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    height: imageHeight,
                    width: double.infinity,
                    color: isDark ? AppTheme.primary.withOpacity(0.1) : AppTheme.primary.withOpacity(0.05),
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                        ? Image.network(
                            course.thumbnail!, 
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) => 
                              const Icon(Icons.play_circle_filled, color: AppTheme.primary, size: 40),
                          )
                        : const Icon(Icons.play_circle_filled, color: AppTheme.primary, size: 40),
                  ),
                ),
                SizedBox(height: isMobile ? 8 : 12),
                Text(
                  course.title,
                  style: TextStyle(
                    fontSize: titleSize, 
                    fontWeight: FontWeight.w700, 
                    letterSpacing: -0.2,
                    height: 1.2,
                    color: AppTheme.getTextColor(context),
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  'By ${course.displayInstructor}',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context), 
                    fontSize: isMobile ? 10 : 11,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                if (enrollment.accessExpirationDate != null) ...[
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: CountdownTimer(
                      expirationDate: enrollment.accessExpirationDate,
                      showSeconds: true,
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                const Spacer(),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Progress',
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            color: AppTheme.getSecondaryTextColor(context),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Text(
                          '${enrollment.progress.toInt()}%',
                          style: TextStyle(
                            fontSize: isMobile ? 9 : 10,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: LinearProgressIndicator(
                        value: enrollment.progress / 100,
                        backgroundColor: isDark 
                            ? AppTheme.primary.withOpacity(0.15) 
                            : AppTheme.primary.withOpacity(0.1),
                        valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primary),
                        minHeight: isMobile ? 3 : 5,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCourses(BuildContext context, List<Course> courses, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final crossAxisCount = isDesktop ? 3 : (isTablet ? 2 : 1);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Recommended Courses',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.5),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Row(
                children: [
                  Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
                  SizedBox(width: 4),
                  Icon(Icons.chevron_right_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isDesktop || isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isDesktop ? 0.9 : (isTablet ? 0.85 : 0.75),
            ),
            itemCount: courses.take(isDesktop ? 3 : 2).length,
            itemBuilder: (context, index) {
              return _buildCourseCardV2(context, courses[index], enrolledCourses);
            },
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: courses.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildCourseCardV2(context, courses[index], enrolledCourses),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCardV2(BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6)),
        boxShadow: [BoxShadow(color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.02), blurRadius: 10)],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (isEnrolled) {
              context.push('/learning/${course.id}');
            } else {
              CourseNavigationUtils.navigateToCourseWithContext(context, ref, course);
            }
          },
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: Container(
                      height: 140,
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                          ? Image.network(course.thumbnail!, fit: BoxFit.cover)
                          : Icon(Icons.image_outlined, size: 40, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                    ),
                  ),
                  if (isEnrolled)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded, color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ENROLLED',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                            ),
                          ],
                        ),
                      ),
                    )
                  else ...[
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ((course.price ?? 0) == 0 ? const Color(0xFF10B981) : const Color(0xFF0F766E)).withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (course.price ?? 0) == 0 ? 'FREE' : 'PAID',
                          style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              Flexible(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        course.title,
                        style: TextStyle(
                          fontSize: 15, 
                          fontWeight: FontWeight.w800, 
                          color: isDark ? Colors.white : const Color(0xFF1F2937), 
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            (course.averageRating ?? 0.0).toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11, 
                              fontWeight: FontWeight.bold, 
                              color: isDark ? Colors.white : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 6),
                          Flexible(
                            child: Text(
                              '(${course.enrollmentCount ?? 0})',
                              style: TextStyle(
                                fontSize: 11, 
                                color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF6B7280),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      const Spacer(),
                      if (isEnrolled)
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(width: 6),
                              Icon(Icons.play_circle_fill, color: Colors.white, size: 14),
                            ],
                          ),
                        )
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if ((course.price ?? 0) > 0)
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 9,
                                      color: isDark ? Colors.white38 : const Color(0xFF9CA3AF),
                                      decoration: TextDecoration.lineThrough,
                                    ),
                                  ),
                                  Text(
                                    'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w900,
                                      color: isDark ? const Color(0xFF2DD4BF) : const Color(0xFF0F766E),
                                    ),
                                  ),
                                ],
                              )
                            else
                              const Text(
                                'FREE',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF10B981),
                                ),
                              ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                              decoration: BoxDecoration(
                                color: ((course.price ?? 0) == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B)).withOpacity(0.1),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    (course.price ?? 0) == 0 ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
                                    size: 9,
                                    color: (course.price ?? 0) == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    (course.price ?? 0) == 0 ? 'FREE' : 'PAID',
                                    style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w800,
                                      color: (course.price ?? 0) == 0 ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResponsivePopularCourses(
      BuildContext context, List<Course> popularCourses, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Popular Courses',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Text('View All', style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isDesktop || isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: 20,
              mainAxisSpacing: 20,
              childAspectRatio: isDesktop ? 0.9 : (isTablet ? 0.85 : 0.75),
            ),
            itemCount: popularCourses.take(crossAxisCount * 2).length,
            itemBuilder: (context, index) {
              return _buildCourseCardV2(context, popularCourses[index], enrolledCourses);
            },
          )
        else
          SizedBox(
            height: 280,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularCourses.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 280,
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildCourseCardV2(context, popularCourses[index], enrolledCourses),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.card,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.3) : Colors.black.withOpacity(0.04),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: AppTheme.borderGrey.withOpacity(0.2)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => CourseNavigationUtils.navigateToCourseWithContext(context, ref, course),
          borderRadius: BorderRadius.circular(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    Container(
                      height: 110,
                      width: double.infinity,
                      color: AppTheme.primary.withOpacity(0.1),
                      child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                          ? Image.network(course.thumbnail!, fit: BoxFit.cover)
                          : Icon(Icons.image_outlined, color: isDark ? Colors.white38 : AppTheme.primary, size: 40),
                    ),
                    if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 12,
                        left: 12,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, letterSpacing: -0.2),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By ${course.displayInstructor}',
                      style: TextStyle(color: AppTheme.greyColor, fontSize: 12),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        if ((course.price ?? 0) > 0)
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                                style: TextStyle(
                                  fontSize: 11,
                                  decoration: TextDecoration.lineThrough,
                                  color: AppTheme.greyColor.withOpacity(0.6),
                                ),
                              ),
                              Text(
                                'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                                style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: AppTheme.primary),
                              ),
                            ],
                          )
                        else
                          Text(
                            'FREE',
                            style: TextStyle(
                              fontSize: 15, 
                              fontWeight: FontWeight.w800, 
                              color: isDark ? const Color(0xFF10B981) : Colors.green,
                            ),
                          ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(

                            color: Colors.amber.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            children: [
                              Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                              SizedBox(width: 2),
                              Text('4.8', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.amber)),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 80,
      decoration: BoxDecoration(
        color: Theme.of(context).bottomNavigationBarTheme.backgroundColor ??
            AppTheme.getCardColor(context),
        border: Border(
          top: BorderSide(
              color: AppTheme.greyColor.withValues(alpha: 0.2),
              width: 1), // FIX #8
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          // FIX #7: 'Home' nav item now scrolls to top via ScrollController
          // or simply stays put (already on dashboard) — replaced empty onTap.
          _buildNavItem(context, Icons.home_filled, 'Home', true, () {
            // Already on dashboard; no navigation needed.
            // Optionally scroll to top if a ScrollController is wired up.
          }),
          _buildNavItem(context, Icons.search_outlined, 'Search', false,
              () => context.push('/courses')),
          _buildNavItem(context, Icons.bookmark_border_outlined, 'My Courses',
              false, () => context.push('/my-courses')),
          _buildNavItem(context, Icons.person_outline, 'Profile', false,
              () => context.push('/profile')),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label,
      bool isSelected, Function onTap) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: () => onTap(),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon,
              color: isSelected
                  ? (theme.bottomNavigationBarTheme.selectedItemColor ??
                      AppTheme.primaryGreen)
                  : (theme.bottomNavigationBarTheme.unselectedItemColor ??
                      AppTheme.getSecondaryTextColor(context)),
              size: 28),
          const SizedBox(height: 4),
          Text(label,
              style: TextStyle(
                color: isSelected
                    ? (theme.bottomNavigationBarTheme.selectedItemColor ??
                        AppTheme.primaryGreen)
                    : (theme.bottomNavigationBarTheme.unselectedItemColor ??
                        AppTheme.getSecondaryTextColor(context)),
                fontSize: 12,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              )),
        ],
      ),
    );
  }

  // FIX #1: Removed duplicate _showLogoutDialog that existed as a stub outside
  // the class at the bottom of the file. Only this single definition is kept.
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Logout',
              style: TextStyle(color: AppTheme.getTextColor(context))),
          content: Text('Are you sure you want to logout?',
              style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel',
                  style: TextStyle(color: AppTheme.getSecondaryTextColor(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: const Text('Logout', style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Widget _buildLoadingCard(BuildContext context, String title) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withValues(alpha: 0.1), // FIX #8
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.2), // FIX #8
              width: 1,
            ),
          ),
          child: const Padding(
            padding: EdgeInsets.all(20),
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(
      BuildContext context, String title, String errorMessage) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title,
            style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.bold)),
        const SizedBox(height: 15),
        Container(
          decoration: BoxDecoration(
            color: Theme.of(context).cardTheme.color,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context)
                    .shadowColor
                    .withValues(alpha: 0.1), // FIX #8
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
            border: Border.all(
              color: Theme.of(context)
                  .dividerColor
                  .withValues(alpha: 0.2), // FIX #8
              width: 1,
            ),
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Center(
              child: Text('Error loading data: $errorMessage',
                  style: const TextStyle(color: Colors.red, fontSize: 14)),
            ),
          ),
        ),
      ],
    );
  }

  // FIX #5: Replaced Navigator.push with context.push for consistent go_router navigation.
  void _navigateToCategories(BuildContext context) =>
      context.push('/categories');

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.contact_support, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            Text('Contact Us',
                style: TextStyle(color: AppTheme.getTextColor(context))),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: 'WhatsApp',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchWhatsApp('250793828834')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: 'WhatsApp',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchWhatsApp('250788535156')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: 'Call Us',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchPhone('250788535156')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: 'Call Us',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchPhone('250793828834')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.email,
                    title: 'Email Us',
                    subtitle: 'info@excellencecoachinghub.com',
                    onTap: () =>
                        _launchEmail('info@excellencecoachinghub.com')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('Close',
                    style:
                        TextStyle(color: AppTheme.getSecondaryTextColor(context)))),
          ],
        );
      },
    );
  }

  Widget _buildContactMethod(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDark
              ? AppTheme.primaryGreen.withValues(alpha: 0.1)
              : AppTheme.primaryGreen.withValues(alpha: 0.05), // FIX #8
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: isDark
                  ? AppTheme.primaryGreen.withValues(alpha: 0.3)
                  : AppTheme.primaryGreen.withValues(alpha: 0.2),
              width: 1), // FIX #8
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: AppTheme.getTextColor(context))),
                  const SizedBox(height: 2),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 14,
                          color: AppTheme.getSecondaryTextColor(context))),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios,
                color: AppTheme.getSecondaryTextColor(context), size: 14),
          ],
        ),
      ),
    );
  }

  Future<void> _launchWhatsApp(String phoneNumber) async {
    final Uri whatsappUri = Uri(
        scheme: 'https',
        host: 'api.whatsapp.com',
        path: 'send',
        queryParameters: {'phone': phoneNumber});

    try {
      if (await canLaunchUrl(whatsappUri)) {
        await launchUrl(whatsappUri, mode: LaunchMode.externalApplication);
      } else if (context.mounted) {
        _showWhatsAppFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showWhatsAppFallbackDialog(context, phoneNumber);
    }
  }

  void _showWhatsAppFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.warning, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('WhatsApp Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                  'WhatsApp is not installed or not accessible on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.phone,
                  title: 'Call Directly',
                  subtitle: phoneNumber,
                  onTap: () => _launchPhone(phoneNumber)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Number',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, phoneNumber, 'Phone number')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Widget _buildFallbackOption(BuildContext context,
      {required IconData icon,
      required String title,
      required String subtitle,
      required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!, width: 1),
        ),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.primaryGreen, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title,
                      style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                          color: AppTheme.getTextColor(context))),
                  Text(subtitle,
                      style: TextStyle(
                          fontSize: 12,
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 14, color: AppTheme.primaryGreen),
          ],
        ),
      ),
    );
  }

  // FIX #11: Implemented clipboard copy using flutter/services Clipboard API.
  Future<void> _copyToClipboard(
      BuildContext context, String value, String label) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (context.mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$label copied to clipboard'),
          backgroundColor: AppTheme.primaryGreen,
        ),
      );
    }
  }

  Future<void> _launchPhone(String phoneNumber) async {
    final Uri phoneUri = Uri(scheme: 'tel', path: phoneNumber);
    try {
      if (await canLaunchUrl(phoneUri)) {
        await launchUrl(phoneUri);
      } else if (context.mounted) {
        _showPhoneFallbackDialog(context, phoneNumber);
      }
    } catch (_) {
      if (context.mounted) _showPhoneFallbackDialog(context, phoneNumber);
    }
  }

  void _showPhoneFallbackDialog(BuildContext context, String phoneNumber) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.phone_disabled, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Call Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Phone calls are not supported on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.message,
                  title: 'WhatsApp Message',
                  subtitle: 'Send WhatsApp message',
                  onTap: () => _launchWhatsApp(phoneNumber)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Number',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, phoneNumber, 'Phone number')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  Future<void> _launchEmail(String email) async {
    final Uri emailUri = Uri(scheme: 'mailto', path: email);
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else if (context.mounted) {
        _showEmailFallbackDialog(context, email);
      }
    } catch (_) {
      if (context.mounted) _showEmailFallbackDialog(context, email);
    }
  }

  void _showEmailFallbackDialog(BuildContext context, String email) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            const Icon(Icons.email_outlined, color: Colors.orange),
            const SizedBox(width: 10),
            const Text('Email Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Email client is not available on this device.'),
              const SizedBox(height: 16),
              const Text('Alternative options:',
                  style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildFallbackOption(context,
                  icon: Icons.copy,
                  title: 'Copy Email',
                  subtitle: 'Copy to clipboard',
                  onTap: () => _copyToClipboard(
                      context, email, 'Email address')), // FIX #11
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Close')),
          ],
        );
      },
    );
  }

  /// Compact header for small mobile devices (≤ 360px)
  Widget _buildSmallMobileHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text - stacked vertically for space
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 12,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            user?.fullName ?? 'Student',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 18,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          // Compact action row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.contact_support, size: 20),
                onPressed: () => _showContactInfoDialog(context),
                tooltip: 'Contact',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 20),
                    if (ref
                        .watch(notificationProvider)
                        .notifications
                        .any((n) => !n.isRead))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notifications',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 20),
                onPressed: () async {
                  await _refreshDashboard();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Refreshed'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Refresh',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 18,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    onTap: () => context.push('/profile'),
                    child: const Row(children: [
                      Icon(Icons.person_outline, size: 16),
                      SizedBox(width: 8),
                      Text('Profile', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    onTap: () => context.push('/settings'),
                    child: const Row(children: [
                      Icon(Icons.settings_outlined, size: 16),
                      SizedBox(width: 8),
                      Text('Settings', style: TextStyle(fontSize: 14)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const Row(children: [
                      Icon(Icons.logout, color: Colors.red, size: 16),
                      SizedBox(width: 8),
                      Text('Logout',
                          style: TextStyle(color: Colors.red, fontSize: 14)),
                    ]),
                  ),
                ],
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// Header for standard mobile devices (361px - 768px)
  Widget _buildStandardMobileHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Welcome text
          Text(
            'Welcome back,',
            style: TextStyle(
              color: Theme.of(context).textTheme.bodyMedium?.color,
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            user?.fullName ?? 'Student',
            style: TextStyle(
              color: Theme.of(context).textTheme.headlineSmall?.color,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 16),
          // Action row with better spacing
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              IconButton(
                icon: const Icon(Icons.contact_support, size: 22),
                onPressed: () => _showContactInfoDialog(context),
                tooltip: 'Contact Us',
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () async {
                  await _refreshDashboard();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Dashboard refreshed'),
                        backgroundColor: AppTheme.primaryGreen,
                        duration: Duration(seconds: 1),
                      ),
                    );
                  }
                },
                tooltip: 'Refresh Dashboard',
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 22),
                    if (ref
                        .watch(notificationProvider)
                        .notifications
                        .any((n) => !n.isRead))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () => context.push('/notifications'),
                tooltip: 'Notifications',
                padding: const EdgeInsets.all(8),
              ),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen.withValues(alpha: 0.1),
                  child: Text(
                    user?.fullName?.substring(0, 1).toUpperCase() ?? 'U',
                    style: const TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) => <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    value: 'profile',
                    onTap: () => context.push('/profile'),
                    child: const Row(children: [
                      Icon(Icons.person_outline, size: 17),
                      SizedBox(width: 9),
                      Text('Profile', style: TextStyle(fontSize: 15)),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    onTap: () => context.push('/settings'),
                    child: const Row(children: [
                      Icon(Icons.settings_outlined, size: 17),
                      SizedBox(width: 9),
                      Text('Settings', style: TextStyle(fontSize: 15)),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: const Row(children: [
                      Icon(Icons.logout, color: Colors.red, size: 17),
                      SizedBox(width: 9),
                      Text('Logout',
                          style: TextStyle(color: Colors.red, fontSize: 15)),
                    ]),
                  ),
                ],
                padding: const EdgeInsets.all(8),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
// FIX #1 & #2: Removed the two invalid top-level stubs that were outside the class:
//   void _showLogoutDialog(BuildContext context) {}
//   class _navigateToCategories {}

class _QuickAccessCard extends StatefulWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Function onTap;

  const _QuickAccessCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  State<_QuickAccessCard> createState() => _QuickAccessCardState();
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final scale = _isPressed ? 0.92 : (_isHovered ? 1.05 : 1.0);
    
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _isPressed = true),
        onTapUp: (_) => setState(() => _isPressed = false),
        onTapCancel: () => setState(() => _isPressed = false),
        onTap: () => widget.onTap(),
        child: AnimatedScale(
          scale: scale,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOutBack,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            decoration: BoxDecoration(
              color: widget.color,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_isHovered ? 0.4 : 0.3),
                  blurRadius: _isHovered ? 16 : 12,
                  offset: Offset(0, _isHovered ? 8 : 6),
                ),
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(_isHovered ? 0.3 : 0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: isDesktop ? 24 : 22,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
