import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // FIX #11: Added for Clipboard.setData
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/payment_riverpod_provider.dart';
import 'package:excellencecoachinghub/data/repositories/course_repository.dart';
import 'package:excellencecoachinghub/models/category.dart';
import 'package:excellencecoachinghub/models/course.dart';
import 'package:excellencecoachinghub/models/enrollment.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/widgets/downloads_section.dart';
import 'package:excellencecoachinghub/widgets/countdown_timer.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/widgets/enhanced_course_navigation.dart';
import 'package:excellencecoachinghub/widgets/support_floating_button.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

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
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final l10n = AppLocalizations.of(context);

    return Container(
      padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 20, vertical: isMobile ? 10 : 16),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.primaryDark.withOpacity(0.18)
            : AppTheme.primarySoft.withOpacity(0.7),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppTheme.primaryLight.withOpacity(0.18)
              : AppTheme.primary.withOpacity(0.16),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
            size: isMobile ? 18 : 22,
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Text(
              l10n?.accountBoundToDevice ?? 'Account secured to this device. Contact support to change.',
              style: TextStyle(
                color: isDark
                    ? AppTheme.darkTextPrimary.withOpacity(0.84)
                    : AppTheme.primaryDark,
                fontSize: isMobile ? 12 : 14,
                fontWeight: FontWeight.w500,
                letterSpacing: -0.2,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
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

// Custom painter for a subtle woven dashboard edge.
class _CurvedEdgePainter extends CustomPainter {
  final bool isDark;

  _CurvedEdgePainter({this.isDark = false});

  @override
  void paint(Canvas canvas, Size size) {
    final wavePaint = Paint()
      ..color = (isDark ? AppTheme.primaryLight : AppTheme.primary)
          .withOpacity(isDark ? 0.18 : 0.16)
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, size.height);
    path.lineTo(0, size.height * 0.3);
    path.quadraticBezierTo(
      size.width * 0.25,
      size.height * 0.1,
      size.width * 0.5,
      size.height * 0.3,
    );
    path.quadraticBezierTo(
      size.width * 0.75,
      size.height * 0.5,
      size.width,
      size.height * 0.2,
    );

    path.lineTo(size.width, size.height);
    path.close();

    canvas.drawPath(path, wavePaint);

    final stripePaint = Paint()
      ..color = Colors.white.withOpacity(isDark ? 0.08 : 0.18)
      ..strokeWidth = 2;

    for (var x = -size.height; x < size.width; x += 26) {
      canvas.drawLine(
        Offset(x, size.height),
        Offset(x + size.height, 0),
        stripePaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _DashboardScreenState extends ConsumerState<DashboardScreen>
    with SingleTickerProviderStateMixin, WidgetsBindingObserver {
  bool _hasCheckedRole = false;
  bool _isRefreshing = false;
  Timer? _autoRefreshTimer;
  Timer? _phraseTimer;
  AnimationController? _animationController;
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _showCategoryDropdown = false;
  bool _isOffline = false;
  StreamSubscription? _connectivitySubscription;

  AppLocalizations? get l10n => AppLocalizations.of(context);

  // Gamification
  int _phraseIndex = 0;
  List<String> get _motivationalPhrases => [
    l10n?.motivationalQuote1 ?? 'Build skills for your next opportunity.',
    l10n?.motivationalQuote2 ?? 'Every lesson brings you closer to your goal.',
    l10n?.motivationalQuote3 ?? 'Keep going — consistency beats talent.',
    l10n?.motivationalQuote4 ?? 'Champions learn daily. You are one.',
    l10n?.motivationalQuote5 ?? 'Small steps, massive results.',
    l10n?.motivationalQuote6 ?? 'Your future self is watching. Make it count.',
    l10n?.motivationalQuote7 ?? 'Top performers never stop learning.',
  ];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    PushNotificationService.clearNotifications();

    _initConnectivityListener();

    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _startAutoRefresh();
    _animationController?.forward();

    // Rotate motivational phrase every 5 seconds
    _phraseTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (mounted) {
        setState(() => _phraseIndex =
            (_phraseIndex + 1) % _motivationalPhrases.length);
      }
    });

    // Show welcome-back popup after first frame
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowWelcomePopup();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    // Refresh dashboard when app is resumed (user returns from background)
    if (state == AppLifecycleState.resumed) {
      debugPrint('DashboardScreen: App resumed, refreshing data...');
      _refreshDashboard();
    }
  }

  Future<void> _maybeShowWelcomePopup() async {
    if (!mounted) return;
    final storage = StorageManager();
    final lastSeen = await storage.getItem('dashboard_last_seen');
    final today = DateTime.now().toIso8601String().substring(0, 10);
    await storage.saveItem('dashboard_last_seen', today);

    if (!mounted) return;

    // First ever open — show "welcome" toast
    if (lastSeen == null) {
      _showDashboardToast(
        icon: '👋',
        title: l10n?.welcomeToExcellenceHub ?? 'Welcome to Excellence Hub!',
        message: l10n?.startFirstLesson ?? 'Start your first lesson today and earn XP.',
        color: AppTheme.primary,
      );
      return;
    }

    // Returning user on a new day — show motivational toast
    if (lastSeen != today) {
      final hour = DateTime.now().hour;
      final greeting = hour < 12
          ? l10n?.goodMorning ?? 'Good morning'
          : hour < 17
              ? l10n?.goodAfternoon ?? 'Good afternoon'
              : l10n?.goodEvening ?? 'Good evening';
      _showDashboardToast(
        icon: '🔥',
        title: '$greeting! ${l10n?.keepStreakAlive ?? 'Keep the streak alive.'}',
        message: l10n?.consistencyIsSuperpower ?? 'Your consistency is your superpower.',
        color: const Color(0xFFFF7043),
      );
    }
  }

  void _showDashboardToast({
    required String icon,
    required String title,
    required String message,
    required Color color,
  }) {
    if (!mounted) return;
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'toast',
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 350),
      transitionBuilder: (ctx, anim, _, child) => SlideTransition(
        position: Tween<Offset>(
                begin: const Offset(0, 0.18), end: Offset.zero)
            .animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic)),
        child: FadeTransition(opacity: anim, child: child),
      ),
      pageBuilder: (ctx, _, __) => _DashboardToast(
        icon: icon,
        title: title,
        message: message,
        color: color,
        onDismiss: () => Navigator.of(ctx).pop(),
      ),
    );
  }

  void _checkProgressMilestone(List<Enrollment> enrollments) {
    if (enrollments.isEmpty) return;
    final avg = enrollments.fold(0.0, (s, e) => s + e.progress) /
        enrollments.length;
    final milestones = [25, 50, 75, 100];
    for (final m in milestones) {
      if (avg >= m) {
        _maybeShowMilestone(m, avg);
        return;
      }
    }
  }

  Future<void> _maybeShowMilestone(int milestone, double progress) async {
    if (!mounted) return;
    final storage = StorageManager();
    final key = 'milestone_shown_$milestone';
    final already = await storage.getItem(key);
    if (already == 'true') return;
    await storage.saveItem(key, 'true');
    if (!mounted) return;

    final messages = {
      25: ('🚀', l10n?.quarterWay ?? 'Quarter way there!', l10n?.momentumBuilding ?? 'You have hit 25% — momentum is building!'),
      50: ('⚡', l10n?.halfwayChampion ?? 'Halfway champion!', l10n?.finishLineReal ?? 'You are at 50% — the finish line is real.'),
      75: ('🏅', l10n?.almostThere ?? 'Almost there!', l10n?.nearlyUnstoppable ?? '75% done — you are nearly unstoppable.'),
      100: ('🎓', l10n?.courseCompleted ?? 'Course completed!', l10n?.incredibleEffort ?? 'You finished a course. Incredible effort!'),
    };
    final data = messages[milestone];
    if (data == null) return;

    _showDashboardToast(
      icon: data.$1,
      title: data.$2,
      message: data.$3,
      color: milestone == 100
          ? const Color(0xFFFFD700)
          : milestone >= 75
              ? AppTheme.accent
              : AppTheme.primary,
    );
  }

  void _startAutoRefresh() {
    // Check payment status every 60 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 60), (timer) {
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
    WidgetsBinding.instance.removeObserver(this);
    _autoRefreshTimer?.cancel();
    _phraseTimer?.cancel();
    _animationController?.dispose();
    _searchController.dispose();
    _connectivitySubscription?.cancel();
    super.dispose();
  }

  void _initConnectivityListener() async {
    // Check initial connectivity state
    final initialResults = await Connectivity().checkConnectivity();
    final isInitiallyOffline = initialResults.isEmpty || initialResults.contains(ConnectivityResult.none);
    if (mounted) {
      setState(() {
        _isOffline = isInitiallyOffline;
      });
    }
    print('Initial offline state: $_isOffline');

    // Listen for connectivity changes
    _connectivitySubscription = Connectivity().onConnectivityChanged.listen((List<ConnectivityResult> results) {
      final isNowOffline = results.isEmpty || results.contains(ConnectivityResult.none);
      print('Connectivity changed: offline=$isNowOffline');
      if (mounted) {
        setState(() {
          _isOffline = isNowOffline;
        });
      }
    });
  }

  Widget _buildOfflineBanner(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.orange.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.wifi_off, color: Colors.orange, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You\'re offline',
                  style: TextStyle(
                    color: isDark ? Colors.white : Colors.black87,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Some content may not be available. Go to Downloads to view offline content.',
                  style: TextStyle(
                    color: isDark ? Colors.white70 : Colors.black54,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          TextButton.icon(
            onPressed: () => context.push('/downloads'),
            icon: const Icon(Icons.download, color: AppTheme.primaryGreen),
            label: const Text(
              'Downloads',
              style: TextStyle(color: AppTheme.primaryGreen),
            ),
          ),
        ],
      ),
    );
  }

  // Handle search submission with category filtering
  void _performSearch(String query) {
    final trimmedQuery = query.trim();

    // Allow search if either query is not empty OR a category is selected
    if (trimmedQuery.isEmpty && _selectedCategoryId == null) {
      // Show a hint to user that they need to enter something or select a category
      debugPrint('Dashboard: Cannot search - empty query and no category selected');
      return;
    }

    // Close keyboard before navigating
    FocusManager.instance.primaryFocus?.unfocus();

    // Close category dropdown if open
    if (_showCategoryDropdown) {
      setState(() => _showCategoryDropdown = false);
    }

    final extra = {
      'searchQuery': trimmedQuery.isEmpty ? null : trimmedQuery,
      'categoryId': _selectedCategoryId,
      'categoryName': _selectedCategoryName,
    };
    
    debugPrint('Dashboard: Navigating to courses with extra: $extra');

    // Navigate and then clear after navigation completes
    context.push('/courses', extra: extra).then((_) {
      // Clear search after returning from courses screen
      if (mounted) {
        _searchController.clear();
        setState(() {
          _selectedCategoryId = null;
          _selectedCategoryName = null;
        });
        debugPrint('Dashboard: Search state cleared after navigation');
      }
    });
  }

  // Trigger search with button tap
  void _onSearchButtonTap() {
    _performSearch(_searchController.text);
  }

  // FIX #10: Removed duplicate _checkUserRole call from didUpdateWidget.
  // didChangeDependencies already handles re-checks; calling it from
  // didUpdateWidget too caused redundant checks on every widget rebuild.

  void _checkUserRole() async {
    if (!_hasCheckedRole) {
      final authState =
          ref.read(authProvider); // use read, not watch, outside build

      // Prevent onboarding redirect during initial auth restoration.
      // This avoids a bounce right after login when onboarding flags are not yet stable.
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
        } else if (authState.user?.role == 'instructor') {
          debugPrint(
              'DashboardScreen: Instructor detected, redirecting to teacher dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) context.go('/teacher/dashboard');
          });
        } else {
          final userHasCompletedOnboarding =
              authState.user?.hasCompletedOnboarding ?? false;
          final userName = authState.user?.fullName ?? '';
          final needsName = userName.isEmpty || userName == 'Unknown User';

          // Check name first: phone auth users may reach dashboard without a name.
          if (needsName) {
            debugPrint(
                'DashboardScreen: User has no name, redirecting to name-collection');
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) context.go('/name-collection');
            });
          } else {
            // Only redirect based on backend/profile value.
            // Avoid local-storage race conditions during login/session restoration.
            final shouldRedirect = !userHasCompletedOnboarding;

            if (shouldRedirect) {
              debugPrint(
                  'DashboardScreen: Student has not completed onboarding, redirecting to onboarding');
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) context.go('/interest-selection');
              });
            }
          }
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

    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Cache resolved values to prevent repeated when() calls
    final List<Course> popularCourses = popularCoursesAsync.when(
      data: (courses) => courses,
      loading: () => <Course>[],
      error: (_, __) => <Course>[],
    );

    final List<Course> recommendedCourses = recommendedCoursesAsync.when(
      data: (courses) => courses,
      loading: () => <Course>[],
      error: (_, __) => <Course>[],
    );

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF07111D) : const Color(0xFFF6F8FB),
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            displacement: 50,
            strokeWidth: 3,
            color: AppTheme.primary,
            backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
            child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(
            parent: BouncingScrollPhysics(),
          ),
          slivers: [
          // Modern Header with Gradient
          SliverToBoxAdapter(
            child: _buildModernHeader(context, user),
          ),
          // Offline Banner
          if (_isOffline)
            SliverToBoxAdapter(
              child: _buildOfflineBanner(context),
            ),
          // Main Content
          if (!_isOffline)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 12),
                        _buildModernSearchBar(context),
                        // DEBUG: Temporary test button
                        Row(
                          children: [
                            ElevatedButton(
                              onPressed: () async {
                                final repo = CourseRepository();
                                debugPrint('=== NORMAL FILTER (isPublished=true) ===');
                                debugPrint('Testing category: 69c5017a27858856e87d001f');
                                final result = await repo.getCoursesPaged(
                                  page: 1,
                                  limit: 10,
                                  categoryId: '69c5017a27858856e87d001f',
                                );
                                debugPrint('Found ${result.courses.length} published courses');
                                
                                debugPrint('=== UNPUBLISHED FILTER (isPublished=any) ===');
                                final result2 = await repo.getCoursesPaged(
                                  page: 1,
                                  limit: 10,
                                  categoryId: '69c5017a27858856e87d001f',
                                  showUnpublished: true,
                                );
                                debugPrint('Found ${result2.courses.length} total courses (including unpublished)');
                                for (var c in result2.courses) {
                                  debugPrint('  - ${c.title} (published: ${c.isPublished})');
                                }
                                debugPrint('=======================');
                              },
                              child: const Text('TEST API'),
                            ),
                            const SizedBox(width: 8),
                            ElevatedButton(
                              onPressed: () async {
                                final repo = CourseRepository();
                                debugPrint('=== ALL COURSES TEST ===');
                                final result = await repo.getCoursesPaged(
                                  page: 1,
                                  limit: 10,
                                );
                                debugPrint('Found ${result.courses.length} total courses');
                                for (var c in result.courses) {
                                  debugPrint('  - ${c.title} (cat: ${c.categoryId})');
                                }
                                debugPrint('========================');
                              },
                              child: const Text('TEST ALL'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),
                        // For new users: Show recommended first, then popular
                        // For returning users: Show continue learning first
                        userEnrollmentsAsync.when(
                          data: (enrollments) {
                            final isNewUser = enrollments.isEmpty;
                            final enrolledCourses = enrollments
                                .map((e) => e.course)
                                .where((course) => course != null)
                                .cast<Course>()
                                .toList();
                            final coursesToShow = recommendedCourses.isNotEmpty
                                ? recommendedCourses
                                : popularCourses;

                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // For new users: Prominent welcome + recommended courses
                                if (isNewUser) ...[
                                  _buildNewUserWelcome(context),
                                  const SizedBox(height: 24),
                                  _buildRecommendedCourses(
                                    context,
                                    coursesToShow,
                                    enrolledCourses,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildResponsivePopularCourses(
                                    context,
                                    popularCourses,
                                    enrolledCourses,
                                  ),
                                  const SizedBox(height: 24),
                                ],
                                // Continue learning / Explore card
                                _buildContinueLearningCard(context, enrollments),
                                // For returning users: Quick actions, Stats, Recommended, Popular
                                if (!isNewUser) ...[
                                  const SizedBox(height: 20),
                                  _buildQuickActions(context),
                                  const SizedBox(height: 24),
                                  _buildProgressStats(context, enrollments),
                                  const SizedBox(height: 24),
                                  _buildRecommendedCourses(
                                    context,
                                    coursesToShow,
                                    enrolledCourses,
                                  ),
                                  const SizedBox(height: 24),
                                  _buildResponsivePopularCourses(
                                    context,
                                    popularCourses,
                                    enrolledCourses,
                                  ),
                                ],
                              ],
                            );
                          },
                          loading: () {
                            final coursesToShow = recommendedCourses.isNotEmpty
                                ? recommendedCourses
                                : popularCourses;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNewUserWelcome(context),
                                const SizedBox(height: 24),
                                _buildRecommendedCourses(
                                    context, coursesToShow, []),
                                const SizedBox(height: 24),
                                _buildResponsivePopularCourses(
                                    context, popularCourses, []),
                                const SizedBox(height: 24),
                                _buildLoadingCard(context, l10n?.continueLearning ?? 'Continue Learning'),
                              ],
                            );
                          },
                          error: (_, __) {
                            final coursesToShow = recommendedCourses.isNotEmpty
                                ? recommendedCourses
                                : popularCourses;
                            return Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildNewUserWelcome(context),
                                const SizedBox(height: 24),
                                _buildRecommendedCourses(
                                    context, coursesToShow, []),
                                const SizedBox(height: 24),
                                _buildResponsivePopularCourses(
                                    context, popularCourses, []),
                                const SizedBox(height: 24),
                                _buildContinueLearningCard(context, []),
                              ],
                            );
                          },
                        ),
                        const SizedBox(height: 18),
                        _buildUpdateInterestsCard(context),
                        const SizedBox(height: 18),
                        _buildLiveClassesContactCard(context),
                        const SizedBox(height: 18),
                        _buildExamPreparationCard(context),
                        const SizedBox(height: 24),
                        const DownloadsSection(),
                        const SizedBox(height: 32),
                        if (ref.watch(authProvider.notifier).isAdmin)
                          _buildAdminAccessButton(context),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          // Show only downloads when offline
          if (_isOffline)
            SliverPadding(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 16 : 28),
              sliver: SliverToBoxAdapter(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1180),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 24),
                        const DownloadsSection(),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
          ),
          // Floating Support Button
          const Positioned(
            right: 16,
            bottom: 16,
            child: SupportFloatingButton(),
          ),
        ],
      ),
    );
  }

  // FIX #6: Extracted refresh logic into a dedicated method to cleanly
  // discard provider refresh futures without the warning-suppression no-op pattern.
  Future<void> _refreshDashboard() async {
    if (_isRefreshing) return; // Prevent concurrent refreshes

    setState(() => _isRefreshing = true);

    try {
      // Invalidate all dashboard data providers to trigger fresh fetch
      ref.invalidate(enrolledCoursesProvider);
      ref.invalidate(userEnrollmentsProvider);
      ref.invalidate(popularCoursesProvider);
      ref.invalidate(recommendedCoursesProvider);

      // Wait for the providers to reload
      await Future.wait([
        ref.read(enrolledCoursesProvider.future),
        ref.read(userEnrollmentsProvider.future),
        ref.read(popularCoursesProvider.future),
        ref.read(recommendedCoursesProvider.future),
      ]);
    } catch (e) {
      debugPrint('DashboardScreen: Error during refresh: $e');
    } finally {
      if (mounted) {
        setState(() => _isRefreshing = false);
      }
    }
  }

  // Compact Modern Header - Minimal style like modern apps
  Widget _buildModernHeader(BuildContext context, user) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? (l10n?.goodMorning ?? 'Good morning')
        : hour < 17
            ? (l10n?.goodAfternoon ?? 'Good afternoon')
            : (l10n?.goodEvening ?? 'Good evening');

    return Container(
      color: isDark ? const Color(0xFF07111D) : const Color(0xFFF6F8FB),
      child: SafeArea(
        child: Padding(
          padding: EdgeInsets.fromLTRB(
            isMobile ? 16 : 28,
            isMobile ? 12 : 16,
            isMobile ? 16 : 28,
            isMobile ? 16 : 20,
          ),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1180),
              child: Row(
                children: [
                  // Profile Avatar
                  _buildProfileAvatar(context, user, isMobile),
                  const SizedBox(width: 12),
                  // Greeting
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$greeting, ${user?.fullName?.split(" ")[0] ?? 'Student'}',
                          style: TextStyle(
                            fontSize: isMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          l10n?.studentDashboard ?? 'Student dashboard',
                          style: TextStyle(
                            fontSize: isMobile ? 12 : 13,
                            fontWeight: FontWeight.w500,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Action Buttons
                  Row(
                    children: [
                      _buildLanguageSwitcher(),
                      const SizedBox(width: 8),
                      _isRefreshing
                          ? SizedBox(
                              width: 40,
                              height: 40,
                              child: Center(
                                child: SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      isDark ? Colors.white : AppTheme.primary,
                                    ),
                                  ),
                                ),
                              ),
                            )
                          : _buildCompactHeaderButton(
                              icon: Icons.refresh_rounded,
                              tooltip: l10n?.refresh ?? 'Refresh',
                              onTap: _refreshDashboard,
                              isDark: isDark,
                            ),
                      const SizedBox(width: 8),
                      _buildCompactHeaderButton(
                        icon: Icons.contact_support_rounded,
                        tooltip: l10n?.contactUs ?? 'Contact Us',
                        onTap: () => _showContactInfoDialog(context),
                        isDark: isDark,
                      ),
                      const SizedBox(width: 8),
                      Consumer(
                        builder: (context, ref, child) {
                          final notifications = ref
                              .watch(notificationProvider)
                              .notifications;
                          final unreadCount = notifications
                              .where((n) => !n.isRead)
                              .length;

                          return Stack(
                            children: [
                              _buildCompactHeaderButton(
                                icon: unreadCount > 0
                                    ? Icons.notifications_active_rounded
                                    : Icons.notifications_outlined,
                                tooltip: l10n?.notifications ?? 'Notifications',
                                onTap: () {
                                  PushNotificationService.clearNotifications();
                                  context.push('/notifications');
                                },
                                isDark: isDark,
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  right: 2,
                                  top: 2,
                                  child: Container(
                                    constraints: const BoxConstraints(
                                      minWidth: 16,
                                      minHeight: 16,
                                    ),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: isDark
                                            ? const Color(0xFF07111D)
                                            : const Color(0xFFF6F8FB),
                                        width: 2,
                                      ),
                                    ),
                                    child: Text(
                                      unreadCount > 9
                                          ? '9+'
                                          : unreadCount.toString(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCompactHeaderButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
    required bool isDark,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.white.withOpacity(0.1)
                    : AppTheme.primary.withOpacity(0.1),
              ),
            ),
            child: Icon(
              icon,
              color: isDark ? Colors.white70 : AppTheme.primaryDark,
              size: 20,
            ),
          ),
        ),
      ),
    );
  }

  // Prominent welcome section for new users
  Widget _buildNewUserWelcome(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(authProvider).user;
    final hour = DateTime.now().hour;
    final greeting = hour < 12
        ? (l10n?.goodMorning ?? 'Good morning')
        : hour < 17
            ? (l10n?.goodAfternoon ?? 'Good afternoon')
            : (l10n?.goodEvening ?? 'Good evening');

    return Container(
      padding: EdgeInsets.all(isMobile ? 20 : 28),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppTheme.primaryDark.withOpacity(0.8),
                  const Color(0xFF0B2530),
                ]
              : [
                  AppTheme.primary,
                  AppTheme.primaryDark,
                ],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.waving_hand_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '$greeting, ${user?.fullName?.split(" ")[0] ?? 'Student'}!',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        height: 1.2,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.welcomeToExcellenceHub ?? 'Welcome to Excellence Hub!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.white.withOpacity(0.2),
              ),
            ),
            child: Text(
              l10n?.startFirstLesson ?? 'Start your first lesson today and begin your learning journey.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: isMobile ? 13 : 14,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeaderIconButton({
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.2),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.white.withOpacity(0.35),
          width: 2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.15),
            blurRadius: 12,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: IconButton(
        onPressed: onTap,
        icon: Icon(icon, color: Colors.white, size: 24),
        tooltip: tooltip,
        padding: const EdgeInsets.all(10),
      ),
    );
  }

  Widget _buildLanguageSwitcher() {
    return Consumer(
      builder: (context, ref, child) {
        final currentLocale = ref.watch(localeProvider);
        final currentLang = currentLocale.languageCode;
        
        return Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.2),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: PopupMenuButton<String>(
            icon: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  currentLang == 'en' ? '🇬🇧' : '🇷🇼',
                  style: const TextStyle(fontSize: 20),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.arrow_drop_down,
                  color: Colors.white,
                  size: 20,
                ),
              ],
            ),
            tooltip: 'Change Language',
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1E293B)
                : Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            onSelected: (String languageCode) async {
              await ref.read(localeProvider.notifier).setLanguage(languageCode);
            },
            itemBuilder: (BuildContext context) => [
              PopupMenuItem<String>(
                value: 'en',
                child: Row(
                  children: [
                    const Text('🇬🇧', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      'English',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A2433),
                        fontWeight: currentLang == 'en'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLang == 'en')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Color(0xFF00C896)),
                      ),
                  ],
                ),
              ),
              PopupMenuItem<String>(
                value: 'rw',
                child: Row(
                  children: [
                    const Text('🇷🇼', style: TextStyle(fontSize: 20)),
                    const SizedBox(width: 12),
                    Text(
                      'Kinyarwanda',
                      style: TextStyle(
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white
                            : const Color(0xFF1A2433),
                        fontWeight: currentLang == 'rw'
                            ? FontWeight.bold
                            : FontWeight.normal,
                      ),
                    ),
                    if (currentLang == 'rw')
                      const Padding(
                        padding: EdgeInsets.only(left: 8),
                        child: Icon(Icons.check, color: Color(0xFF00C896)),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildProfileAvatar(BuildContext context, dynamic user, bool isMobile) {
    final hasProfilePicture = user?.profilePicture != null && user!.profilePicture!.isNotEmpty;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: isMobile ? 64 : 80,
          height: isMobile ? 64 : 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(
              color: Colors.white.withOpacity(0.5),
              width: 3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: InkWell(
            onTap: () => context.go('/profile'),
            borderRadius: BorderRadius.circular(999),
            child: ClipOval(
              child: hasProfilePicture
                  ? NetworkImageWidget(
                      imageUrl: user.profilePicture!,
                      fit: BoxFit.cover,
                    )
                  : Container(
                      color: Colors.white.withOpacity(0.25),
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          Icon(
                            Icons.person_rounded,
                            color: Colors.white,
                            size: isMobile ? 32 : 40,
                          ),
                          Positioned(
                            bottom: 8,
                            right: 8,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFFBBF24),
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: Colors.white,
                                  width: 2,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.2),
                                    blurRadius: 4,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Icon(
                                Icons.camera_alt_rounded,
                                color: Colors.white,
                                size: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
        if (!hasProfilePicture) ...[
          const SizedBox(height: 8),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFFFBBF24).withOpacity(0.9),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.15),
                    blurRadius: 6,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.upload_rounded,
                    color: AppTheme.primaryDark,
                    size: isMobile ? 12 : 14,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Add Photo',
                    style: TextStyle(
                      color: AppTheme.primaryDark,
                      fontSize: isMobile ? 10 : 11,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  List<BoxShadow> _softShadows(Color color, {double opacity = 0.10}) {
    return [
      BoxShadow(
        color: color.withOpacity(opacity),
        blurRadius: 28,
        offset: const Offset(0, 14),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.04),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ];
  }

  BoxDecoration _modernPanelDecoration(BuildContext context, {Color? accent}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? const Color(0xFF111C2E) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE6ECF3);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor),
      boxShadow: _softShadows(accent ?? const Color(0xFF64748B),
          opacity: isDark ? 0.16 : 0.08),
    );
  }

  BoxDecoration _liveClassesDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? const Color(0xFF0D2D1A) 
        : const Color(0xFFECFDF5);
    final borderColor = isDark 
        ? const Color(0xFF10B981).withOpacity(0.3) 
        : const Color(0xFF10B981).withOpacity(0.2);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: _softShadows(const Color(0xFF10B981), opacity: isDark ? 0.2 : 0.12),
    );
  }

  BoxDecoration _examPreparationDecoration(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark 
        ? const Color(0xFF1E1B3A) 
        : const Color(0xFFF5F3FF);
    final borderColor = isDark 
        ? const Color(0xFF8B5CF6).withOpacity(0.3) 
        : const Color(0xFF8B5CF6).withOpacity(0.2);

    return BoxDecoration(
      color: baseColor,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(color: borderColor, width: 1.5),
      boxShadow: _softShadows(const Color(0xFF8B5CF6), opacity: isDark ? 0.2 : 0.12),
    );
  }

  // Modern Search Bar with visible search button
  Widget _buildModernSearchBar(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Column(
      children: [
        Container(
          height: isMobile ? 58 : 64,
          decoration: _modernPanelDecoration(
            context,
            accent: const Color(0xFF2563EB),
          ),
          child: Row(
            children: [
              // Search Icon
              Container(
                margin: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.search_rounded,
                  color: Color(0xFF0F766E),
                ),
              ),
              // Text Field
              Expanded(
                child: TextField(
                  controller: _searchController,
                  onSubmitted: _performSearch,
                  onChanged: (_) => setState(() {}),
                  textInputAction: TextInputAction.search,
                  decoration: InputDecoration(
                    hintText: _selectedCategoryName == null
                        ? l10n?.searchHint ?? 'Search courses, skills, lessons...'
                        : 'Search in $_selectedCategoryName...',
                    hintStyle: TextStyle(
                      color: isDark ? Colors.white60 : const Color(0xFF7C8797),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                    border: InputBorder.none,
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
                  ),
                ),
              ),
              // Action Buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Clear button
                  if (_searchController.text.isNotEmpty)
                    IconButton(
                      icon: Icon(
                        Icons.clear_rounded,
                        color:
                            isDark ? Colors.white54 : const Color(0xFF9A8A76),
                        size: 20,
                      ),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {});
                      },
                    ),
                  // Category Filter Button
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        setState(() => _showCategoryDropdown = !_showCategoryDropdown);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: _selectedCategoryId != null
                              ? const Color(0xFF10B981).withOpacity(0.15)
                              : Colors.transparent,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: _selectedCategoryId != null
                                ? const Color(0xFF10B981)
                                : (isDark ? Colors.white24 : const Color(0xFFE5E7EB)),
                            width: _selectedCategoryId != null ? 2 : 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              _showCategoryDropdown
                                  ? Icons.keyboard_arrow_up_rounded
                                  : Icons.tune_rounded,
                              color: _selectedCategoryId != null
                                  ? const Color(0xFF0F766E)
                                  : (isDark ? Colors.white70 : const Color(0xFF6B7280)),
                              size: 18,
                            ),
                            if (_selectedCategoryName != null) ...[
                              const SizedBox(width: 6),
                              Text(
                                _selectedCategoryName!,
                                style: TextStyle(
                                  color: const Color(0xFF0F766E),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Search Button
                  Material(
                    color: const Color(0xFF0F766E),
                    borderRadius: BorderRadius.circular(12),
                    child: InkWell(
                      onTap: _onSearchButtonTap,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        height: 44,
                        width: 44,
                        child: const Icon(
                          Icons.arrow_forward_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ],
          ),
        ),
        if (_showCategoryDropdown)
          Padding(
            padding: const EdgeInsets.only(top: 10),
            child: _buildCategoryDropdown(context),
          ),
      ],
    );
  }

  // Continue Learning Card
  Widget _buildContinueLearningCard(
      BuildContext context, List<Enrollment> enrollments) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    if (enrollments.isEmpty) {
      // Show Explore Courses card for users with no enrollments
      return _buildExploreCoursesCard(context);
    }

    final lastEnrollment = enrollments.first;
    final lastCourse = lastEnrollment.course;

    if (lastCourse == null) {
      return _buildExploreCoursesCard(context);
    }

    final progress = (lastEnrollment.progress / 100).clamp(0.0, 1.0);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryDark,
            AppTheme.primary,
            AppTheme.accent,
          ],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.18)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryDark.withOpacity(0.28),
            blurRadius: 26,
            offset: const Offset(0, 14),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: isMobile ? 54 : 64,
                height: isMobile ? 54 : 64,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: lastCourse.thumbnail != null &&
                        lastCourse.thumbnail!.isNotEmpty
                    ? ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: NetworkImageWidget(
                          imageUrl: lastCourse.thumbnail!,
                          fit: BoxFit.cover,
                        ),
                      )
                    : const Icon(
                        Icons.play_arrow_rounded,
                        color: Colors.white,
                        size: 28,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.continueLearning ?? 'Continue Learning',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastCourse.title,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w800,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Progress Bar
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Progress',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.8),
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Text(
                    '${lastEnrollment.progress.toInt()}%',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Container(
                height: 6,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FractionallySizedBox(
                  widthFactor: progress,
                  alignment: Alignment.centerLeft,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [AppTheme.primaryLight, Colors.white],
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Continue Button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () =>
                  CourseNavigationUtils.navigateToCourseWithContext(
                      context, ref, lastCourse),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.play_arrow_rounded, size: 20),
                  const SizedBox(width: 6),
                  Text(
                    l10n?.continueLearning ?? 'Continue Learning',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
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

  // Minimal Explore Courses Card for new users
  Widget _buildExploreCoursesCard(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: EdgeInsets.all(isMobile ? 14 : 18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111C2F) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.08)
              : AppTheme.primary.withOpacity(0.12),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withOpacity(isDark ? 0.15 : 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              Icons.school_outlined,
              color: AppTheme.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.startYourJourney ?? 'Start Your Journey',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: isMobile ? 14 : 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n?.findCourseForGoals ?? 'Find a course for your goals',
                  style: TextStyle(
                    color: AppTheme.getSecondaryTextColor(context),
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Compact Explore Button
          Material(
            color: AppTheme.primary,
            borderRadius: BorderRadius.circular(10),
            child: InkWell(
              onTap: () => context.push('/courses'),
              borderRadius: BorderRadius.circular(10),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.explore ?? 'Explore',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Progress Stats
  Widget _buildProgressStats(
      BuildContext context, List<Enrollment> enrollments) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length
        : 0.0;

    final statCards = [
      _buildStatCard(
        context,
        Icons.school_rounded,
        '$coursesEnrolled',
        'Enrolled',
        AppTheme.primary,
      ),
      _buildStatCard(
        context,
        Icons.verified_rounded,
        '$coursesCompleted',
        'Completed',
        AppTheme.accent,
      ),
      _buildStatCard(
        context,
        Icons.auto_graph_rounded,
        '${averageProgress.toInt()}%',
        'Avg Progress',
        AppTheme.primaryDark,
      ),
    ];

    return Container(
      padding: EdgeInsets.all(isMobile ? 10 : 12),
      decoration: _modernPanelDecoration(
        context,
        accent: AppTheme.primary,
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final spacing = isMobile ? 10.0 : 12.0;
          final columns = isMobile ? 2 : 3;
          final itemWidth =
              (constraints.maxWidth - spacing * (columns - 1)) / columns;

          return Wrap(
            spacing: spacing,
            runSpacing: spacing,
            children: [
              for (var index = 0; index < statCards.length; index++)
                SizedBox(
                  width:
                      isMobile && index == 2 ? constraints.maxWidth : itemWidth,
                  child: statCards[index],
                ),
            ],
          );
        },
      ),
    );
  }

  // Stat Card
  Widget _buildStatCard(
    BuildContext context,
    IconData icon,
    String value,
    String label,
    Color color,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 12 : 16),
      decoration: BoxDecoration(
        color:
            isDark ? Colors.white.withOpacity(0.04) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.18 : 0.12),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: isMobile ? 20 : 24,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: isMobile ? 11 : 12,
              color: AppTheme.getSecondaryTextColor(context),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  // Quick Actions
  Widget _buildQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final actions = [
      {
        'icon': Icons.play_lesson_rounded,
        'label': l10n?.myCourses ?? 'My Courses',
        'subtitle': l10n?.resumeLessons ?? 'Resume lessons',
        'route': '/my-courses',
        'color': AppTheme.primaryDark,
      },
      {
        'icon': Icons.download_done_rounded,
        'label': l10n?.downloads ?? 'Downloads',
        'subtitle': l10n?.studyOffline ?? 'Study offline',
        'route': '/downloads',
        'color': AppTheme.accent,
      },
      {
        'icon': Icons.verified_rounded,
        'label': l10n?.certificates ?? 'Certificates',
        'subtitle': l10n?.showProgress ?? 'Show progress',
        'route': '/certificates',
        'color': AppTheme.primary,
      },
      {
        'icon': Icons.local_library_rounded,
        'label': l10n?.library ?? 'E-Library',
        'subtitle': l10n?.browseBooks ?? 'Browse books',
        'route': '/library',
        'color': AppTheme.accent,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.quickAccess ?? 'Quick Access',
          style: TextStyle(
            fontSize: isMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            color: AppTheme.getTextColor(context),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final spacing = isMobile ? 10.0 : 12.0;
            final columns = isMobile ? 2 : 4;
            final itemWidth =
                (constraints.maxWidth - spacing * (columns - 1)) / columns;
            final itemHeight = isMobile ? 116.0 : 128.0;

            return Wrap(
              spacing: spacing,
              runSpacing: spacing,
              children: actions.map((action) {
                final color = action['color'] as Color;
                return SizedBox(
                  width: itemWidth,
                  height: itemHeight,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => context.push(action['route'] as String),
                      borderRadius: BorderRadius.circular(18),
                      child: Ink(
                        decoration: BoxDecoration(
                          color:
                              isDark ? const Color(0xFF111C2F) : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.16)),
                          boxShadow: _softShadows(
                            color,
                            opacity: isDark ? 0.18 : 0.10,
                          ),
                        ),
                        child: Padding(
                          padding: EdgeInsets.all(isMobile ? 10 : 14),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: isMobile ? 34 : 44,
                                height: isMobile ? 34 : 44,
                                decoration: BoxDecoration(
                                  gradient: LinearGradient(
                                    colors: [
                                      color,
                                      color.withOpacity(0.72),
                                    ],
                                  ),
                                  borderRadius: BorderRadius.circular(14),
                                  boxShadow: [
                                    BoxShadow(
                                      color: color.withOpacity(0.24),
                                      blurRadius: 12,
                                      offset: const Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Icon(
                                  action['icon'] as IconData,
                                  color: Colors.white,
                                  size: isMobile ? 18 : 22,
                                ),
                              ),
                              SizedBox(height: isMobile ? 8 : 10),
                              Flexible(
                                child: Text(
                                  action['label'] as String,
                                  style: TextStyle(
                                    fontSize: isMobile ? 12 : 14,
                                    fontWeight: FontWeight.w800,
                                    color: AppTheme.getTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Flexible(
                                child: Text(
                                  action['subtitle'] as String,
                                  style: TextStyle(
                                    fontSize: isMobile ? 10 : 12,
                                    fontWeight: FontWeight.w600,
                                    color:
                                        AppTheme.getSecondaryTextColor(context),
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            );
          },
        ),
      ],
    );
  }

  Widget _buildUpdateInterestsCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => context.push('/interest-selection', extra: {'isEditMode': true}),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _modernPanelDecoration(
            context,
            accent: AppTheme.primary,
          ),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 50,
                height: isMobile ? 42 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: AppTheme.primaryGradient,
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.tune_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.updateInterests ?? 'Update your interests',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.updateYourInterests ?? 'Refresh recommendations based on what you want to learn next.',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? AppTheme.primaryLight : AppTheme.primaryDark,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLiveClassesContactCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () => _showContactInfoDialog(context),
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _liveClassesDecoration(context),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 50,
                height: isMobile ? 42 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF10B981), Color(0xFF059669)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.live_tv_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.liveClassesAvailable ?? 'Live Classes Available',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.liveClassesBenefit ?? 'Get real-time interaction, instant feedback & personalized guidance from instructors.',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? const Color(0xFF6EE7B7) : const Color(0xFF059669),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildExamPreparationCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          final url = l10n?.examMarketplaceUrl ?? 'https://www.eexams.net/marketplace';
          final uri = Uri.parse(url);
          if (await canLaunchUrl(uri)) {
            await launchUrl(uri, mode: LaunchMode.externalApplication);
          }
        },
        borderRadius: BorderRadius.circular(22),
        child: Ink(
          padding: EdgeInsets.all(isMobile ? 16 : 20),
          decoration: _examPreparationDecoration(context),
          child: Row(
            children: [
              Container(
                width: isMobile ? 42 : 50,
                height: isMobile ? 42 : 50,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF8B5CF6), Color(0xFF6366F1)],
                  ),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.quiz_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n?.examPreparation ?? 'Exam Preparation',
                      style: TextStyle(
                        fontSize: isMobile ? 15 : 17,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.examPreparationBenefit ?? 'Access past papers, practice tests, and expert guidance to ace your exams',
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        height: 1.35,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
                      maxLines: isMobile ? 2 : 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: isDark ? const Color(0xFFA78BFA) : const Color(0xFF6366F1),
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showStatsDialog(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Row(
            children: [
              const Icon(Icons.auto_graph, color: Color(0xFF10B981)),
              const SizedBox(width: 12),
              Text(l10n?.learningStatistics ?? 'Learning Statistics'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _StatItem(
                icon: Icons.school,
                label: l10n?.coursesEnrolled ?? 'Courses Enrolled',
                value: '5',
                color: const Color(0xFF10B981),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.play_circle,
                label: l10n?.lessonsCompleted ?? 'Lessons Completed',
                value: '24',
                color: const Color(0xFF3B82F6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.quiz,
                label: l10n?.examsTaken ?? 'Exams Taken',
                value: '8',
                color: const Color(0xFF8B5CF6),
              ),
              const SizedBox(height: 16),
              _StatItem(
                icon: Icons.access_time,
                label: l10n?.hoursLearned ?? 'Hours Learned',
                value: '12.5',
                color: const Color(0xFFF59E0B),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(l10n?.close ?? 'Close'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCategoryDropdown(BuildContext context) {
    // Use .watch to get categories from AsyncNotifierProvider
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      margin: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.category_rounded,
                  color: const Color(0xFF10B981),
                  size: 20,
                ),
                const SizedBox(width: 8),
                Text(
                  l10n?.selectCategory ?? 'Select Category',
                  style: TextStyle(
                    color: AppTheme.getTextColor(context),
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                GestureDetector(
                  onTap: () {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _showCategoryDropdown = false);
                      }
                    });
                  },
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.getSecondaryTextColor(context),
                    size: 20,
                  ),
                ),
              ],
            ),
          ),
          // Category List
          Container(
            constraints: BoxConstraints(
              maxHeight: isMobile ? 200 : 300,
            ),
            child: categoriesAsync.when(
              data: (categories) {
                // Ensure categories is not null and is a list
                if (categories.isEmpty) {
                  return Container(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'No categories available',
                        style: TextStyle(
                          color: AppTheme.getSecondaryTextColor(context),
                          fontSize: 14,
                        ),
                      ),
                    ),
                  );
                }

                return ListView(
                  shrinkWrap: true,
                  children: [
                    // All Categories Option
                    _buildCategoryOption(
                      context,
                      'all',
                      l10n?.allCategories ?? 'All Categories',
                      l10n?.searchAcrossAllCourses ?? 'Search across all available courses',
                      Icons.grid_view_rounded,
                      const Color(0xFF10B981),
                      null,
                    ),
                    // Category Options - Add null checks
                    ...categories
                        .where((category) => category != null)
                        .map((category) => _buildCategoryOption(
                              context,
                              category.id,
                              category.name,
                              'Courses in ${category.name}',
                              CategoryUtils.getCategoryIcon(category.id,
                                  name: category.name),
                              CategoryUtils.getCategoryColor(category.id,
                                  name: category.name),
                              category,
                            )),
                  ],
                );
              },
              loading: () => Container(
                padding: const EdgeInsets.all(20),
                child: const Center(
                  child: CircularProgressIndicator(color: Color(0xFF10B981)),
                ),
              ),
              error: (_, __) => Container(
                padding: const EdgeInsets.all(20),
                child: Center(
                  child: Text(
                    l10n?.failedToLoadCategories ?? 'Failed to load categories',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryOption(
    BuildContext context,
    String categoryId,
    String name,
    String description,
    IconData icon,
    Color color,
    Category? category,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSelected = _selectedCategoryId == categoryId;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          // Immediate response for better UX
          setState(() {
            _selectedCategoryId = categoryId;
            _selectedCategoryName = name;
            _showCategoryDropdown = false;
          });

          // Perform search immediately if category is selected to improve UX
          if (categoryId != 'all') {
            _performSearch(''); // Trigger search with selected category
          }
        },
        splashColor: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 10 : 14),
          decoration: BoxDecoration(
            color: isSelected
                ? color.withOpacity(0.15)
                : isDark
                    ? const Color(0xFF2D3748)
                    : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected
                  ? color.withOpacity(0.3)
                  : isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Row(
            children: [
              // Animated icon container
              AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                curve: Curves.easeInOut,
                width: isMobile ? 36 : 44,
                height: isMobile ? 36 : 44,
                decoration: BoxDecoration(
                  color: isSelected
                      ? color.withOpacity(0.2)
                      : color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
                ),
                child: Icon(
                  icon,
                  color: isSelected ? color : color.withOpacity(0.8),
                  size: isMobile ? 18 : 22,
                ),
              ),
              SizedBox(width: isMobile ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      name,
                      style: TextStyle(
                        color:
                            isSelected ? color : AppTheme.getTextColor(context),
                        fontSize: isMobile ? 14 : 16,
                        fontWeight: FontWeight.w700,
                        height: 1.2,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: isMobile ? 2 : 4),
                    Text(
                      description,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: isMobile ? 11 : 12,
                        height: 1.2,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              // Animated checkmark
              AnimatedScale(
                scale: isSelected ? 1.0 : 0.0,
                duration: const Duration(milliseconds: 150),
                curve: Curves.elasticOut,
                child: Icon(
                  Icons.check_circle_rounded,
                  color: color,
                  size: isMobile ? 18 : 22,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCategoryFilters(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      height: isMobile ? 40 : 44,
      margin: EdgeInsets.only(bottom: isMobile ? 16 : 24),
      child: categoriesAsync.when(
        data: (categories) => ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: categories.length + 1,
          padding: EdgeInsets.zero,
          physics: const BouncingScrollPhysics(),
          itemBuilder: (context, index) {
            final isFirst = index == 0;
            final category = isFirst ? null : categories[index - 1];
            final categoryId = isFirst ? 'all' : category!.id;
            final color = CategoryUtils.getCategoryColor(categoryId,
                name: isFirst ? 'all' : category?.name);
            final name = isFirst ? 'All' : category!.name;
            final icon = CategoryUtils.getCategoryIcon(categoryId,
                name: isFirst ? 'all' : category?.name);

            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: InkWell(
                onTap: () {
                  context.push('/courses', extra: {
                    'categoryId': categoryId,
                    'categoryName': isFirst ? 'All Courses' : name,
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: color.withOpacity(0.12),
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        icon,
                        size: isMobile ? 16 : 18,
                        color: color,
                      ),
                      SizedBox(width: isMobile ? 6 : 8),
                      Text(
                        name,
                        style: TextStyle(
                          color: color,
                          fontWeight: FontWeight.w700,
                          fontSize: isMobile ? 12 : 13,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
        loading: () => const SizedBox.shrink(),
        error: (err, stack) => const SizedBox.shrink(),
      ),
    );
  }

  Widget _buildWelcomeCard(
      BuildContext context, user, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF00C896), Color(0xFF059669)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
        child: Column(
          children: [
            // Profile Header Section
            Row(
              children: [
                // Profile Picture
                Container(
                  width: isMobile ? 50 : 60,
                  height: isMobile ? 50 : 60,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: user?.profilePicture != null &&
                          user!.profilePicture!.isNotEmpty
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(30),
                          child: NetworkImageWidget(
                            imageUrl: user.profilePicture!,
                            fit: BoxFit.cover,
                          ),
                        )
                      : Icon(
                          Icons.person,
                          color: Colors.white,
                          size: isMobile ? 24 : 28,
                        ),
                ),
                const SizedBox(width: 16),
                // Greeting
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Hello, ${user?.fullName?.split(" ")[0] ?? 'Student'}!',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 20 : 24,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready to continue your learning journey?',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 12 : 14,
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Enhanced Notification Bell
                Consumer(
                  builder: (context, ref, child) {
                    final notifications =
                        ref.watch(notificationProvider).notifications;
                    final unreadCount =
                        notifications.where((n) => !n.isRead).length;
                    final isMobile = ResponsiveBreakpoints.isMobile(context);

                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeInOut,
                      child: Material(
                        color: Colors.transparent,
                        child: InkWell(
                          onTap: () {
                            // Clear notification badge when clicked
                            PushNotificationService.clearNotifications();
                            context.push('/notifications');
                          },
                          borderRadius: BorderRadius.circular(20),
                          splashColor: const Color(0xFF10B981).withOpacity(0.1),
                          child: Container(
                            width: isMobile ? 36 : 44,
                            height: isMobile ? 36 : 44,
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              alignment: Alignment.center,
                              children: [
                                // Bell Icon
                                AnimatedScale(
                                  scale: unreadCount > 0 ? 1.1 : 1.0,
                                  duration: const Duration(milliseconds: 150),
                                  curve: Curves.elasticOut,
                                  child: Icon(
                                    unreadCount > 0
                                        ? Icons.notifications_active_rounded
                                        : Icons.notifications_outlined,
                                    color: Colors.white,
                                    size: isMobile ? 18 : 22,
                                  ),
                                ),
                                // Notification Badge
                                AnimatedScale(
                                  scale: unreadCount > 0 ? 1.0 : 0.0,
                                  duration: const Duration(milliseconds: 200),
                                  curve: Curves.bounceOut,
                                  child: Container(
                                    width: isMobile ? 16 : 20,
                                    height: isMobile ? 16 : 20,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFEF4444),
                                      shape: BoxShape.circle,
                                      border: Border.all(
                                        color: Colors.white,
                                        width: 2,
                                      ),
                                    ),
                                    child: Center(
                                      child: Text(
                                        unreadCount > 99
                                            ? '99+'
                                            : unreadCount.toString(),
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: isMobile ? 8 : 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),
            // Search Bar floats on the green card
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: _buildEnhancedSearchBar(context, false),
            ),
            // Category Dropdown
            if (_showCategoryDropdown)
              GestureDetector(
                onTap: () {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _showCategoryDropdown = false);
                    }
                  });
                },
                child: _buildCategoryDropdown(context),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchBar(BuildContext context, bool isDark) {
    return Row(
      children: [
        // Category Filter Button
        GestureDetector(
          onTap: () {
            // Use WidgetsBinding to prevent frame callback issues
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (mounted) {
                setState(() => _showCategoryDropdown = !_showCategoryDropdown);
              }
            });
          },
          child: Container(
            height: 48,
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: _selectedCategoryId != null
                  ? const Color(0xFF10B981).withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              border: Border(
                right: BorderSide(
                  color: isDark
                      ? const Color(0xFF374151)
                      : const Color(0xFFE5E7EB),
                  width: 1,
                ),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.category_outlined,
                  color: _selectedCategoryId != null
                      ? const Color(0xFF10B981)
                      : AppTheme.getSecondaryTextColor(context),
                  size: 18,
                ),
                const SizedBox(width: 6),
                Text(
                  _selectedCategoryName ?? 'All',
                  style: TextStyle(
                    color: _selectedCategoryId != null
                        ? const Color(0xFF10B981)
                        : AppTheme.getSecondaryTextColor(context),
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(width: 4),
                Icon(
                  _showCategoryDropdown
                      ? Icons.keyboard_arrow_up
                      : Icons.keyboard_arrow_down,
                  color: _selectedCategoryId != null
                      ? const Color(0xFF10B981)
                      : AppTheme.getSecondaryTextColor(context),
                  size: 16,
                ),
              ],
            ),
          ),
        ),
        // Search Input
        Expanded(
          child: TextField(
            controller: _searchController,
            onSubmitted: _performSearch,
            onChanged: (value) {
              if (_showCategoryDropdown) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  if (mounted) {
                    setState(() {});
                  }
                });
              }
            },
            decoration: InputDecoration(
              hintText: _selectedCategoryId != null
                  ? 'Search in $_selectedCategoryName...'
                  : 'Search courses, topics, instructors...',
              hintStyle: TextStyle(
                color: AppTheme.getSecondaryTextColor(context),
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search_outlined,
                color: AppTheme.getSecondaryTextColor(context),
              ),
              suffixIcon: _searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear_rounded,
                          color: AppTheme.greyColor),
                      onPressed: () {
                        _searchController.clear();
                      },
                    )
                  : IconButton(
                      icon: Icon(
                        Icons.tune,
                        color: AppTheme.getSecondaryTextColor(context),
                        size: 18,
                      ),
                      onPressed: () {
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (mounted) {
                            setState(() =>
                                _showCategoryDropdown = !_showCategoryDropdown);
                          }
                        });
                      },
                    ),
              border: InputBorder.none,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLiveClassInfo(BuildContext context, bool isDark) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        padding: EdgeInsets.all(isMobile ? 12 : 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF10B981).withOpacity(0.1),
              const Color(0xFF06B6D4).withOpacity(0.05),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF10B981).withOpacity(0.2),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            // Icon
            Container(
              width: isMobile ? 32 : 40,
              height: isMobile ? 32 : 40,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.15),
                borderRadius: BorderRadius.circular(isMobile ? 8 : 10),
              ),
              child: Icon(
                Icons.live_tv_rounded,
                color: const Color(0xFF10B981),
                size: isMobile ? 16 : 20,
              ),
            ),
            SizedBox(width: isMobile ? 10 : 12),
            // Message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n?.liveClassesAvailable ?? 'Live Classes Available',
                    style: TextStyle(
                      color: const Color(0xFF10B981),
                      fontSize: isMobile ? 14 : 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  SizedBox(height: isMobile ? 4 : 6),
                  Text(
                    'Want to join our live classes? Contact us to get started!',
                    style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context),
                      fontSize: isMobile ? 12 : 13,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            // Contact Options
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildContactOption(
                    context,
                    Icons.email_rounded,
                    'Email',
                    'support@excellencecoachinghub.com',
                    () => _launchEmail('support@excellencecoachinghub.com'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.phone_rounded,
                    'Phone',
                    '+0781 671 517',
                    () => _launchPhone('0781671517'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.phone_rounded,
                    'Phone',
                    '+250 788 1234',
                    () => _launchPhone('2507881234'),
                  ),
                  SizedBox(height: isMobile ? 6 : 8),
                  _buildContactOption(
                    context,
                    Icons.message_rounded,
                    'WhatsApp',
                    '+250 788 1234',
                    () => _launchWhatsApp('2507881234'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showContactDialog(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          contentPadding: EdgeInsets.zero,
          content: Container(
            constraints: BoxConstraints(
              maxWidth: isMobile ? 300 : 400,
            ),
            padding: EdgeInsets.all(isMobile ? 20 : 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.contact_support_rounded,
                        color: Color(0xFF10B981),
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Contact Us for Live Classes',
                      style: TextStyle(
                        fontSize: isMobile ? 16 : 18,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Contact Options
                _buildContactOption(
                  context,
                  Icons.email_rounded,
                  'Email',
                  'support@excellencecoachinghub.com',
                  () => _launchEmail('support@excellencecoachinghub.com'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.phone_rounded,
                  'Phone',
                  '+0781 671 517',
                  () => _launchPhone('0781671517'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.phone_rounded,
                  'Phone',
                  '+250 788 1234',
                  () => _launchPhone('2507881234'),
                ),
                SizedBox(height: isMobile ? 6 : 8),
                _buildContactOption(
                  context,
                  Icons.message_rounded,
                  'WhatsApp',
                  '+250 788 1234',
                  () {
                    // Open WhatsApp
                    Navigator.of(context).pop();
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(
                'Close',
                style: TextStyle(
                  color: const Color(0xFF10B981),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildContactOption(
    BuildContext context,
    IconData icon,
    String title,
    String value,
    VoidCallback onTap,
  ) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        splashColor: const Color(0xFF10B981).withOpacity(0.1),
        child: Container(
          padding: EdgeInsets.all(isMobile ? 12 : 16),
          decoration: BoxDecoration(
            color: Theme.of(context).brightness == Brightness.dark
                ? const Color(0xFF1F2937)
                : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: const Color(0xFFE5E7EB),
              width: 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: const Color(0xFF10B981),
                  size: 16,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.getTextColor(context),
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getSecondaryTextColor(context),
                      ),
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

  Widget _buildCompactContinueButton(BuildContext context, Course lastCourse) {
    return InkWell(
      onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
          context, ref, lastCourse),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.1), width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.play_arrow_rounded,
                  color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    (l10n?.continueLearning ?? 'CONTINUE LEARNING').toUpperCase(),
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                    ),
                  ),
                  Text(
                    lastCourse.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Colors.white70),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopStatsOverlay(BuildContext context,
      List<Enrollment> enrollments, double averageProgress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: !isMobile(context)
            ? Colors.white.withOpacity(0.12)
            : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: !isMobile(context)
            ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5)
            : null,
        boxShadow: !isMobile(context)
            ? []
            : [
                BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 10),
              ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildWelcomeStatItem(
                    context,
                    Icons.school_rounded,
                    '${enrollments.length} Courses',
                    'Enrolled',
                    !isMobile(context) ? Colors.white : const Color(0xFF10B981),
                    isDesktop: !isMobile(context)),
                SizedBox(height: isDesktop ? 16 : 12),
                _buildWelcomeStatItem(
                    context,
                    Icons.auto_graph_rounded,
                    '${averageProgress.toInt()}%',
                    'Avg. Progress',
                    !isMobile(context) ? Colors.white : const Color(0xFF06B6D4),
                    isDesktop: !isMobile(context)),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          _buildCircularProgress(context, averageProgress,
              mini: isMobile(context) || !isDesktop,
              color: !isMobile(context) ? Colors.white : null),
        ],
      ),
    );
  }

  bool isMobile(BuildContext context) =>
      ResponsiveBreakpoints.isMobile(context);

  Widget _buildWelcomeStatItem(BuildContext context, IconData icon,
      String value, String label, Color color,
      {bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
              color: isDesktop
                  ? Colors.white.withOpacity(0.2)
                  : color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: isDesktop ? Colors.white : color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: isDesktop
                        ? Colors.white
                        : (isDark ? Colors.white : const Color(0xFF333333)),
                    height: 1.2,
                  )),
              Text(label,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDesktop
                        ? Colors.white.withOpacity(0.8)
                        : (isDark ? Colors.white70 : const Color(0xFF9CA3AF)),
                    height: 1.2,
                  )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context, double progress,
      {bool mini = false, Color? color}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = mini ? 54.0 : 70.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: size,
          height: size,
          child: CircularProgressIndicator(
            value: progress / 100,
            strokeWidth: mini ? 5 : 8,
            backgroundColor: Colors.white.withOpacity(0.15),
            valueColor: AlwaysStoppedAnimation<Color>(
                color ?? (mini ? Colors.white : const Color(0xFF10B981))),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${progress.toInt()}%',
                style: TextStyle(
                  fontSize: mini ? 12 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                )),
            if (!mini)
              Text('Completed',
                  style: TextStyle(
                    fontSize: 8,
                    color: Colors.white70,
                  )),
          ],
        ),
      ],
    );
  }

  Widget _buildAdminAccessButton(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.all(isMobile ? 16 : 20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF00C896), Color(0xFF059669)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.admin_panel_settings,
              color: Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n?.adminPanel ?? 'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: isMobile ? 16 : 18,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  l10n?.coursesManagement ?? 'Manage courses, students & settings',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.9),
                    fontSize: isMobile ? 12 : 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
            child: IconButton(
              icon: const Icon(Icons.arrow_forward, color: Color(0xFF00C896)),
              onPressed: () => context.push('/admin'),
            ),
          ),
        ],
      ),
    );
  }

  // FIX #4: Removed unused _buildQuickActions (non-responsive version).
  // Only _buildResponsiveQuickActions is kept since it's the only one referenced.

  Widget _buildResponsiveQuickActions(BuildContext context) {
    final actions = [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'subtitle': l10n?.continueText ?? 'Continue',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'subtitle': l10n?.offline ?? 'Offline',
        'icon': Icons.file_download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': l10n?.exams ?? 'Exams',
        'subtitle': l10n?.history ?? 'History',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/exams/history'),
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'subtitle': l10n?.awards ?? 'Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/certificates'),
      },
    ];

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final crossAxisCount = isDesktop
        ? 4
        : (isMobile ? 4 : 2); // 4 in a row for mobile too to be COMPACT

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Quick Access',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () {}, // Optional: more actions
              child: Text(l10n?.seeAll ?? 'See All',
                  style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: crossAxisCount,
            crossAxisSpacing: isMobile ? 8 : 20,
            mainAxisSpacing: isMobile ? 8 : 20,
            childAspectRatio: isMobile ? 0.85 : 1.6,
          ),
          itemCount: actions.length,
          itemBuilder: (context, index) {
            final action = actions[index];
            return _QuickAccessCard(
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['onTap'] as Function,
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

  Widget _buildLearningAndOnboarding(
      BuildContext context, List<Enrollment> enrollments) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Column(
      children: [
        _buildContinueLearning(context, enrollments),
        const SizedBox(height: 24),
        _buildMyProgress(context, enrollments),
      ],
    );
  }

  // Desktop stats section for right column
  Widget _buildDesktopStatsSection(
      BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Calculate statistics
    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length
        : 0.0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            l10n?.myProgress ?? 'My Progress',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 20),
          _DesktopStatCard(
            icon: Icons.school_rounded,
            value: '$coursesEnrolled',
            label: l10n?.coursesEnrolled ?? 'Courses Enrolled',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.verified_rounded,
            value: '$coursesCompleted',
            label: l10n?.completed ?? 'Completed',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.auto_graph_rounded,
            value: '${averageProgress.toInt()}%',
            label: l10n?.averageScore ?? 'Average Score',
            color: const Color(0xFFF59E0B),
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  // Desktop quick actions for right column
  Widget _buildDesktopQuickActions(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final quickActions = [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'subtitle': l10n?.continueCourses ?? 'Continue Courses',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': l10n?.library ?? 'Library',
        'subtitle': l10n?.browseResources ?? 'Browse Resources',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.go('/library'),
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'subtitle': l10n?.offlineContent ?? 'Offline Content',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'subtitle': l10n?.viewAwards ?? 'View Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/certificates'),
      },
      {
        'title': l10n?.examHistory ?? 'Exam History',
        'subtitle': l10n?.pastResults ?? 'Past Results',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.go('/exams/history'),
      },
    ];

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.3)
                : Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Access',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.5,
              color: AppTheme.getTextColor(context),
            ),
          ),
          const SizedBox(height: 16),
          ...quickActions
              .map((action) => Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _DesktopQuickActionCard(
                      title: action['title'] as String,
                      subtitle: action['subtitle'] as String,
                      icon: action['icon'] as IconData,
                      color: action['color'] as Color,
                      onTap: action['onTap'] as Function,
                      isDark: isDark,
                    ),
                  ))
              ,
        ],
      ),
    );
  }

  Widget _buildMyProgress(BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    // Calculate statistics
    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) /
            enrollments.length
        : 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n?.myProgress ?? 'My Progress',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            // Courses Enrolled Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFDCFCE7),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.school_rounded,
                        color: Color(0xFF10B981),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$coursesEnrolled',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF10B981),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.coursesEnrolled ?? 'Courses Enrolled',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Courses Completed Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFDBEAFE),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFF3B82F6).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.verified_rounded,
                        color: Color(0xFF3B82F6),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '$coursesCompleted',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF3B82F6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.completed ?? 'Completed',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            // Average Score Card
            Expanded(
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1F2937)
                      : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark
                        ? const Color(0xFF374151)
                        : const Color(0xFFFDE68A),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(
                        Icons.auto_graph_rounded,
                        color: Color(0xFFF59E0B),
                        size: 18,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${averageProgress.toInt()}%',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 20 : 24,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFFF59E0B),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      l10n?.averageScore ?? 'Average Score',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 11 : 12,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildQuickNavigationButtons(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    final quickActions = [
      {
        'title': 'Library',
        'subtitle': 'Browse Resources',
        'icon': Icons.local_library_rounded,
        'color': const Color(0xFF6366F1),
        'onTap': () => context.go('/library'),
      },
      {
        'title': 'Downloads',
        'subtitle': 'Offline Content',
        'icon': Icons.download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': 'Exam History',
        'subtitle': 'Past Results',
        'icon': Icons.history_edu_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.go('/exams/history'),
      },
      {
        'title': 'Discover',
        'subtitle': 'New Courses',
        'icon': Icons.explore_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.go('/courses'),
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Access',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        // Responsive grid layout
        if (isMobile)
          Column(
            children: quickActions
                .map((action) => Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: _buildQuickActionCard(
                        context: context,
                        title: action['title'] as String,
                        subtitle: action['subtitle'] as String,
                        icon: action['icon'] as IconData,
                        color: action['color'] as Color,
                        onTap: action['onTap'] as Function,
                        isFullWidth: true,
                      ),
                    ))
                .toList(),
          )
        else
          Row(
            children: quickActions
                .map((action) => Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 16),
                        child: _buildQuickActionCard(
                          context: context,
                          title: action['title'] as String,
                          subtitle: action['subtitle'] as String,
                          icon: action['icon'] as IconData,
                          color: action['color'] as Color,
                          onTap: action['onTap'] as Function,
                          isFullWidth: false,
                        ),
                      ),
                    ))
                .toList(),
          ),
      ],
    );
  }

  Widget _buildQuickActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required Function onTap,
    required bool isFullWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        width: isFullWidth ? double.infinity : null,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1F2937) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.3)
                  : Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 20,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: AppTheme.getSecondaryTextColor(context),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: AppTheme.getSecondaryTextColor(context),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContinueLearning(
      BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);

    if (enrollments.isEmpty) {
      return const SizedBox.shrink(); // Hide if no enrollments
    }

    final lastEnrollment = enrollments.first;
    final course = lastEnrollment.course;
    if (course == null) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.continueLearning ?? 'Continue Learning',
              style: TextStyle(
                fontSize: isSmallMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/my-courses'),
              child: Text(
                l10n?.seeAll ?? 'See All',
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                  color: const Color(0xFF10B981),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1F2937) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.3)
                    : Colors.black.withOpacity(0.05),
                blurRadius: 10,
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
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child:
                        course.thumbnail != null && course.thumbnail!.isNotEmpty
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: NetworkImageWidget(
                                  imageUrl: course.thumbnail!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(
                                Icons.play_circle_filled,
                                color: const Color(0xFF10B981),
                                size: 30,
                              ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          course.title,
                          style: TextStyle(
                            fontSize: isSmallMobile ? 16 : 18,
                            fontWeight: FontWeight.w700,
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
                            fontSize: isSmallMobile ? 12 : 14,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Progress Section
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Progress',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.getSecondaryTextColor(context),
                        ),
                      ),
                      Text(
                        '${lastEnrollment.progress.toInt()}%',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF10B981),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 8,
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF374151)
                          : const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: lastEnrollment.progress / 100,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // Continue Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () =>
                      CourseNavigationUtils.navigateToCourseWithContext(
                          context, ref, course),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF10B981),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.play_arrow_rounded, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        l10n?.continueLearning ?? 'Continue Learning',
                        style: TextStyle(
                          fontSize: isSmallMobile ? 14 : 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
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
      height: 300, // Fixed height for uniform sizing
      decoration: BoxDecoration(
        color: AppTheme.getCardColor(context),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.4)
                : Colors.black.withOpacity(0.05),
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
          onTap: () => CourseNavigationUtils.navigateToCourseWithContext(
              context, ref, course),
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
                    color: isDark
                        ? AppTheme.primary.withOpacity(0.1)
                        : AppTheme.primary.withOpacity(0.05),
                    child: course.thumbnail != null &&
                            course.thumbnail!.isNotEmpty
                        ? NetworkImageWidget(
                            imageUrl: course.thumbnail!,
                            fit: BoxFit.cover,
                            errorWidget: const Icon(Icons.play_circle_filled,
                                color: AppTheme.primary, size: 40),
                          )
                        : const Icon(Icons.play_circle_filled,
                            color: AppTheme.primary, size: 40),
                  ),
                ),
                const SizedBox(height: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
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
                      const Spacer(),
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
                                  color:
                                      AppTheme.getSecondaryTextColor(context),
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
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                  AppTheme.primary),
                              minHeight: isMobile ? 3 : 5,
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
      ),
    );
  }

  Widget _buildRecommendedCourses(BuildContext context, List<Course> courses,
      List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    final displayCourses = courses.take(8).toList();

    if (displayCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.recommendedForYou ?? 'Recommended for you',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: Text(
                l10n?.seeAll ?? 'See All',
                style: TextStyle(
                  color: const Color(0xFF0F766E),
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: isMobile ? 244 : 264,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: displayCourses.length,
            padding: EdgeInsets.zero,
            itemBuilder: (context, index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _buildModernCourseCard(
                    context, displayCourses[index], enrolledCourses),
              );
            },
          ),
        ),
      ],
    );
  }

  // Modern Course Card
  Widget _buildModernCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isEnrolled = enrolledCourses.any((c) => c.id == course.id);

    final cardWidth = isMobile ? 178.0 : 206.0;
    final price = course.price ?? 0;
    final isFree = price == 0;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        width: cardWidth,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF111C2F) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isDark ? const Color(0xFF263449) : const Color(0xFFF1E6D1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (isDark ? Colors.black : AppTheme.primary)
                  .withOpacity(isDark ? 0.24 : 0.08),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Course Thumbnail
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.1),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(18),
                        topRight: Radius.circular(18),
                      ),
                    ),
                    child: course.thumbnail != null &&
                            course.thumbnail!.isNotEmpty
                        ? ClipRRect(
                            borderRadius: const BorderRadius.only(
                              topLeft: Radius.circular(16),
                              topRight: Radius.circular(16),
                            ),
                            child: NetworkImageWidget(
                              imageUrl: course.thumbnail!,
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Icon(
                              Icons.play_circle_filled,
                              color: const Color(0xFF10B981).withOpacity(0.5),
                              size: 40,
                            ),
                          ),
                  ),
                  if (isEnrolled)
                    Positioned(
                      top: 8,
                      left: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'Enrolled',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),
                  Positioned(
                    right: 8,
                    bottom: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.58),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        isFree ? 'FREE' : 'RWF ${price.toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Course Info
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isMobile ? 12 : 13,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    if (course.category != null)
                      Text(
                        course.category is String
                            ? course.category as String
                            : 'Category',
                        style: TextStyle(
                          fontSize: isMobile ? 10 : 11,
                          color: AppTheme.getSecondaryTextColor(context),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Row(
                      children: [
                        Icon(
                          Icons.star_rounded,
                          color: const Color(0xFFF59E0B),
                          size: isMobile ? 14 : 15,
                        ),
                        const SizedBox(width: 3),
                        Text(
                          (course.averageRating ?? 0.0).toStringAsFixed(1),
                          style: TextStyle(
                            fontSize: isMobile ? 10 : 11,
                            fontWeight: FontWeight.w800,
                            color: AppTheme.getSecondaryTextColor(context),
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 16,
                          color:
                              isDark ? Colors.white70 : const Color(0xFF0F766E),
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
    );
  }

  Widget _buildRecommendedCoursesGrid(BuildContext context,
      List<Course> courses, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.6,
      ),
      itemCount: courses.length,
      itemBuilder: (context, index) {
        return _buildRecommendedCourseCard(
            context, courses[index], enrolledCourses);
      },
    );
  }

  Widget _buildModernCategorySection(BuildContext context) {
    final categoriesAsync = ref.watch(backendCategoriesProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.exploreCategories ?? 'Explore Categories',
              style: TextStyle(
                fontSize: isMobile ? 18 : 20,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
                color: AppTheme.getTextColor(context),
              ),
            ),
            if (!isMobile)
              TextButton(
                onPressed: () => context.push('/courses'),
                child: Text(
                  l10n?.viewAll ?? 'View All',
                  style: TextStyle(
                    color: const Color(0xFF10B981),
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 16),
        categoriesAsync.when(
          data: (categories) {
            final displayCategories = isDesktop
                ? categories.take(6).toList()
                : categories.take(4).toList();
            return isDesktop
                ? _buildCategoryGrid(context, displayCategories)
                : _buildCategoryHorizontalList(context, displayCategories);
          },
          loading: () => _buildCategoryLoading(context),
          error: (_, __) => _buildCategoryError(context),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(BuildContext context, List<Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 1.3,
      ),
      itemCount: categories.length,
      itemBuilder: (context, index) {
        final category = categories[index];
        final color =
            CategoryUtils.getCategoryColor(category.id, name: category.name);
        final icon =
            CategoryUtils.getCategoryIcon(category.id, name: category.name);

        return Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () {
              context.push('/courses', extra: {
                'categoryId': category.id,
                'categoryName': category.name,
              });
            },
            borderRadius: BorderRadius.circular(16),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    color.withOpacity(0.15),
                    color.withOpacity(0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: color.withOpacity(0.3),
                  width: 1.5,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      icon,
                      color: color,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    category.name,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCategoryHorizontalList(
      BuildContext context, List<Category> categories) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SizedBox(
      height: 100,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: categories.length,
        padding: EdgeInsets.zero,
        physics: const BouncingScrollPhysics(),
        itemBuilder: (context, index) {
          final category = categories[index];
          final color =
              CategoryUtils.getCategoryColor(category.id, name: category.name);
          final icon =
              CategoryUtils.getCategoryIcon(category.id, name: category.name);

          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () {
                  context.push('/courses', extra: {
                    'categoryId': category.id,
                    'categoryName': category.name,
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  width: 100,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.15),
                        color.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                      width: 1.5,
                    ),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(
                          icon,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Text(
                          category.name,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.getTextColor(context),
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildCategoryLoading(BuildContext context) {
    return SizedBox(
      height: 100,
      child: const Center(
        child: CircularProgressIndicator(color: Color(0xFF10B981)),
      ),
    );
  }

  Widget _buildCategoryError(BuildContext context) {
    return SizedBox(
      height: 100,
      child: Center(
        child: Text(
          'Failed to load categories',
          style: TextStyle(
            color: AppTheme.getSecondaryTextColor(context),
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCourseCard(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final price = course.price ?? 0;
    final isFree = price == 0;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
          ),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.25)
                  : Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Thumbnail
            ClipRRect(
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                bottomLeft: Radius.circular(16),
              ),
              child: SizedBox(
                width: isMobile ? 90 : 100,
                height: isMobile ? 90 : 100,
                child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                    ? NetworkImageWidget(
                        imageUrl: course.thumbnail!,
                        fit: BoxFit.cover,
                        width: isMobile ? 90 : 100,
                        height: isMobile ? 90 : 100,
                      )
                    : Container(
                        color: const Color(0xFF10B981).withOpacity(0.15),
                        child: const Icon(
                          Icons.play_circle_fill,
                          color: Color(0xFF10B981),
                          size: 36,
                        ),
                      ),
              ),
            ),
            // Info
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Level badge
                    if (course.level.isNotEmpty)
                      Container(
                        margin: const EdgeInsets.only(bottom: 6),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981).withOpacity(0.12),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          course.level[0].toUpperCase() +
                              course.level.substring(1),
                          style: const TextStyle(
                            color: Color(0xFF059669),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    Text(
                      course.title,
                      style: TextStyle(
                        fontSize: isMobile ? 13 : 15,
                        fontWeight: FontWeight.w700,
                        color: AppTheme.getTextColor(context),
                        height: 1.3,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      course.displayInstructor,
                      style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        // Price
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isFree
                                ? const Color(0xFF10B981).withOpacity(0.1)
                                : const Color(0xFF3B82F6).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            isFree ? 'FREE' : 'RWF ${price.toStringAsFixed(0)}',
                            style: TextStyle(
                              color: isFree
                                  ? const Color(0xFF059669)
                                  : const Color(0xFF2563EB),
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const Spacer(),
                        if (isEnrolled)
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: const Color(0xFF10B981),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text(
                              'Enrolled',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          )
                        else
                          Icon(
                            Icons.arrow_forward_ios_rounded,
                            size: 14,
                            color: AppTheme.getSecondaryTextColor(context),
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
    );
  }

  Widget _buildCourseCardV2(
      BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return EnhancedCourseNavigation(
      course: course,
      showRipple: true,
      enableHapticFeedback: true,
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFF3F4F6)),
          boxShadow: [
            BoxShadow(
                color: isDark
                    ? Colors.black.withOpacity(0.2)
                    : Colors.black.withOpacity(0.02),
                blurRadius: 10)
          ],
        ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image with badge
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: const BorderRadius.all(Radius.circular(20)),
                    child: Container(
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.thumbnail != null &&
                                course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(
                                imageUrl: course.thumbnail!, fit: BoxFit.cover)
                            : Icon(Icons.image_outlined,
                                size: 40,
                                color: isDark
                                    ? Colors.white38
                                    : const Color(0xFF9CA3AF)),
                      ),
                    ),
                  ),
                  if (isEnrolled)
                    Positioned(
                      top: 16,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF10B981),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.check_circle_rounded,
                                color: Colors.white, size: 12),
                            SizedBox(width: 4),
                            Text(
                              'ENROLLED',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800),
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: ((course.price ?? 0) == 0
                                  ? const Color(0xFF10B981)
                                  : const Color(0xFF0F766E))
                              .withOpacity(0.9),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          (course.price ?? 0) == 0 ? 'FREE' : 'PAID',
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w800),
                        ),
                      ),
                    ),
                    if ((course.price ?? 0) > 0)
                      Positioned(
                        top: 16,
                        left: 16,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.red.withOpacity(0.9),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text(
                            '20% OFF',
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w900),
                          ),
                        ),
                      ),
                  ],
                ],
              ),
              // Content section with fixed height to prevent overflow
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 14),
                child: SizedBox(
                  height: 110,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title - takes available space
                      Expanded(
                        child: Text(
                          course.title,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color:
                                isDark ? Colors.white : const Color(0xFF1F2937),
                            height: 1.25,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Rating row
                      Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: Colors.amber, size: 13),
                          const SizedBox(width: 3),
                          Text(
                            (course.averageRating ?? 0.0).toStringAsFixed(1),
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF1F2937),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '(${course.enrollmentCount ?? 0})',
                            style: TextStyle(
                              fontSize: 10,
                              color: isDark
                                  ? const Color(0xFF94A3B8)
                                  : const Color(0xFF6B7280),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      // Bottom row - Continue button or Price
                      if (isEnrolled)
                        Container(
                          width: double.infinity,
                          height: 34,
                          decoration: BoxDecoration(
                            color: AppTheme.primaryGreen,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.play_arrow_rounded,
                                  color: Colors.white, size: 16),
                              SizedBox(width: 4),
                              Text(
                                'Continue',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        )
                      else
                        SizedBox(
                          height: 34,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              if ((course.price ?? 0) > 0)
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      'RWF ${((course.price ?? 0) / 0.8).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 9,
                                        color: isDark
                                            ? Colors.white38
                                            : const Color(0xFF9CA3AF),
                                        decoration: TextDecoration.lineThrough,
                                      ),
                                    ),
                                    Text(
                                      'RWF ${(course.price ?? 0).toStringAsFixed(0)}',
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: isDark
                                            ? const Color(0xFF2DD4BF)
                                            : const Color(0xFF0F766E),
                                      ),
                                    ),
                                  ],
                                )
                              else
                                const Text(
                                  'FREE',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: Color(0xFF10B981),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: ((course.price ?? 0) == 0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B))
                                      .withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      (course.price ?? 0) == 0
                                          ? Icons.check_circle_rounded
                                          : Icons.monetization_on_rounded,
                                      size: 10,
                                      color: (course.price ?? 0) == 0
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                    ),
                                    const SizedBox(width: 3),
                                    Text(
                                      (course.price ?? 0) == 0 ? 'FREE' : 'PAID',
                                      style: TextStyle(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w800,
                                        color: (course.price ?? 0) == 0
                                            ? const Color(0xFF10B981)
                                            : const Color(0xFFF59E0B),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
    );
  }

  Widget _buildResponsivePopularCourses(BuildContext context,
      List<Course> popularCourses, List<Course> enrolledCourses) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              l10n?.popularCourses ?? 'Popular Courses',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            TextButton(
              onPressed: () => context.push('/courses'),
              child: const Text('View All',
                  style: TextStyle(fontWeight: FontWeight.w700)),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (isDesktop || isTablet)
          LayoutBuilder(
            builder: (context, constraints) {
              // Calculate card width based on available space
              final cardWidth = (constraints.maxWidth - (crossAxisCount - 1) * 20) / crossAxisCount;
              // Card height = image (16:9 ratio of width) + content (120 fixed)
              final imageHeight = cardWidth * 9 / 16;
              final cardHeight = imageHeight + 120;
              final aspectRatio = cardWidth / cardHeight;

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 20,
                  mainAxisSpacing: 20,
                  childAspectRatio: aspectRatio,
                ),
                itemCount: popularCourses.take(crossAxisCount * 2).length,
                itemBuilder: (context, index) {
                  return _buildCourseCardV2(
                      context, popularCourses[index], enrolledCourses);
                },
              );
            },
          )
        else
          SizedBox(
            height: 300,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: popularCourses.length,
              itemBuilder: (context, index) {
                return Container(
                  width: 260,
                  margin: const EdgeInsets.only(right: 12),
                  child: _buildCourseCardV2(
                      context, popularCourses[index], enrolledCourses),
                );
              },
            ),
          ),
      ],
    );
  }

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
                  style: TextStyle(
                      color: AppTheme.getSecondaryTextColor(context))),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
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
            Text(l10n?.contactUs ?? 'Contact Us',
                style: TextStyle(color: AppTheme.getTextColor(context))),
          ]),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: l10n?.whatsapp ?? 'WhatsApp',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchWhatsApp('250793828834')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.message,
                    title: l10n?.whatsapp ?? 'WhatsApp',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchWhatsApp('250788535156')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '+250 788 535 156',
                    onTap: () => _launchPhone('250788535156')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '+250 793 828 834',
                    onTap: () => _launchPhone('250793828834')),
                const SizedBox(height: 8),
                _buildContactMethod(context,
                    icon: Icons.phone,
                    title: l10n?.callUs ?? 'Call Us',
                    subtitle: '0781671517',
                    onTap: () => _launchPhone('0781671517')),
                const SizedBox(height: 16),
                _buildContactMethod(context,
                    icon: Icons.email,
                    title: l10n?.emailUs ?? 'Email Us',
                    subtitle: 'info@excellencecoachinghub.com',
                    onTap: () =>
                        _launchEmail('info@excellencecoachinghub.com')),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n?.close ?? 'Close',
                    style: TextStyle(
                        color: AppTheme.getSecondaryTextColor(context)))),
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
            Text(l10n?.whatsappNotAvailable ?? 'WhatsApp Not Available'),
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
          content: Text('$label ${l10n?.copiedToClipboard ?? 'copied to clipboard'}'),
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
            Text(l10n?.callNotAvailable ?? 'Call Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.phoneCallsNotSupported ?? 'Phone calls are not supported on this device.'),
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
            Text(l10n?.emailNotAvailable ?? 'Email Not Available'),
          ]),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(l10n?.emailClientNotAvailable ?? 'Email client is not available on this device.'),
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
                      SnackBar(
                        content: Text(l10n?.refreshed ?? 'Refreshed'),
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
                tooltip: l10n?.contactUs ?? 'Contact Us',
                padding: const EdgeInsets.all(8),
              ),
              IconButton(
                icon: const Icon(Icons.refresh, size: 22),
                onPressed: () async {
                  await _refreshDashboard();
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(l10n?.dashboardRefreshed ?? 'Dashboard refreshed'),
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

// Desktop stat card widget
class _DesktopStatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final bool isDark;

  const _DesktopStatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.15),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : const Color(0xFF6B7280),
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
}

// Desktop quick action card widget
class _DesktopQuickActionCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final Function onTap;
  final bool isDark;

  const _DesktopQuickActionCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark
              ? const Color(0xFF374151).withOpacity(0.3)
              : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isDark ? const Color(0xFF4B5563) : const Color(0xFFE5E7EB),
            width: 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.getTextColor(context),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? Colors.white70 : const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: isDark ? Colors.white54 : const Color(0xFF9CA3AF),
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

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

// ═══════════════════════════════════════════════════
//  DASHBOARD TOAST  (gamified popup)
// ═══════════════════════════════════════════════════
class _DashboardToast extends StatefulWidget {
  final String icon;
  final String title;
  final String message;
  final Color color;
  final VoidCallback onDismiss;

  const _DashboardToast({
    required this.icon,
    required this.title,
    required this.message,
    required this.color,
    required this.onDismiss,
  });

  @override
  State<_DashboardToast> createState() => _DashboardToastState();
}

class _DashboardToastState extends State<_DashboardToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseCtrl;
  late Animation<double> _pulse;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 900),
        lowerBound: 0.96,
        upperBound: 1.0)
      ..repeat(reverse: true);
    _pulse = _pulseCtrl;
    // Auto-dismiss after 5 s
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) widget.onDismiss();
    });
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenW = MediaQuery.of(context).size.width;
    final isMobile = screenW < 600;

    return Align(
      alignment: Alignment.bottomCenter,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
            isMobile ? 20 : 40, 0, isMobile ? 20 : 40, 48),
        child: Material(
          color: Colors.transparent,
          child: ScaleTransition(
            scale: _pulse,
            child: Container(
              constraints: const BoxConstraints(maxWidth: 480),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1C2333) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: widget.color.withOpacity(0.35), width: 1.5),
                boxShadow: [
                  BoxShadow(
                    color: widget.color.withOpacity(0.28),
                    blurRadius: 32,
                    offset: const Offset(0, 12),
                  ),
                  BoxShadow(
                    color: Colors.black.withOpacity(0.12),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 16, 18),
                child: Row(
                  children: [
                    // Icon circle
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            widget.color,
                            widget.color.withOpacity(0.7)
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                              color: widget.color.withOpacity(0.4),
                              blurRadius: 14,
                              offset: const Offset(0, 6))
                        ],
                      ),
                      child: Center(
                        child: Text(widget.icon,
                            style: const TextStyle(fontSize: 24)),
                      ),
                    ),
                    const SizedBox(width: 14),
                    // Text
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            widget.title,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: isDark
                                  ? Colors.white
                                  : const Color(0xFF0D1117),
                              height: 1.2,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            widget.message,
                            style: TextStyle(
                              fontSize: 13,
                              color: isDark
                                  ? Colors.white70
                                  : const Color(0xFF6B7280),
                              height: 1.35,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    // Dismiss
                    GestureDetector(
                      onTap: widget.onDismiss,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: isDark
                              ? Colors.white.withOpacity(0.08)
                              : const Color(0xFFF3F4F6),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.close_rounded,
                          size: 16,
                          color:
                              isDark ? Colors.white54 : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _QuickAccessCardState extends State<_QuickAccessCard> {
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final scale = _isPressed ? 0.95 : (_isHovered ? 1.05 : 1.0);

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
              gradient: LinearGradient(
                colors: [
                  widget.color,
                  widget.color.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(isMobile ? 16 : 24),
              boxShadow: [
                BoxShadow(
                  color: widget.color.withOpacity(_isHovered ? 0.4 : 0.25),
                  blurRadius: _isHovered ? 16 : 10,
                  offset: Offset(0, _isHovered ? 8 : 4),
                ),
              ],
            ),
            child: Padding(
              padding: EdgeInsets.all(isMobile ? 8.0 : 16.0),
              child: Column(
                crossAxisAlignment: isMobile
                    ? CrossAxisAlignment.center
                    : CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(isMobile ? 8 : 10),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(isMobile ? 10 : 14),
                    ),
                    child: Icon(
                      widget.icon,
                      color: Colors.white,
                      size: isMobile ? 20 : 24,
                    ),
                  ),
                  SizedBox(height: isMobile ? 8 : 12),
                  if (!isMobile) const Spacer(),
                  Flexible(
                    child: Text(
                      widget.title,
                      style: TextStyle(
                        fontSize: isMobile ? 10 : 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.2,
                      ),
                      textAlign: isMobile ? TextAlign.center : TextAlign.start,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (!isMobile) ...[
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
