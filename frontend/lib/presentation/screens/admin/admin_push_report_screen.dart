import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_push_report_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';

/// Push delivery report.
///
/// Push sends swallow their own errors on the server so a dead device token can
/// never break the action that triggered the notification. That makes silent
/// failure the default, so this page is the only place an admin can see which
/// notifications actually reached a phone and why the rest did not.
class AdminPushReportScreen extends ConsumerStatefulWidget {
  const AdminPushReportScreen({super.key});

  @override
  ConsumerState<AdminPushReportScreen> createState() => _AdminPushReportScreenState();
}

class _AdminPushReportScreenState extends ConsumerState<AdminPushReportScreen> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _searchController = TextEditingController();

  static const _statusFilters = <String, String>{
    'all': 'All',
    'sent': 'Delivered',
    'failed': 'Failed',
    'skipped': 'Not sent',
  };

  static const _windows = <int, String>{
    1: 'Last 24h',
    7: 'Last 7 days',
    30: 'Last 30 days',
  };

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    Future.microtask(() => ref.read(adminPushReportProvider.notifier).load());
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 300) {
      ref.read(adminPushReportProvider.notifier).loadMore();
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminPushReportProvider);
    final isWide = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Push Delivery Report'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.read(adminPushReportProvider.notifier).load(),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(adminPushReportProvider.notifier).load(),
        child: _buildBody(state, isWide),
      ),
    );
  }

  Widget _buildBody(AdminPushReportState state, bool isWide) {
    if (state.isLoading && state.report == null) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.report == null) {
      return _errorView(state.error!);
    }

    final report = state.report;
    if (report == null) return const SizedBox.shrink();

    return ListView(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      children: [
        _summaryCards(report.summary, isWide),
        const SizedBox(height: 20),
        if (report.daily.isNotEmpty) ...[
          _trendCard(report.daily),
          const SizedBox(height: 20),
        ],
        if (report.breakdown.isNotEmpty) ...[
          _failureBreakdown(report.breakdown),
          const SizedBox(height: 20),
        ],
        _filters(state),
        const SizedBox(height: 12),
        _logList(state),
        if (state.isLoadingMore)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()),
          ),
        const SizedBox(height: 32),
      ],
    );
  }

  Widget _errorView(String error) {
    return ListView(
      children: [
        const SizedBox(height: 120),
        const Icon(Icons.error_outline, size: 60, color: Colors.red),
        const SizedBox(height: 16),
        Center(child: Text('Error: $error', textAlign: TextAlign.center)),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton(
            onPressed: () => ref.read(adminPushReportProvider.notifier).load(),
            child: const Text('Retry'),
          ),
        ),
      ],
    );
  }

  // ── Summary ───────────────────────────────────────────────────────

  Widget _summaryCards(PushReportSummary summary, bool isWide) {
    final cards = [
      _statCard('Delivered', summary.sent.toString(), Icons.check_circle_rounded,
          AppTheme.primaryGreen, 'Accepted by FCM'),
      _statCard('Failed', summary.failed.toString(), Icons.error_rounded,
          const Color(0xFFEF4444), 'Rejected by FCM'),
      _statCard('Not sent', summary.skipped.toString(), Icons.block_rounded,
          const Color(0xFFF59E0B), 'No token or capped'),
      _statCard(
          'Delivery rate',
          '${summary.deliveryRate.toStringAsFixed(1)}%',
          Icons.trending_up_rounded,
          AppTheme.accent,
          '${summary.total} attempts'),
    ];

    if (isWide) {
      return Row(
        children: [
          for (var i = 0; i < cards.length; i++) ...[
            Expanded(child: cards[i]),
            if (i < cards.length - 1) const SizedBox(width: 12),
          ],
        ],
      );
    }

    return Column(
      children: [
        Row(children: [
          Expanded(child: cards[0]),
          const SizedBox(width: 12),
          Expanded(child: cards[1]),
        ]),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(child: cards[2]),
          const SizedBox(width: 12),
          Expanded(child: cards[3]),
        ]),
      ],
    );
  }

  Widget _statCard(String label, String value, IconData icon, Color color, String hint) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade700,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 2),
          Text(
            hint,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  /// Shared white card used by the trend and breakdown sections.
  Widget _panel({required String title, required Widget child, Widget? trailing}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
              if (trailing != null) Flexible(child: trailing),
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }

  // ── Trend ─────────────────────────────────────────────────────────

  Widget _trendCard(List<PushDailyPoint> daily) {
    final maxTotal = daily.fold<int>(1, (m, d) => d.total > m ? d.total : m);

    return _panel(
      title: 'Daily volume',
      child: SizedBox(
        height: 140,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: daily.map((point) {
            return Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Text(
                      point.total.toString(),
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                    const SizedBox(height: 4),
                    // Stacked bar: delivered at the bottom, then failed, then skipped.
                    Tooltip(
                      message:
                          '${point.date}\nDelivered: ${point.sent}\nFailed: ${point.failed}\nNot sent: ${point.skipped}',
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _barSegment(point.skipped, maxTotal, const Color(0xFFF59E0B),
                              top: true),
                          _barSegment(point.failed, maxTotal, const Color(0xFFEF4444)),
                          _barSegment(point.sent, maxTotal, AppTheme.primaryGreen,
                              bottom: true),
                        ],
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      _shortDate(point.date),
                      style: TextStyle(fontSize: 9, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          _legendDot(AppTheme.primaryGreen, 'Delivered'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFEF4444), 'Failed'),
          const SizedBox(width: 10),
          _legendDot(const Color(0xFFF59E0B), 'Not sent'),
        ],
      ),
    );
  }

  Widget _barSegment(int value, int max, Color color, {bool top = false, bool bottom = false}) {
    if (value <= 0) return const SizedBox.shrink();
    // 90px of headroom keeps the tallest stack clear of the count label.
    final height = (value / max) * 90;
    return Container(
      height: height < 3 ? 3 : height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(top ? 4 : 0),
          bottom: Radius.circular(bottom ? 4 : 0),
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }

  String _shortDate(String isoDate) {
    try {
      return DateFormat('d MMM').format(DateTime.parse(isoDate));
    } catch (_) {
      return isoDate;
    }
  }

  // ── Failure breakdown ─────────────────────────────────────────────

  Widget _failureBreakdown(List<PushFailureReason> reasons) {
    return _panel(
      title: 'Why notifications did not arrive',
      child: Column(
        children: reasons.map((reason) {
          final color = reason.status == 'failed'
              ? const Color(0xFFEF4444)
              : const Color(0xFFF59E0B);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 2),
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    reason.count.toString(),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        reason.code,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          fontFamily: 'monospace',
                        ),
                      ),
                      if (reason.explanation != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          reason.explanation!,
                          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Filters ───────────────────────────────────────────────────────

  Widget _filters(AdminPushReportState state) {
    final notifier = ref.read(adminPushReportProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Delivery log',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              ..._statusFilters.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: state.status == entry.key,
                      onSelected: (_) => notifier.setStatus(entry.key),
                      selectedColor: AppTheme.primaryGreen.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: state.status == entry.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: state.status == entry.key
                            ? AppTheme.primaryDark
                            : Colors.grey.shade700,
                      ),
                    ),
                  )),
              Container(
                width: 1,
                height: 24,
                margin: const EdgeInsets.symmetric(horizontal: 8),
                color: Colors.grey.shade300,
              ),
              ..._windows.entries.map((entry) => Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: ChoiceChip(
                      label: Text(entry.value),
                      selected: state.days == entry.key,
                      onSelected: (_) => notifier.setDays(entry.key),
                      selectedColor: AppTheme.accent.withValues(alpha: 0.18),
                      labelStyle: TextStyle(
                        fontSize: 12,
                        fontWeight: state.days == entry.key
                            ? FontWeight.bold
                            : FontWeight.normal,
                        color: state.days == entry.key
                            ? AppTheme.accent
                            : Colors.grey.shade700,
                      ),
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: _searchController,
          decoration: InputDecoration(
            hintText: 'Search title, message or error code',
            prefixIcon: const Icon(Icons.search, size: 20),
            suffixIcon: _searchController.text.isEmpty
                ? null
                : IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      _searchController.clear();
                      notifier.setSearch('');
                    },
                  ),
            isDense: true,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade300),
            ),
          ),
          onSubmitted: notifier.setSearch,
        ),
      ],
    );
  }

  // ── Log list ──────────────────────────────────────────────────────

  Widget _logList(AdminPushReportState state) {
    if (state.isLoading) {
      return const Padding(
        padding: EdgeInsets.all(40),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.logs.isEmpty) {
      return Container(
        padding: const EdgeInsets.symmetric(vertical: 48),
        alignment: Alignment.center,
        child: Column(
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              state.status == 'all'
                  ? 'No push notifications in this period'
                  : 'No "${_statusFilters[state.status]}" notifications in this period',
              style: TextStyle(color: Colors.grey.shade600),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        for (final log in state.logs) ...[
          _logTile(log),
          const SizedBox(height: 8),
        ],
        if (state.logs.length < state.totalLogsOrZero)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              'Showing ${state.logs.length} of ${state.totalLogsOrZero}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
            ),
          ),
      ],
    );
  }

  Widget _logTile(PushLogEntry log) {
    final (color, icon, label) = switch (log.status) {
      'sent' => (AppTheme.primaryGreen, Icons.check_circle_rounded, 'Delivered'),
      'failed' => (const Color(0xFFEF4444), Icons.error_rounded, 'Failed'),
      _ => (const Color(0xFFF59E0B), Icons.block_rounded, 'Not sent'),
    };

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Theme(
        // Keeps the tile compact until it is opened.
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          title: Text(
            log.title.isEmpty ? '(no title)' : log.title,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Text(
              '${log.userName ?? 'Unknown user'} · ${DateFormat('d MMM, HH:mm').format(log.timestamp)}',
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          trailing: Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              label,
              style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: color),
            ),
          ),
          children: [
            _detailRow('Message', log.message),
            if (log.userEmail != null) _detailRow('Recipient', log.userEmail!),
            if (log.errorCode != null) _detailRow('Error code', log.errorCode!),
            if (log.explanation != null) _detailRow('What it means', log.explanation!),
            if (log.errorMessage != null) _detailRow('Details', log.errorMessage!),
            if (log.messageId != null) _detailRow('FCM message id', log.messageId!),
            if (log.tokenTail != null)
              _detailRow('Device token', '…${log.tokenTail} (from ${log.tokenSource})'),
            if (log.attempts > 0) _detailRow('Attempts', log.attempts.toString()),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

extension on AdminPushReportState {
  int get totalLogsOrZero => report?.totalLogs ?? 0;
}
