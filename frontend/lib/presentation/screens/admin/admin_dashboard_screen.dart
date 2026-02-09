import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/notification_provider.dart';
import 'package:excellence_coaching_hub/services/admin_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  String? _syncMessage;

  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing users...';
    });
    
    try {
      final adminService = AdminService();
      final result = await adminService.manualSyncUsers();
      
      setState(() {
        _syncMessage = result['message'] ?? 'Sync completed successfully';
        _isSyncing = false;
      });
      
      // Reload dashboard data to show updated stats
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      });
      
      // Show success snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_syncMessage!),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() {
        _syncMessage = 'Sync failed: ${e.toString()}';
        _isSyncing = false;
      });
      
      // Show error snackbar
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(_syncMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(adminDashboardProvider);
      
    // Load dashboard data only once when screen opens
    if (!_hasLoadedInitialData && dashboardState.stats == null && !dashboardState.isLoading) {
      _hasLoadedInitialData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      });
    }
      
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: _isSyncing 
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.sync),
            onPressed: _isSyncing ? null : _triggerManualSync,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
          ),
          Consumer(
            builder: (context, ref, child) {
              final notificationState = ref.watch(notificationProvider);
              final unreadCount = notificationState.notifications.where((n) => !n.isRead).length;
              
              return IconButton(
                icon: Stack(
                  children: [
                    const Icon(Icons.notifications_outlined, size: 24),
                    // Notification badge - show if there are unread notifications
                    if (unreadCount > 0)
                      Positioned(
                        top: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(2),
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          constraints: const BoxConstraints(
                            minWidth: 16,
                            minHeight: 16,
                          ),
                          child: Text(
                            unreadCount > 99 ? '99+' : unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
                onPressed: () {
                  // Handle notifications
                  _showNotificationCenter(context);
                },
              );
            },
          ),
          // Profile menu with popup options
          Consumer(
            builder: (context, ref, child) {
              final user = ref.watch(authProvider).user;
              return PopupMenuButton(
                icon: CircleAvatar(
                  radius: 20,
                  backgroundColor: AppTheme.primaryGreen,
                  child: Text(
                    user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                color: AppTheme.whiteColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: const Row(
                        children: [
                          Icon(Icons.person_outline, color: AppTheme.blackColor, size: 18),
                          SizedBox(width: 10),
                          Text('Profile', style: TextStyle(color: AppTheme.blackColor)),
                        ],
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: const Row(
                        children: [
                          Icon(Icons.settings_outlined, color: AppTheme.blackColor, size: 18),
                          SizedBox(width: 10),
                          Text('Settings', style: TextStyle(color: AppTheme.blackColor)),
                        ],
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                    const PopupMenuDivider(),
                    const PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: Colors.red, size: 18),
                          SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: Colors.red)),
                        ],
                      ),
                    ),
                  ];
                },
              );
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildDashboardContent(context, ref, dashboardState),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.whiteColor,
          title: const Text(
            'Logout',
            style: TextStyle(color: AppTheme.blackColor),
          ),
          content: const Text(
            'Are you sure you want to logout?',
            style: TextStyle(color: AppTheme.greyColor),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text(
                'Cancel',
                style: TextStyle(color: AppTheme.greyColor),
              ),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                ref.read(authProvider.notifier).logout();
                context.go('/login');
              },
              child: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
            ),
          ],
        );
      },
    );
  }
  
  void _showNotificationCenter(BuildContext context) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, Animation<double> animation, Animation<double> secondaryAnimation) {
        return Consumer(
          builder: (context, ref, child) {
            final notificationState = ref.watch(notificationProvider);
            final notificationNotifier = ref.read(notificationProvider.notifier);
              
            // Load notifications when dialog opens
            WidgetsBinding.instance.addPostFrameCallback((_) {
              if (notificationState.notifications.isEmpty && !notificationState.isLoading) {
                notificationNotifier.loadNotifications();
              }
            });
              
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Container(
                width: 400,
                height: 500,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Column(
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryGreen,
                        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Notifications',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(context).pop(),
                          ),
                        ],
                      ),
                    ),
                      
                    // Notifications list
                    Expanded(
                      child: notificationState.isLoading
                        ? const Center(child: CircularProgressIndicator())
                        : notificationState.error != null
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.error,
                                    size: 60,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  Text(
                                    'Error loading notifications',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 16,
                                    ),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      notificationNotifier.loadNotifications();
                                    },
                                    child: const Text('Retry'),
                                  ),
                                ],
                              ),
                            )
                          : notificationState.notifications.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.notifications_none,
                                      size: 60,
                                      color: Colors.grey[400],
                                    ),
                                    const SizedBox(height: 16),
                                    const Text(
                                      'No new notifications',
                                      style: TextStyle(
                                        color: Colors.grey,
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : ListView.builder(
                                itemCount: notificationState.notifications.length,
                                itemBuilder: (context, index) {
                                  final notification = notificationState.notifications[index];
                                  Color iconColor = Colors.grey;
                                  switch (notification.type) {
                                    case 'success':
                                      iconColor = Colors.green;
                                      break;
                                    case 'info':
                                      iconColor = AppTheme.primaryGreen;
                                      break;
                                    case 'achievement':
                                      iconColor = Colors.orange;
                                      break;
                                    case 'warning':
                                      iconColor = Colors.orange;
                                      break;
                                    case 'error':
                                      iconColor = Colors.red;
                                      break;
                                    default:
                                      iconColor = AppTheme.primaryGreen;
                                  }
                                    
                                  String timeAgo = _getTimeAgo(notification.timestamp);
                                    
                                  return ListTile(
                                    leading: Container(
                                      padding: const EdgeInsets.all(8),
                                      decoration: BoxDecoration(
                                        color: iconColor.withOpacity(0.1),
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Icon(
                                        notification.type == 'success' ? Icons.payment : 
                                        notification.type == 'info' ? Icons.person_add : 
                                        notification.type == 'achievement' ? Icons.school : 
                                        notification.type == 'warning' ? Icons.warning : 
                                        notification.type == 'error' ? Icons.error : 
                                        Icons.notifications,
                                        color: iconColor,
                                      ),
                                    ),
                                    title: Text(
                                      notification.title,
                                      style: TextStyle(
                                        fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                      ),
                                    ),
                                    subtitle: Text(notification.message),
                                    trailing: Text(
                                      timeAgo,
                                      style: const TextStyle(color: Colors.grey),
                                    ),
                                    contentPadding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 8,
                                    ),
                                    onTap: () {
                                      notificationNotifier.markAsRead(notification.id);
                                    },
                                    tileColor: notification.isRead ? null : Colors.grey[50],
                                  );
                                },
                              ),
                    ),
                      
                    // Footer with mark all as read
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(16)),
                      ),
                      child: ElevatedButton.icon(
                        onPressed: notificationState.notifications.isNotEmpty ? () {
                          notificationNotifier.markAllAsRead();
                        } : null,
                        icon: const Icon(Icons.check, size: 16),
                        label: const Text('Mark All as Read'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryGreen,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
    
  String _getTimeAgo(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);
      
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
  
  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          const DrawerHeader(
            decoration: BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                SizedBox(height: 10),
                Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Excellence Coaching Hub',
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard),
            title: const Text('Dashboard'),
            selected: true,
            onTap: () {
              // Already on dashboard
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.school),
            title: const Text('Courses'),
            onTap: () {
              context.push('/admin/courses');
              Navigator.pop(context);
            },
          ),

          ListTile(
            leading: const Icon(Icons.people),
            title: const Text('Students'),
            onTap: () {
              context.push('/admin/students');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.analytics),
            title: const Text('Analytics'),
            onTap: () {
              context.push('/admin/analytics');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.payment),
            title: const Text('Payments'),
            onTap: () {
              context.push('/admin/payments');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.settings),
            title: const Text('Settings'),
            onTap: () {
              context.push('/admin/settings');
              Navigator.pop(context);
            },
          ),
          const Divider(),
          Consumer(
            builder: (context, ref, child) {
              return ListTile(
                leading: const Icon(Icons.logout),
                title: const Text('Logout'),
                onTap: () {
                  // Handle logout
                  ref.read(authProvider.notifier).logout();
                  context.go('/login');
                  Navigator.pop(context);
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardContent(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
    if (dashboardState.isLoading && dashboardState.stats == null) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 20),
            Text('Loading dashboard data...'),
          ],
        ),
      );
    }
    
    if (dashboardState.error != null && dashboardState.stats == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error, size: 50, color: Colors.red),
            const SizedBox(height: 20),
            Text(
              'Error loading dashboard: ${dashboardState.error}',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.red),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }
    
    final stats = dashboardState.stats;
    
    if (stats == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Welcome back, Admin!',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: AppTheme.blackColor,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Manage your coaching platform efficiently',
            style: TextStyle(
              fontSize: 16,
              color: AppTheme.greyColor,
            ),
          ),
          const SizedBox(height: 30),
          
          // Data Source Info
          _buildDataSourceInfo(stats),
          
          const SizedBox(height: 20),
          
          // Stats Cards
          _buildStatsSection(stats),
          
          const SizedBox(height: 30),
          
          // Quick Actions
          _buildQuickActionsSection(context),
          
          const SizedBox(height: 30),
          
          // Recent Activity
          _buildRecentActivitySection(stats),
        ],
      ),
    );
  }

  Widget _buildDataSourceInfo(AdminDashboardStats stats) {
    // For now, we'll use default values since AdminDashboardStats doesn't have source info
    final sourceText = 'MongoDB Primary';
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning,
            color: Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data Source: $sourceText',
              style: TextStyle(
                color: Colors.orange[800],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(AdminDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Statistics Overview',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            _buildStatCard('Total Courses', stats.totalCourses.toString(), Icons.school, AppTheme.primaryGreen),
            const SizedBox(width: 15),
            _buildStatCard('Active Students', stats.activeStudents.toString(), Icons.people, AppTheme.accent),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildStatCard('Total Revenue', 'RWF ${stats.totalRevenue.toStringAsFixed(0)}', Icons.attach_money, AppTheme.primaryGreen),
            const SizedBox(width: 15),
            _buildStatCard('Pending Exams', stats.pendingExams.toString(), Icons.quiz, AppTheme.accent),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(
                icon,
                color: color,
                size: 24,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              value,
              style: const TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              title,
              style: const TextStyle(
                fontSize: 14,
                color: AppTheme.greyColor,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 15,
          mainAxisSpacing: 15,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildActionCard(
              context,
              'Create Course',
              'Add new courses to platform',
              Icons.add,
              AppTheme.primaryGreen,
              '/admin/courses/create',
            ),
            _buildActionCard(
              context,
              'Upload Video',
              'Add educational videos',
              Icons.video_call,
              AppTheme.accent,
              '/admin/videos/upload',
            ),
            _buildActionCard(
              context,
              'Create Exam',
              'Generate new assessments',
              Icons.quiz,
              AppTheme.primaryGreen,
              '/admin/exams/create',
            ),
            _buildActionCard(
              context,
              'View Reports',
              'Check platform analytics',
              Icons.bar_chart,
              AppTheme.accent,
              '/admin/analytics',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildActionCard(
    BuildContext context,
    String title,
    String subtitle,
    IconData icon,
    Color color,
    String route,
  ) {
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.1),
              spreadRadius: 1,
              blurRadius: 5,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: color,
                size: 30,
              ),
            ),
            const SizedBox(height: 15),
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 5),
            Text(
              subtitle,
              style: const TextStyle(
                fontSize: 12,
                color: AppTheme.greyColor,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(AdminDashboardStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(15),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.1),
                spreadRadius: 1,
                blurRadius: 5,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: stats.recentActivity.map((activity) => Column(
              children: [
                _ActivityItem(
                  icon: _getIconFromString(activity.icon),
                  title: activity.title,
                  subtitle: activity.subtitle,
                  time: activity.time,
                ),
                if (stats.recentActivity.indexOf(activity) < stats.recentActivity.length - 1)
                  const SizedBox(height: 15),
              ],
            )).toList(),
          ),
        ),
      ],
    );
  }
  static IconData _getIconFromString(String? iconString) {
    switch (iconString) {
      case 'school':
        return Icons.school;
      case 'people':
        return Icons.people;
      case 'payment':
        return Icons.payment;
      case 'video_call':
        return Icons.video_call;
      case 'quiz':
        return Icons.quiz;
      case 'add':
        return Icons.add;
      case 'person_add':
        return Icons.person_add;
      default:
        return Icons.info;
    }
  }
}

class _ActivityItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String time;

  const _ActivityItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.time,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: const BoxDecoration(
            color: AppTheme.primaryGreen,
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            color: Colors.white,
            size: 16,
          ),
        ),
        const SizedBox(width: 15),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.greyColor,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
        Text(
          time,
          style: const TextStyle(
            color: AppTheme.greyColor,
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}