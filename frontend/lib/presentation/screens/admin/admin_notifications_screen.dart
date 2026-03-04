import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_notification_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';

class AdminNotificationsScreen extends ConsumerStatefulWidget {
  const AdminNotificationsScreen({super.key});

  @override
  ConsumerState<AdminNotificationsScreen> createState() => _AdminNotificationsScreenState();
}

class _AdminNotificationsScreenState extends ConsumerState<AdminNotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final List<String> _tabs = ['All', 'Payments', 'Exams', 'Users', 'Enrollments'];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: _tabs.length, vsync: this);
    Future.microtask(() => ref.read(adminNotificationProvider.notifier).loadNotifications());
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminNotificationProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('System Notifications'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.read(adminNotificationProvider.notifier).loadNotifications(),
            tooltip: 'Refresh Notifications',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabs: _tabs.map((tab) => Tab(text: tab)).toList(),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: _tabs.map((tab) => _buildBody(state, tab.toLowerCase())).toList(),
      ),
    );
  }

  Widget _buildBody(AdminNotificationState state, String filter) {
    if (state.isLoading && state.notifications.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.notifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 60, color: Colors.red),
            const SizedBox(height: 16),
            Text('Error: ${state.error}'),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.read(adminNotificationProvider.notifier).loadNotifications(),
              child: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    List<AdminNotification> filteredNotifications = state.notifications;
    if (filter != 'all') {
      // Map tab names to notification types
      String typeFilter = filter;
      if (filter == 'payments') typeFilter = 'payment';
      if (filter == 'exams') typeFilter = 'exam';
      if (filter == 'users') typeFilter = 'user';
      if (filter == 'enrollments') typeFilter = 'enrollment';
      
      filteredNotifications = state.notifications.where((n) => n.type == typeFilter).toList();
    }

    if (filteredNotifications.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.notifications_none_rounded, size: 80, color: AppTheme.greyColor.withOpacity(0.5)),
            const SizedBox(height: 16),
            Text(
              'No ${filter == 'all' ? '' : filter} notifications found',
              style: TextStyle(fontSize: 18, color: AppTheme.greyColor),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => ref.read(adminNotificationProvider.notifier).loadNotifications(),
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(vertical: 8),
        itemCount: filteredNotifications.length,
        itemBuilder: (context, index) {
          final notification = filteredNotifications[index];
          return _NotificationItem(notification: notification);
        },
      ),
    );
  }
}

class _NotificationItem extends StatelessWidget {
  final AdminNotification notification;

  const _NotificationItem({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
        border: notification.isRead 
          ? null 
          : Border.all(color: _getSeverityColor().withOpacity(0.3), width: 1),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(12),
        leading: _getLeadingIcon(),
        title: Row(
          children: [
            Expanded(
              child: Text(
                notification.title,
                style: TextStyle(
                  fontWeight: notification.isRead ? FontWeight.w500 : FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            if (notification.isVirtual)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'SYSTEM',
                  style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                ),
              ),
          ],
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 6),
            Text(
              notification.message,
              style: TextStyle(
                color: isDark ? Colors.white70 : Colors.black87,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _formatTimestamp(notification.timestamp),
                  style: TextStyle(fontSize: 12, color: AppTheme.greyColor),
                ),
                if (!notification.isRead && !notification.isVirtual)
                  Text(
                    'NEW',
                    style: TextStyle(
                      fontSize: 10, 
                      color: _getSeverityColor(), 
                      fontWeight: FontWeight.bold
                    ),
                  ),
              ],
            ),
          ],
        ),
        onTap: () => _handleTap(context),
        isThreeLine: true,
      ),
    );
  }

  String _formatTimestamp(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);

    if (difference.inMinutes < 60) {
      return '${difference.inMinutes} mins ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return DateFormat('MMM dd, hh:mm a').format(timestamp);
    }
  }

  Color _getSeverityColor() {
    switch (notification.severity) {
      case 'high':
        return Colors.red;
      case 'medium':
        return Colors.orange;
      case 'info':
      default:
        return AppTheme.primaryGreen;
    }
  }

  Widget _getLeadingIcon() {
    IconData iconData;
    Color color;

    switch (notification.type) {
      case 'payment':
        iconData = Icons.payments_rounded;
        color = Colors.orange;
        break;
      case 'course':
        iconData = Icons.school_rounded;
        color = Colors.blue;
        break;
      case 'exam':
        iconData = Icons.quiz_rounded;
        color = Colors.purple;
        break;
      case 'user':
        iconData = Icons.person_add_rounded;
        color = Colors.teal;
        break;
      case 'enrollment':
        iconData = Icons.how_to_reg_rounded;
        color = Colors.indigo;
        break;
      case 'error':
        iconData = Icons.error_rounded;
        color = Colors.red;
        break;
      default:
        iconData = Icons.notifications_rounded;
        color = AppTheme.primaryGreen;
    }

    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(iconData, color: color, size: 24),
    );
  }

  void _handleTap(BuildContext context) {
    if (notification.type == 'payment') {
      context.push('/admin/payments');
    } else if (notification.type == 'course' && notification.data.containsKey('courseId')) {
      context.push('/admin/courses/${notification.data['courseId']}');
    } else if (notification.type == 'user' && notification.data.containsKey('userId')) {
      context.push('/admin/students/${notification.data['userId']}');
    } else if (notification.type == 'exam' && notification.data.containsKey('userId')) {
      // Could navigate to student results or exam management
      context.push('/admin/students/${notification.data['userId']}');
    }
  }
}
