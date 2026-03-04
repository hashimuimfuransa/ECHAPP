import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/course_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/enrollment_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/admin_dashboard_provider.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/widgets/analytics_charts.dart';

class AdminAnalyticsScreen extends ConsumerStatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  ConsumerState<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends ConsumerState<AdminAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  StudentAnalytics? _analytics;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadAnalytics();
  }

  Future<void> _loadAnalytics() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await _adminService.getStudentAnalytics();
      if (!mounted) return;
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  void _handleGlobalRefresh() {
    // Refresh all key providers
    // NOTE: We DO NOT invalidate authProvider here because it causes the user to be logged out.
    ref.invalidate(coursesProvider);
    ref.invalidate(popularCoursesProvider);
    ref.invalidate(enrolledCoursesProvider);
    ref.invalidate(backendCategoriesProvider);
    ref.invalidate(notificationCountProvider);
    ref.invalidate(adminDashboardProvider);
    
    // Also refresh local data
    _loadAnalytics();
    
    // Show a small feedback to the user
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Application refreshed'),
        duration: Duration(seconds: 1),
        behavior: SnackBarBehavior.floating,
        width: 200,
        backgroundColor: AppTheme.primaryGreen,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: (context.canPop() || GoRouterState.of(context).uri.path != '/admin') 
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              onPressed: () {
                if (context.canPop()) {
                  context.pop();
                } else {
                  context.go('/admin');
                }
              },
              tooltip: 'Back',
            ) 
          : null,
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _handleGlobalRefresh,
            tooltip: 'Refresh App',
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh Analytics',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading && _analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    if (_errorMessage != null) {
      return _buildErrorState();
    }
    
    if (_analytics == null) {
      return const Center(child: CircularProgressIndicator());
    }
    
    return SafeArea(child: _buildResponsiveContent());
  }

  Widget _buildErrorState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error, size: 60, color: Colors.red),
          const SizedBox(height: 20),
          Text(
            'Error loading analytics: $_errorMessage',
            textAlign: TextAlign.center,
            style: const TextStyle(color: Colors.red),
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _loadAnalytics,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildResponsiveContent() {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final isLargeScreen = screenWidth > 1200;
        final isMediumScreen = screenWidth > 768 && screenWidth <= 1200;
        final isSmallScreen = screenWidth <= 768;
        
        return SingleChildScrollView(
          padding: EdgeInsets.symmetric(
            horizontal: isSmallScreen ? 16 : 32,
            vertical: isSmallScreen ? 16 : 24,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSmallScreen),
              const SizedBox(height: 32),
              _buildOverviewMetrics(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 40),
              _buildChartsSection(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 40),
              _buildActivityStats(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 40),
              _buildTopPerformers(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 48),
              _buildDataTimestamp(),
              const SizedBox(height: 32),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Container(
      padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppTheme.primaryGreen.withOpacity(0.05),
            Colors.white,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryGreen.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.analytics_rounded,
                        color: AppTheme.primaryGreen,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Analytics Insights',
                      style: TextStyle(
                        fontSize: isSmallScreen ? 20 : 28,
                        fontWeight: FontWeight.w800,
                        color: AppTheme.blackColor,
                        letterSpacing: -0.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Comprehensive overview of platform performance and student engagement',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: AppTheme.greyColor.withOpacity(0.8),
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          if (!isSmallScreen) ...[
            const SizedBox(width: 20),
            _buildQuickActions(),
          ] else ...[
            const SizedBox(width: 8),
            _actionButton(
              icon: Icons.more_vert_rounded,
              onPressed: () => _showMobileActions(context),
              tooltip: 'Actions',
              color: AppTheme.primaryGreen,
            ),
          ],
        ],
      ),
    );
  }

  void _showMobileActions(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.refresh_rounded, color: AppTheme.primaryGreen),
              title: const Text('Refresh Data'),
              onTap: () {
                Navigator.pop(context);
                _loadAnalytics();
              },
            ),
            ListTile(
              leading: const Icon(Icons.file_download_outlined, color: AppTheme.accent),
              title: const Text('Export Report'),
              onTap: () {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Report generation started...')),
                );
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Row(
      children: [
        _actionButton(
          icon: Icons.refresh_rounded,
          onPressed: _loadAnalytics,
          tooltip: 'Sync Data',
          color: AppTheme.primaryGreen,
        ),
        const SizedBox(width: 12),
        _actionButton(
          icon: Icons.file_download_outlined,
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Report generation started...')),
            );
          },
          tooltip: 'Export Report',
          color: AppTheme.accent,
        ),
      ],
    );
  }

  Widget _actionButton({
    required IconData icon,
    required VoidCallback onPressed,
    required String tooltip,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
        tooltip: tooltip,
        style: IconButton.styleFrom(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewMetrics(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Platform Vitals',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                  letterSpacing: -0.3,
                ),
              ),
              if (isSmallScreen)
                IconButton(
                  icon: const Icon(Icons.info_outline, size: 20, color: AppTheme.greyColor),
                  onPressed: () {},
                ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLargeScreen)
          _buildLargeMetricsGrid()
        else if (isMediumScreen)
          _buildMediumMetricsGrid()
        else
          _buildSmallMetricsGrid(),
      ],
    );
  }

  Widget _buildLargeMetricsGrid() {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _metricCard('Total Students', _analytics!.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen, '+12%')),
          const SizedBox(width: 16),
          Expanded(child: _metricCard('Active Users', _analytics!.activeStudents.toString(), Icons.bolt_rounded, Colors.orange, 'Live')),
          const SizedBox(width: 16),
          Expanded(child: _metricCard('New Registrations', _analytics!.newStudentsThisMonth.toString(), Icons.person_add_rounded, AppTheme.accent, 'Monthly')),
          const SizedBox(width: 16),
          Expanded(child: _metricCard('Engagement Rate', '${_analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1)} crs', Icons.auto_graph_rounded, Colors.indigo, 'Avg')),
        ],
      ),
    );
  }

  Widget _buildMediumMetricsGrid() {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _metricCard('Total Students', _analytics!.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen, '+12%')),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Active Users', _analytics!.activeStudents.toString(), Icons.bolt_rounded, Colors.orange, 'Live')),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _metricCard('New Registrations', _analytics!.newStudentsThisMonth.toString(), Icons.person_add_rounded, AppTheme.accent, 'Monthly')),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Engagement', '${_analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1)} crs', Icons.auto_graph_rounded, Colors.indigo, 'Avg')),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallMetricsGrid() {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.1,
      children: [
        _metricCard('Total', _analytics!.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen, '+12%'),
        _metricCard('Active', _analytics!.activeStudents.toString(), Icons.bolt_rounded, Colors.orange, 'Live'),
        _metricCard('New', _analytics!.newStudentsThisMonth.toString(), Icons.person_add_rounded, AppTheme.accent, 'This Mo'),
        _metricCard('Avg Enr', _analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1), Icons.auto_graph_rounded, Colors.indigo, 'Per Std'),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color, String trend) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.08),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
        border: Border.all(color: color.withOpacity(0.05)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trend.startsWith('+') ? Colors.green.withOpacity(0.1) : AppTheme.greyColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  trend,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: trend.startsWith('+') ? Colors.green : AppTheme.greyColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: AppTheme.blackColor,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: AppTheme.greyColor.withOpacity(0.7),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _buildChartsSection(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    final distributionData = [
      ChartData('Active', _analytics!.activeStudents.toDouble()),
      ChartData('Inactive', _analytics!.inactiveStudents.toDouble()),
    ];
    
    final statusData = [
      PieChartData('Active', _analytics!.activeStudents.toDouble(), AppTheme.primaryGreen),
      PieChartData('Inactive', _analytics!.inactiveStudents.toDouble(), Colors.orange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Student Demographics',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.pie_chart_outline_rounded, size: 20, color: AppTheme.greyColor.withOpacity(0.6)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLargeScreen)
          _buildLargeCharts(distributionData, statusData)
        else
          _buildResponsiveCharts(distributionData, statusData, isSmallScreen),
      ],
    );
  }

  Widget _buildLargeCharts(List<ChartData> barData, List<PieChartData> pieData) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 3,
          child: Container(
            height: 400,
            decoration: _chartContainerDecoration(),
            child: BarChartWidget(
              data: barData,
              title: 'Activity Distribution',
              barColor: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          flex: 2,
          child: Container(
            height: 400,
            decoration: _chartContainerDecoration(),
            child: PieChartWidget(
              data: pieData,
              title: 'User Status',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveCharts(List<ChartData> barData, List<PieChartData> pieData, bool isSmallScreen) {
    return Column(
      children: [
        Container(
          height: isSmallScreen ? 300 : 350,
          decoration: _chartContainerDecoration(),
          child: BarChartWidget(
            data: barData,
            title: 'Activity Distribution',
            barColor: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 20),
        Container(
          height: isSmallScreen ? 320 : 380,
          decoration: _chartContainerDecoration(),
          child: PieChartWidget(
            data: pieData,
            title: 'User Status Breakdown',
          ),
        ),
      ],
    );
  }

  BoxDecoration _chartContainerDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(24),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
      border: Border.all(color: AppTheme.greyColor.withOpacity(0.05)),
    );
  }

  Widget _buildActivityStats(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    final stats = _analytics!.studentActivityStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            children: [
              Text(
                'Activity Insights',
                style: TextStyle(
                  fontSize: isSmallScreen ? 18 : 22,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.blackColor,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.insights_rounded, size: 20, color: AppTheme.greyColor.withOpacity(0.6)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (isLargeScreen)
          _buildLargeActivityGrid(stats)
        else if (isMediumScreen)
          _buildMediumActivityGrid(stats)
        else
          _buildSmallActivityGrid(stats),
      ],
    );
  }

  Widget _buildLargeActivityGrid(dynamic stats) {
    return IntrinsicHeight(
      child: Row(
        children: [
          Expanded(child: _statCard('Daily Active', stats.dailyActiveStudents.toString(), Icons.today_rounded, Colors.blue)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Weekly Active', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week_rounded, Colors.purple)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Monthly Active', stats.monthlyActiveStudents.toString(), Icons.calendar_month_rounded, Colors.indigo)),
          const SizedBox(width: 16),
          Expanded(child: _statCard('Avg Session', '${stats.avgSessionDuration.toStringAsFixed(0)} min', Icons.timer_rounded, Colors.teal)),
        ],
      ),
    );
  }

  Widget _buildMediumActivityGrid(dynamic stats) {
    return Column(
      children: [
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _statCard('Daily Active', stats.dailyActiveStudents.toString(), Icons.today_rounded, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Weekly Active', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week_rounded, Colors.purple)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        IntrinsicHeight(
          child: Row(
            children: [
              Expanded(child: _statCard('Monthly Active', stats.monthlyActiveStudents.toString(), Icons.calendar_month_rounded, Colors.indigo)),
              const SizedBox(width: 16),
              Expanded(child: _statCard('Avg Session', '${stats.avgSessionDuration.toStringAsFixed(0)} min', Icons.timer_rounded, Colors.teal)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSmallActivityGrid(dynamic stats) {
    return GridView.count(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisCount: 2,
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      childAspectRatio: 1.4,
      children: [
        _statCard('Daily', stats.dailyActiveStudents.toString(), Icons.today_rounded, Colors.blue),
        _statCard('Weekly', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week_rounded, Colors.purple),
        _statCard('Monthly', stats.monthlyActiveStudents.toString(), Icons.calendar_month_rounded, Colors.indigo),
        _statCard('Session', '${stats.avgSessionDuration.toStringAsFixed(0)}m', Icons.timer_rounded, Colors.teal),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.08)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.blackColor,
                  ),
                ),
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 11,
                    color: AppTheme.greyColor.withOpacity(0.7),
                    fontWeight: FontWeight.w500,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Text(
                    'Top Performing Students',
                    style: TextStyle(
                      fontSize: isSmallScreen ? 18 : 22,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.blackColor,
                      letterSpacing: -0.3,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(Icons.emoji_events_outlined, size: 20, color: Colors.amber.shade700),
                ],
              ),
              TextButton(
                onPressed: () => context.push('/admin/students'),
                child: const Text('View All Students'),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        _buildPerformersTable(isLargeScreen, isMediumScreen, isSmallScreen),
      ],
    );
  }

  Widget _buildPerformersTable(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.05)),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              color: AppTheme.greyColor.withOpacity(0.03),
              child: Row(
                children: [
                  Expanded(
                    flex: isSmallScreen ? 3 : 2,
                    child: Text(
                      'STUDENT',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.greyColor.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                  if (!isSmallScreen)
                    Expanded(
                      child: Text(
                        'ENROLLMENTS',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.greyColor.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  if (isLargeScreen)
                    Expanded(
                      child: Text(
                        'COMPLETED',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.greyColor.withOpacity(0.8),
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  Expanded(
                    child: Text(
                      'PROGRESS',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: AppTheme.greyColor.withOpacity(0.8),
                        letterSpacing: 1,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _analytics!.topPerformingStudents.length,
              separatorBuilder: (context, index) => Divider(
                height: 1,
                color: AppTheme.greyColor.withOpacity(0.05),
                indent: 24,
                endIndent: 24,
              ),
              itemBuilder: (context, index) {
                final student = _analytics!.topPerformingStudents[index];
                return InkWell(
                  onTap: () => context.push('/admin/students/${student.id}'),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                    child: Row(
                      children: [
                        _studentCell(student, isSmallScreen),
                        if (!isSmallScreen)
                          Expanded(
                            child: Text(
                              student.totalEnrollments.toString(),
                              textAlign: TextAlign.center,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        if (isLargeScreen)
                          Expanded(
                            child: Container(
                              alignment: Alignment.center,
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.green.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  student.completedCourses.toString(),
                                  style: const TextStyle(
                                    color: Colors.green,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 12,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        Expanded(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${student.averageProgress.toStringAsFixed(0)}%',
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: AppTheme.primaryGreen,
                                ),
                              ),
                              const SizedBox(height: 4),
                              SizedBox(
                                width: 60,
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(2),
                                  child: LinearProgressIndicator(
                                    value: student.averageProgress / 100,
                                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation<Color>(AppTheme.primaryGreen),
                                    minHeight: 3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _studentCell(dynamic student, bool isSmallScreen) {
    return Expanded(
      flex: isSmallScreen ? 3 : 2,
      child: Row(
        children: [
          Container(
            width: isSmallScreen ? 36 : 42,
            height: isSmallScreen ? 36 : 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [
                  AppTheme.primaryGreen.withOpacity(0.8),
                  AppTheme.primaryGreen,
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.primaryGreen.withOpacity(0.2),
                  blurRadius: 8,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Center(
              child: Text(
                student.name.substring(0, 1).toUpperCase(),
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: isSmallScreen ? 14 : 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: isSmallScreen ? 14 : 15,
                    color: AppTheme.blackColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  student.email,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppTheme.greyColor.withOpacity(0.7),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDataTimestamp() {
    final now = DateTime.now();
    final formattedTime = DateFormat('HH:mm:ss').format(now);
    final formattedDate = DateFormat('MMM dd, yyyy').format(now);
    
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
      decoration: BoxDecoration(
        color: AppTheme.primaryGreen.withOpacity(0.03),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.primaryGreen.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.history_rounded, size: 18, color: AppTheme.primaryGreen.withOpacity(0.6)),
          const SizedBox(width: 12),
          Text(
            'Analytics last synced: ',
            style: TextStyle(
              fontSize: 13, 
              color: AppTheme.greyColor.withOpacity(0.8),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            '$formattedDate at $formattedTime',
            style: const TextStyle(
              fontSize: 13, 
              color: AppTheme.primaryGreen,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 12),
          _buildPulseIndicator(),
        ],
      ),
    );
  }

  Widget _buildPulseIndicator() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.green,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.green,
            blurRadius: 4,
            spreadRadius: 1,
          ),
        ],
      ),
    );
  }
}