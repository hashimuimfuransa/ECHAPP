import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/utils/navigation_optimizer.dart';
import 'package:excellencecoachinghub/widgets/responsive_navigation_drawer.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_course_provider.dart';
import 'package:excellencecoachinghub/models/user.dart' as app_models;
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/services/notification_service.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class MainLayout extends ConsumerWidget {
  final Widget child;
  final String? title;

  const MainLayout({
    super.key,
    required this.child,
    this.title,
  });

  void _enableFullscreenMode() async {
    if (!kIsWeb) {
      await SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.edgeToEdge,
        overlays: [],
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Enable fullscreen mode to hide system navigation
    _enableFullscreenMode();
    
    // Set context for notifications navigation
    PushNotificationService.setContext(context);
    
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);

    // Global listener for authentication state changes - use select to minimize rebuilds
    ref.listen(authProvider.select((state) => state.user), (previous, next) {
      if (next == null && context.mounted) {
        final currentRoute = GoRouterState.of(context).uri.path;
        final bool isAuthRoute = currentRoute == '/login' || 
                                 currentRoute == '/register' || 
                                 currentRoute == '/auth-selection' ||
                                 currentRoute == '/forgot-password' ||
                                 currentRoute == '/email-auth-option' ||
                                 currentRoute == '/enter-reset-code' ||
                                 currentRoute == '/reset-password' ||
                                 currentRoute == '/landing' ||
                                 currentRoute == '/' ||
                                 currentRoute == '/language-selection' ||
                                 currentRoute == '/phone-auth';
        
        if (!isAuthRoute) {
          if (isDesktop) {
            context.go('/email-auth-option');
          } else {
            context.go('/auth-selection');
          }
        }
      }
    });
    
    final isPlatformDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
    
    // We want the sidebar layout for large screens OR for any desktop platform window that is wide enough
    // This provides the "window layout" the user expects on Windows
    final bool useSidebarLayout = isDesktop || (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);

    // Use selective watching to minimize rebuilds - only rebuild when user changes, not on loading state
    final user = ref.watch(authProvider.select((state) => state.user));
    final String currentRoute = GoRouterState.of(context).uri.path;
    
    // Responsive sidebar auto-collapse - only watch the value, not the entire state
    final double screenWidth = MediaQuery.of(context).size.width;
    final bool shouldBeCollapsed = screenWidth < 1100 && screenWidth >= 600;
    
    // Use addPostFrameCallback to avoid updating state during build
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (context.mounted) {
        final isCurrentlyCollapsed = ref.read(sidebarProvider);
        if (shouldBeCollapsed && !isCurrentlyCollapsed) {
          ref.read(sidebarProvider.notifier).setCollapsed(true);
        } else if (screenWidth >= 1100 && isCurrentlyCollapsed) {
          // Optional: auto-expand on larger screens if previously auto-collapsed
          // ref.read(sidebarProvider.notifier).setCollapsed(false);
        }
      }
    });

    // Watch only the boolean value, not the entire notifier state
    final isCollapsed = ref.watch(sidebarProvider);
    final bool isAuthRoute = currentRoute == '/login' || 
                             currentRoute == '/register' || 
                             currentRoute == '/auth-selection' ||
                             currentRoute == '/forgot-password' ||
                             currentRoute == '/email-auth-option' ||
                             currentRoute == '/enter-reset-code' ||
                             currentRoute == '/reset-password' ||
                             currentRoute == '/landing' ||
                             currentRoute == '/' ||
                             currentRoute == '/language-selection' ||
                             currentRoute == '/phone-auth';
    
    // Map routes to keys for ResponsiveNavigationDrawer
    String currentPage = 'dashboard';
    if (currentRoute.contains('/courses')) currentPage = 'courses';
    if (currentRoute.contains('/my-courses')) currentPage = 'my-courses';
    if (currentRoute.contains('/categories')) currentPage = 'categories';
    if (currentRoute.contains('/certificates')) currentPage = 'certificates';
    if (currentRoute.contains('/downloads')) currentPage = 'downloads';
    if (currentRoute.contains('/notifications')) currentPage = 'notifications';
    if (currentRoute.contains('/payments')) currentPage = 'payments';
    if (currentRoute.contains('/exams')) currentPage = 'exams';
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
                    _buildDesktopTopBar(context, ref, user, title ?? _getPageTitle(currentPage, context), isCollapsed),
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
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        drawer: isAuthRoute ? null : ResponsiveNavigationDrawer(currentPage: currentPage),
        body: child,
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
    
    // Invalidate caches
    CategoriesCache.invalidateCache();
    BackendCategoriesCache.invalidateCache();
    
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

  String _getPageTitle(String page, BuildContext context) {
    final l10n = AppLocalizations.of(context);
    switch (page) {
      case 'dashboard': return l10n?.dashboard ?? 'Dashboard';
      case 'courses': return l10n?.courses ?? 'Courses';
      case 'my-courses': return l10n?.myLearning ?? 'My Learning';
      case 'categories': return l10n?.categories ?? 'Categories';
      case 'certificates': return l10n?.certificates ?? 'Certificates';
      case 'downloads': return l10n?.downloads ?? 'Downloads';
      case 'notifications': return l10n?.notifications ?? 'Notifications';
      case 'payments': return l10n?.payments ?? 'Payments';
      case 'exams': return l10n?.exams ?? 'Exams';
      case 'profile': return l10n?.profile ?? 'Profile';
      case 'settings': return l10n?.settings ?? 'Settings';
      default: return l10n?.excellenceHub ?? 'Excellence Hub';
    }
  }

  Widget _buildDesktopTopBar(BuildContext context, WidgetRef ref, app_models.User? user, String title, bool isCollapsed) {
    final l10n = AppLocalizations.of(context);
    // For desktop, show back button if we can pop OR if we are not on a root level route
    final String currentRoute = GoRouterState.of(context).uri.path;
    final bool isRootRoute = currentRoute == '/dashboard' || currentRoute == '/admin' || currentRoute == '/';
    final bool showBackButton = context.canPop() || !isRootRoute;
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          bottom: BorderSide(
            color: const Color(0xFF00C896).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00C896).withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
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
                if (context.mounted) {
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
                }
              },
              tooltip: l10n?.sidebarGoBack ?? 'Go back',
            ),
          if (showBackButton) const SizedBox(width: 8),
          // Sidebar Toggle Button
          IconButton(
            icon: Icon(
              isCollapsed ? Icons.menu_open_rounded : Icons.menu_rounded,
              color: AppTheme.getTextColor(context).withOpacity(0.7),
            ),
            onPressed: () => ref.read(sidebarProvider.notifier).toggleSidebar(),
            tooltip: isCollapsed ? l10n?.sidebarExpandSidebar ?? 'Expand Sidebar' : l10n?.sidebarCollapseSidebar ?? 'Collapse Sidebar',
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
            tooltip: l10n?.sidebarRefreshApp ?? 'Refresh App',
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
    } else if (currentRoute.contains('/books')) {
      currentIndex = 2;
    } else if (currentRoute.contains('/downloads')) {
      currentIndex = 3;
    } else if (currentRoute.contains('/my-courses')) {
      currentIndex = 4;
    }
    
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    
    return Container(
      height: _getResponsiveNavBarHeight(context),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          top: BorderSide(
            color: const Color(0xFF00C896).withOpacity(0.15),
            width: 1.5,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: _getResponsiveNavBarPadding(context),
            vertical: 8,
          ),
          child: Row(
            children: _buildNavItems(context, currentIndex, screenWidth).map((item) => Expanded(child: item)).toList(),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildNavItems(BuildContext context, int currentIndex, double screenWidth) {
    final l10n = AppLocalizations.of(context);
    final navItems = [
      {'icon': Icons.home_rounded, 'label': l10n?.home ?? 'Home'},
      {'icon': Icons.school_rounded, 'label': l10n?.courses ?? 'Courses'},
      {'icon': Icons.menu_book_rounded, 'label': l10n?.library ?? 'Library'},
      {'icon': Icons.download_rounded, 'label': l10n?.downloads ?? 'Downloads'},
      {'icon': Icons.bookmark_rounded, 'label': l10n?.enrolled ?? 'Enrolled'},
    ];
    
    return navItems.asMap().entries.map<Widget>((entry) {
      final index = entry.key;
      final item = entry.value;
      final isSelected = currentIndex == index;
      
      return _buildMobileNavItem(
        context: context,
        icon: item['icon'] as IconData,
        label: item['label'] as String,
        isSelected: isSelected,
        onTap: _getNavigationAction(index, context),
        screenWidth: screenWidth,
      );
    }).toList();
  }

  Widget _buildMobileNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    required double screenWidth,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSmallScreen = screenWidth < 360;
    
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: _getResponsiveNavItemPadding(context),
          vertical: 8,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: _getResponsiveNavIconSize(context),
              height: _getResponsiveNavIconSize(context),
              decoration: BoxDecoration(
                color: isSelected 
                    ? const Color(0xFF10B981).withOpacity(0.15)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(_getResponsiveNavIconRadius(context)),
              ),
              child: Icon(
                icon,
                size: _getResponsiveNavIconSize(context) * 0.6,
                color: isSelected 
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
            ),
            const SizedBox(height: 1),
            Text(
              label,
              style: TextStyle(
                fontSize: _getResponsiveNavTextSize(context),
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected 
                    ? const Color(0xFF10B981)
                    : (isDark ? Colors.white70 : Colors.black54),
              ),
              textAlign: TextAlign.center,
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
          title: const Row(
            children: [
              Icon(Icons.support_agent_rounded, color: Color(0xFF10B981)),
              SizedBox(width: 12),
              Text('AI Support'),
            ],
          ),
          content: const Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Get help from our AI assistant for:',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              SizedBox(height: 12),
              Text('• Course recommendations'),
              Text('• Study tips and guidance'),
              Text('• Technical support'),
              Text('• Learning progress tracking'),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                // Navigate to AI support or open chat
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981),
                foregroundColor: Colors.white,
              ),
              child: const Text('Start Chat'),
            ),
          ],
        );
      },
    );
  }

  // Responsive helper methods for bottom navigation
  double _getResponsiveNavBarHeight(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;
    if (screenHeight < 600) {
      return 100; // Very small screens - compact but fits larger icons/text
    } else if (screenHeight < 700) {
      return 110; // Small screens - compact but fits larger icons/text
    } else if (screenHeight < 800) {
      return 120; // Medium screens - compact but fits larger icons/text
    } else {
      return 130; // Large screens - compact but fits larger icons/text
    }
  }

  double _getResponsiveNavBarPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 4; // Very small screens
    } else if (screenWidth < 400) {
      return 6; // Small screens
    } else {
      return 10; // Medium and large screens
    }
  }

  double _getResponsiveNavIconSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 24; // Increased for very small screens
    } else if (screenWidth < 400) {
      return 28; // Increased for small screens
    } else {
      return 32; // Increased for medium/large screens
    }
  }

  double _getResponsiveNavIconRadius(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 10; // Very small screens - increased
    } else if (screenWidth < 400) {
      return 12; // Small screens - increased
    } else {
      return 14; // Medium and large screens - increased
    }
  }

  double _getResponsiveNavTextSize(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 11; // Very small screens - increased for readability
    } else if (screenWidth < 400) {
      return 12; // Small screens - increased for readability
    } else {
      return 14; // Medium and large screens - increased for readability
    }
  }

  double _getResponsiveNavItemPadding(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return 2; // Very small screens
    } else if (screenWidth < 400) {
      return 3; // Small screens
    } else {
      return 6; // Medium and large screens
    }
  }

  VoidCallback _getNavigationAction(int index, BuildContext context) {
    switch (index) {
      case 0:
        return () => NavigationOptimizer.navigateToTab(context, '/dashboard');
      case 1:
        return () => NavigationOptimizer.navigateToTab(context, '/courses');
      case 2:
        return () => NavigationOptimizer.navigateToTab(context, '/library');
      case 3:
        return () => NavigationOptimizer.navigateToTab(context, '/downloads');
      case 4:
        return () => NavigationOptimizer.navigateToTab(context, '/my-courses');
      case 5:
        return () => NavigationOptimizer.navigateToTab(context, '/personalization');
      default:
        return () => NavigationOptimizer.navigateToTab(context, '/dashboard');
    }
  }

}
