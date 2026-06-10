import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';

/// Admin Live Sessions Screen - Track all live sessions across different courses
class AdminLiveSessionsScreen extends ConsumerStatefulWidget {
  const AdminLiveSessionsScreen({super.key});

  @override
  ConsumerState<AdminLiveSessionsScreen> createState() => _AdminLiveSessionsScreenState();
}

class _AdminLiveSessionsScreenState extends ConsumerState<AdminLiveSessionsScreen>
    with SingleTickerProviderStateMixin {
  final LiveSessionService _liveSessionService = LiveSessionService();
  late TabController _tabController;

  List<LiveSession> _upcomingSessions = [];
  List<LiveSession> _liveSessions = [];
  List<LiveSession> _pastSessions = [];
  List<LiveSession> _allSessions = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _tabController.addListener(_onTabChanged);
    _loadSessions();
  }

  @override
  void dispose() {
    _tabController.removeListener(_onTabChanged);
    _tabController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      String status;
      switch (_tabController.index) {
        case 0:
          status = 'scheduled';
          break;
        case 1:
          status = 'live';
          break;
        case 2:
          status = 'ended';
          break;
        default:
          status = '';
      }
      _loadSessions(status: status.isEmpty ? null : status);
    }
  }

  Future<void> _loadSessions({String? status}) async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final response = await _liveSessionService.getTeacherSessions(
        status: status,
        page: _currentPage,
        limit: 50,
      );

      setState(() {
        if (status == 'scheduled') {
          _upcomingSessions = response.sessions;
        } else if (status == 'live') {
          _liveSessions = response.sessions;
        } else if (status == 'ended') {
          _pastSessions = response.sessions;
        } else {
          _allSessions = response.sessions;
        }
        _totalPages = response.totalPages;
        _currentPage = response.currentPage;
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      setState(() {
        _errorMessage = 'Error loading sessions: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _viewAttendance(LiveSession session) async {
    setState(() => _isLoading = true);
    try {
      final attendance = await _liveSessionService.getSessionAttendance(session.id);
      if (mounted) {
        _showAttendanceDialog(session, attendance);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading attendance: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showAttendanceDialog(LiveSession session, dynamic attendance) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: cardColor,
        title: Text('Attendance: ${session.title}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Summary
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppTheme.primaryGreen.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _AttendanceStat(
                      label: 'Enrolled',
                      value: attendance.totalEnrolled.toString(),
                      color: Colors.blue,
                    ),
                    _AttendanceStat(
                      label: 'Attended',
                      value: attendance.totalAttended.toString(),
                      color: Colors.green,
                    ),
                    _AttendanceStat(
                      label: 'Rate',
                      value: '${attendance.attendanceRate}%',
                      color: Colors.orange,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              // Attended Students
              Text(
                'Attended (${attendance.attendedStudents.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (attendance.attendedStudents.isEmpty)
                Text('No students attended', style: TextStyle(color: textSecondary))
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attendance.attendedStudents.length,
                    itemBuilder: (context, index) {
                      final student = attendance.attendedStudents[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          child: Text(
                            student['student']?['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
                          ),
                        ),
                        title: Text(
                          student['student']?['fullName'] ?? 'Unknown',
                          style: TextStyle(color: textPrimary, fontSize: 12),
                        ),
                        subtitle: Text(
                          'Joined: ${student['joinedAt'] != null ? DateFormat('h:mm a').format(DateTime.parse(student['joinedAt'])) : 'N/A'}',
                          style: TextStyle(color: textSecondary, fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 16),
              // Not Attended Students
              Text(
                'Did Not Attend (${attendance.notAttendedStudents.length})',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              if (attendance.notAttendedStudents.isEmpty)
                Text('All students attended', style: TextStyle(color: textSecondary))
              else
                SizedBox(
                  height: 100,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attendance.notAttendedStudents.length,
                    itemBuilder: (context, index) {
                      final student = attendance.notAttendedStudents[index];
                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: Colors.grey[300],
                          child: Text(
                            student['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
                          ),
                        ),
                        title: Text(
                          student['fullName'] ?? 'Unknown',
                          style: TextStyle(color: textPrimary, fontSize: 12),
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    return Scaffold(
      backgroundColor: AppTheme.getBackgroundColor(context),
      appBar: AppBar(
        title: const Text('Live Sessions'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Live'),
            Tab(text: 'Past'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              String status;
              switch (_tabController.index) {
                case 0:
                  status = 'scheduled';
                  break;
                case 1:
                  status = 'live';
                  break;
                case 2:
                  status = 'ended';
                  break;
                default:
                  status = '';
              }
              _loadSessions(status: status.isEmpty ? null : status);
              if (mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Sessions refreshed')),
                );
              }
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? _buildErrorWidget()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildSessionsList(_upcomingSessions, 'upcoming'),
                    _buildSessionsList(_liveSessions, 'live'),
                    _buildSessionsList(_pastSessions, 'past'),
                    _buildSessionsList(_allSessions, 'all'),
                  ],
                ),
    );
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          Text(_errorMessage!, style: const TextStyle(color: Colors.red)),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () => _loadSessions(),
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildSessionsList(List<LiveSession> sessions, String type) {
    if (sessions.isEmpty) {
      return _buildEmptyState(type);
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardColor = AppTheme.getCardColor(context);
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: sessions.length,
      itemBuilder: (context, index) {
        final session = sessions[index];
        return _SessionCard(
          session: session,
          type: type,
          onViewAttendance: () => _viewAttendance(session),
          isDark: isDark,
          cardColor: cardColor,
          textPrimary: textPrimary,
          textSecondary: textSecondary,
        );
      },
    );
  }

  Widget _buildEmptyState(String type) {
    String message;
    IconData icon;

    switch (type) {
      case 'upcoming':
        message = 'No upcoming sessions scheduled';
        icon = Icons.schedule;
        break;
      case 'live':
        message = 'No live sessions currently';
        icon = Icons.videocam;
        break;
      case 'past':
        message = 'No past sessions yet';
        icon = Icons.history;
        break;
      default:
        message = 'No sessions found';
        icon = Icons.video_call;
    }

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: textSecondary.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: textSecondary),
          ),
        ],
      ),
    );
  }
}

/// Session Card Widget for Admin
class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final String type;
  final VoidCallback onViewAttendance;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _SessionCard({
    required this.session,
    required this.type,
    required this.onViewAttendance,
    required this.isDark,
    required this.cardColor,
    required this.textPrimary,
    required this.textSecondary,
  });

  @override
  Widget build(BuildContext context) {
    final isScheduled = session.status == 'scheduled';
    final isLive = session.status == 'live';
    final isEnded = session.status == 'ended';
    final isCancelled = session.status == 'cancelled';

    Color statusColor;
    switch (session.status) {
      case 'scheduled':
        statusColor = Colors.orange;
        break;
      case 'live':
        statusColor = Colors.green;
        break;
      case 'ended':
        statusColor = Colors.blue;
        break;
      case 'cancelled':
        statusColor = Colors.red;
        break;
      default:
        statusColor = Colors.grey;
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: cardColor,
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                isScheduled ? Icons.schedule : (isLive ? Icons.videocam : Icons.videocam_off),
                color: statusColor,
                size: 32,
              ),
            ),
            title: Text(
              session.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: textPrimary,
              ),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                if (session.course != null)
                  Text(
                    session.course!['title'] ?? '',
                    style: TextStyle(
                      color: textSecondary,
                      fontSize: 13,
                    ),
                  ),
                if (session.teacher != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.person, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        session.teacher!['fullName'] ?? session.teacher!['name'] ?? 'Unknown',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(isDark ? 0.2 : 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        session.status.toUpperCase(),
                        style: TextStyle(
                          color: statusColor,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.schedule, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(session.scheduledAt),
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.timer, size: 14, color: textSecondary),
                    const SizedBox(width: 4),
                    Text(
                      '${session.duration} min',
                      style: TextStyle(color: textSecondary, fontSize: 12),
                    ),
                  ],
                ),
                if (session.expectedEndTime != null) ...[
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.event_available, size: 14, color: textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        'Ends: ${DateFormat('h:mm a').format(session.expectedEndTime!)}',
                        style: TextStyle(color: textSecondary, fontSize: 12),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            trailing: session.status == 'ended'
                ? IconButton(
                    icon: const Icon(Icons.people_outline, color: AppTheme.primaryGreen),
                    onPressed: onViewAttendance,
                    tooltip: 'View Attendance',
                  )
                : null,
          ),
        ],
      ),
    );
  }
}

class _AttendanceStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _AttendanceStat({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
