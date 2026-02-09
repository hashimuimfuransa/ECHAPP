import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/models/notification.dart';
import 'package:excellence_coaching_hub/services/notification_service.dart';

class NotificationState {
  final bool isLoading;
  final List<Notification> notifications;
  final String? error;

  NotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  NotificationState copyWith({
    bool? isLoading,
    List<Notification>? notifications,
    String? error,
  }) {
    return NotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}

class NotificationNotifier extends StateNotifier<NotificationState> {
  NotificationNotifier() : super(NotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final notificationService = NotificationService();
      final notifications = await notificationService.getNotifications();
      state = state.copyWith(
        isLoading: false,
        notifications: notifications,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  Future<void> markAsRead(String notificationId) async {
    try {
      final notificationService = NotificationService();
      await notificationService.markAsRead(notificationId);
      
      final updatedNotifications = state.notifications.map((notification) {
        if (notification.id == notificationId) {
          return notification.copyWith(isRead: true);
        }
        return notification;
      }).toList();
      
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> markAllAsRead() async {
    try {
      final notificationService = NotificationService();
      await notificationService.markAllAsRead();
      
      final updatedNotifications = state.notifications.map((notification) {
        return notification.copyWith(isRead: true);
      }).toList();
      
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }


}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier();
});