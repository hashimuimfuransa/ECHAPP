import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSyncing = false;
  bool _hasLoadedInitialData = false;
  bool _hasCheckedRole = false;
  String? _syncMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkUserRole();
  }

  @override
  void didUpdateWidget(covariant AdminDashboardScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    _checkUserRole();
  }

  void _checkUserRole() {
    if (!_hasCheckedRole) {
      final authState = ref.watch(authProvider);
      if (authState.user != null && !authState.isLoading) {
        _hasCheckedRole = true;
        debugPrint('AdminDashboardScreen: Checking user role - ${authState.user?.role}');
        
        // If user is not admin, redirect to student dashboard
        if (authState.user?.role != 'admin') {
          debugPrint('AdminDashboardScreen: Non-admin detected, redirecting to student dashboard');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            context.go('/dashboard');
          });
        }
      }
    }
  }

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
      
    if (!_hasLoadedInitialData && dashboardState.stats == null && !dashboardState.isLoading) {
      _hasLoadedInitialData = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      });
    }
    
    if (ResponsiveBreakpoints.isDesktop(context)) {
      return _buildDesktopLayout(context, ref, dashboardState);
    } else {
      return _buildMobileLayout(context, ref, dashboardState);
    }
  }
  
  Widget _buildDesktopLayout(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
    return Scaffold(
      body: Row(
        children: [
          _buildDesktopSidebar(context, ref),
          Expanded(
            child: Column(
              children: [
                _buildDesktopHeader(context, ref),
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: Theme.of(context).brightness == Brightness.dark
                            ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                            : [const Color(0xFFF8FAFC), const Color(0xFFF0F9FF)],
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                      ),
                    ),
                    child: _buildDashboardContent(context, ref, dashboardState),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileLayout(BuildContext context, WidgetRef ref, AdminDashboardState dashboardState) {
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
                  _showNotificationCenter(context);
                },
              );
            },
          ),
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
                color: Theme.of(context).cardColor,
                onSelected: (value) {
                  if (value == 'logout') {
                    _showLogoutDialog(context);
                  }
                },
                itemBuilder: (context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      value: 'profile',
                      child: Row(
                        children: [
                          Icon(Icons.person_outline, color: AppTheme.getIconColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Profile', style: TextStyle(color: AppTheme.getTextColor(context))),
                        ],
                      ),
                      onTap: () => context.push('/profile'),
                    ),
                    PopupMenuItem<String>(
                      value: 'settings',
                      child: Row(
                        children: [
                          Icon(Icons.settings_outlined, color: AppTheme.getIconColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Settings', style: TextStyle(color: AppTheme.getTextColor(context))),
                        ],
                      ),
                      onTap: () => context.push('/settings'),
                    ),
                    const PopupMenuDivider(),
                    PopupMenuItem<String>(
                      value: 'logout',
                      child: Row(
                        children: [
                          Icon(Icons.logout, color: AppTheme.getErrorColor(context), size: 18),
                          const SizedBox(width: 10),
                          Text('Logout', style: TextStyle(color: AppTheme.getErrorColor(context))),
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
  
  Widget _buildDesktopSidebar(BuildContext context, WidgetRef ref) {
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
          Padding(
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
                  'Admin Panel',
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
                  'Manage platform',
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
              children: [
                _buildDesktopNavItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', true),
                _buildDesktopNavItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false),
                _buildDesktopNavItem(context, 'Students', Icons.people_rounded, '/admin/students', false),
                _buildDesktopNavItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false),
                _buildDesktopNavItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false),
                _buildDesktopNavItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: SizedBox(
              width: double.infinity,
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () => _showLogoutDialog(context),
                  borderRadius: BorderRadius.circular(10),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    child: Row(
                      children: [
                        Icon(
                          Icons.logout_rounded,
                          size: 18,
                          color: Colors.red.shade600,
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Logout',
                          style: TextStyle(
                            color: Colors.red.shade600,
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                          ),
                        ),
                      ],
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
  
  Widget _buildDesktopNavItem(BuildContext context, String title, IconData icon, String route, bool isActive) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isActive ? null : () => context.push(route),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isActive
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
                    color: isActive
                        ? AppTheme.primaryGreen.withOpacity(0.15)
                        : AppTheme.greyColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(
                    icon,
                    color: isActive ? AppTheme.primaryGreen : AppTheme.greyColor,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      color: isActive ? AppTheme.primaryGreen : AppTheme.getTextColor(context),
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                      fontSize: 14,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                if (isActive)
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
  }
  
  Widget _buildDesktopHeader(BuildContext context, WidgetRef ref) {
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Welcome back, Admin',
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Manage your coaching platform efficiently',
                style: TextStyle(
                  fontSize: 14,
                  color: AppTheme.greyColor,
                ),
              ),
            ],
          ),
          Row(
            children: [
              IconButton(
                icon: _isSyncing 
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.sync),
                onPressed: _isSyncing ? null : _triggerManualSync,
                tooltip: 'Sync Users',
              ),
              IconButton(
                icon: const Icon(Icons.refresh),
                onPressed: () => ref.read(adminDashboardProvider.notifier).loadDashboardData(),
                tooltip: 'Refresh Dashboard',
              ),
              Consumer(
                builder: (context, ref, child) {
                  final notificationState = ref.watch(notificationProvider);
                  final unreadCount = notificationState.notifications.where((n) => !n.isRead).length;
                  
                  return IconButton(
                    icon: Stack(
                      children: [
                        const Icon(Icons.notifications_outlined, size: 24),
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
                    onPressed: () => _showNotificationCenter(context),
                    tooltip: 'Notifications',
                  );
                },
              ),
              Consumer(
                builder: (context, ref, child) {
                  final user = ref.watch(authProvider).user;
                  return PopupMenuButton(
                    icon: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                      child: Text(
                        user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
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
                    itemBuilder: (context) {
                      return <PopupMenuEntry<String>>[
                        PopupMenuItem<String>(
                          value: 'profile',
                          child: Row(
                            children: [
                              Icon(Icons.person_outline, color: AppTheme.getIconColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Profile', style: TextStyle(color: AppTheme.getTextColor(context))),
                            ],
                          ),
                          onTap: () => context.push('/profile'),
                        ),
                        PopupMenuItem<String>(
                          value: 'settings',
                          child: Row(
                            children: [
                              Icon(Icons.settings_outlined, color: AppTheme.getIconColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Settings', style: TextStyle(color: AppTheme.getTextColor(context))),
                            ],
                          ),
                          onTap: () => context.push('/settings'),
                        ),
                        const PopupMenuDivider(),
                        PopupMenuItem<String>(
                          value: 'logout',
                          child: Row(
                            children: [
                              Icon(Icons.logout, color: AppTheme.getErrorColor(context), size: 18),
                              const SizedBox(width: 10),
                              Text('Logout', style: TextStyle(color: AppTheme.getErrorColor(context))),
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
        ],
      ),
    );
  }
  
  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: AppTheme.whiteColor,
          title: Text(
            'Logout',
            style: TextStyle(color: AppTheme.getTextColor(context)),
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
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 4),
                const Text(
                  'Manage platform',
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
              children: [
                _buildMobileNavItem(context, 'Dashboard', Icons.dashboard_rounded, '/admin', true),
                _buildMobileNavItem(context, 'Courses', Icons.school_rounded, '/admin/courses', false),
                _buildMobileNavItem(context, 'Students', Icons.people_rounded, '/admin/students', false),
                _buildMobileNavItem(context, 'Analytics', Icons.analytics_rounded, '/admin/analytics', false),
                _buildMobileNavItem(context, 'Payments', Icons.payments_rounded, '/admin/payments', false),
                _buildMobileNavItem(context, 'Settings', Icons.settings_rounded, '/admin/settings', false),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Consumer(
              builder: (context, ref, child) {
                return SizedBox(
                  width: double.infinity,
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () {
                        ref.read(authProvider.notifier).logout();
                        context.go('/login');
                        Navigator.pop(context);
                      },
                      borderRadius: BorderRadius.circular(10),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
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
          ),
        ],
      ),
    );
  }
  
  Widget _buildMobileNavItem(BuildContext context, String title, IconData icon, String route, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isSelected ? null : () {
            context.push(route);
            Navigator.pop(context);
          },
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: isSelected
                ? BoxDecoration(
                    color: AppTheme.primaryGreen.withOpacity(0.15),
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
                    ),
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 4,
                    height: 20,
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
    
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 32.0 : 20.0;
    
    return SingleChildScrollView(
      padding: EdgeInsets.all(padding),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isDesktop) ...[
            Text(
              'Welcome back, Admin!',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
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
          ],
          
          _buildDataSourceInfo(stats),
          
          SizedBox(height: isDesktop ? 28 : 20),
          
          _buildStatsSection(stats, context),
          
          SizedBox(height: isDesktop ? 40 : 30),
          
          _buildQuickActionsSection(context),
          
          SizedBox(height: isDesktop ? 40 : 30),
          
          _buildRecentActivitySection(stats, context),
          
          SizedBox(height: isDesktop ? 40 : 20),
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
  
  Widget _buildStatsSection(AdminDashboardStats stats, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final spacing = isDesktop ? 20.0 : 15.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Statistics Overview',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          children: [
            _buildStatCard('Total Courses', stats.totalCourses.toString(), Icons.school, AppTheme.primaryGreen, context),
            _buildStatCard('Active Students', stats.activeStudents.toString(), Icons.people, AppTheme.accent, context),
            _buildStatCard('Total Revenue', 'RWF ${stats.totalRevenue.toStringAsFixed(0)}', Icons.attach_money, AppTheme.primaryGreen, context),
            _buildStatCard('Pending Exams', stats.pendingExams.toString(), Icons.quiz, AppTheme.accent, context),
          ],
        ),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 24.0 : 20.0;
    final iconSize = isDesktop ? 28.0 : 24.0;
    final valueFontSize = isDesktop ? 28.0 : 24.0;
    
    return Container(
      padding: EdgeInsets.all(padding),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.08),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: EdgeInsets.all(isDesktop ? 12 : 10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: color,
              size: iconSize,
            ),
          ),
          SizedBox(height: isDesktop ? 20 : 15),
          Text(
            value,
            style: TextStyle(
              fontSize: valueFontSize,
              fontWeight: FontWeight.bold,
              color: AppTheme.getTextColor(context),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: isDesktop ? 8 : 5),
          Text(
            title,
            style: TextStyle(
              fontSize: isDesktop ? 14 : 13,
              color: AppTheme.greyColor,
              height: 1.3,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionsSection(BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final isTablet = ResponsiveBreakpoints.isTablet(context);
    
    final crossAxisCount = isDesktop ? 4 : (isTablet ? 3 : 2);
    final spacing = isDesktop ? 20.0 : 15.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Quick Actions',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        GridView.count(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: spacing,
          mainAxisSpacing: spacing,
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
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    final padding = isDesktop ? 24.0 : 20.0;
    final iconSize = isDesktop ? 36.0 : 30.0;
    final titleFontSize = isDesktop ? 16.0 : 15.0;
    final subtitleFontSize = isDesktop ? 13.0 : 12.0;
    
    return GestureDetector(
      onTap: () => context.push(route),
      child: Container(
        padding: EdgeInsets.all(padding),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.08),
              spreadRadius: 1,
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: EdgeInsets.all(isDesktop ? 18 : 15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                icon,
                color: color,
                size: iconSize,
              ),
            ),
            SizedBox(height: isDesktop ? 18 : 15),
            Text(
              title,
              style: TextStyle(
                fontSize: titleFontSize,
                fontWeight: FontWeight.bold,
                color: AppTheme.getTextColor(context),
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            SizedBox(height: isDesktop ? 6 : 5),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: subtitleFontSize,
                color: AppTheme.greyColor,
                height: 1.3,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivitySection(AdminDashboardStats stats, BuildContext context) {
    final isDesktop = ResponsiveBreakpoints.isDesktop(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Activity',
          style: TextStyle(
            fontSize: isDesktop ? 22 : 20,
            fontWeight: FontWeight.bold,
            color: AppTheme.getTextColor(context),
          ),
        ),
        SizedBox(height: isDesktop ? 24 : 20),
        Container(
          padding: EdgeInsets.all(isDesktop ? 24.0 : 20.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.grey.withOpacity(0.08),
                spreadRadius: 1,
                blurRadius: 8,
                offset: const Offset(0, 2),
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
                  Padding(
                    padding: EdgeInsets.symmetric(vertical: isDesktop ? 16 : 15),
                    child: Divider(
                      height: 1,
                      color: Colors.grey.withOpacity(0.1),
                    ),
                  ),
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
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: AppTheme.getTextColor(context),
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
