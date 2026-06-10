import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';

/// Live Sessions Screen - View and manage all live sessions
class LiveSessionsScreen extends ConsumerStatefulWidget {
  const LiveSessionsScreen({super.key});

  @override
  ConsumerState<LiveSessionsScreen> createState() => _LiveSessionsScreenState();
}

class _LiveSessionsScreenState extends ConsumerState<LiveSessionsScreen>
    with SingleTickerProviderStateMixin {
  final LiveSessionService _liveSessionService = LiveSessionService();
  late TabController _tabController;

  List<LiveSession> _upcomingSessions = [];
  List<LiveSession> _pastSessions = [];
  List<LiveSession> _allSessions = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  
  int _currentPage = 1;
  int _totalPages = 1;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
        limit: 20,
      );

      List<LiveSession> filteredSessions = response.sessions;

      // Filter and sort upcoming sessions
      if (status == 'scheduled') {
        final now = DateTime.now();
        filteredSessions = response.sessions.where((session) {
          return session.status == 'scheduled' && session.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5))) ||
                 session.status == 'live';
        }).toList();
        // Sort by scheduled date (soonest first)
        filteredSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
      }

      setState(() {
        if (status == 'scheduled') {
          _upcomingSessions = filteredSessions;
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

  Future<void> _joinSession(LiveSession session) async {
    try {
      final response = await _liveSessionService.joinSession(session.id);
      
      if (mounted) {
        // Show join dialog
        _showJoinDialog(response.joinUrl, session);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error joining session: $e')),
        );
      }
    }
  }

  void _showJoinDialog(String joinUrl, LiveSession session) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textSecondary = isDark ? AppTheme.darkTextSecondary : Colors.grey[600]!;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: Text('Join ${session.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are about to join the BigBlueButton meeting.'),
            const SizedBox(height: 8),
            Text(
              'This will open in a new window.',
              style: TextStyle(color: textSecondary, fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () async {
              Navigator.pop(context);
              // Launch BBB meeting URL in external browser
              final uri = Uri.parse(joinUrl);
              if (await canLaunchUrl(uri)) {
                await launchUrl(
                  uri,
                  mode: LaunchMode.externalApplication,
                );
              } else {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Could not launch meeting URL')),
                  );
                }
              }
            },
            icon: const Icon(Icons.video_call, color: Colors.white),
            label: const Text('Join Meeting', style: TextStyle(color: Colors.white)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primaryGreen,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(LiveSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: const Text('End Session'),
        content: Text('Are you sure you want to end "${session.title}"?\n\nThis will close the meeting for all participants.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('End Session'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _liveSessionService.endSession(session.id);
        _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session ended successfully')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error ending session: $e')),
          );
        }
      }
    }
  }

  Future<void> _cancelSession(LiveSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: const Text('Cancel Session'),
        content: Text('Are you sure you want to cancel "${session.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Cancel Session'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _liveSessionService.cancelSession(session.id);
        _loadSessions();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session cancelled')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
    }
  }

  Future<void> _deleteSession(LiveSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: const Text('Delete Session'),
        content: Text('Are you sure you want to permanently delete "${session.title}"?\n\nThis action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Keep'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _liveSessionService.deleteSession(session.id);
        // Reload based on current tab
        String status;
        switch (_tabController.index) {
          case 0:
            status = 'scheduled';
            break;
          case 1:
            status = 'ended';
            break;
          default:
            status = '';
        }
        _loadSessions(status: status.isEmpty ? null : status);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Session deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error: $e')),
          );
        }
      }
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

  Future<void> _viewRecording(LiveSession session) async {
    try {
      final recording = await _liveSessionService.getSessionRecording(session.id);
      
      if (recording.hasRecording) {
        // Show recording dialog
        _showRecordingDialog(recording);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Recording not available yet. Please check back later.')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading recording: $e')),
        );
      }
    }
  }

  void _showRecordingDialog(RecordingResponse recording) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? AppTheme.darkTextPrimary : Colors.black87;

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.getCardColor(context),
        title: Text(recording.sessionTitle ?? 'Session Recording'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle, size: 64, color: AppTheme.primaryGreen),
            const SizedBox(height: 16),
            Text('Duration: ${recording.duration} minutes', style: TextStyle(color: textPrimary)),
            const SizedBox(height: 8),
            Text('Format: ${recording.format ?? 'Video'}', style: TextStyle(color: textPrimary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Launch recording URL
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening recording...')),
              );
            },
            icon: const Icon(Icons.play_arrow),
            label: const Text('Play Recording'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  void _scheduleNewSession() {
    context.push('/teacher/sessions/create');
  }

  Future<void> _handleLogout() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Logout'),
          ),
        ],
      ),
    );

    if (confirmed == true && mounted) {
      await ref.read(authProvider.notifier).logout();
      if (mounted) {
        context.go('/auth-selection');
      }
    }
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
            Tab(text: 'Past'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              // Get current tab status
              String status;
              switch (_tabController.index) {
                case 0:
                  status = 'scheduled';
                  break;
                case 1:
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
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _handleLogout,
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
                    _buildSessionsList(_pastSessions, 'past'),
                    _buildSessionsList(_allSessions, 'all'),
                  ],
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _scheduleNewSession,
        icon: const Icon(Icons.add),
        label: const Text('New Session'),
        backgroundColor: AppTheme.primaryGreen,
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
          onJoin: () => _joinSession(session),
          onEnd: () => _endSession(session),
          onCancel: () => _cancelSession(session),
          onDelete: () => _deleteSession(session),
          onViewRecording: () => _viewRecording(session),
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
          const SizedBox(height: 16),
          if (type == 'upcoming')
            ElevatedButton.icon(
              onPressed: _scheduleNewSession,
              icon: const Icon(Icons.add),
              label: const Text('Schedule Session'),
              style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
            ),
        ],
      ),
    );
  }
}

