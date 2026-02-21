import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX #11: Added for Clipboard.setData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/wishlist_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_payment_providers.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/payment_status.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/widgets/responsive_navigation_drawer.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/widgets/downloads_section.dart';

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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF3E0), // Light orange background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFFB74D), // Orange border
          width: 1,
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.security,
            color: Color(0xFFF57C00), // Orange icon
            size: 20,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(
              'Device Security: Your account is bound to this device. Logging in from other devices will be blocked. Contact support to change devices.',
              style: TextStyle(
                color: Color(0xFF333333), // Dark text for visibility
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
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
                style: const TextStyle(
                  fontSize: 14,
                  color: Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  bool _hasCheckedRole = false;
  Timer? _autoRefreshTimer;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void initState() {
    super.initState();
    // Start auto-refresh timer to check payment status periodically
    _startAutoRefresh();
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
    final popularCoursesAsync = ref.watch(popularCoursesProvider);

    if (ResponsiveBreakpoints.isDesktop(context)) {
      return Scaffold(
        body: Row(
          children: [
            ResponsiveNavigationDrawer(currentPage: 'dashboard'),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: Theme.of(context).brightness == Brightness.dark
                        ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                        : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    children: [
                      _buildDesktopHeader(context, user),
                      Expanded(
                        child: RefreshIndicator(
                          onRefresh: _refreshDashboard,
                          child: SingleChildScrollView(
                            padding: ResponsiveBreakpoints.getPadding(context),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildWelcomeCard(context, user),
                                const SizedBox(height: 20),
                                const _DashboardDeviceBindingPolicy(),
                                const SizedBox(height: 25),
                                if (ref
                                    .watch(authProvider.notifier)
                                    .isAdmin) ...[
                                  _buildAdminAccessButton(context),
                                  const SizedBox(height: 25),
                                ],
                                enrolledCoursesAsync.when(
                                  data: (enrolledCourses) =>
                                      _buildContinueLearning(
                                          context, enrolledCourses),
                                  loading: () => _buildLoadingCard(
                                      context, 'Continue Learning'),
                                  error: (error, stack) => _buildErrorCard(
                                      context,
                                      'Continue Learning',
                                      error.toString()),
                                ),
                                const SizedBox(height: 25),
                                const DownloadsSection(),
                                const SizedBox(height: 25),
                                popularCoursesAsync.when(
                                  data: (popularCourses) {
                                    debugPrint(
                                        'Dashboard: Received ${popularCourses.length} popular courses'); // FIX #9: print -> debugPrint
                                    if (popularCourses.isNotEmpty) {
                                      debugPrint(
                                          'Dashboard: First popular course thumbnail: ${popularCourses[0].thumbnail ?? "null"}'); // FIX #9
                                    }
                                    return _buildResponsivePopularCourses(
                                        context, popularCourses);
                                  },
                                  loading: () => _buildLoadingCard(
                                      context, 'Popular Courses'),
                                  error: (error, stack) => _buildErrorCard(
                                      context,
                                      'Popular Courses',
                                      error.toString()),
                                ),
                                const SizedBox(height: 25),
                                _buildWishlistSection(context),
                                const SizedBox(height: 40),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        body: SafeArea(
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: Theme.of(context).brightness == Brightness.dark
                    ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                    : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
            child: Column(
              children: [
                _buildHeader(context, user),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: _refreshDashboard,
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildWelcomeCard(context, user),
                          const SizedBox(height: 20),
                          const _DashboardDeviceBindingPolicy(),
                          const SizedBox(height: 25),
                          if (ref.watch(authProvider.notifier).isAdmin) ...[
                            _buildAdminAccessButton(context),
                            const SizedBox(height: 25),
                          ],
                          enrolledCoursesAsync.when(
                            data: (enrolledCourses) => _buildContinueLearning(
                                context, enrolledCourses),
                            loading: () =>
                                _buildLoadingCard(context, 'Continue Learning'),
                            error: (error, stack) => _buildErrorCard(
                                context, 'Continue Learning', error.toString()),
                          ),
                          const SizedBox(height: 25),
                          const DownloadsSection(),
                          const SizedBox(height: 25),
                          popularCoursesAsync.when(
                            data: (popularCourses) =>
                                _buildPopularCourses(context, popularCourses),
                            loading: () =>
                                _buildLoadingCard(context, 'Popular Courses'),
                            error: (error, stack) => _buildErrorCard(
                                context, 'Popular Courses', error.toString()),
                          ),
                          const SizedBox(height: 25),
                          _buildWishlistSection(context),
                          const SizedBox(height: 20),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        bottomNavigationBar: _buildBottomNavBar(context),
        drawer: ResponsiveNavigationDrawer(currentPage: 'dashboard'),
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
  }

  // FIX #6: Extracted refresh logic into a dedicated method to cleanly
  // discard provider refresh futures without the warning-suppression no-op pattern.
  Future<void> _refreshDashboard() async {
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(popularCoursesProvider);
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

  Widget _buildHeader(BuildContext context, user) {
    // Use enhanced responsive layout
    if (ResponsiveBreakpoints.isSmallMobile(context)) {
      return _buildSmallMobileHeader(context, user);
    } else if (ResponsiveBreakpoints.isStandardMobile(context)) {
      return _buildStandardMobileHeader(context, user);
    } else {
      return _buildDesktopHeader(context, user);
    }
  }

  Widget _buildDesktopHeader(BuildContext context, user) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: ResponsiveBreakpoints.getPadding(context),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Welcome section with enhanced styling
          Container(
            padding: const EdgeInsets.all(16),
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
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.waving_hand,
                    color: Colors.white,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Welcome back,',
                      style: TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      user?.fullName ?? 'Student',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: Icon(Icons.contact_support,
                    color: AppTheme.primaryGreen, size: 24),
                onPressed: () => _showContactInfoDialog(context),
                tooltip: 'Contact Us',
              ),
              const SizedBox(width: 16),
              IconButton(
                icon:
                    Icon(Icons.refresh, color: AppTheme.primaryGreen, size: 24),
                onPressed: () async {
                  await _refreshDashboard(); // FIX #6
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
              ),
              const SizedBox(width: 16),
              IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 24),
                    // Notification badge
                    if (ref
                        .watch(notificationProvider)
                        .notifications
                        .any((n) => !n.isRead))
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          width: 10,
                          height: 10,
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
              ),
              const SizedBox(width: 16),
              PopupMenuButton(
                icon: CircleAvatar(
                  radius: 22,
                  backgroundColor:
                      AppTheme.primaryGreen.withValues(alpha: 0.1), // FIX #8
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'U',
                    style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 16,
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
                    child: Row(children: [
                      Icon(Icons.person_outline,
                          color: AppTheme.getIconColor(context), size: 18),
                      const SizedBox(width: 10),
                      Text('Profile',
                          style:
                              TextStyle(color: AppTheme.getTextColor(context))),
                    ]),
                  ),
                  PopupMenuItem<String>(
                    value: 'settings',
                    onTap: () => context.push('/settings'),
                    child: Row(children: [
                      Icon(Icons.settings_outlined,
                          color: AppTheme.getIconColor(context), size: 18),
                      const SizedBox(width: 10),
                      Text('Settings',
                          style:
                              TextStyle(color: AppTheme.getTextColor(context))),
                    ]),
                  ),
                  const PopupMenuDivider(),
                  PopupMenuItem<String>(
                    value: 'logout',
                    child: Row(children: [
                      Icon(Icons.logout,
                          color: AppTheme.getErrorColor(context), size: 18),
                      const SizedBox(width: 10),
                      Text('Logout',
                          style: TextStyle(
                              color: AppTheme.getErrorColor(context))),
                    ]),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeCard(BuildContext context, user) {
    // Responsive sizing based on screen size
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    final isStandardMobile = ResponsiveBreakpoints.isStandardMobile(context);

    final padding = isSmallMobile ? 16.0 : (isStandardMobile ? 20.0 : 24.0);
    final iconSize = isSmallMobile ? 24.0 : (isStandardMobile ? 26.0 : 28.0);
    final titleFontSize =
        isSmallMobile ? 18.0 : (isStandardMobile ? 20.0 : 22.0);
    final subtitleFontSize =
        isSmallMobile ? 12.0 : (isStandardMobile ? 13.0 : 14.0);
    final borderRadius = isSmallMobile ? 16.0 : 20.0;
    return Container(
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF6366F1).withValues(alpha: 0.3), // FIX #8
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(padding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: EdgeInsets.all(isSmallMobile ? 10.0 : 12.0),
                  decoration: BoxDecoration(
                    color: AppTheme.whiteColor.withValues(alpha: 0.2), // FIX #8
                    borderRadius:
                        BorderRadius.circular(isSmallMobile ? 12.0 : 16.0),
                  ),
                  child: Icon(Icons.school,
                      color: AppTheme.whiteColor, size: iconSize),
                ),
                SizedBox(width: isSmallMobile ? 12.0 : 16.0),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Welcome Back, ${user?.fullName ?? 'Student'}!',
                        style: TextStyle(
                          color: AppTheme.whiteColor,
                          fontSize: titleFontSize,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: isSmallMobile ? 1 : 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: isSmallMobile ? 4.0 : 6.0),
                      Text(
                        isSmallMobile
                            ? 'Continue learning and achieve goals'
                            : 'Continue your learning journey and achieve your goals',
                        style: TextStyle(
                          color: AppTheme.whiteColor
                              .withValues(alpha: 0.9), // FIX #8
                          fontSize: subtitleFontSize,
                        ),
                        maxLines: isSmallMobile ? 2 : 3,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: isSmallMobile ? 16.0 : 24.0),
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: () {
                      ref.read(enrolledCoursesProvider).maybeWhen(
                            data: (courses) => courses.isNotEmpty
                                ? context.push('/my-courses')
                                : context.push('/courses'),
                            orElse: () => context.push('/courses'),
                          );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryGreen,
                      foregroundColor: AppTheme.whiteColor,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      elevation: 2,
                    ),
                    child: const Text(
                      'Continue Learning',
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => context.push('/courses'),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(color: AppTheme.whiteColor, width: 2),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                    child: Text(
                      'View Courses',
                      style: TextStyle(
                        color: AppTheme.whiteColor,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
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
        'title': 'Browse Categories',
        'subtitle': 'Explore coaching categories',
        'icon': Icons.category_outlined,
        'color': AppTheme.primaryGreen,
        'onTap': () =>
            context.push('/categories'), // FIX #5: use go_router consistently
      },
      {
        'title': 'My Learning',
        'subtitle': 'Continue courses',
        'icon': Icons.play_circle_outline,
        'color': const Color(0xFF00cdac),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': 'Certificates',
        'subtitle': 'View achievements',
        'icon': Icons.verified_outlined,
        'color': const Color(0xFFfa709a),
        'onTap': () => context.push('/certificates'),
      },
    ];

    final gridCount = ResponsiveGridCount(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 20),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: gridCount.crossAxisCount,
            crossAxisSpacing: 20,
            mainAxisSpacing: 20,
            childAspectRatio: gridCount.childAspectRatio,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _buildResponsiveActionCard(
              context,
              action['title'] as String,
              action['subtitle'] as String,
              action['icon'] as IconData,
              action['color'] as Color,
              action['onTap'] as Function,
            );
          },
        ),
      ],
    );
  }

  Widget _buildResponsiveActionCard(BuildContext context, String title,
      String subtitle, IconData icon, Color color, Function onTap) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(isDesktop ? 16.0 : 12.0),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.08), // FIX #8
            blurRadius: isDesktop ? 10.0 : 8.0,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              Theme.of(context).dividerColor.withValues(alpha: 0.1), // FIX #8
          width: 0.5,
        ),
      ),
      child: InkWell(
        onTap: () => onTap(),
        borderRadius: BorderRadius.circular(isDesktop ? 16.0 : 12.0),
        child: Padding(
          padding: EdgeInsets.all(isDesktop ? 18.0 : 15.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(isDesktop ? 16.0 : 14.0),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.1), // FIX #8
                  borderRadius: BorderRadius.circular(isDesktop ? 14.0 : 12.0),
                ),
                child: Icon(icon, color: color, size: isDesktop ? 36.0 : 32.0),
              ),
              SizedBox(height: isDesktop ? 14.0 : 12.0),
              Text(
                title,
                style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: isDesktop ? 17.0 : 16.0,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: isDesktop ? 6.0 : 5.0),
              Text(
                subtitle,
                style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: isDesktop ? 14.0 : 12.0),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContinueLearning(
      BuildContext context, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    
    if (enrolledCourses.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Continue Learning',
            style: TextStyle(
              color: AppTheme.getTextColor(context),
              fontSize: isDesktop ? 24 : 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 15),
          Container(
            decoration: BoxDecoration(
              color: Theme.of(context).cardTheme.color,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Theme.of(context)
                      .shadowColor
                      .withValues(alpha: 0.08),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: Theme.of(context)
                    .dividerColor
                    .withValues(alpha: 0.1),
                width: 0.5,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.all(isDesktop ? 24 : 16),
              child: Row(
                children: [
                  Container(
                    width: isDesktop ? 70 : 60,
                    height: isDesktop ? 70 : 60,
                    decoration: BoxDecoration(
                      color:
                          AppTheme.greyColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(Icons.play_circle_outline,
                        color: AppTheme.greyColor, size: isDesktop ? 36 : 30),
                  ),
                  SizedBox(width: isDesktop ? 20 : 15),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('No courses in progress',
                            style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: isDesktop ? 18 : 16,
                                fontWeight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        Text('Start a course to see your progress here',
                            style: TextStyle(
                                color: AppTheme.greyColor, fontSize: isDesktop ? 14 : 13)),
                      ],
                    ),
                  ),
                  Container(
                    padding: EdgeInsets.symmetric(
                        horizontal: isDesktop ? 16 : 12, vertical: isDesktop ? 8 : 6),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen
                          .withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text('Start Now',
                        style: TextStyle(
                            color: AppTheme.primaryGreen,
                            fontSize: isDesktop ? 13 : 12,
                            fontWeight: FontWeight.w500)),
                  ),
                ],
              ),
            ),
          ),
        ],
      );
    } else {
      final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
      
      if (isDesktop || isTablet) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue Learning',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: isDesktop ? 24 : 20),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: crossAxisCount,
                crossAxisSpacing: isDesktop ? 20 : 15,
                mainAxisSpacing: isDesktop ? 20 : 15,
                childAspectRatio: 0.75,
              ),
              itemCount: enrolledCourses.length,
              itemBuilder: (context, index) {
                final course = enrolledCourses[index];
                return InkWell(
                  onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
                      context, ref, course),
                  borderRadius: BorderRadius.circular(16),
                  child: _buildEnrolledCourseCard(context, course),
                );
              },
            ),
          ],
        );
      } else {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Continue Learning',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 15),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: enrolledCourses.length,
                itemBuilder: (context, index) {
                  final course = enrolledCourses[index];
                  return GestureDetector(
                    onTap: () =>
                        CourseNavigationUtils.navigateToCourseWithContext(
                            context, ref, course),
                    child: Container(
                      width: 280,
                      margin: const EdgeInsets.only(right: 12),
                      child: _buildMobileEnrolledCourseCard(context, course),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      }
    }
  }
  
  Widget _buildEnrolledCourseCard(BuildContext context, Course course) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            blurRadius: isDesktop ? 12 : 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 16 : 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Container(
                height: isDesktop ? 100 : 80,
                width: double.infinity,
                color: AppTheme.greyColor.withValues(alpha: 0.1),
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? Image.network(
                        course.thumbnail!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Icon(Icons.play_circle_filled,
                              color: AppTheme.greyColor, size: 24);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor, size: 24),
                      )
                    : const Icon(Icons.play_circle_filled,
                        color: AppTheme.greyColor, size: 32),
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 10),
            Text(
              course.title,
              style: TextStyle(
                color: AppTheme.whiteColor,
                fontSize: isDesktop ? 15 : 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isDesktop ? 8 : 6),
            Container(
              padding: EdgeInsets.symmetric(
                  horizontal: 8, vertical: isDesktop ? 4 : 3),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('In Progress',
                  style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: isDesktop ? 12 : 11,
                      fontWeight: FontWeight.w500)),
            ),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      value: 0.65,
                      backgroundColor: AppTheme.whiteColor.withValues(alpha: 0.2),
                      valueColor: AlwaysStoppedAnimation<Color>(
                          AppTheme.whiteColor),
                      minHeight: 4,
                    ),
                  ),
                ),
                SizedBox(width: isDesktop ? 8 : 6),
                Container(
                  decoration: BoxDecoration(
                      color: AppTheme.whiteColor,
                      borderRadius: BorderRadius.circular(6)),
                  padding: const EdgeInsets.all(4),
                  child: Icon(Icons.arrow_forward,
                      color: AppTheme.primaryGreen, size: isDesktop ? 16 : 14),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  Widget _buildMobileEnrolledCourseCard(BuildContext context, Course course) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryGreen.withValues(alpha: 0.2),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Container(
                height: 80,
                width: double.infinity,
                color: AppTheme.greyColor.withValues(alpha: 0.1),
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? Image.network(
                        course.thumbnail!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Icon(Icons.play_circle_filled,
                              color: AppTheme.greyColor, size: 24);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor, size: 24),
                      )
                    : const Icon(Icons.play_circle_filled,
                        color: AppTheme.greyColor, size: 28),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              style: const TextStyle(
                color: AppTheme.whiteColor,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: AppTheme.whiteColor.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text('In Progress',
                  style: TextStyle(
                      color: AppTheme.whiteColor,
                      fontSize: 11,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
      ),
    );
  }

  // FIX #3: Restored correct method structure; original had mismatched braces
  // causing the method body to bleed into _buildResponsivePopularCourses.
  Widget _buildPopularCourses(
      BuildContext context, List<Course> popularCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Courses',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Text('View All',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: 14,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        const SizedBox(height: 15),
        SizedBox(
          height: 180,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return GestureDetector(
                onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
                    context, ref, course),
                child: Container(
                  width: 240,
                  margin: const EdgeInsets.only(right: 15),
                  child: _buildCourseCard(context, course),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildResponsivePopularCourses(
      BuildContext context, List<Course> popularCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final gridCount = ResponsiveGridCount(context);
    
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : gridCount.crossAxisCount);
    final spacing = isDesktop ? 20.0 : 15.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Popular Courses',
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: isDesktop ? 24 : 20,
                fontWeight: FontWeight.w600,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: Text('View All',
                  style: TextStyle(
                      color: AppTheme.primaryGreen,
                      fontSize: isDesktop ? 16 : 14,
                      fontWeight: FontWeight.w500)),
            ),
          ],
        ),
        SizedBox(height: isDesktop ? 24 : 15),
        if (isDesktop || isTablet)
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: crossAxisCount,
              crossAxisSpacing: spacing,
              mainAxisSpacing: spacing,
              childAspectRatio: isDesktop ? 0.75 : gridCount.childAspectRatio,
            ),
            itemCount: popularCourses.length,
            itemBuilder: (context, index) {
              final course = popularCourses[index];
              return InkWell(
                onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
                    context, ref, course),
                borderRadius: BorderRadius.circular(16),
                child: _buildResponsiveCourseCard(context, course),
              );
            },
          )
        else
          SizedBox(
            height: 200,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularCourses.length,
              itemBuilder: (context, index) {
                final course = popularCourses[index];
                return GestureDetector(
                  onTap: () =>
                      CourseNavigationUtils.navigateToCourseWithContext(
                          context, ref, course),
                  child: Container(
                    width: 240,
                    margin: const EdgeInsets.only(right: 15),
                    child: _buildCourseCard(context, course),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }

  Widget _buildResponsiveCourseCard(BuildContext context, Course course) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(isDesktop ? 16 : 12),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.08), // FIX #8
            blurRadius: isDesktop ? 10 : 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              Theme.of(context).dividerColor.withValues(alpha: 0.1), // FIX #8
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(isDesktop ? 14 : 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(isDesktop ? 10 : 8),
              child: Container(
                height: isDesktop ? 120.0 : 80.0,
                width: double.infinity,
                color: AppTheme.greyColor.withValues(alpha: 0.1), // FIX #8
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? Image.network(
                        course.thumbnail!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Icon(Icons.play_circle_filled,
                              color: AppTheme.greyColor, size: 30);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor, size: 30),
                      )
                    : const Icon(Icons.play_circle_filled,
                        color: AppTheme.greyColor, size: 35),
              ),
            ),
            SizedBox(height: isDesktop ? 12 : 10),
            Text(
              course.title,
              style: TextStyle(
                color: AppTheme.getTextColor(context),
                fontSize: isDesktop ? 16.0 : 15.0,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('by ${course.createdBy.fullName}',
                style: TextStyle(
                    color: AppTheme.greyColor,
                    fontSize: isDesktop ? 13.0 : 12.0)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text('4.8',
                      style: TextStyle(
                          color: AppTheme.getTextColor(context), fontSize: 11)),
                ]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryGreen.withValues(alpha: 0.1), // FIX #8
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RWF ${course.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCourseCard(BuildContext context, Course course) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color:
                Theme.of(context).shadowColor.withValues(alpha: 0.08), // FIX #8
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color:
              Theme.of(context).dividerColor.withValues(alpha: 0.1), // FIX #8
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Container(
                height: 80,
                width: double.infinity,
                color: AppTheme.greyColor.withValues(alpha: 0.1), // FIX #8
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? Image.network(
                        course.thumbnail!,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return const Icon(Icons.play_circle_filled,
                              color: AppTheme.greyColor, size: 30);
                        },
                        errorBuilder: (context, error, stackTrace) =>
                            const Icon(Icons.image_not_supported_outlined,
                                color: AppTheme.greyColor, size: 30),
                      )
                    : const Icon(Icons.play_circle_filled,
                        color: AppTheme.greyColor, size: 35),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              course.title,
              style: TextStyle(
                  color: AppTheme.getTextColor(context),
                  fontSize: 15,
                  fontWeight: FontWeight.w600),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text('by ${course.createdBy.fullName}',
                style:
                    const TextStyle(color: AppTheme.greyColor, fontSize: 12)),
            const Spacer(),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(children: [
                  const Icon(Icons.star, color: Colors.amber, size: 14),
                  const SizedBox(width: 3),
                  Text('4.8',
                      style: TextStyle(
                          color: AppTheme.getTextColor(context), fontSize: 11)),
                ]),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color:
                        AppTheme.primaryGreen.withValues(alpha: 0.1), // FIX #8
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'RWF ${course.price.toStringAsFixed(0)}',
                    style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontSize: 12,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ],
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
          backgroundColor: AppTheme.whiteColor,
          title: const Text('Logout',
              style: TextStyle(color: AppTheme.blackColor)),
          content: const Text('Are you sure you want to logout?',
              style: TextStyle(color: AppTheme.greyColor)),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppTheme.greyColor)),
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

  Widget _buildWishlistSection(BuildContext context) {
    final wishlistAsync = ref.watch(wishlistProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Wishlist',
          style: TextStyle(
            color: AppTheme.getTextColor(context),
            fontSize: ResponsiveBreakpoints.isDesktop(context) ? 24 : 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 15),
        wishlistAsync.when(
          data: (courses) {
            if (courses.isEmpty) {
              return Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Theme.of(context).cardTheme.color,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Theme.of(context)
                        .dividerColor
                        .withValues(alpha: 0.1), // FIX #8
                    width: 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(Icons.bookmark_border,
                        size: 48,
                        color: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.color
                            ?.withValues(alpha: 0.6)), // FIX #8
                    const SizedBox(height: 12),
                    Text('Your wishlist is empty',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color:
                                Theme.of(context).textTheme.bodyMedium?.color)),
                    const SizedBox(height: 8),
                    Text("Start adding courses you're interested in",
                        style: TextStyle(
                            fontSize: 14,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.7))), // FIX #8
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: () => _navigateToCategories(
                          context), // FIX #5: use consistent nav
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Browse Courses'),
                    ),
                  ],
                ),
              );
            }

            return Container(
              decoration: BoxDecoration(
                color: Theme.of(context).cardTheme.color,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Theme.of(context)
                        .shadowColor
                        .withValues(alpha: 0.08), // FIX #8
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(
                  color: Theme.of(context)
                      .dividerColor
                      .withValues(alpha: 0.1), // FIX #8
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Saved Courses (${courses.length})',
                            style: const TextStyle(
                                fontSize: 16, fontWeight: FontWeight.w600)),
                        TextButton(
                          onPressed: () =>
                              context.push('/wishlist'), // FIX #5: go_router
                          child: const Text('View All',
                              style: TextStyle(
                                  color: AppTheme.primaryGreen,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    height: 120,
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount: courses.length,
                      itemBuilder: (context, index) =>
                          _buildWishlistCoursePreview(
                              context, courses[index], ref),
                    ),
                  ),
                ],
              ),
            );
          },
          loading: () => _buildLoadingCard(context, 'My Wishlist'),
          error: (error, stack) =>
              _buildErrorCard(context, 'My Wishlist', error.toString()),
        ),
      ],
    );
  }

  Widget _buildWishlistCoursePreview(
      BuildContext context, Course course, WidgetRef ref) {
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color:
              Theme.of(context).dividerColor.withValues(alpha: 0.1), // FIX #8
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
            context, ref, course),
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 60,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(12)),
                image: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? DecorationImage(
                        image: NetworkImage(course.thumbnail!),
                        fit: BoxFit.cover)
                    : null,
              ),
              child: course.thumbnail == null || course.thumbnail!.isEmpty
                  ? Icon(Icons.play_circle_outline,
                      color: Colors.grey[400], size: 24)
                  : null,
            ),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(course.title,
                      style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getTextColor(context)),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 4),
                  Text('by ${course.createdBy.fullName}',
                      style: TextStyle(
                          fontSize: 12,
                          color: Theme.of(context)
                              .textTheme
                              .bodyMedium
                              ?.color
                              ?.withValues(alpha: 0.7)), // FIX #8
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        course.price == 0
                            ? 'FREE'
                            : 'RWF ${course.price.toStringAsFixed(0)}',
                        style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: course.price == 0
                                ? Colors.green
                                : AppTheme.blackColor),
                      ),
                      IconButton(
                        icon: Icon(Icons.close,
                            size: 16,
                            color: Theme.of(context)
                                .textTheme
                                .bodyMedium
                                ?.color
                                ?.withValues(alpha: 0.6)), // FIX #8
                        onPressed: () => ref
                            .read(wishlistNotifierProvider.notifier)
                            .removeCourse(course.id),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactInfoDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(children: [
            Icon(Icons.contact_support, color: AppTheme.primaryGreen),
            const SizedBox(width: 10),
            const Text('Contact Us'),
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
                child: const Text('Close')),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.primaryGreen.withValues(alpha: 0.05), // FIX #8
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
              color: AppTheme.primaryGreen.withValues(alpha: 0.2),
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
                          color:
                              Theme.of(context).textTheme.bodyMedium?.color)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios,
                size: 16, color: AppTheme.primaryGreen),
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
