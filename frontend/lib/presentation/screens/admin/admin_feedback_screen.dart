import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/feedback_provider.dart';
import 'package:excellencecoachinghub/models/feedback.dart';

class AdminFeedbackScreen extends ConsumerStatefulWidget {
  const AdminFeedbackScreen({super.key});

  @override
  ConsumerState<AdminFeedbackScreen> createState() => _AdminFeedbackScreenState();
}

class _AdminFeedbackScreenState extends ConsumerState<AdminFeedbackScreen> {
  @override
  void initState() {
    super.initState();
    // Refresh feedback on load
    Future.microtask(() => ref.invalidate(allFeedbackProvider));
  }

  @override
  Widget build(BuildContext context) {
    final feedbackAsync = ref.watch(allFeedbackProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Feedback'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(allFeedbackProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: feedbackAsync.when(
        data: (feedbacks) {
          if (feedbacks.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.feedback_outlined, size: 80, color: AppTheme.greyColor.withOpacity(0.5)),
                  const SizedBox(height: 16),
                  Text(
                    'No feedback received yet',
                    style: TextStyle(fontSize: 18, color: AppTheme.greyColor),
                  ),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(allFeedbackProvider),
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              itemCount: feedbacks.length,
              itemBuilder: (context, index) {
                final feedback = feedbacks[index];
                return _FeedbackItem(feedback: feedback);
              },
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, size: 60, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.invalidate(allFeedbackProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FeedbackItem extends ConsumerWidget {
  final FeedbackModel feedback;

  const _FeedbackItem({required this.feedback});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userName = feedback.user?.fullName ?? 'Unknown User';
    final userEmail = feedback.user?.email ?? 'No email';
    
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 6),
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
        border: feedback.isRead 
          ? null 
          : Border.all(color: AppTheme.primaryGreen.withOpacity(0.3), width: 1),
      ),
      child: ExpansionTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
          child: Text(
            userName.isNotEmpty ? userName[0].toUpperCase() : '?',
            style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold),
          ),
        ),
        title: Text(
          userName,
          style: TextStyle(
            fontWeight: feedback.isRead ? FontWeight.w500 : FontWeight.bold,
            fontSize: 16,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        subtitle: Text(
          DateFormat('MMM dd, yyyy • hh:mm a').format(feedback.createdAt),
          style: TextStyle(fontSize: 12, color: AppTheme.greyColor),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!feedback.isRead)
              Container(
                margin: const EdgeInsets.only(right: 8),
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text(
                  'NEW',
                  style: TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            const Icon(Icons.expand_more),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Divider(),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.email_outlined, size: 14, color: AppTheme.greyColor),
                    const SizedBox(width: 4),
                    Text(userEmail, style: TextStyle(fontSize: 13, color: AppTheme.greyColor)),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  feedback.content,
                  style: TextStyle(
                    fontSize: 15,
                    color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    if (!feedback.isRead)
                      TextButton.icon(
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Mark as Read'),
                        onPressed: () => ref.read(feedbackNotifierProvider.notifier).markAsRead(feedback.id),
                        style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                      ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                      onPressed: () => _showDeleteConfirmation(context, ref),
                      tooltip: 'Delete Feedback',
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Feedback'),
        content: const Text('Are you sure you want to delete this feedback?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              ref.read(feedbackNotifierProvider.notifier).deleteFeedback(feedback.id);
              Navigator.pop(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
