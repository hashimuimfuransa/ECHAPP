import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/widgets/analytics_charts.dart';

class AdminAnalyticsScreen extends StatefulWidget {
  const AdminAnalyticsScreen({super.key});

  @override
  State<AdminAnalyticsScreen> createState() => _AdminAnalyticsScreenState();
}

class _AdminAnalyticsScreenState extends State<AdminAnalyticsScreen> {
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
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final analytics = await _adminService.getStudentAnalytics();
      setState(() {
        _analytics = analytics;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Analytics Dashboard'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
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
    
    return _buildResponsiveContent();
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
          padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(isSmallScreen),
              const SizedBox(height: 30),
              _buildOverviewMetrics(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 30),
              _buildChartsSection(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 30),
              _buildActivityStats(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 30),
              _buildTopPerformers(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 30),
              _buildDataTimestamp(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHeader(bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Analytics Dashboard',
          style: TextStyle(
            fontSize: isSmallScreen ? 24 : 32,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Real-time insights into your platform performance',
          style: TextStyle(
            fontSize: isSmallScreen ? 14 : 16,
            color: AppTheme.greyColor,
          ),
        ),
      ],
    );
  }

  Widget _buildOverviewMetrics(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Key Metrics',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
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
    return Row(
      children: [
        _metricCard('Total Students', _analytics!.totalStudents.toString(), Icons.people, AppTheme.primaryGreen),
        const SizedBox(width: 20),
        _metricCard('Active Students', _analytics!.activeStudents.toString(), Icons.check_circle, Colors.green),
        const SizedBox(width: 20),
        _metricCard('New This Month', _analytics!.newStudentsThisMonth.toString(), Icons.trending_up, AppTheme.accent),
        const SizedBox(width: 20),
        _metricCard('Avg. Enrollments', _analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1), Icons.school, Colors.purple),
      ],
    );
  }