/// Session Card Widget
class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final String type;
  final VoidCallback onJoin;
  final VoidCallback onEnd;
  final VoidCallback onCancel;
  final VoidCallback onDelete;
  final VoidCallback onViewRecording;
  final VoidCallback onViewAttendance;
  final bool isDark;
  final Color cardColor;
  final Color textPrimary;
  final Color textSecondary;

  const _SessionCard({
    required this.session,
    required this.type,
    required this.onJoin,
    required this.onEnd,
    required this.onCancel,
    required this.onDelete,
    required this.onViewRecording,
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
    final canJoin = isScheduled || isLive;
    final hasRecording = session.hasRecording;

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
                  ],
                ),
              ],
            ),
            trailing: canJoin
                ? ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.video_call, color: Colors.white),
                    label: isLive
                        ? const Text('Join', style: TextStyle(color: Colors.white))
                        : const Text('Start', style: TextStyle(color: Colors.white)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.green : AppTheme.primaryGreen,
                      foregroundColor: Colors.white,
                    ),
                  )
                : hasRecording
                    ? IconButton(
                        icon: const Icon(Icons.play_circle, color: Colors.blue),
                        onPressed: onViewRecording,
                      )
                    : null,
          ),
          if (isScheduled || isLive || hasRecording)
            Divider(height: 1, color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.2) : Colors.grey[300]),
          if (isScheduled || isLive || hasRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  if (session.status == 'ended')
                    TextButton.icon(
                      onPressed: onViewAttendance,
                      icon: const Icon(Icons.people_outline, size: 18),
                      label: const Text('Attendance'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                    ),
                  if (hasRecording)
                    TextButton.icon(
                      onPressed: onViewRecording,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Recording'),
                    ),
                  if (isScheduled) ...[
                    TextButton(
                      onPressed: onCancel,
                      style: TextButton.styleFrom(foregroundColor: Colors.red),
                      child: const Text('Cancel'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: onJoin,
                      icon: const Icon(Icons.video_call, size: 18, color: Colors.white),
                      label: const Text('Start Early', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                  if (isLive)
                    ElevatedButton.icon(
                      onPressed: onEnd,
                      icon: const Icon(Icons.stop, size: 18, color: Colors.white),
                      label: const Text('End Session', style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  // Delete button for all sessions
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Delete Session',
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
