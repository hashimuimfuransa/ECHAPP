import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

class ResponsiveNavigationDrawer extends ConsumerWidget {
  final String currentPage;
  
  const ResponsiveNavigationDrawer({
    super.key,
    required this.currentPage,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final navItems = [
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
      return _buildDesktopDrawer(context, navItems, ref);
    } else {
      return _buildMobileDrawer(context, navItems, ref);
    }
  }

  Widget _buildDesktopDrawer(BuildContext context, List<Map<String, dynamic>> items, WidgetRef ref) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.1),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        AppTheme.primaryGreen.withOpacity(0.2),
                        AppTheme.primaryGreen.withOpacity(0.05),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppTheme.primaryGreen.withOpacity(0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Image.asset(
                    'assets/logo.png',
                    width: 40,
                    height: 40,
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Excellence Hub',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: AppTheme.getTextColor(context),
                    letterSpacing: 0.3,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 6),
                Text(
                  'Your learning platform',
                  style: TextStyle(
                    fontSize: 12,
                    color: AppTheme.greyColor,
                    fontWeight: FontWeight.w400,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          Divider(
            height: 1,
            color: Theme.of(context).dividerColor.withOpacity(0.1),
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
              )).toList(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context, ref),
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
              )).toList(),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context, ref),
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
  ) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: isSelected ? null : () => context.go(route),
            borderRadius: BorderRadius.circular(10),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: isSelected
                  ? BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          AppTheme.primaryGreen.withOpacity(0.15),
                          AppTheme.primaryGreen.withOpacity(0.05),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: AppTheme.primaryGreen.withOpacity(0.2),
                        width: 1.5,
                      ),
                    )
                  : null,
              child: Row(
                children: [
                  Container(
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
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        color: isSelected ? AppTheme.primaryGreen : AppTheme.getTextColor(context),
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        fontSize: 14,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  if (isSelected)
                    Container(
                      width: 4,
                      height: 24,
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.circular(2),
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

  Widget _buildLogoutButton(BuildContext context, WidgetRef ref) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    if (isDesktop) {
      return Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _showLogoutDialog(context, ref),
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.logout_rounded,
                    size: 18,
                    color: Colors.red.shade600,
                  ),
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