  Widget _buildMediumMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Total Students', _analytics!.totalStudents.toString(), Icons.people, AppTheme.primaryGreen)),
            const SizedBox(width: 15),
            Expanded(child: _metricCard('Active Students', _analytics!.activeStudents.toString(), Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _metricCard('New This Month', _analytics!.newStudentsThisMonth.toString(), Icons.trending_up, AppTheme.accent)),
            const SizedBox(width: 15),
            Expanded(child: _metricCard('Avg. Enrollments', _analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1), Icons.school, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallMetricsGrid() {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _metricCard('Total', _analytics!.totalStudents.toString(), Icons.people, AppTheme.primaryGreen)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Active', _analytics!.activeStudents.toString(), Icons.check_circle, Colors.green)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _metricCard('New', _analytics!.newStudentsThisMonth.toString(), Icons.trending_up, AppTheme.accent)),
            const SizedBox(width: 10),
            Expanded(child: _metricCard('Avg', _analytics!.averageEnrollmentsPerStudent.toStringAsFixed(1), Icons.school, Colors.purple)),
          ],
        ),
      ],
    );
  }

  Widget _metricCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 12,
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
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
        Text(
          'Student Distribution',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
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
          child: SizedBox(
            height: 350,
            child: BarChartWidget(
              data: barData,
              title: 'Student Status Distribution',
              barColor: AppTheme.primaryGreen,
            ),
          ),
        ),
        const SizedBox(width: 25),
        Expanded(
          child: SizedBox(
            height: 350,
            child: PieChartWidget(
              data: pieData,
              title: 'Student Population',
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildResponsiveCharts(List<ChartData> barData, List<PieChartData> pieData, bool isSmallScreen) {
    return Column(
      children: [
        SizedBox(
          height: isSmallScreen ? 280 : 320,
          child: BarChartWidget(
            data: barData,
            title: 'Student Status',
            barColor: AppTheme.primaryGreen,
          ),
        ),
        const SizedBox(height: 25),
        SizedBox(
          height: isSmallScreen ? 300 : 350,
          child: PieChartWidget(
            data: pieData,
            title: 'Population Breakdown',
          ),
        ),
      ],
    );
  }

  Widget _buildActivityStats(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    final stats = _analytics!.studentActivityStats;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Activity Insights',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
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
    return Row(
      children: [
        _statCard('Daily Active', stats.dailyActiveStudents.toString(), Icons.today, Colors.blue),
        const SizedBox(width: 20),
        _statCard('Weekly Active', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week, Colors.purple),
        const SizedBox(width: 20),
        _statCard('Monthly Active', stats.monthlyActiveStudents.toString(), Icons.calendar_month, Colors.indigo),
        const SizedBox(width: 20),
        _statCard('Avg Session (min)', stats.avgSessionDuration.toStringAsFixed(0), Icons.timer, Colors.teal),
      ],
    );
  }

  Widget _buildMediumActivityGrid(dynamic stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Daily Active', stats.dailyActiveStudents.toString(), Icons.today, Colors.blue)),
            const SizedBox(width: 15),
            Expanded(child: _statCard('Weekly Active', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week, Colors.purple)),
          ],
        ),
        const SizedBox(height: 15),
        Row(
          children: [
            Expanded(child: _statCard('Monthly Active', stats.monthlyActiveStudents.toString(), Icons.calendar_month, Colors.indigo)),
            const SizedBox(width: 15),
            Expanded(child: _statCard('Avg Session', stats.avgSessionDuration.toStringAsFixed(0), Icons.timer, Colors.teal)),
          ],
        ),
      ],
    );
  }

  Widget _buildSmallActivityGrid(dynamic stats) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: _statCard('Daily', stats.dailyActiveStudents.toString(), Icons.today, Colors.blue)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Weekly', stats.weeklyActiveStudents.toString(), Icons.calendar_view_week, Colors.purple)),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _statCard('Monthly', stats.monthlyActiveStudents.toString(), Icons.calendar_month, Colors.indigo)),
            const SizedBox(width: 10),
            Expanded(child: _statCard('Session', stats.avgSessionDuration.toStringAsFixed(0), Icons.timer, Colors.teal)),
          ],
        ),
      ],
    );
  }

  Widget _statCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(
              fontSize: 11,
              color: AppTheme.greyColor,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildTopPerformers(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Top Performing Students',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 24,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 20),
        _buildPerformersTable(isLargeScreen, isMediumScreen, isSmallScreen),
      ],
    );
  }

  Widget _buildPerformersTable(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            spreadRadius: 1,
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: const BoxDecoration(
              color: AppTheme.primaryGreen,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: isLargeScreen
                ? const Row(
                    children: [
                      Expanded(flex: 2, child: Text('Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                      Expanded(child: Text('Enrollments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text('Completed', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                      Expanded(child: Text('Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                    ],
                  )
                : isMediumScreen
                    ? const Row(
                        children: [
                          Expanded(flex: 2, child: Text('Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Enrollments', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                          Expanded(child: Text('Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      )
                    : const Row(
                        children: [
                          Expanded(flex: 3, child: Text('Student', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold))),
                          Expanded(child: Text('Progress', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                        ],
                      ),
          ),
          ..._analytics!.topPerformingStudents.asMap().entries.map((entry) {
            final student = entry.value;
            return Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(color: AppTheme.greyColor.withOpacity(0.1)),
                ),
              ),
              child: isLargeScreen
                  ? Row(
                      children: [
                        _studentCell(student, isSmallScreen),
                        Expanded(
                          child: Text(student.totalEnrollments.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
                        ),
                        Expanded(
                          child: Text(student.completedCourses.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                        ),
                        Expanded(
                          child: Text('${student.averageProgress.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.accent)),
                        ),
                      ],
                    )
                  : isMediumScreen
                      ? Row(
                          children: [
                            _studentCell(student, isSmallScreen),
                            Expanded(
                              child: Text(student.totalEnrollments.toString(), textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500)),
                            ),
                            Expanded(
                              child: Text('${student.averageProgress.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.accent)),
                            ),
                          ],
                        )
                      : Row(
                          children: [
                            _studentCell(student, isSmallScreen),
                            Expanded(
                              child: Text('${student.averageProgress.toStringAsFixed(1)}%', textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.w500, color: AppTheme.accent)),
                            ),
                          ],
                        ),
            );
          }),
        ],
      ),
    );
  }

  Widget _studentCell(dynamic student, bool isSmallScreen) {
    return Expanded(
      flex: isSmallScreen ? 3 : 2,
      child: Row(
        children: [
          CircleAvatar(
            radius: isSmallScreen ? 16 : 18,
            backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
            child: Text(
              student.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
                color: AppTheme.primaryGreen,
                fontWeight: FontWeight.bold,
                fontSize: isSmallScreen ? 14 : 16,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  student.name,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: isSmallScreen ? 13 : 14,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  student.email,
                  style: TextStyle(
                    fontSize: isSmallScreen ? 11 : 12,
                    color: AppTheme.greyColor,
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
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.greyColor.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.greyColor.withOpacity(0.1)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.access_time, size: 16, color: AppTheme.greyColor),
          const SizedBox(width: 8),
          Text(
            'Data refreshed: ${now.hour}:${now.minute.toString().padLeft(2, '0')}:${now.second.toString().padLeft(2, '0')}',
            style: const TextStyle(fontSize: 12, color: AppTheme.greyColor),
          ),
          const SizedBox(width: 8),
          const Icon(Icons.sync, size: 14, color: AppTheme.primaryGreen),
        ],
      ),
    );
  }
}