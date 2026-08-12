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

/// Groups nav items by their `section` label while preserving the order the
/// items were declared in. Items without a section land in a single unlabeled
/// group, so callers can mix grouped and ungrouped menus.
List<MapEntry<String, List<Map<String, dynamic>>>> _groupBySection(
  List<Map<String, dynamic>> items,
) {
  final order = <String>[];
  final grouped = <String, List<Map<String, dynamic>>>{};

  for (final item in items) {
    final section = (item['section'] as String?) ?? '';
    if (!grouped.containsKey(section)) {
      order.add(section);
      grouped[section] = <Map<String, dynamic>>[];
    }
    grouped[section]!.add(item);
  }

  return order.map((s) => MapEntry(s, grouped[s]!)).toList();
}

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

    // Section labels used to group the menu into scannable blocks.
    final sGetStarted = l10n?.sidebarSectionGetStarted ?? 'Get Started';
    final sOverview = l10n?.sidebarSectionOverview ?? 'Overview';
    final sLearning = l10n?.sidebarSectionLearning ?? 'Learning';
    final sConnect = l10n?.sidebarSectionConnect ?? 'Connect';
    final sManage = l10n?.sidebarSectionManage ?? 'Manage';
    final sAccount = l10n?.sidebarSectionAccount ?? 'Account';

    final navItems = isAuth ? [
      {
        'title': l10n?.welcome ?? 'Welcome',
        'icon': Icons.handshake_outlined,
        'route': '/auth-selection',
        'key': 'auth',
        'section': sGetStarted
      },
      {
        'title': l10n?.sidebarSignIn ?? 'Sign In',
        'icon': Icons.login_rounded,
        'route': '/login',
        'key': 'login',
        'section': sGetStarted
      },
      {
        'title': l10n?.sidebarRegister ?? 'Register',
        'icon': Icons.person_add_rounded,
        'route': '/register',
        'key': 'register',
        'section': sGetStarted
      },
      {
        'title': l10n?.helpCenter ?? 'Help Center',
        'icon': Icons.help_outline_rounded,
        'route': '/help',
        'key': 'help',
        'section': sGetStarted
      },
    ] : isAdmin ? [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/admin',
        'key': 'dashboard',
        'section': sOverview
      },
      {
        'title': l10n?.sidebarAdminAnalytics ?? 'Analytics',
        'icon': Icons.analytics_outlined,
        'route': '/admin/analytics',
        'key': 'analytics',
        'section': sOverview
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/admin/courses',
        'key': 'courses',
        'section': sManage
      },
      {
        'title': l10n?.sidebarAdminStudents ?? 'Students',
        'icon': Icons.people_outline,
        'route': '/admin/students',
        'key': 'students',
        'section': sManage
      },
      {
        'title': 'Recordings',
        'icon': Icons.video_library_outlined,
        'route': '/admin/recordings',
        'key': 'recordings',
        'section': sManage
      },
      {
        'title': l10n?.sidebarAdminPayments ?? 'Payments',
        'icon': Icons.payments_outlined,
        'route': '/admin/payments',
        'key': 'payments',
        'section': sManage
      },
      {
        'title': l10n?.sidebarAdminNotifications ?? 'Notifications',
        'icon': Icons.notifications_active_outlined,
        'route': '/admin/notifications',
        'key': 'admin-notifications',
        'section': sManage
      },
      {
        'title': 'Push Report',
        'icon': Icons.mark_email_read_outlined,
        'route': '/admin/push-report',
        'key': 'admin-push-report',
        'section': sManage
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile',
        'section': sAccount
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings',
        'section': sAccount
      },
    ] : [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/dashboard',
        'key': 'dashboard',
        'section': sOverview
      },
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'icon': Icons.play_circle_outline,
        'route': '/my-courses',
        'key': 'my-courses',
        'section': sLearning
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/courses',
        'key': 'courses',
        'section': sLearning
      },
      {
        'title': l10n?.categories ?? 'Categories',
        'icon': Icons.category_outlined,
        'route': '/categories',
        'key': 'categories',
        'section': sLearning
      },
      {
        'title': l10n?.library ?? 'Library',
        'icon': Icons.local_library_outlined,
        'route': '/library',
        'key': 'library',
        'section': sLearning
      },
      {
        'title': l10n?.exams ?? 'Exams',
        'icon': Icons.quiz_outlined,
        'route': '/exams/history',
        'key': 'exams',
        'section': sLearning
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'icon': Icons.verified_outlined,
        'route': '/certificates',
        'key': 'certificates',
        'section': sLearning
      },
      {
        'title': l10n?.downloads ?? 'Downloads',
        'icon': Icons.download_for_offline_outlined,
        'route': '/downloads',
        'key': 'downloads',
        'section': sLearning
      },
      {
        'title': l10n?.community ?? 'Community',
        'icon': Icons.groups_outlined,
        'route': '/community',
        'key': 'community',
        'section': sConnect
      },
      {
        'title': l10n?.messages ?? 'Messages',
        'icon': Icons.chat_bubble_outline_rounded,
        'route': '/messages',
        'key': 'messages',
        'section': sConnect
      },
      {
        'title': l10n?.notifications ?? 'Notifications',
        'icon': Icons.notifications_outlined,
        'route': '/notifications',
        'key': 'notifications',
        'section': sConnect
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile',
        'section': sAccount
      },
      {
        'title': l10n?.payments ?? 'Payments',
        'icon': Icons.payment_outlined,
        'route': '/payments/history',
        'key': 'payments',
        'section': sAccount
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings',
        'section': sAccount
      },
    ];

    // Simplified mobile items - only essential ones not in header/quick actions
    final mobileNavItems = isAuth ? navItems : isAdmin ? [
      {
        'title': l10n?.dashboard ?? 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/admin',
        'key': 'dashboard',
        'section': sOverview
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/admin/courses',
        'key': 'courses',
        'section': sManage
      },
      {
        'title': l10n?.sidebarAdminStudents ?? 'Students',
        'icon': Icons.people_outline,
        'route': '/admin/students',
        'key': 'students',
        'section': sManage
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile',
        'section': sAccount
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings',
        'section': sAccount
      },
    ] : [
      {
        'title': l10n?.myLearning ?? 'My Learning',
        'icon': Icons.play_circle_outline,
        'route': '/my-courses',
        'key': 'my-courses',
        'section': sLearning
      },
      {
        'title': l10n?.courses ?? 'Courses',
        'icon': Icons.school_outlined,
        'route': '/courses',
        'key': 'courses',
        'section': sLearning
      },
      {
        'title': l10n?.categories ?? 'Categories',
        'icon': Icons.category_outlined,
        'route': '/categories',
        'key': 'categories',
        'section': sLearning
      },
      {
        'title': l10n?.certificates ?? 'Certificates',
        'icon': Icons.verified_outlined,
        'route': '/certificates',
        'key': 'certificates',
        'section': sLearning
      },
      {
        'title': l10n?.community ?? 'Community',
        'icon': Icons.groups_outlined,
        'route': '/community',
        'key': 'community',
        'section': sConnect
      },
      {
        'title': l10n?.messages ?? 'Messages',
        'icon': Icons.chat_bubble_outline_rounded,
        'route': '/messages',
        'key': 'messages',
        'section': sConnect
      },
      {
        'title': l10n?.profile ?? 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile',
        'section': sAccount
      },
      {
        'title': l10n?.settings ?? 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings',
        'section': sAccount
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
    final groups = _groupBySection(items);

    final navChildren = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (isCollapsed) {
        // The rail has no room for labels, so groups are separated by a
        // hairline instead.
        if (i > 0) {
          navChildren.add(_buildRailGroupDivider(context));
        }
      } else if (group.key.isNotEmpty) {
        navChildren.add(_buildSectionLabel(context, group.key, dense: i == 0));
      }
      navChildren.addAll(group.value.map((item) => _buildNavItem(
            context,
            item['title'] as String,
            item['icon'] as IconData,
            item['route'] as String,
            item['key'] as String,
            currentPage == item['key'] ||
                (item['key'] == 'auth' && currentPage == 'auth'),
            isCollapsed,
          )));
    }

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
              padding: EdgeInsets.fromLTRB(
                isCollapsed ? 10 : 12,
                isCollapsed ? 10 : 4,
                isCollapsed ? 10 : 12,
                12,
              ),
              children: navChildren,
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
    final media = MediaQuery.of(context);
    final groups = _groupBySection(items);

    // Cap the width so the drawer stays a panel on large phones and tablets
    // instead of swallowing the whole screen.
    final drawerWidth = (media.size.width * 0.86).clamp(280.0, 348.0);

    final navChildren = <Widget>[];
    for (var i = 0; i < groups.length; i++) {
      final group = groups[i];
      if (group.key.isNotEmpty) {
        navChildren.add(_buildSectionLabel(context, group.key, dense: i == 0));
      }
      navChildren.addAll(group.value.map((item) => _buildModernMobileNavItem(
            context,
            item['title'] as String,
            item['icon'] as IconData,
            item['route'] as String,
            item['key'] as String,
            currentPage == item['key'],
          )));
    }

    return Drawer(
      backgroundColor: isDark ? const Color(0xFF151E2E) : Colors.white,
      width: drawerWidth,
      elevation: 12,
      shadowColor: Colors.black.withOpacity(0.25),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topRight: Radius.circular(28),
          bottomRight: Radius.circular(28),
        ),
      ),
      child: Column(
        children: [
          _buildMobileHeader(context, user),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 16),
              physics: const BouncingScrollPhysics(),
              children: navChildren,
            ),
          ),

          _buildMobileFooter(context, ref, media.padding.bottom),
        ],
      ),
    );
  }

  Widget _buildMobileHeader(BuildContext context, user) {
    final l10n = AppLocalizations.of(context);
    final media = MediaQuery.of(context);
    final isSmallScreen = media.size.height < 700;
    // Respect the real status bar inset, with a floor for devices that report
    // none (older Android, desktop web at phone widths).
    final topInset = (media.padding.top < 24 ? 24.0 : media.padding.top) + 14;

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color(0xFF00C896),
            Color(0xFF059669),
            Color(0xFF047857),
          ],
        ),
        borderRadius: BorderRadius.only(topRight: Radius.circular(28)),
      ),
      child: Stack(
        children: [
          // Soft light blooms give the flat gradient some depth.
          Positioned(
            top: -46,
            right: -34,
            child: _headerGlow(132, 0.16),
          ),
          Positioned(
            bottom: -58,
            left: -30,
            child: _headerGlow(150, 0.10),
          ),

          Padding(
            padding: EdgeInsets.fromLTRB(18, topInset, 14, isSmallScreen ? 16 : 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.22),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: Colors.white.withOpacity(0.28),
                          width: 1,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 10,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Image.asset(
                        'assets/logo.png',
                        width: isSmallScreen ? 26 : 30,
                        height: isSmallScreen ? 26 : 30,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => SizedBox(
                          width: isSmallScreen ? 26 : 30,
                          height: isSmallScreen ? 26 : 30,
                          child: const Icon(Icons.school, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            l10n?.excellenceHub ?? 'Excellence Hub',
                            style: TextStyle(
                              fontSize: isSmallScreen ? 15 : 16.5,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              letterSpacing: -0.2,
                              height: 1.15,
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            l10n?.sidebarLearningPlatform ?? 'LEARNING PLATFORM',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.75),
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.3,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 6),
                    _headerIconButton(
                      context,
                      icon: Icons.close_rounded,
                      tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
                      onTap: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),

                if (user != null) ...[
                  SizedBox(height: isSmallScreen ? 14 : 18),
                  _buildProfileCard(context, user, l10n, isSmallScreen),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _headerGlow(double size, double opacity) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withOpacity(opacity),
            Colors.white.withOpacity(0),
          ],
        ),
      ),
    );
  }

  Widget _headerIconButton(
    BuildContext context, {
    required IconData icon,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.white.withOpacity(0.18),
        shape: const CircleBorder(),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: SizedBox(
            width: 36,
            height: 36,
            child: Icon(icon, color: Colors.white, size: 19),
          ),
        ),
      ),
    );
  }

  /// Glass profile card in the header — doubles as the shortcut to /profile.
  Widget _buildProfileCard(
    BuildContext context,
    dynamic user,
    AppLocalizations? l10n,
    bool isSmallScreen,
  ) {
    final avatarSize = isSmallScreen ? 42.0 : 46.0;
    final hasPhoto = user.profilePicture != null && (user.profilePicture as String).isNotEmpty;
    final initial = (user.fullName as String).trim().isNotEmpty
        ? (user.fullName as String).trim()[0].toUpperCase()
        : '?';

    return Material(
      color: Colors.white.withOpacity(0.16),
      borderRadius: BorderRadius.circular(18),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.of(context).pop();
          context.go('/profile');
        },
        child: Container(
          padding: EdgeInsets.all(isSmallScreen ? 10 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: Colors.white.withOpacity(0.24),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: avatarSize,
                height: avatarSize,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withOpacity(0.2),
                  image: hasPhoto
                      ? DecorationImage(
                          image: NetworkImage(mediaProxyUrl(user.profilePicture)),
                          fit: BoxFit.cover,
                        )
                      : null,
                  border: Border.all(
                    color: Colors.white.withOpacity(0.55),
                    width: 2,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.15),
                      blurRadius: 8,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: hasPhoto
                    ? null
                    : Center(
                        child: Text(
                          initial,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: isSmallScreen ? 16 : 18,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      user.fullName,
                      style: TextStyle(
                        fontSize: isSmallScreen ? 14 : 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                        letterSpacing: -0.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      user.email,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.78),
                        fontSize: isSmallScreen ? 10.5 : 11.5,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 6),
              Tooltip(
                message: l10n?.sidebarViewProfile ?? 'View profile',
                child: Container(
                  width: 28,
                  height: 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withOpacity(0.2),
                  ),
                  child: const Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Uppercase group label with a hairline that fades out to the right.
  Widget _buildSectionLabel(BuildContext context, String label, {bool dense = false}) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final labelColor = isDark ? Colors.white.withOpacity(0.42) : const Color(0xFF94A3B8);
    final ruleColor = isDark ? Colors.white.withOpacity(0.10) : const Color(0xFFE2E8F0);

    return Padding(
      padding: EdgeInsets.fromLTRB(12, dense ? 12 : 20, 12, 8),
      child: Row(
        children: [
          Text(
            label.toUpperCase(),
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: labelColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [ruleColor, ruleColor.withOpacity(0)],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRailGroupDivider(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Container(
        height: 1,
        color: isDark ? Colors.white.withOpacity(0.08) : const Color(0xFFE2E8F0),
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
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            if (!isSelected) {
              context.go(route);
            }
            Navigator.of(context).pop();
          },
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOut,
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            decoration: BoxDecoration(
              gradient: isSelected
                  ? LinearGradient(
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      colors: [
                        AppTheme.primaryGreen.withOpacity(isDark ? 0.24 : 0.14),
                        AppTheme.primaryGreen.withOpacity(isDark ? 0.06 : 0.02),
                      ],
                    )
                  : null,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                // Accent bar keeps the active row obvious without a heavy border.
                AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  curve: Curves.easeOut,
                  width: 3.5,
                  height: isSelected ? 26 : 0,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(width: 9),
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: isSelected
                        ? const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF10B981), Color(0xFF059669)],
                          )
                        : null,
                    color: isSelected
                        ? null
                        : (isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9)),
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? null
                        : Border.all(
                            color: isDark
                                ? Colors.white.withOpacity(0.08)
                                : const Color(0xFFE8EDF3),
                            width: 1,
                          ),
                    boxShadow: isSelected
                        ? [
                            BoxShadow(
                              color: AppTheme.primaryGreen.withOpacity(0.32),
                              blurRadius: 10,
                              offset: const Offset(0, 3),
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    icon,
                    color: isSelected
                        ? Colors.white
                        : (isDark ? Colors.white70 : const Color(0xFF64748B)),
                    size: 19,
                  ),
                ),
                const SizedBox(width: 13),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isSelected
                          ? (isDark ? AppTheme.primaryLight : AppTheme.primaryDark)
                          : (isDark ? Colors.white.withOpacity(0.88) : const Color(0xFF1E293B)),
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                      fontSize: 14.5,
                      letterSpacing: -0.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 7,
                    height: 7,
                    decoration: const BoxDecoration(
                      color: AppTheme.primaryGreen,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  /// Pinned footer so logout is always reachable without scrolling, while
  /// staying out of the way of the actual navigation.
  Widget _buildMobileFooter(BuildContext context, WidgetRef ref, double bottomInset) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(14, 12, 14, 12 + bottomInset),
      // No borderRadius here: Border.paint rejects a radius on a non-uniform
      // border. The Drawer's shape already rounds this corner for us.
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF111927) : const Color(0xFFFAFBFC),
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.07) : const Color(0xFFEDF1F5),
            width: 1,
          ),
        ),
      ),
      child: _buildModernMobileLogoutButton(context, ref),
    );
  }

  // Modern mobile logout button
  Widget _buildModernMobileLogoutButton(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final danger = isDark ? const Color(0xFFF87171) : const Color(0xFFDC2626);

    return Material(
      color: danger.withOpacity(isDark ? 0.12 : 0.07),
      borderRadius: BorderRadius.circular(14),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _showLogoutDialog(context, ref),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: danger.withOpacity(isDark ? 0.28 : 0.18),
              width: 1.2,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 11, horizontal: 12),
          child: Row(
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: danger.withOpacity(isDark ? 0.18 : 0.12),
                  borderRadius: BorderRadius.circular(11),
                ),
                child: Icon(
                  Icons.logout_rounded,
                  color: danger,
                  size: 18,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  l10n?.logout ?? 'Logout',
                  style: TextStyle(
                    color: danger,
                    fontWeight: FontWeight.w700,
                    fontSize: 14.5,
                    letterSpacing: -0.1,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(
                Icons.chevron_right_rounded,
                color: danger.withOpacity(0.6),
                size: 18,
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
              padding: const EdgeInsets.fromLTRB(8, 10, 12, 10),
              alignment: Alignment.centerLeft,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
                    width: 3,
                    height: isSelected ? 18 : 0,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryGreen,
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 9),
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
