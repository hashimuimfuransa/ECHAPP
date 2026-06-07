import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/services/live_session_service.dart';
import 'package:excellencecoachinghub/models/live_session.dart';
import 'package:excellencecoachinghub/widgets/network_image_widget.dart';

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

      setState(() {
        if (status == 'scheduled') {
          _upcomingSessions = response.sessions;
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Join ${session.title}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('You are about to join the BigBlueButton meeting.'),
            const SizedBox(height: 8),
            Text(
              'This will open in a new window.',
              style: TextStyle(color: Colors.grey[600], fontSize: 12),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              // Launch URL - in real app, use url_launcher
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening BigBlueButton...')),
              );
            },
            icon: const Icon(Icons.video_call),
            label: const Text('Join Meeting'),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.primaryGreen),
          ),
        ],
      ),
    );
  }

  Future<void> _endSession(LiveSession session) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(recording.sessionTitle ?? 'Session Recording'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.play_circle, size: 64, color: AppTheme.primaryGreen),
            const SizedBox(height: 16),
            Text('Duration: ${recording.duration} minutes'),
            const SizedBox(height: 8),
            Text('Format: ${recording.format ?? 'Video'}'),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
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
            onPressed: () => _loadSessions(),
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
          onViewRecording: () => _viewRecording(session),
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

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(color: Colors.grey[600]),
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
  final VoidCallback onViewRecording;

  const _SessionCard({
    required this.session,
    required this.type,
    required this.onJoin,
    required this.onEnd,
    required this.onCancel,
    required this.onViewRecording,
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.all(16),
            leading: Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.1),
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
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
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
                      color: Colors.grey[600],
                      fontSize: 13,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: statusColor.withOpacity(0.1),
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
                    Icon(Icons.schedule, size: 14, color: Colors.grey[600]),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM d, h:mm a').format(session.scheduledAt),
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ],
                ),
              ],
            ),
            trailing: canJoin
                ? ElevatedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.video_call),
                    label: isLive ? const Text('Join') : const Text('Start'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: isLive ? Colors.green : AppTheme.primaryGreen,
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
            Divider(height: 1, color: Colors.grey[300]),
          if (isScheduled || isLive || hasRecording)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
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
                      icon: const Icon(Icons.video_call, size: 18),
                      label: const Text('Start Early'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    ),
                  ],
                  if (isLive)
                    ElevatedButton.icon(
                      onPressed: onEnd,
                      icon: const Icon(Icons.stop, size: 18),
                      label: const Text('End Session'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
