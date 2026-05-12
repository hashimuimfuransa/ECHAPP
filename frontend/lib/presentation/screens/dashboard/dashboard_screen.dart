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
import 'package:excellencecoachinghub/utils/category_utils.dart';
import 'package:excellencecoachinghub/utils/course_navigation_utils.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
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
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: isMobile ? 12 : 20, 
        vertical: isMobile ? 10 : 16
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF431407).withOpacity(0.2) : const Color(0xFFFFF7ED),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF7C2D12).withOpacity(0.3) : const Color(0xFFFFEDD5),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.security_rounded,
            color: isDark ? const Color(0xFFFB923C) : const Color(0xFFF97316),
            size: isMobile ? 18 : 22,
          ),
          SizedBox(width: isMobile ? 10 : 16),
          Expanded(
            child: Text(
              'Account secured to this device. Contact support to change.',
              style: TextStyle(
                color: isDark ? const Color(0xFFFFEDD5).withOpacity(0.8) : const Color(0xFF92400E),
                fontSize: isMobile ? 12 : 14,
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
  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedCategoryName;
  bool _showCategoryDropdown = false;

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
    _autoRefreshTimer?.cancel();
    _animationController?.dispose();
    _searchController.dispose();
    super.dispose();
  }

  // Handle search submission with category filtering
  void _performSearch(String query) {
    if (query.trim().isEmpty && _selectedCategoryId == null) return;
    
    context.push('/courses', extra: {
      'searchQuery': query.trim().isEmpty ? null : query.trim(),
      'categoryId': _selectedCategoryId,
      'categoryName': _selectedCategoryName,
    });
    _searchController.clear();
    setState(() {
      _selectedCategoryId = null;
      _selectedCategoryName = null;
    });
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
    
    // Use .read for providers that don't need rebuilds on every change
    final popularCoursesAsync = ref.read(popularCoursesProvider);
    final recommendedCoursesAsync = ref.read(recommendedCoursesProvider);

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final padding = isDesktop 
        ? const EdgeInsets.fromLTRB(32, 24, 32, 40)
        : isTablet
        ? const EdgeInsets.fromLTRB(24, 20, 24, 32)
        : ResponsiveBreakpoints.getPadding(context);

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
      backgroundColor: Colors.transparent,
      body: Stack(
        children: [
          RefreshIndicator(
            onRefresh: _refreshDashboard,
            child: CustomScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              slivers: [
                SliverPadding(
                  padding: padding,
                  sliver: SliverToBoxAdapter(
                    child: Center(
                      child: Container(
                        constraints: BoxConstraints(
                          maxWidth: isDesktop ? 1200 : (isTablet ? 800 : double.infinity), // Wider for desktop, medium for tablet
                        ),
                        child: isDesktop 
                          ? _buildDesktopLayout(context, user, userEnrollmentsAsync, popularCourses, recommendedCourses)
                          : _buildMobileLayout(context, user, userEnrollmentsAsync, popularCourses, recommendedCourses)
                      ),
                    ),
                  ),
                ),
                if (ref.watch(authProvider.notifier).isAdmin)
                  SliverPadding(
                    padding: EdgeInsets.symmetric(horizontal: padding.left),
                    sliver: SliverToBoxAdapter(
                      child: Center(
                        child: Container(
                          constraints: BoxConstraints(
                            maxWidth: isDesktop ? 1200 : (isTablet ? 800 : double.infinity),
                          ),
                          child: Column(
                            children: [
                              const SizedBox(height: 32),
                              _buildAdminAccessButton(context),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: !isDesktop ? FloatingActionButton(
        onPressed: () => _showContactInfoDialog(context),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 6,
        child: Stack(
          alignment: Alignment.center,
          children: [
            const Icon(Icons.contact_support, size: 22),
            Positioned(
              top: 0,
              right: 0,
              child: Container(
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 2,
                  ),
                ),
              ),
            ),
          ],
        ),
      ) : null,
      floatingActionButtonLocation: !isDesktop ? FloatingActionButtonLocation.endFloat : null,
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

  // Desktop layout with two-column design
  Widget _buildDesktopLayout(BuildContext context, user, AsyncValue<List<Enrollment>> userEnrollmentsAsync, List<Course> popularCourses, List<Course> recommendedCourses) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Left column - Main content
        Expanded(
          flex: 2,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userEnrollmentsAsync.when(
                data: (enrollments) => _buildWelcomeCard(context, user, enrollments),
                loading: () => _buildWelcomeCard(context, user, []),
                error: (_, __) => _buildWelcomeCard(context, user, []),
              ),
              const SizedBox(height: 24),
              userEnrollmentsAsync.when(
                data: (enrollments) => _buildLearningAndOnboarding(context, enrollments),
                loading: () => _buildLoadingCard(context, 'Continue Learning'),
                error: (error, stack) => _buildErrorCard(context, 'Continue Learning', error.toString()),
              ),
              const SizedBox(height: 32),
              userEnrollmentsAsync.when(
                data: (enrollments) {
                  final enrolledCourses = enrollments.map((e) => e.course).where((course) => course != null).cast<Course>().toList();
                  final coursesToShow = recommendedCourses.isNotEmpty ? recommendedCourses : popularCourses;
                  return _buildRecommendedCourses(
                    context, 
                    coursesToShow, 
                    enrolledCourses
                  );
                },
                loading: () => _buildRecommendedCourses(context, [], []),
                error: (_, __) => _buildRecommendedCourses(context, [], []),
              ),
            ],
          ),
        ),
        const SizedBox(width: 32),
        // Right column - Quick actions and stats
        Expanded(
          flex: 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              userEnrollmentsAsync.when(
                data: (enrollments) => _buildDesktopStatsSection(context, enrollments),
                loading: () => _buildDesktopStatsSection(context, []),
                error: (_, __) => _buildDesktopStatsSection(context, []),
              ),
              const SizedBox(height: 24),
              _buildDesktopQuickActions(context),
            ],
          ),
        ),
      ],
    );
  }

  // Mobile/Tablet layout - single column
  Widget _buildMobileLayout(BuildContext context, user, AsyncValue<List<Enrollment>> userEnrollmentsAsync, List<Course> popularCourses, List<Course> recommendedCourses) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        userEnrollmentsAsync.when(
          data: (enrollments) => _buildWelcomeCard(context, user, enrollments),
          loading: () => _buildWelcomeCard(context, user, []),
          error: (_, __) => _buildWelcomeCard(context, user, []),
        ),
        const SizedBox(height: 24),
        userEnrollmentsAsync.when(
          data: (enrollments) => _buildLearningAndOnboarding(context, enrollments),
          loading: () => _buildLoadingCard(context, 'Continue Learning'),
          error: (error, stack) => _buildErrorCard(context, 'Continue Learning', error.toString()),
        ),
        const SizedBox(height: 32),
        userEnrollmentsAsync.when(
          data: (enrollments) {
            final enrolledCourses = enrollments.map((e) => e.course).where((course) => course != null).cast<Course>().toList();
            final coursesToShow = recommendedCourses.isNotEmpty ? recommendedCourses : popularCourses;
            return _buildRecommendedCourses(
              context, 
              coursesToShow, 
              enrolledCourses
            );
          },
          loading: () => _buildRecommendedCourses(context, [], []),
          error: (_, __) => _buildRecommendedCourses(context, [], []),
        ),
      ],
    );
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
                  color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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
                  'Select Category',
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
                if (categories == null || categories.isEmpty) {
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
                      'All Categories',
                      'Search across all available courses',
                      Icons.grid_view_rounded,
                      const Color(0xFF10B981),
                      null,
                    ),
                    // Category Options - Add null checks
                    ...categories.where((category) => category != null).map((category) => _buildCategoryOption(
                      context,
                      category.id,
                      category.name,
                      'Courses in ${category.name}',
                      CategoryUtils.getCategoryIcon(category.id, name: category.name),
                      CategoryUtils.getCategoryColor(category.id, name: category.name),
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
                    'Failed to load categories',
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
                : isDark ? const Color(0xFF2D3748) : const Color(0xFFF8FAFC),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected 
                    ? color.withOpacity(0.3)
                    : isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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
                        color: isSelected 
                              ? color
                              : AppTheme.getTextColor(context),
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
            final color = CategoryUtils.getCategoryColor(categoryId, name: isFirst ? 'all' : category?.name);
            final name = isFirst ? 'All' : category!.name;
            final icon = CategoryUtils.getCategoryIcon(categoryId, name: isFirst ? 'all' : category?.name);

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

  Widget _buildWelcomeCard(BuildContext context, user, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    
    return Container(
      width: double.infinity,
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
                  gradient: LinearGradient(
                    colors: [const Color(0xFF10B981), const Color(0xFF0EA5E9)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF10B981).withOpacity(0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: user?.profilePicture != null && user!.profilePicture!.isNotEmpty
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
                        color: AppTheme.getTextColor(context),
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Ready to continue your learning journey?',
                      style: TextStyle(
                        fontSize: isSmallMobile ? 12 : 14,
                        color: AppTheme.getSecondaryTextColor(context),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Enhanced Notification Bell
              Consumer(
                builder: (context, ref, child) {
                  final notifications = ref.watch(notificationProvider).notifications;
                  final unreadCount = notifications.where((n) => !n.isRead).length;
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
                            color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF3F4F6),
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
                                  color: unreadCount > 0 
                                      ? const Color(0xFF10B981)
                                      : AppTheme.getSecondaryTextColor(context),
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
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
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
          // Enhanced Search Bar with Category Filter
          _buildEnhancedSearchBar(context, isDark),
          // Category Dropdown
          if (_showCategoryDropdown)
            GestureDetector(
              onTap: () {
                // Use WidgetsBinding to prevent frame callback issues
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
    );
  }

  Widget _buildEnhancedSearchBar(BuildContext context, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
        ),
      ),
      child: Row(
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
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFE5E7EB),
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
                    _showCategoryDropdown ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
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
                    ? 'Search in ${_selectedCategoryName}...'
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
                      icon: const Icon(Icons.clear_rounded, color: AppTheme.greyColor),
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
                          setState(() => _showCategoryDropdown = !_showCategoryDropdown);
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
      ),
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
                    'Live Classes Available',
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
      onTap: () => CourseNavigationUtils.navigateToCourseWithContext(context, ref, lastCourse),
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
              child: const Icon(Icons.play_arrow_rounded, color: Color(0xFF10B981), size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'CONTINUE LEARNING',
                    style: TextStyle(
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

  Widget _buildDesktopStatsOverlay(BuildContext context, List<Enrollment> enrollments, double averageProgress) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Container(
      padding: EdgeInsets.all(isDesktop ? 24 : 16),
      decoration: BoxDecoration(
        color: !isMobile(context) ? Colors.white.withOpacity(0.12) : (isDark ? const Color(0xFF1E293B) : Colors.white),
        borderRadius: BorderRadius.circular(24),
        border: !isMobile(context) ? Border.all(color: Colors.white.withOpacity(0.2), width: 1.5) : null,
        boxShadow: !isMobile(context) ? [] : [
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
                  isDesktop: !isMobile(context)
                ),
                SizedBox(height: isDesktop ? 16 : 12),
                _buildWelcomeStatItem(
                  context, 
                  Icons.auto_graph_rounded, 
                  '${averageProgress.toInt()}%', 
                  'Avg. Progress', 
                  !isMobile(context) ? Colors.white : const Color(0xFF06B6D4),
                  isDesktop: !isMobile(context)
                ),
              ],
            ),
          ),
          SizedBox(width: isDesktop ? 16 : 12),
          _buildCircularProgress(
            context, 
            averageProgress, 
            mini: isMobile(context) || !isDesktop, 
            color: !isMobile(context) ? Colors.white : null
          ),
        ],
      ),
    );
  }

  bool isMobile(BuildContext context) => ResponsiveBreakpoints.isMobile(context);

  Widget _buildWelcomeStatItem(BuildContext context, IconData icon, String value, String label, Color color, {bool isDesktop = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDesktop ? Colors.white.withOpacity(0.2) : color.withOpacity(0.1), 
            borderRadius: BorderRadius.circular(10)
          ),
          child: Icon(icon, color: isDesktop ? Colors.white : color, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(value, style: TextStyle(
                fontSize: 15, 
                fontWeight: FontWeight.w800, 
                color: isDesktop ? Colors.white : (isDark ? Colors.white : const Color(0xFF333333)), 
                height: 1.2,
              )),
              Text(label, style: TextStyle(
                fontSize: 12, 
                color: isDesktop ? Colors.white.withOpacity(0.8) : (isDark ? Colors.white70 : const Color(0xFF9CA3AF)), 
                height: 1.2,
              )),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCircularProgress(BuildContext context, double progress, {bool mini = false, Color? color}) {
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
              color ?? (mini ? Colors.white : const Color(0xFF10B981))
            ),
            strokeCap: StrokeCap.round,
          ),
        ),
        Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('${progress.toInt()}%', style: TextStyle(
              fontSize: mini ? 12 : 16, 
              fontWeight: FontWeight.w900, 
              color: Colors.white,
            )),
            if (!mini)
              Text('Completed', style: TextStyle(
                fontSize: 8, 
                color: Colors.white70,
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
        'subtitle': 'Continue',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
      {
        'title': 'Downloads',
        'subtitle': 'Offline',
        'icon': Icons.file_download_done_rounded,
        'color': const Color(0xFF3B82F6),
        'onTap': () => context.go('/downloads'),
      },
      {
        'title': 'Exams',
        'subtitle': 'History',
        'icon': Icons.assignment_turned_in_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/exams/history'),
      },
      {
        'title': 'Certificates',
        'subtitle': 'Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFFF59E0B),
        'onTap': () => context.push('/certificates'),
      },
    ];

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final crossAxisCount = isDesktop ? 4 : (isMobile ? 4 : 2); // 4 in a row for mobile too to be COMPACT

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
              child: const Text('See All', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
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

  Widget _buildLearningAndOnboarding(BuildContext context, List<Enrollment> enrollments) {
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
  Widget _buildDesktopStatsSection(BuildContext context, List<Enrollment> enrollments) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Calculate statistics
    final coursesEnrolled = enrollments.length;
    final coursesCompleted = enrollments.where((e) => e.progress >= 100).length;
    final averageProgress = enrollments.isNotEmpty 
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) / enrollments.length 
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
            'My Progress',
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
            label: 'Courses Enrolled',
            color: const Color(0xFF10B981),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.verified_rounded,
            value: '$coursesCompleted',
            label: 'Completed',
            color: const Color(0xFF3B82F6),
            isDark: isDark,
          ),
          const SizedBox(height: 16),
          _DesktopStatCard(
            icon: Icons.auto_graph_rounded,
            value: '${averageProgress.toInt()}%',
            label: 'Average Score',
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
        'title': 'My Learning',
        'subtitle': 'Continue Courses',
        'icon': Icons.play_lesson_rounded,
        'color': const Color(0xFF10B981),
        'onTap': () => context.push('/my-courses'),
      },
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
        'title': 'Certificates',
        'subtitle': 'View Awards',
        'icon': Icons.verified_rounded,
        'color': const Color(0xFF8B5CF6),
        'onTap': () => context.push('/certificates'),
      },
      {
        'title': 'Exam History',
        'subtitle': 'Past Results',
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
          ...quickActions.map((action) => Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: _DesktopQuickActionCard(
              title: action['title'] as String,
              subtitle: action['subtitle'] as String,
              icon: action['icon'] as IconData,
              color: action['color'] as Color,
              onTap: action['onTap'] as Function,
              isDark: isDark,
            ),
          )).toList(),
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
        ? enrollments.fold(0.0, (sum, e) => sum + e.progress) / enrollments.length 
        : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'My Progress',
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
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFF0FDF4),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFDCFCE7),
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
                      'Courses Enrolled',
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
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFDBEAFE),
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
                      'Completed',
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
                  color: isDark ? const Color(0xFF1F2937) : const Color(0xFFFEF3C7),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? const Color(0xFF374151) : const Color(0xFFFDE68A),
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
                      'Average Score',
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
            children: quickActions.map((action) => Padding(
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
            )).toList(),
          )
        else
          Row(
            children: quickActions.map((action) => Expanded(
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
            )).toList(),
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
              'Continue Learning',
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
                'See All',
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
                    child: course.thumbnail != null && course.thumbnail!.isNotEmpty
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
                      color: isDark ? const Color(0xFF374151) : const Color(0xFFF3F4F6),
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
                  onPressed: () => CourseNavigationUtils.navigateToCourseWithContext(context, ref, course),
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
                        'Continue Learning',
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
                        ? NetworkImageWidget(
                            imageUrl: course.thumbnail!, 
                            fit: BoxFit.cover,
                            errorWidget: const Icon(Icons.play_circle_filled, color: AppTheme.primary, size: 40),
                          )
                        : const Icon(Icons.play_circle_filled, color: AppTheme.primary, size: 40),
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
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRecommendedCourses(BuildContext context, List<Course> courses, List<Course> enrolledCourses) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    final isSmallMobile = ResponsiveBreakpoints.isSmallMobile(context);
    
    // Take only first 2 courses for cleaner layout
    final displayCourses = courses.take(2).toList();
    
    if (displayCourses.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recommended for You',
          style: TextStyle(
            fontSize: isSmallMobile ? 18 : 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.5,
            color: AppTheme.getTextColor(context),
          ),
        ),
        const SizedBox(height: 16),
        // Course Cards
        ...displayCourses.map((course) => Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: _buildRecommendedCourseCard(context, course, enrolledCourses),
        )).toList(),
      ],
    );
  }

  Widget _buildRecommendedCourseCard(BuildContext context, Course course, List<Course> enrolledCourses) {
    final bool isEnrolled = enrolledCourses.any((e) => e.id == course.id);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = ResponsiveBreakpoints.isMobile(context);
    
    return GestureDetector(
      onTap: () {
        if (isEnrolled) {
          // If enrolled, navigate to learning screen
          context.push('/learning/${course.id}');
        } else {
          // If not enrolled, navigate to course description/details
          CourseNavigationUtils.navigateToCourseWithContext(context, ref, course);
        }
      },
      child: Container(
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
            // Course Thumbnail
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(8),
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
            // Course Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    course.title,
                    style: TextStyle(
                      fontSize: isMobile ? 14 : 16,
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
                      fontSize: isMobile ? 12 : 14,
                    ),
                  ),
                ],
              ),
            ),
            // Arrow Icon and Status Indicator
            Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (isEnrolled)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      'Enrolled',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 8,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Icon(
                  Icons.chevron_right_rounded,
                  color: AppTheme.getSecondaryTextColor(context),
                  size: 20,
                ),
              ],
            ),
          ],
        ),
      ),
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
                      width: double.infinity,
                      margin: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primary.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: AspectRatio(
                        aspectRatio: 16 / 9,
                        child: course.thumbnail != null && course.thumbnail!.isNotEmpty
                            ? NetworkImageWidget(imageUrl: course.thumbnail!, fit: BoxFit.cover)
                            : Icon(Icons.image_outlined, size: 40, color: isDark ? Colors.white38 : const Color(0xFF9CA3AF)),
                      ),
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
          color: isDark ? const Color(0xFF374151).withOpacity(0.3) : const Color(0xFFF9FAFB),
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
                crossAxisAlignment: isMobile ? CrossAxisAlignment.center : CrossAxisAlignment.start,
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
