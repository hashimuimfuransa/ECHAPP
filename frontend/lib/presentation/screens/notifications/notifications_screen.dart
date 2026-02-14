import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/models/notification.dart' as app_notification;
import 'package:excellencecoachinghub/utils/responsive_utils.dart';

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();
    // Load notifications when screen opens
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationProvider.notifier).loadNotifications();
    });
  }

  String _getTimeAgo(DateTime timestamp) {
    final now = DateTime.now();
    final difference = now.difference(timestamp);
    
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

  IconData _getNotificationIcon(app_notification.Notification notification) {
    switch (notification.type) {
      case 'success':
        return Icons.check_circle;
      case 'info':
        return Icons.info;
      case 'achievement':
        return Icons.emoji_events;
      case 'warning':
        return Icons.warning;
      case 'error':
        return Icons.error;
      case 'payment':
        return Icons.payment;
      case 'course':
        return Icons.school;
      case 'exam':
        return Icons.quiz;
      default:
        return Icons.notifications;
    }
  }

  Color _getNotificationColor(app_notification.Notification notification, BuildContext context) {
    switch (notification.type) {
      case 'success':
        return Colors.green;
      case 'info':
        return AppTheme.primaryGreen;
      case 'achievement':
        return Colors.orange;
      case 'warning':
        return Colors.orange;
      case 'error':
        return Theme.of(context).colorScheme.error;
      case 'payment':
        return Colors.green;
      case 'course':
        return AppTheme.primaryGreen;
      case 'exam':
        return Colors.blue;
      default:
        return AppTheme.greyColor;
    }
  }

  @override
  Widget build(BuildContext context) {
    final notificationState = ref.watch(notificationProvider);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor,
        elevation: 0,
        actions: [
          if (notificationState.notifications.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.done_all),
              onPressed: () {
                ref.read(notificationProvider.notifier).markAllAsRead();
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('All notifications marked as read'),
                    backgroundColor: AppTheme.primaryGreen,
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              tooltip: 'Mark all as read',
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await ref.read(notificationProvider.notifier).loadNotifications();
        },
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: Theme.of(context).brightness == Brightness.dark
                  ? [const Color(0xFF0F172A), const Color(0xFF1E293B)]
                  : [const Color(0xFFF0F9FF), const Color(0xFFE0F2FE)],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
          ),
          child: SafeArea(
            child: notificationState.isLoading
                ? const Center(child: CircularProgressIndicator(color: AppTheme.primaryGreen))
                : notificationState.error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.error_outline,
                              size: 64,
                              color: AppTheme.greyColor,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Failed to load notifications',
                              style: TextStyle(
                                color: AppTheme.getTextColor(context),
                                fontSize: 18,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              notificationState.error!,
                              style: const TextStyle(
                                color: AppTheme.greyColor,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            const SizedBox(height: 24),
                            ElevatedButton(
                              onPressed: () {
                                ref.read(notificationProvider.notifier).loadNotifications();
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppTheme.primaryGreen,
                                foregroundColor: AppTheme.whiteColor,
                              ),
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
                                  Icons.notifications_off_outlined,
                                  size: 64,
                                  color: AppTheme.greyColor,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No notifications yet',
                                  style: TextStyle(
                                    color: AppTheme.getTextColor(context),
                                    fontSize: 18,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'You\'ll see important updates here',
                                  style: const TextStyle(
                                    color: AppTheme.greyColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: ResponsiveBreakpoints.getPadding(context),
                            itemCount: notificationState.notifications.length,
                            itemBuilder: (context, index) {
                              final notification = notificationState.notifications[index] as app_notification.Notification;
                              final notificationNotifier = ref.read(notificationProvider.notifier);
                              
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: ListTile(
                                  contentPadding: const EdgeInsets.all(16),
                                  leading: Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _getNotificationColor(notification, context).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Icon(
                                      _getNotificationIcon(notification),
                                      color: _getNotificationColor(notification, context),
                                      size: 24,
                                    ),
                                  ),
                                  title: Text(
                                    notification.title,
                                    style: TextStyle(
                                      fontWeight: notification.isRead ? FontWeight.normal : FontWeight.bold,
                                      color: AppTheme.getTextColor(context),
                                    ),
                                  ),
                                  subtitle: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      const SizedBox(height: 4),
                                      Text(
                                        notification.message,
                                        style: TextStyle(
                                          color: AppTheme.greyColor,
                                          fontSize: 14,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text(
                                            _getTimeAgo(notification.timestamp),
                                            style: const TextStyle(
                                              color: AppTheme.greyColor,
                                              fontSize: 12,
                                            ),
                                          ),
                                          if (!notification.isRead)
                                            Container(
                                              width: 8,
                                              height: 8,
                                              decoration: const BoxDecoration(
                                                color: AppTheme.primaryGreen,
                                                shape: BoxShape.circle,
                                              ),
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  onTap: () {
                                    // Mark as read when tapped
                                    if (!notification.isRead) {
                                      notificationNotifier.markAsRead(notification.id);
                                    }
                                    
                                    // Handle notification actions based on type
                                    _handleNotificationAction(notification);
                                  },
                                  tileColor: notification.isRead 
                                      ? null 
                                      : Theme.of(context).cardColor.withOpacity(0.7),
                                ),
                              );
                            },
                          ),
          ),
        ),
      ),
    );
  }

  void _handleNotificationAction(app_notification.Notification notification) {
    switch (notification.type) {
      case 'payment':
        // Navigate to payment history
        context.push('/payments/history');
        break;
      case 'course':
        // Navigate to enrolled courses
        context.push('/my-courses');
        break;
      case 'exam':
        // Navigate to exam history
        context.push('/exams/history');
        break;
      case 'achievement':
        // Navigate to certificates or achievements
        context.push('/profile');
        break;
      default:
        // For info, success, warning, error types, just mark as read
        break;
    }
  }
}