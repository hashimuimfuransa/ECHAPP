import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';

class AdminNotificationState {
  final bool isLoading;
  final List<AdminNotification> notifications;
  final String? error;

  AdminNotificationState({
    this.isLoading = false,
    this.notifications = const [],
    this.error,
  });

  AdminNotificationState copyWith({
    bool? isLoading,
    List<AdminNotification>? notifications,
    String? error,
  }) {
    return AdminNotificationState(
      isLoading: isLoading ?? this.isLoading,
      notifications: notifications ?? this.notifications,
      error: error ?? this.error,
    );
  }
}

class AdminNotificationNotifier extends StateNotifier<AdminNotificationState> {
  final AdminService _adminService;

  AdminNotificationNotifier(this._adminService) : super(AdminNotificationState());

  Future<void> loadNotifications() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final notifications = await _adminService.getNotifications();
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

  Future<void> markAllAsRead() async {
    try {
      await _adminService.markAllAsRead();
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> deleteAllNotifications() async {
    try {
      await _adminService.deleteAllNotifications();
      await loadNotifications();
    } catch (e) {
      state = state.copyWith(error: e.toString());
    }
  }
}

final adminNotificationProvider = StateNotifierProvider<AdminNotificationNotifier, AdminNotificationState>((ref) {
  return AdminNotificationNotifier(AdminService());
});
