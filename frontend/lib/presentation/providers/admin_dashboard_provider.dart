import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/services/admin_service.dart';

class AdminDashboardState {
  final bool isLoading;
  final AdminDashboardStats? stats;
  final String? error;

  AdminDashboardState({
    this.isLoading = false,
    this.stats,
    this.error,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    AdminDashboardStats? stats,
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
  
  DateTime? _lastLoadTime;
  static const Duration _minReloadInterval = Duration(seconds: 5);

  Future<void> loadDashboardData() async {
    // Prevent too frequent reloads
    final now = DateTime.now();
    if (_lastLoadTime != null && 
        now.difference(_lastLoadTime!) < _minReloadInterval) {
      return;
    }
    
    state = state.copyWith(isLoading: true, error: null);
    _lastLoadTime = now;
    
    try {
      final adminService = AdminService();
      final stats = await adminService.getDashboardStats();
      state = state.copyWith(isLoading: false, stats: stats);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }
}

final adminDashboardProvider = StateNotifierProvider<AdminDashboardNotifier, AdminDashboardState>((ref) {
  return AdminDashboardNotifier();
});