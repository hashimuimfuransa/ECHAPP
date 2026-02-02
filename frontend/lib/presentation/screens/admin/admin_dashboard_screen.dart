import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellence_coaching_hub/config/app_theme.dart';
import 'package:excellence_coaching_hub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellence_coaching_hub/presentation/providers/auth_provider.dart';
import 'package:excellence_coaching_hub/services/admin_service.dart';

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSyncing = false;
  String? _syncMessage;

  Future<void> _triggerManualSync() async {
    if (_isSyncing) return;
    
    setState(() {
      _isSyncing = true;
      _syncMessage = 'Syncing users...';
    });
    
    try {
      final result = await AdminService.manualSyncUsers();
      
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
    
    // Load dashboard data when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (dashboardState.stats == null && !dashboardState.isLoading) {
        ref.read(adminDashboardProvider.notifier).loadDashboardData();
      }
    });
    
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
          IconButton(
            icon: const Icon(Icons.notifications),
            onPressed: () {
              // Handle notifications
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle),
            onPressed: () {
              // Handle profile
            },
          ),
        ],
      ),
      drawer: _buildDrawer(context),
      body: _buildDashboardContent(context, ref, dashboardState),
    );
  }

  Widget _buildDrawer(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                const CircleAvatar(
                  radius: 30,
                  backgroundColor: Colors.white,
                  child: Icon(
                    Icons.admin_panel_settings,
                    size: 30,
                    color: AppTheme.primaryGreen,
                  ),
                ),
                const SizedBox(height: 10),
                const Text(
                  'Admin Panel',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 5),
                const Text(
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
            leading: const Icon(Icons.video_library),
            title: const Text('Videos'),
            onTap: () {
              context.push('/admin/videos');
              Navigator.pop(context);
            },
          ),
          ListTile(
            leading: const Icon(Icons.quiz),
            title: const Text('Exams'),
            onTap: () {
              context.push('/admin/exams');
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
                  context.go('/auth-selection');
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
    
    final stats = dashboardState.stats ?? {};
    
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

  Widget _buildDataSourceInfo(Map<String, dynamic> stats) {
    final source = stats['source'] ?? 'unknown';
    final sourceText = source == 'firebase' 
        ? 'Firebase Real-time' 
        : source == 'mongodb' 
            ? 'MongoDB Backup' 
            : 'Fallback Mode';
    
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: source == 'firebase' ? Colors.green[50] : Colors.orange[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: source == 'firebase' ? Colors.green : Colors.orange,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Icon(
            source == 'firebase' ? Icons.cloud_done : Icons.warning,
            color: source == 'firebase' ? Colors.green : Colors.orange,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Data Source: $sourceText',
              style: TextStyle(
                color: source == 'firebase' ? Colors.green[800] : Colors.orange[800],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
          if (source != 'firebase')
            TextButton(
              onPressed: _isSyncing ? null : _triggerManualSync,
              child: _isSyncing
                  ? const SizedBox(
                      width: 12,
                      height: 12,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text(
                      'Sync Now',
                      style: TextStyle(fontSize: 12),
                    ),
            ),
        ],
      ),
    );
  }
  
  Widget _buildStatsSection(Map<String, dynamic> stats) {
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
            _buildStatCard('Total Courses', stats['totalCourses']?.toString() ?? '0', Icons.school, AppTheme.primaryGreen),
            const SizedBox(width: 15),
            _buildStatCard('Active Students', stats['activeStudents']?.toString() ?? '0', Icons.people, AppTheme.accent),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            _buildStatCard('Total Revenue', 'UGX ${stats['totalRevenue']?.toString() ?? '0'}', Icons.attach_money, AppTheme.primaryGreen),
            const SizedBox(width: 15),
            _buildStatCard('Pending Exams', stats['pendingExams']?.toString() ?? '0', Icons.quiz, AppTheme.accent),
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
              '/admin/reports',
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

  Widget _buildRecentActivitySection(Map<String, dynamic> stats) {
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
            children: (
              stats['recentActivity'] as List<dynamic>
            ).map((activity) => Column(
              children: [
                _ActivityItem(
                  icon: _getIconFromString(activity['icon']),
                  title: activity['title'],
                  subtitle: activity['subtitle'],
                  time: activity['time'],
                ),
                if ((stats['recentActivity'] as List<dynamic>).indexOf(activity) < 
                    (stats['recentActivity'] as List<dynamic>).length - 1)
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