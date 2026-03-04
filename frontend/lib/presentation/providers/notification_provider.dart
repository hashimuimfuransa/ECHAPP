import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/models/notification.dart';
import 'package:excellencecoachinghub/services/notification_service.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

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
  final Ref ref;
  NotificationNotifier(this.ref) : super(NotificationState()) {
    // Automatically load notifications when initialized if user is logged in
    _init();
  }

  void _init() {
    // Wait for next frame to avoid state modification during build
    Future.microtask(() {
      final authState = ref.read(authProvider);
      if (authState.user != null) {
        loadNotifications();
      }
    });
    
    // Also listen for auth changes
    ref.listen(authProvider, (previous, next) {
      if (next.user != null && previous?.user == null) {
        loadNotifications();
      }
    });
  }

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

  Future<void> deleteNotification(String notificationId) async {
    try {
      final notificationService = NotificationService();
      await notificationService.deleteNotification(notificationId);
      
      final updatedNotifications = state.notifications
          .where((notification) => notification.id != notificationId)
          .toList();
      
      state = state.copyWith(notifications: updatedNotifications);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      final notificationService = NotificationService();
      await notificationService.deleteAllNotifications();
      
      state = state.copyWith(notifications: []);
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final notificationProvider = StateNotifierProvider<NotificationNotifier, NotificationState>((ref) {
  return NotificationNotifier(ref);
});

final notificationCountProvider = Provider<AsyncValue<int>>((ref) {
  final state = ref.watch(notificationProvider);
  if (state.isLoading) {
    return const AsyncValue.loading();
  }
  if (state.error != null) {
    return AsyncValue.error(state.error!, StackTrace.current);
  }
  final unreadCount = state.notifications.where((n) => !n.isRead).length;
  return AsyncValue.data(unreadCount);
});
