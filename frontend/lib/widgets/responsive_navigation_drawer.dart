import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/utils/responsive_utils.dart';

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
      return _buildDesktopDrawer(context, navItems);
    } else {
      return _buildMobileDrawer(context, navItems);
    }
  }

  Widget _buildDesktopDrawer(BuildContext context, List<Map<String, dynamic>> items) {
    return Container(
      width: 280,
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        border: Border(
          right: BorderSide(
            color: Theme.of(context).dividerColor.withOpacity(0.2),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Logo/Header section
          Container(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppTheme.primaryGreen,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Excellence\nCoaching Hub',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                    height: 1.2,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
          
          const Divider(height: 1),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: const EdgeInsets.symmetric(vertical: 8),
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
          
          // Logout section
          Padding(
            padding: const EdgeInsets.all(16),
            child: _buildLogoutButton(context),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileDrawer(BuildContext context, List<Map<String, dynamic>> items) {
    return Drawer(
      child: Column(
        children: [
          // Drawer header
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.whiteColor.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(
                    Icons.school,
                    color: AppTheme.whiteColor,
                    size: 32,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Excellence Coaching Hub',
                  style: TextStyle(
                    color: AppTheme.whiteColor,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          
          // Navigation items
          Expanded(
            child: ListView(
              padding: EdgeInsets.zero,
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
          
          const Divider(),
          
          // Logout
          _buildLogoutButton(context),
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
    
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppTheme.primaryGreen : AppTheme.greyColor,
        size: isDesktop ? 24 : 28,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppTheme.primaryGreen : AppTheme.blackColor,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          fontSize: isDesktop ? 14 : 16,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppTheme.primaryGreen.withOpacity(0.1),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(isDesktop ? 8 : 0),
      ),
      onTap: () {
        if (!isSelected) {
          context.go(route);
        }
        if (!isDesktop) {
          Navigator.of(context).pop(); // Close drawer on mobile
        }
      },
    );
  }

  Widget _buildLogoutButton(BuildContext context) {
    return ListTile(
      leading: const Icon(
        Icons.logout,
        color: Colors.red,
      ),
      title: const Text(
        'Logout',
        style: TextStyle(
          color: Colors.red,
          fontWeight: FontWeight.w500,
        ),
      ),
      onTap: () {
        _showLogoutDialog(context);
      },
    );
  }

  void _showLogoutDialog(BuildContext context) {
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
                // TODO: Implement logout functionality
                // ref.read(authProvider.notifier).logout();
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