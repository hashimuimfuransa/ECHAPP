import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/sidebar_provider.dart';

class ResponsiveNavigationDrawer extends ConsumerWidget {
  final String currentPage;
  
  const ResponsiveNavigationDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarProvider);
    final user = ref.watch(authProvider).user;
    final bool isAuth = user == null || currentPage == 'auth';

    final navItems = isAuth ? [
      {
        'title': 'Welcome',
        'icon': Icons.handshake_outlined,
        'route': '/auth-selection',
        'key': 'auth'
      },
      {
        'title': 'Sign In',
        'icon': Icons.login_rounded,
        'route': '/login',
        'key': 'login'
      },
      {
        'title': 'Register',
        'icon': Icons.person_add_rounded,
        'route': '/register',
        'key': 'register'
      },
      {
        'title': 'Help Center',
        'icon': Icons.help_outline_rounded,
        'route': '/help',
        'key': 'help'
      },
    ] : [
      {
        'title': 'Dashboard',
        'icon': Icons.dashboard_outlined,
        'route': '/dashboard',
        'key': 'dashboard'
      },
      {
        'title': 'Courses',
        'icon': Icons.school_outlined,
        'route': '/courses',
        'key': 'courses'
      },
      {
        'title': 'My Learning',
        'icon': Icons.play_circle_outline,
        'route': '/my-courses',
        'key': 'my-courses'
      },
      {
        'title': 'Categories',
        'icon': Icons.category_outlined,
        'route': '/categories',
        'key': 'categories'
      },
      {
        'title': 'Certificates',
        'icon': Icons.verified_outlined,
        'route': '/certificates',
        'key': 'certificates'
      },
      {
        'title': 'Profile',
        'icon': Icons.person_outline,
        'route': '/profile',
        'key': 'profile'
      },
      {
        'title': 'Settings',
        'icon': Icons.settings_outlined,
        'route': '/settings',
        'key': 'settings'
      },
    ];

    if (ResponsiveBreakpoints.isDesktop(context)) {
      return _buildDesktopDrawer(context, navItems, ref, isCollapsed, isAuth);
    } else {
      return _buildMobileDrawer(context, navItems, ref);
    }
  }

  Widget _buildDesktopDrawer(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref, bool isCollapsed, bool isAuth) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
      width: isCollapsed ? 80 : 280,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(5, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.fromLTRB(isCollapsed ? 12 : 24, 40, isCollapsed ? 12 : 24, 32),
            child: Row(
              mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                if (!isCollapsed) ...[
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Excellence Hub',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppTheme.getTextColor(context),
                            letterSpacing: -0.5,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'PLATFORM',
                          style: TextStyle(
                            fontSize: 10,
                            color: AppTheme.primaryGreen,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(horizontal: 16),
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
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Theme.of(context).dividerColor.withOpacity(0.05),
                    width: 1,
                  ),
                ),
              ),
              child: _buildLogoutButton(context, ref, isCollapsed),
            ),
          if (isAuth && !isCollapsed)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.auto_awesome, color: AppTheme.primaryGreen, size: 24),
                    const SizedBox(height: 12),
                    Text(
                      'Unlock your potential with expert-led courses.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppTheme.getTextColor(context).withOpacity(0.7),
                        height: 1.5,
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

  Widget _buildMobileDrawer(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref) {
    return Drawer(
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen,
                  AppTheme.primaryGreen.withOpacity(0.8),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 32,
                    height: 32,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Excellence Hub',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Your learning platform',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 13,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
          
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 12),
              children: items.map((item) => _buildNavItem(
                context,
                item['title'] as String,
                item['icon'] as IconData,
                item['route'] as String,
                item['key'] as String,
                currentPage == item['key'],
                false, // Mobile is never collapsed
              )).toList(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context, ref, false), // Mobile is never collapsed
          ),
        ],
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
    
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSelected ? null : () => context.go(route),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : 16, 
                vertical: 10
              ),
              alignment: isCollapsed ? Alignment.center : Alignment.centerLeft,
              decoration: isSelected
                  ? BoxDecoration(
                      color: AppTheme.primaryGreen.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(8),
                    )
                  : null,
              child: isCollapsed
                  ? Icon(
                      icon,
                      color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                      size: 22,
                    )
                  : Row(
                      children: [
                        Icon(
                          icon,
                          color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor.withOpacity(0.7),
                          size: 20,
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            title,
                            style: TextStyle(
                              color: isSelected ? AppTheme.primaryGreen : AppTheme.getTextColor(context).withOpacity(0.8),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (isSelected)
                          Container(
                            width: 4,
                            height: 4,
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
    } else {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isSelected
                ? AppTheme.primaryGreen.withOpacity(0.15)
                : AppTheme.greyColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            icon,
            color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor,
            size: 24,
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            color: isSelected ? AppTheme.primaryGreen : AppTheme.getTextColor(context),
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            fontSize: 16,
          ),
        ),
        selected: isSelected,
        selectedTileColor: AppTheme.primaryGreen.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        onTap: () {
          if (!isSelected) {
            context.go(route);
          }
          Navigator.of(context).pop();
        },
      );
    }
  }

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref, bool isCollapsed) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (isDesktop) {
      return Padding(
        padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 0 : 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context, ref),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: isCollapsed ? 0 : 16, 
                vertical: 12
              ),
              child: Row(
                mainAxisAlignment: isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.red.shade600,
                  ),
                  if (!isCollapsed) ...[
                    const SizedBox(width: 12),
                    Text(
                      'Logout',
                      style: TextStyle(
                        color: Colors.red.shade600,
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      );
    } else {
      return ListTile(
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(
            Icons.logout_rounded,
            color: Colors.red.shade600,
            size: 20,
          ),
        ),
        title: Text(
          'Logout',
          style: TextStyle(
            color: Colors.red.shade600,
            fontWeight: FontWeight.w600,
            fontSize: 16,
          ),
        ),
        onTap: () {
          _showLogoutDialog(context, ref);
        },
      );
    }
  }

  void _showLogoutDialog(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Logout'),
          content: const Text('Are you sure you want to logout?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
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
}
