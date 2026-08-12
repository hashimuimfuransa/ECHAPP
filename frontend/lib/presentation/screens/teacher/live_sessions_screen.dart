import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/screens/community/session_recording_screen.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';
import 'package:excellencecoachinghub/presentation/providers/auth_provider.dart';
import 'package:excellencecoachinghub/presentation/screens/teacher/schedule_live_session_screen.dart';

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
  final TextEditingController _searchController = TextEditingController();

  List<LiveSession> _upcomingSessions = [];
  List<LiveSession> _readyToStartSessions = [];
  List<LiveSession> _pastSessions = [];
  List<LiveSession> _allSessions = [];
  List<LiveSession> _filteredSessions = [];
  
  bool _isLoading = true;
  String? _errorMessage;
  String _searchQuery = '';
  
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
    _searchController.dispose();
    super.dispose();
  }

  void _onTabChanged() {
    if (!_tabController.indexIsChanging) {
      _filterSessionsForCurrentTab();
    }
  }

  void _onSearchChanged(String query) {
    setState(() {
      _searchQuery = query.toLowerCase();
    });
    _filterSessionsForCurrentTab();
  }

  Future<void> _loadSessions() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      // Fetch all sessions without status filter
      final response = await _liveSessionService.getTeacherSessions(
        limit: 100,
      );

      setState(() {
        _allSessions = response.sessions;
        _totalPages = response.totalPages;
        _currentPage = response.currentPage;
        _isLoading = false;
      });

      // Filter for current tab
      _filterSessionsForCurrentTab();
    } catch (e) {
      debugPrint('Error loading sessions: $e');
      setState(() {
        _errorMessage = 'Error loading sessions: $e';
        _isLoading = false;
      });
    }
  }

  void _filterSessionsForCurrentTab() {
    if (_allSessions.isEmpty) return;

    final now = DateTime.now();
    List<LiveSession> baseSessions;

    switch (_tabController.index) {
      case 0: // Upcoming
        baseSessions = _allSessions.where((session) {
          return session.status == 'scheduled' && session.scheduledAt.isAfter(now.subtract(const Duration(minutes: 5))) ||
                 session.status == 'live';
        }).toList();
        baseSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _upcomingSessions = baseSessions;
        break;
      case 1: // Ready to Start
        baseSessions = _allSessions.where((session) {
          return (session.status == 'scheduled' && 
                  session.scheduledAt.isBefore(now.add(const Duration(minutes: 5))) &&
                  !session.isEnded) ||
                 session.status == 'live';
        }).toList();
        baseSessions.sort((a, b) => a.scheduledAt.compareTo(b.scheduledAt));
        _readyToStartSessions = baseSessions;
        break;
      case 2: // Past
        baseSessions = _allSessions.where((session) {
          return session.status == 'ended' || session.status == 'cancelled';
        }).toList();
        baseSessions.sort((a, b) => b.scheduledAt.compareTo(a.scheduledAt)); // Most recent first
        _pastSessions = baseSessions;
        break;
      case 3: // All
        baseSessions = _allSessions;
        break;
      default:
        baseSessions = [];
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      _filteredSessions = baseSessions.where((session) {
        return session.title.toLowerCase().contains(_searchQuery) ||
               (session.course != null && session.course!['title']?.toLowerCase().contains(_searchQuery) == true) ||
               (session.section != null && session.section!['title']?.toLowerCase().contains(_searchQuery) == true) ||
               session.status.toLowerCase().contains(_searchQuery);
      }).toList();
    } else {
      _filteredSessions = baseSessions;
    }

    setState(() {});
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
        await _loadSessions();
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

  Future<void> _editSession(LiveSession session) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ScheduleLiveSessionScreen(
          courseId: session.courseId,
          sectionId: session.sectionId,
          lessonId: session.lessonId,
          editingSession: session,
        ),
      ),
    );

    if (result == true && mounted) {
      await _loadSessions();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Session updated successfully')),
        );
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
        await _loadSessions();
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
        await _loadSessions();
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
    final sessionDuration = session.duration; // in minutes

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
              const SizedBox(height: 8),
              Text(
                'Session Duration: ${session.formattedDuration}',
                style: TextStyle(color: textSecondary, fontSize: 11),
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
                  height: 150,
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: attendance.attendedStudents.length,
                    itemBuilder: (context, index) {
                      final student = attendance.attendedStudents[index];
                      final joinedAt = student['joinedAt'] != null
                          ? DateFormat('h:mm a').format(DateTime.parse(student['joinedAt']))
                          : 'N/A';
                      final duration = student['duration'] ?? 0;
                      final durationText = duration > 0
                          ? '${duration} min'
                          : 'N/A';

                      // Calculate attendance performance percentage
                      final performancePercent = sessionDuration > 0
                          ? ((duration / sessionDuration) * 100).round()
                          : 0;
                      final performanceColor = performancePercent >= 80
                          ? Colors.green
                          : performancePercent >= 50
                              ? Colors.orange
                              : Colors.red;

                      return ListTile(
                        dense: true,
                        leading: CircleAvatar(
                          backgroundColor: Colors.green[100],
                          child: Text(
                            student['student']?['fullName']?.substring(0, 1).toUpperCase() ?? 'S',
                            style: TextStyle(color: Colors.green[800]),
                          ),
                        ),
                        title: Row(
                          children: [
                            Expanded(
                              child: Text(
                                student['student']?['fullName'] ?? 'Unknown',
                                style: TextStyle(color: textPrimary, fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: performanceColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: performanceColor.withOpacity(0.3)),
                              ),
                              child: Text(
                                '$performancePercent%',
                                style: TextStyle(
                                  color: performanceColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                        subtitle: Row(
                          children: [
                            Icon(Icons.access_time, size: 12, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Joined: $joinedAt',
                              style: TextStyle(color: textSecondary, fontSize: 10),
                            ),
                            const SizedBox(width: 12),
                            Icon(Icons.timer, size: 12, color: textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              'Duration: $durationText',
                              style: TextStyle(color: textSecondary, fontSize: 10),
                            ),
                          ],
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

  /// Opens the full recording review screen.
  ///
  /// Replaces a dialog that could only ever say "play" or "not available": the
  /// teacher who ran the class needs to see how long it is, whether a
  /// downloadable file exists, and decide what students may do with it. The
  /// screen also fetches on open, so it reports "still processing" rather than
  /// failing when BBB has not finished rendering.
  void _viewRecording(LiveSession session) {
    openLiveClassRecording(
      context,
      sessionId: session.id,
      title: session.title,
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
        final isDesktop = !kIsWeb && (defaultTargetPlatform == TargetPlatform.windows || 
                                    defaultTargetPlatform == TargetPlatform.linux || 
                                    defaultTargetPlatform == TargetPlatform.macOS);
        context.go(isDesktop ? '/email-auth-option' : '/auth-selection');
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
        title: Row(
          children: [
            const Text('Live Sessions'),
            if (_upcomingSessions.isNotEmpty) ...[
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.schedule, color: Colors.white, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      '${_upcomingSessions.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          tabs: const [
            Tab(text: 'Upcoming'),
            Tab(text: 'Ready to Start'),
            Tab(text: 'Past'),
            Tab(text: 'All'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              _loadSessions();
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
      body: Column(
        children: [
          // Search Bar
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: TextField(
              controller: _searchController,
              onChanged: _onSearchChanged,
              decoration: InputDecoration(
                hintText: 'Search sessions by title, course, or status...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearchChanged('');
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: cardColor,
              ),
            ),
          ),
          // Tab Content
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _errorMessage != null
                    ? _buildErrorWidget()
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildSessionsList(_filteredSessions, 'upcoming'),
                          _buildSessionsList(_filteredSessions, 'ready'),
                          _buildSessionsList(_filteredSessions, 'past'),
                          _buildSessionsList(_filteredSessions, 'all'),
                        ],
                      ),
          ),
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
            onPressed: () async => await _loadSessions(),
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
          onEdit: () => _editSession(session),
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

/// Session Card Widget
class _SessionCard extends StatelessWidget {
  final LiveSession session;
  final String type;
  final VoidCallback onJoin;
  final VoidCallback onEnd;
  final VoidCallback onEdit;
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
    required this.onEdit,
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
          Divider(height: 1, color: isDark ? AppTheme.darkTextSecondary.withOpacity(0.2) : Colors.grey[300]),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // Attendance button for all session types
                TextButton.icon(
                  onPressed: onViewAttendance,
                  icon: const Icon(Icons.people_outline, size: 18),
                  label: Text(isEnded ? 'Attendance' : 'Enrolled'),
                  style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                ),
                  if (hasRecording)
                    TextButton.icon(
                      onPressed: onViewRecording,
                      icon: const Icon(Icons.play_arrow, size: 18),
                      label: const Text('Recording'),
                    ),
                  if (isScheduled) ...[
                    TextButton.icon(
                      onPressed: onEdit,
                      icon: const Icon(Icons.edit, size: 18),
                      label: const Text('Edit'),
                      style: TextButton.styleFrom(foregroundColor: AppTheme.primaryGreen),
                    ),
                    const SizedBox(width: 8),
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
