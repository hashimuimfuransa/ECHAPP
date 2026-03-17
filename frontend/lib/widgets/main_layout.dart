import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/widgets/responsive_navigation_drawer.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/models/user.dart' as app_models;

import 'package:excellencecoachinghub/services/push_notification_service.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String? title;

  const MainLayout({
    super.key,
    required this.child,
    this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Set context for notifications navigation
    PushNotificationService.setContext(context);
    
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isPlatformDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
    
    // We want the sidebar layout for large screens OR for any desktop platform window that is wide enough
    // This provides the "window layout" the user expects on Windows
    final bool useSidebarLayout = isDesktop || (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);

    final app_models.User? user = ref.watch(authProvider).user;
    final String currentRoute = GoRouterState.of(context).uri.path;
    
    // Responsive sidebar auto-collapse
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool shouldBeCollapsed = screenWidth < 1100 && screenWidth >= 600;
    
    // Use addPostFrameCallback to avoid updating state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final isCurrentlyCollapsed = ref.read(sidebarProvider);
      if (shouldBeCollapsed && !isCurrentlyCollapsed) {
        ref.read(sidebarProvider.notifier).setCollapsed(true);
      } else if (screenWidth >= 1100 && isCurrentlyCollapsed) {
        // Optional: auto-expand on larger screens if previously auto-collapsed
        // ref.read(sidebarProvider.notifier).setCollapsed(false);
      }
    });

    final isCollapsed = ref.watch(sidebarProvider);
    final bool isAuthRoute = currentRoute == '/login' || 
                             currentRoute == '/register' || 
                             currentRoute == '/auth-selection' ||
                             currentRoute == '/forgot-password' ||
                             currentRoute == '/email-auth-option' ||
                             currentRoute == '/enter-reset-code' ||
                             currentRoute == '/reset-password' ||
                             currentRoute == '/landing' ||
                             currentRoute == '/';
    
    // Map routes to keys for ResponsiveNavigationDrawer
    String currentPage = 'dashboard';
    if (currentRoute.contains('/courses')) currentPage = 'courses';
    if (currentRoute.contains('/my-courses')) currentPage = 'my-courses';
    if (currentRoute.contains('/categories')) currentPage = 'categories';
    if (currentRoute.contains('/certificates')) currentPage = 'certificates';
    if (currentRoute.contains('/downloads')) currentPage = 'downloads';
    if (currentRoute.contains('/profile')) currentPage = 'profile';
    if (currentRoute.contains('/settings')) currentPage = 'settings';
    if (isAuthRoute) currentPage = 'auth';

    if (useSidebarLayout) {
      return Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        body: Row(
          children: [
            if (!isAuthRoute) ResponsiveNavigationDrawer(currentPage: currentPage),
            Expanded(
              child: Column(
                children: [
                  if (!isAuthRoute && currentRoute != '/') 
                    _buildDesktopTopBar(context, ref, user, title ?? _getPageTitle(currentPage), isCollapsed),
                  Expanded(
                    child: ClipRect(child: child),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      return Scaffold(
        appBar: isAuthRoute ? null : AppBar(
          leading: (context.canPop() || currentRoute != '/dashboard') 
              ? IconButton(
                  icon: const Icon(Icons.arrow_back_ios_rounded),
                  onPressed: () {
                    if (context.canPop()) {
                      context.pop();
                    } else {
                      context.go('/dashboard');
                    }
                  },
                  tooltip: 'Back',
                ) 
              : null,
          title: Text(title ?? _getPageTitle(currentPage)),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () => _handleGlobalRefresh(ref, context),
              tooltip: 'Refresh App',
            ),
            if (user != null) _buildNotificationBadge(context, ref),
            const SizedBox(width: 8),
          ],
        ),
        drawer: isAuthRoute ? null : ResponsiveNavigationDrawer(currentPage: currentPage),
        body: Container(
          color: Theme.of(context).scaffoldBackgroundColor,
          child: child,
        ),
        bottomNavigationBar: (isAuthRoute || user == null) ? null : _buildBottomNavBar(context, currentRoute),
      );
    }
  }

  void _handleGlobalRefresh(WidgetRef ref, BuildContext context) {
    // Refresh all key providers
    // NOTE: We DO NOT invalidate authProvider here because it causes the user to be logged out.
    // Instead, we just refresh the data-related providers.
    ref.invalidate(coursesProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(backendCategoriesProvider);
    ref.invalidate(notificationCountProvider);
    ref.invalidate(adminDashboardProvider);
    ref.invalidate(adminCourseProvider);
    
    // Show a small feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  String _getPageTitle(String page) {
    switch (page) {
      case 'dashboard': return 'Dashboard';
      case 'courses': return 'Courses';
      case 'my-courses': return 'My Learning';
      case 'categories': return 'Categories';
      case 'certificates': return 'Certificates';
      case 'downloads': return 'Downloads';
      case 'profile': return 'Profile';
      case 'settings': return 'Settings';
      default: return 'Excellence Hub';
    }
  }

  Widget _buildDesktopTopBar(BuildContext context, WidgetRef ref, app_models.User? user, String title, bool isCollapsed) {
    // For desktop, show back button if we can pop OR if we are not on a root level route
    final String currentRoute = GoRouterState.of(context).uri.path;
    final bool isRootRoute = currentRoute == '/dashboard' || currentRoute == '/admin' || currentRoute == '/';
    final bool showBackButton = context.canPop() || !isRootRoute;
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.05),
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          if (showBackButton)
            IconButton(
              icon: Icon(
                Icons.arrow_back_ios_rounded,
                size: 18,
                color: AppTheme.getTextColor(context).withOpacity(0.7),
              ),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  // If we can't pop, go to the logical parent
                  if (currentRoute.startsWith('/admin')) {
                    context.go('/admin');
                  } else {
                    context.go('/dashboard');
                  }
                }
              },
              tooltip: 'Go back',
            ),
          if (showBackButton) const SizedBox(width: 8),
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: AppTheme.getTextColor(context).withOpacity(0.7),
            ),
            onPressed: () => ref.read(sidebarProvider.notifier).toggleSidebar(),
            tooltip: isCollapsed ? 'Expand Sidebar' : 'Collapse Sidebar',
          ),
          const SizedBox(width: 16),
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(width: 16),
          // Refresh App Button
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: AppTheme.getTextColor(context).withOpacity(0.7),
            ),
            onPressed: () => _handleGlobalRefresh(ref, context),
            tooltip: 'Refresh App',
          ),
          const Spacer(),
          _buildNotificationBadge(context, ref),
          const SizedBox(width: 16),
          _buildUserAvatar(context, user),
        ],
      ),
    );
  }

  Widget _buildNotificationBadge(BuildContext context, WidgetRef ref) {
    final notificationCount = ref.watch(notificationCountProvider).when(
          data: (count) => count,
          loading: () => 0,
          error: (_, __) => 0,
        );

    return Stack(
      children: [
        IconButton(
          icon: const Icon(Icons.notifications_none_rounded),
          onPressed: () => context.push('/notifications'),
        ),
        if (notificationCount > 0)
          Positioned(
            right: 8,
            top: 8,
            child: GestureDetector(
              onTap: () => context.push('/notifications'),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: const BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                ),
                constraints: const BoxConstraints(
                  minWidth: 16,
                  minHeight: 16,
                ),
                child: Text(
                  notificationCount.toString(),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildUserAvatar(BuildContext context, app_models.User? user) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: () => context.go('/profile'),
        child: Row(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  user?.fullName ?? 'User',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                Text(
                  user?.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                  ),
                ),
              ],
            ),
            const SizedBox(width: 12),
            CircleAvatar(
              radius: 18,
              backgroundColor: AppTheme.primaryGreen.withOpacity(0.2),
              backgroundImage: user?.profilePicture != null
                  ? NetworkImage(user!.profilePicture!)
                  : null,
              child: user?.profilePicture == null
                  ? Text(
                      (user?.fullName ?? 'U')[0].toUpperCase(),
                      style: const TextStyle(
                        color: AppTheme.primaryGreen,
                        fontWeight: FontWeight.bold,
                      ),
                    )
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context, String currentRoute) {
    int currentIndex = 0;
    if (currentRoute.contains('/dashboard')) {
      currentIndex = 0;
    } else if (currentRoute.contains('/courses')) {
      currentIndex = 1;
    } else if (currentRoute.contains('/my-courses')) {
      currentIndex = 2;
    } else if (currentRoute.contains('/downloads')) {
      currentIndex = 3;
    } else if (currentRoute.contains('/profile')) {
      currentIndex = 4;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        color: Colors.transparent,
        child: Container(
          height: 72,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.08),
                blurRadius: 15,
                offset: const Offset(0, 8),
              ),
            ],
            border: Border.all(
              color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.01),
              width: 1,
            ),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BottomNavigationBar(
              currentIndex: currentIndex,
              onTap: (index) {
                switch (index) {
                  case 0:
                    context.go('/dashboard');
                    break;
                  case 1:
                    context.go('/courses');
                    break;
                  case 2:
                    context.go('/my-courses');
                    break;
                  case 3:
                    context.go('/downloads');
                    break;
                  case 4:
                    context.go('/profile');
                    break;
                }
              },
              backgroundColor: Colors.transparent,
              elevation: 0,
              type: BottomNavigationBarType.fixed,
              selectedItemColor: AppTheme.primaryGreen,
              unselectedItemColor: isDark ? Colors.white30 : Colors.black26,
              selectedFontSize: 10,
              unselectedFontSize: 10,
              showUnselectedLabels: false,
              showSelectedLabels: false,
              items: [
                _buildBottomNavItem(
                  icon: currentIndex == 0 ? Icons.grid_view_rounded : Icons.grid_view_outlined,
                  label: 'Home',
                  isSelected: currentIndex == 0,
                ),
                _buildBottomNavItem(
                  icon: currentIndex == 1 ? Icons.school_rounded : Icons.school_outlined,
                  label: 'Courses',
                  isSelected: currentIndex == 1,
                ),
                _buildBottomNavItem(
                  icon: currentIndex == 2 ? Icons.play_circle_filled_rounded : Icons.play_circle_outline_rounded,
                  label: 'Learning',
                  isSelected: currentIndex == 2,
                ),
                _buildBottomNavItem(
                  icon: currentIndex == 3 ? Icons.download_done_rounded : Icons.download_for_offline_outlined,
                  label: 'Downloads',
                  isSelected: currentIndex == 3,
                ),
                _buildBottomNavItem(
                  icon: currentIndex == 4 ? Icons.person_rounded : Icons.person_outline_rounded,
                  label: 'Profile',
                  isSelected: currentIndex == 4,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  BottomNavigationBarItem _buildBottomNavItem({
    required IconData icon,
    required String label,
    required bool isSelected,
  }) {
    return BottomNavigationBarItem(
      icon: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        margin: const EdgeInsets.only(bottom: 0),
        decoration: BoxDecoration(
          color: isSelected ? AppTheme.primaryGreen.withOpacity(0.12) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(icon, size: 22),
      ),
      label: label,
    );
  }
}
