import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';

class AdminPushReportState {
  final bool isLoading;

  /// True while paging in more rows, so the list can keep showing what it has.
  final bool isLoadingMore;
  final PushReport? report;
  final List<PushLogEntry> logs;
  final String? error;

  // Active filters
  final int days;
  final String status;
  final String search;
  final int page;

  const AdminPushReportState({
    this.isLoading = false,
    this.isLoadingMore = false,
    this.report,
    this.logs = const [],
    this.error,
    this.days = 7,
    this.status = 'all',
    this.search = '',
    this.page = 1,
  });

  AdminPushReportState copyWith({
    bool? isLoading,
    bool? isLoadingMore,
    PushReport? report,
    List<PushLogEntry>? logs,
    String? error,
    bool clearError = false,
    int? days,
    String? status,
    String? search,
    int? page,
  }) {
    return AdminPushReportState(
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      report: report ?? this.report,
      logs: logs ?? this.logs,
      error: clearError ? null : (error ?? this.error),
      days: days ?? this.days,
      status: status ?? this.status,
      search: search ?? this.search,
      page: page ?? this.page,
    );
  }

  bool get hasMore => report?.hasMore ?? false;
}

class AdminPushReportNotifier extends StateNotifier<AdminPushReportState> {
  final AdminService _adminService;

  AdminPushReportNotifier(this._adminService) : super(const AdminPushReportState());

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true, page: 1);
    try {
      final report = await _adminService.getPushReport(
        days: state.days,
        status: state.status,
        search: state.search,
        page: 1,
      );
      state = state.copyWith(
        isLoading: false,
        report: report,
        logs: report.logs,
        page: 1,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// Appends the next page of log rows; summary figures stay as they are.
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    state = state.copyWith(isLoadingMore: true);
    try {
      final next = state.page + 1;
      final report = await _adminService.getPushReport(
        days: state.days,
        status: state.status,
        search: state.search,
        page: next,
      );
      state = state.copyWith(
        isLoadingMore: false,
        report: report,
        logs: [...state.logs, ...report.logs],
        page: next,
      );
    } catch (e) {
      state = state.copyWith(isLoadingMore: false, error: e.toString());
    }
  }

  Future<void> setDays(int days) async {
    if (days == state.days) return;
    state = state.copyWith(days: days);
    await load();
  }

  Future<void> setStatus(String status) async {
    if (status == state.status) return;
    state = state.copyWith(status: status);
    await load();
  }

  Future<void> setSearch(String search) async {
    if (search == state.search) return;
    state = state.copyWith(search: search);
    await load();
  }
}

final adminPushReportProvider =
    StateNotifierProvider<AdminPushReportNotifier, AdminPushReportState>((ref) {
  return AdminPushReportNotifier(AdminService());
});
