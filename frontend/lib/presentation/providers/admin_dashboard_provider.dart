import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/services/admin_service.dart';

class AdminDashboardState {
  final bool isLoading;
  final Map<String, dynamic>? stats;
  final String? error;

  AdminDashboardState({
    this.isLoading = false,
    this.stats,
    this.error,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    Map<String, dynamic>? stats,
    String? error,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      stats: stats ?? this.stats,
      error: error ?? this.error,
    );
  }
}

class AdminDashboardNotifier extends StateNotifier<AdminDashboardState> {
  AdminDashboardNotifier() : super(AdminDashboardState());

  Future<void> loadDashboardData() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final stats = await AdminService.getDashboardStats();
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier();
});