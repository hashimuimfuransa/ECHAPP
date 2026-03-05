import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/admin_service.dart';
import 'package:excellencecoachinghub/widgets/analytics_charts.dart';

class CourseAnalyticsScreen extends ConsumerStatefulWidget {
  final String courseId;
  const CourseAnalyticsScreen({super.key, required this.courseId});

  @override
  ConsumerState<CourseAnalyticsScreen> createState() => _CourseAnalyticsScreenState();
}

class _CourseAnalyticsScreenState extends ConsumerState<CourseAnalyticsScreen> {
  final AdminService _adminService = AdminService();
  bool _isLoading = false;
  CourseAnalytics? _analytics;
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
      final analytics = await _adminService.getCourseAnalytics(widget.courseId);
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

  Future<void> _unenrollStudent(CourseStudentPerformance student) async {
    final bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Confirm Unenrollment'),
        content: Text('Are you sure you want to unenroll ${student.name} from this course? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red, foregroundColor: Colors.white),
            child: const Text('Unenroll'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => _isLoading = true);

    try {
      await _adminService.unenrollStudent(widget.courseId, student.id);
      if (!mounted) return;
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Successfully unenrolled ${student.name}'),
          backgroundColor: Colors.green,
        ),
      );
      
      // Refresh analytics to update the list
      _loadAnalytics();
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error unenrolling student: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_analytics?.course['title'] ?? 'Course Analytics'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadAnalytics,
            tooltip: 'Refresh',
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
              _buildReviewsSection(isLargeScreen, isMediumScreen, isSmallScreen),
              const SizedBox(height: 40),
              _buildStudentList(isLargeScreen, isMediumScreen, isSmallScreen),
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
          if (_analytics?.course['thumbnail'] != null)
            Container(
              width: 60,
              height: 60,
              margin: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                image: DecorationImage(
                  image: NetworkImage(_analytics!.course['thumbnail']),
                  fit: BoxFit.cover,
                ),
              ),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _analytics?.course['title'] ?? 'Course Analytics',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 20 : 28,
                    fontWeight: FontWeight.w800,
                    color: AppTheme.blackColor,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Detailed performance tracking for this course',
                  style: TextStyle(
                    fontSize: isSmallScreen ? 13 : 15,
                    color: AppTheme.greyColor.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOverviewMetrics(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    final stats = _analytics!.stats;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Vitals',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 16),
        if (isLargeScreen)
          Row(
            children: [
              Expanded(child: _metricCard('Total Enrolled', stats.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Active Students', stats.activeStudents.toString(), Icons.bolt_rounded, Colors.orange)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Avg. Progress', '${stats.averageProgress.toStringAsFixed(1)}%', Icons.auto_graph_rounded, Colors.indigo)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Avg. Rating', stats.averageRating.toStringAsFixed(1), Icons.star_rounded, Colors.amber)),
              const SizedBox(width: 16),
              Expanded(child: _metricCard('Total Ratings', stats.totalRatings.toString(), Icons.rate_review_rounded, Colors.teal)),
            ],
          )
        else if (isMediumScreen)
          Column(
            children: [
              Row(
                children: [
                  Expanded(child: _metricCard('Total Enrolled', stats.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen)),
                  const SizedBox(width: 16),
                  Expanded(child: _metricCard('Active Students', stats.activeStudents.toString(), Icons.bolt_rounded, Colors.orange)),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(child: _metricCard('Avg. Progress', '${stats.averageProgress.toStringAsFixed(1)}%', Icons.auto_graph_rounded, Colors.indigo)),
                  const SizedBox(width: 16),
                  Expanded(child: _metricCard('Avg. Rating', stats.averageRating.toStringAsFixed(1), Icons.star_rounded, Colors.amber)),
                ],
              ),
            ],
          )
        else
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.1,
            children: [
              _metricCard('Total Enrolled', stats.totalStudents.toString(), Icons.people_alt_rounded, AppTheme.primaryGreen),
              _metricCard('Avg. Progress', '${stats.averageProgress.toStringAsFixed(0)}%', Icons.auto_graph_rounded, Colors.indigo),
              _metricCard('Avg. Rating', stats.averageRating.toStringAsFixed(1), Icons.star_rounded, Colors.amber),
              _metricCard('Total Ratings', stats.totalRatings.toString(), Icons.rate_review_rounded, Colors.teal),
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
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
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
    final stats = _analytics!.stats;
    
    final statusData = [
      PieChartData('Completed', stats.completedCount.toDouble(), Colors.green),
      PieChartData('In Progress', (stats.totalStudents - stats.completedCount).toDouble(), Colors.orange),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Completion Status',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 350,
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
          child: PieChartWidget(
            data: statusData,
            title: 'Completion Rate: ${stats.completionRate.toStringAsFixed(1)}%',
          ),
        ),
      ],
    );
  }

  Widget _buildReviewsSection(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    if (_analytics!.reviews.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Course Reviews',
          style: TextStyle(
            fontSize: isSmallScreen ? 18 : 22,
            fontWeight: FontWeight.bold,
            color: AppTheme.blackColor,
          ),
        ),
        const SizedBox(height: 16),
        Container(
          height: 300,
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
            child: ListView.separated(
              padding: const EdgeInsets.all(20),
              itemCount: _analytics!.reviews.length,
              separatorBuilder: (context, index) => Divider(height: 32, color: AppTheme.greyColor.withOpacity(0.1)),
              itemBuilder: (context, index) {
                final review = _analytics!.reviews[index];
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            CircleAvatar(
                              radius: 16,
                              backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                              child: Text(review.userName[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryGreen, fontSize: 12, fontWeight: FontWeight.bold)),
                            ),
                            const SizedBox(width: 12),
                            Text(review.userName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          ],
                        ),
                        Row(
                          children: [
                            if (review.rating != null) ...[
                              Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                              const SizedBox(width: 4),
                              Text(review.rating!.toStringAsFixed(1), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                            ],
                            const SizedBox(width: 12),
                            Text(DateFormat('MMM dd, yyyy').format(review.date), style: TextStyle(fontSize: 12, color: AppTheme.greyColor)),
                          ],
                        ),
                      ],
                    ),
                    if (review.feedback != null && review.feedback!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppTheme.greyColor.withOpacity(0.03),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          review.feedback!,
                          style: TextStyle(fontSize: 14, color: AppTheme.blackColor.withOpacity(0.8), height: 1.4),
                        ),
                      ),
                    ],
                  ],
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStudentList(bool isLargeScreen, bool isMediumScreen, bool isSmallScreen) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Enrolled Students',
              style: TextStyle(
                fontSize: isSmallScreen ? 18 : 22,
                fontWeight: FontWeight.bold,
                color: AppTheme.blackColor,
              ),
            ),
            Text(
              '${_analytics!.students.length} Total',
              style: const TextStyle(color: AppTheme.greyColor),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Container(
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
                      Expanded(flex: 3, child: _headerText('STUDENT')),
                      Expanded(child: _headerText('PROGRESS', textAlign: TextAlign.center)),
                      if (!isSmallScreen)
                        Expanded(child: _headerText('RATING', textAlign: TextAlign.center)),
                      if (!isSmallScreen)
                        Expanded(child: _headerText('STATUS', textAlign: TextAlign.center)),
                      if (isLargeScreen)
                        Expanded(child: _headerText('ENROLLED', textAlign: TextAlign.center)),
                      Expanded(child: _headerText('ACTIONS', textAlign: TextAlign.center)),
                    ],
                  ),
                ),
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _analytics!.students.length,
                  separatorBuilder: (context, index) => Divider(height: 1, color: AppTheme.greyColor.withOpacity(0.05)),
                  itemBuilder: (context, index) {
                    final student = _analytics!.students[index];
                    return InkWell(
                      onTap: () => context.push('/admin/students/${student.id}'),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Row(
                                children: [
                                  CircleAvatar(
                                    radius: 18,
                                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                                    child: Text(student.name[0].toUpperCase(), style: const TextStyle(color: AppTheme.primaryGreen, fontWeight: FontWeight.bold)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(student.name, style: const TextStyle(fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis),
                                        Text(student.email, style: const TextStyle(fontSize: 12, color: AppTheme.greyColor), overflow: TextOverflow.ellipsis),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              child: Column(
                                children: [
                                  Text('${student.progress.toStringAsFixed(0)}%', style: const TextStyle(fontWeight: FontWeight.bold, color: AppTheme.primaryGreen)),
                                  const SizedBox(height: 4),
                                  LinearProgressIndicator(
                                    value: student.progress / 100,
                                    backgroundColor: AppTheme.primaryGreen.withOpacity(0.1),
                                    valueColor: const AlwaysStoppedAnimation(AppTheme.primaryGreen),
                                    minHeight: 2,
                                  ),
                                ],
                              ),
                            ),
                            if (!isSmallScreen)
                              Expanded(
                                child: Center(
                                  child: student.rating != null
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                            const SizedBox(width: 4),
                                            Text(
                                              student.rating!.toStringAsFixed(1),
                                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                            ),
                                          ],
                                        )
                                      : const Text('-', style: TextStyle(color: AppTheme.greyColor)),
                                ),
                              ),
                            if (!isSmallScreen)
                              Expanded(
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                    decoration: BoxDecoration(
                                      color: (student.completionStatus == 'completed' ? Colors.green : Colors.orange).withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Text(
                                      student.completionStatus.capitalize(),
                                      style: TextStyle(
                                        color: student.completionStatus == 'completed' ? Colors.green : Colors.orange,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            if (isLargeScreen)
                              Expanded(
                                child: Text(
                                  DateFormat('MMM dd, yyyy').format(student.enrollmentDate),
                                  textAlign: TextAlign.center,
                                  style: const TextStyle(fontSize: 13, color: AppTheme.greyColor),
                                ),
                              ),
                            Expanded(
                              child: Center(
                                child: IconButton(
                                  icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                                  onPressed: () => _unenrollStudent(student),
                                  tooltip: 'Unenroll Student',
                                ),
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
        ),
      ],
    );
  }

  Widget _headerText(String text, {TextAlign? textAlign}) {
    return Text(
      text,
      textAlign: textAlign,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.bold,
        color: AppTheme.greyColor.withOpacity(0.8),
        letterSpacing: 1,
      ),
    );
  }

  Widget _buildDataTimestamp() {
    final now = DateTime.now();
    return Center(
      child: Text(
        'Data refreshed: ${DateFormat('HH:mm:ss').format(now)}',
        style: const TextStyle(fontSize: 12, color: AppTheme.greyColor),
      ),
    );
  }
}

extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1)}';
  }
}
