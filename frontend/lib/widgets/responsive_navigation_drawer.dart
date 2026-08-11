import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/media_proxy.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';
import 'package:excellencecoachinghub/widgets/modern_dialog.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';

/// Width of the collapsed desktop sidebar (icon rail).
const double kSidebarRailWidth = 88;

/// Width of the expanded desktop sidebar.
const double kSidebarExpandedWidth = 260;

class ResponsiveNavigationDrawer extends ConsumerWidget {
  final String currentPage;

  const ResponsiveNavigationDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isCollapsed = ref.watch(sidebarProvider);
    final user = ref.watch(authProvider.select((state) => state.user));
    final bool isAuth = user == null || currentPage == 'auth';
    final bool isAdmin = user?.role == 'admin';

    final navItems = isAuth ? [
      {
        'title': l10n?.welcome ?? 'Welcome',
        'icon': Icons.handshake_outlined,
        'route': '/auth-selection',
        'key': 'auth'
      },
      {
        'title': l10n?.sidebarSignIn ?? 'Sign In',
        'icon': Icons.login_rounded,
        'route': '/login',
        'key': 'login'
      },
      {
        'title': l10n?.sidebarRegister ?? 'Register',
        'icon': Icons.person_add_rounded,
        'route': '/register',
        'key': 'register'
      },
      {
        'title': l10n?.helpCenter ?? 'Help Center',
        'icon': Icons.help_outline_rounded,
        'route': '/help',
        'key': 'help'
      },
    ] : isAdmin ? [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/admin',
        'key': 'dashboard'
      },
      {
        'title': l10n?.sidebarAdminNotifications ?? 'Notifications',
        'icon': Icons.notifications_active_outlined,
        'route': '/admin/notifications',
        'key': 'admin-notifications'
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/admin/courses',
        'key': 'courses'
      },
      {
        'title': l10n?.sidebarAdminStudents ?? 'Students',
        'icon': Icons.people_outline,
        'route': '/admin/students',
        'key': 'students'
      },
      {
        'title': l10n?.sidebarAdminPayments ?? 'Payments',
        'icon': Icons.payments_outlined,
        'route': '/admin/payments',
        'key': 'payments'
      },
      {
        'title': l10n?.sidebarAdminAnalytics ?? 'Analytics',
        'icon': Icons.analytics_outlined,
        'route': '/admin/analytics',
        'key': 'analytics'
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile'
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings'
      },
    ] : [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/dashboard',
        'key': 'dashboard'
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/courses',
        'key': 'courses'
      },
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'icon': Icons.play_circle_outline,
        'route': '/my-courses',
        'key': 'my-courses'
      },
      {
        'title': 'Community',
        'icon': Icons.groups_outlined,
        'route': '/community',
        'key': 'community'
      },
      {
        'title': 'Messages',
        'icon': Icons.chat_bubble_outline_rounded,
        'route': '/messages',
        'key': 'messages'
      },
      {
        'title': l10n?.categories ?? 'Categories',
        'icon': Icons.category_outlined,
        'route': '/categories',
        'key': 'categories'
      },
      {
        'title': l10n?.library ?? 'Library',
        'icon': Icons.local_library_outlined,
        'route': '/library',
        'key': 'library'
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'icon': Icons.verified_outlined,
        'route': '/certificates',
        'key': 'certificates'
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'icon': Icons.download_for_offline_outlined,
        'route': '/downloads',
        'key': 'downloads'
      },
      {
        'title': l10n?.notifications ?? 'Notifications',
        'icon': Icons.notifications_outlined,
        'route': '/notifications',
        'key': 'notifications'
      },
      {
        'title': l10n?.payments ?? 'Payments',
        'icon': Icons.payment_outlined,
        'route': '/payments/history',
        'key': 'payments'
      },
      {
        'title': l10n?.exams ?? 'Exams',
        'icon': Icons.quiz_outlined,
        'route': '/exams/history',
        'key': 'exams'
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile'
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings'
      },
    ];

    // Simplified mobile items - only essential ones not in header/quick actions
    final mobileNavItems = isAuth ? navItems : isAdmin ? [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/admin',
        'key': 'dashboard'
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/admin/courses',
        'key': 'courses'
      },
      {
        'title': l10n?.sidebarAdminStudents ?? 'Students',
        'icon': Icons.people_outline,
        'route': '/admin/students',
        'key': 'students'
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile'
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings'
      },
    ] : [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'icon': Icons.play_circle_outline,
        'route': '/my-courses',
        'key': 'my-courses'
      },
      {
        'title': 'Community',
        'icon': Icons.groups_outlined,
        'route': '/community',
        'key': 'community'
      },
      {
        'title': 'Messages',
        'icon': Icons.chat_bubble_outline_rounded,
        'route': '/messages',
        'key': 'messages'
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/courses',
        'key': 'courses'
      },
      {
        'title': l10n?.categories ?? 'Categories',
        'icon': Icons.category_outlined,
        'route': '/categories',
        'key': 'categories'
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'icon': Icons.verified_outlined,
        'route': '/certificates',
        'key': 'certificates'
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile'
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings'
      },
    ];

    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isPlatformDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
    
    // Consistent with MainLayout logic - use desktop style sidebar for desktop platforms 
    // down to 600px width
    final bool useSidebarStyle = isDesktop || (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);

    if (useSidebarStyle) {
      return _buildDesktopDrawer(context, navItems, ref, isCollapsed, isAuth);
    } else {
      return _buildMobileDrawer(context, mobileNavItems, ref);
    }
  }

  Widget _buildDesktopDrawer(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref, bool isCollapsed, bool isAuth) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? kSidebarRailWidth : kSidebarExpandedWidth,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 20, 22, isCollapsed ? 12 : 20, 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF00C896), Color(0xFF059669)],
              ),
            ),
            // The width animates between the two states, so for a few frames the
            // box is narrower than the labels want to be. Clipping and letting the
            // label column shrink to nothing keeps that transition overflow-free.
            child: ClipRect(
              child: Row(
                mainAxisAlignment: isCollapsed
                    ? MainAxisAlignment.center
                    : MainAxisAlignment.start,
                children: [
                  Container(
                    padding: EdgeInsets.all(isCollapsed ? 7 : 6),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Image.asset(
                      'assets/logo.png',
                      width: isCollapsed ? 34 : 28,
                      height: isCollapsed ? 34 : 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => SizedBox(
                        width: isCollapsed ? 34 : 28,
                        height: isCollapsed ? 34 : 28,
                        child: const Icon(Icons.school,
                            color: Colors.white, size: 22),
                      ),
                    ),
                  ),
                  if (!isCollapsed)
                    Flexible(
                      child: Padding(
                        padding: const EdgeInsets.only(left: 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              l10n?.excellenceHub ?? 'Excellence Hub',
                              style: const TextStyle(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                            Text(
                              l10n?.sidebarLearningPlatform ??
                                  'LEARNING PLATFORM',
                              style: const TextStyle(
                                fontSize: 8,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 1.0,
                              ),
                              maxLines: 1,
                              softWrap: false,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 10 : 12,
                vertical: 8,
              ),
              children: items.map((item) => _buildNavItem(
                context,
                item['title'] as String,
                item['icon'] as IconData,
                item['route'] as String,
                item['key'] as String,
                currentPage == item['key'] || (item['key'] == 'auth' && currentPage == 'auth'),
                isCollapsed,
              )).toList(),
            ),
          ),
          
          if (!isAuth)
            Container(
              padding: EdgeInsets.symmetric(
                vertical: 12,
                horizontal: isCollapsed ? 8 : 12,
              ),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: isDark ? Colors.white.withOpacity(0.05) : Colors.black.withOpacity(0.06),
                    width: 1,
                  ),
                ),
              ),
              child: _buildLogoutButton(context, ref, isCollapsed),
            ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref) {
    final user = ref.watch(authProvider.select((state) => state.user));
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
      width: MediaQuery.of(context).size.width * 0.85,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildMobileHeader(context, user),
          
          // Logout button at top for visibility
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
            child: _buildModernMobileLogoutButton(context, ref),
          ),
          
          const Divider(height: 1),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
              physics: const BouncingScrollPhysics(),
              children: [
                ...items.map((item) => _buildModernMobileNavItem(
                  context,
                  item['title'] as String,
                  item['icon'] as IconData,
                  item['route'] as String,
                  item['key'] as String,
                  currentPage == item['key'],
                )),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, user) {
    final l10n = AppLocalizations.of(context);
    final screenHeight = MediaQuery.of(context).size.height;
    final isSmallScreen = screenHeight < 700;
    
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(
        16, 
        isSmallScreen ? 40 : 50, 
        16, 
        isSmallScreen ? 12 : 16
      ),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFF00C896),
            const Color(0xFF059669),
            const Color(0xFF047857),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.25),
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/logo.png',
                  width: isSmallScreen ? 24 : 28,
                  height: isSmallScreen ? 24 : 28,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => SizedBox(
                    width: isSmallScreen ? 24 : 28,
                    height: isSmallScreen ? 24 : 28,
                    child: const Icon(Icons.school, color: Colors.white, size: 20),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      l10n?.excellenceHub ?? 'Excellence Hub',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      l10n?.sidebarLearningPlatform ?? 'LEARNING PLATFORM',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 7,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (user != null) ...[
            SizedBox(height: isSmallScreen ? 10 : 14),
            Container(
              padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.18),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.white.withOpacity(0.25),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: isSmallScreen ? 36 : 40,
                    height: isSmallScreen ? 36 : 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      image: user.profilePicture != null && user.profilePicture!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(mediaProxyUrl(user.profilePicture)),
                            fit: BoxFit.cover,
                          )
                        : null,
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 2,
                      ),
                    ),
                    child: user.profilePicture == null || user.profilePicture!.isEmpty
                      ? Container(
                          decoration: const BoxDecoration(
                            color: AppTheme.primaryGreen,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user.fullName[0].toUpperCase(),
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: isSmallScreen ? 14 : 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        )
                      : null,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          user.fullName,
                          style: TextStyle(
                            fontSize: isSmallScreen ? 13 : 14,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user.email,
                          style: TextStyle(
                            color: Colors.white70,
                            fontSize: isSmallScreen ? 9 : 10,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // Modern mobile nav item with cleaner design
  Widget _buildModernMobileNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String key,
    bool isSelected,
  ) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: InkWell(
        onTap: () {
          if (!isSelected) {
            context.go(route);
          }
          Navigator.of(context).pop();
        },
        borderRadius: BorderRadius.circular(14),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          decoration: BoxDecoration(
            gradient: isSelected
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      AppTheme.primaryGreen.withOpacity(0.15),
                      AppTheme.primaryGreen.withOpacity(0.05),
                    ],
                  )
                : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(14),
            border: isSelected
                ? Border.all(
                    color: AppTheme.primaryGreen.withOpacity(0.3),
                    width: 1.5,
                  )
                : null,
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  gradient: isSelected
                      ? LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            AppTheme.primaryGreen,
                            const Color(0xFF059669),
                          ],
                        )
                      : null,
                  color: isSelected ? null : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                  borderRadius: BorderRadius.circular(11),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppTheme.primaryGreen.withOpacity(0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Icon(
                  icon,
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    color: isSelected 
                        ? AppTheme.primaryGreen 
                        : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
              if (isSelected)
                Icon(
                  Icons.check_circle_rounded,
                  color: AppTheme.primaryGreen,
                  size: 18,
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Modern mobile logout button
  Widget _buildModernMobileLogoutButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.red.withOpacity(0.08),
            Colors.red.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: Colors.red.withOpacity(0.15),
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: () => _showLogoutDialog(context, ref),
        borderRadius: BorderRadius.circular(14),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: Colors.red.shade600,
                  size: 19,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  l10n?.logout ?? 'Logout',
                  style: TextStyle(
                    color: Colors.red.shade600,
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    String title,
    IconData icon,
    String route,
    String key,
    bool isSelected,
    bool isCollapsed,
  ) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isPlatformDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
    
    // Use desktop style for desktop platforms down to 600px width
    final bool useDesktopStyle = isDesktop || (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);
    
    if (useDesktopStyle) {
      final Color itemColor = isSelected
          ? AppTheme.primaryGreen
          : AppTheme.greyColor.withOpacity(0.6);

      // Collapsed: a generous icon-only target with a tooltip, so the rail
      // stays readable without labels.
      if (isCollapsed) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Tooltip(
            message: title,
            waitDuration: const Duration(milliseconds: 400),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: isSelected ? null : () => context.go(route),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  decoration: isSelected
                      ? BoxDecoration(
                          color: AppTheme.primaryGreen.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(14),
                        )
                      : null,
                  child: Icon(icon, color: itemColor, size: 24),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 1),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSelected ? null : () => context.go(route),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              alignment: Alignment.centerLeft,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Row(
                children: [
                  Icon(icon, color: itemColor, size: 18),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected
                            ? AppTheme.primaryGreen
                            : AppTheme.getTextColor(context).withOpacity(0.75),
                        fontWeight:
                            isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: InkWell(
          onTap: () {
            if (!isSelected) {
              context.go(route);
            }
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(12),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppTheme.primaryGreen.withOpacity(0.08)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppTheme.primaryGreen
                        : (isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.05)),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    color: isSelected ? Colors.white : (isDark ? Colors.white70 : Colors.black54),
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected 
                          ? AppTheme.primaryGreen 
                          : (isDark ? Colors.white.withOpacity(0.9) : Colors.black87),
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isCollapsed) {
    final l10n = AppLocalizations.of(context);
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isPlatformDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || defaultTargetPlatform == TargetPlatform.linux || defaultTargetPlatform == TargetPlatform.macOS);
    
    // Use desktop style for desktop platforms down to 600px width
    final bool useDesktopStyle = isDesktop || (isPlatformDesktop && MediaQuery.of(context).size.width >= 600);
    
    if (useDesktopStyle) {
      final logoutLabel = l10n?.logout ?? 'Logout';

      if (isCollapsed) {
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Tooltip(
            message: logoutLabel,
            waitDuration: const Duration(milliseconds: 400),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => _showLogoutDialog(context, ref),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.logout_rounded,
                    size: 22,
                    color: Colors.red.shade600,
                  ),
                ),
              ),
            ),
          ),
        );
      }

      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context, ref),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.red.shade600,
                  ),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(
                      logoutLabel,
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      softWrap: false,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      final isDark = Theme.of(context).brightness == Brightness.dark;
      
      return Container(
        decoration: BoxDecoration(
          color: isDark ? Colors.red.withOpacity(0.08) : Colors.red.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: Colors.red.withOpacity(isDark ? 0.15 : 0.1),
            width: 1,
          ),
        ),
        child: InkWell(
          onTap: () => _showLogoutDialog(context, ref),
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.red.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.logout_rounded,
                    color: Colors.red.shade600,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    l10n?.logout ?? 'Logout',
                    style: TextStyle(
                      color: Colors.red.shade600,
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    showModernDialog(
      context: context,
      title: l10n?.logout ?? 'Logout',
      content: Text(
        l10n?.sidebarAreYouSureLogout ?? 'Are you sure you want to logout?',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 14, color: AppTheme.greyColor),
      ),
      icon: const Icon(Icons.logout_rounded, color: AppTheme.primary, size: 32),
      actions: [
        ModernDialogAction.cancel(onPressed: () => Navigator.of(context).pop()),
        ModernDialogAction.danger(
          onPressed: () {
            Navigator.of(context).pop();
            ref.read(authProvider.notifier).logout();
          },
          text: l10n?.logout ?? 'Logout',
        ),
      ],
    );
  }
}
