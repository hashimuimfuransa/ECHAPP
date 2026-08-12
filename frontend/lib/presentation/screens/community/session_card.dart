import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';

/// A study session, with its full meeting lifecycle.
///
/// The organiser opens the room (which creates the BigBlueButton meeting and
/// notifies everyone attending); classmates join once it is live; afterwards
/// the recording appears here.
class SessionCard extends ConsumerStatefulWidget {
  final String courseId;
  final StudySession session;

  const SessionCard({required this.courseId, required this.session});

  @override
  ConsumerState<SessionCard> createState() => SessionCardState();
}

class SessionCardState extends ConsumerState<SessionCard> {
  bool _isBusy = false;

  StudySession get session => widget.session;

  Future<void> _run(Future<void> Function() action) async {
    if (_isBusy) return;
    setState(() => _isBusy = true);
    try {
      await action();
    } catch (e) {
      if (mounted) {
        communitySnack(
          context,
          e.toString().replaceFirst('Exception: ', ''),
          isError: true,
        );
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  /// Opens (organiser) or enters (attendee) the meeting room.
  Future<void> _enterRoom() => _run(() async {
        final ticket = await ref
            .read(communityActionsProvider)
            .joinSessionRoom(widget.courseId, session.id);

        if (ticket.joinUrl.isEmpty) {
          if (mounted) {
            communitySnack(context, 'No meeting link was returned', isError: true);
          }
          return;
        }
        if (!mounted) return;

        await openExternalLink(
          context,
          ticket.joinUrl,
          title: ticket.isModerator ? 'Your room is open' : 'Join the session',
          actionLabel: 'Enter the room',
          description: ticket.isModerator
              ? 'The room is open and everyone attending has been notified. '
                  'Tap to enter.'
              : 'The session is live. Tap to enter the room.',
        );
      });

  Future<void> _toggleRsvp() => _run(() async {
        final updated =
            await ref.read(communityActionsProvider).rsvpSession(widget.courseId, session.id);
        if (mounted) {
          communitySnack(
            context,
            updated.isJoined ? 'You are on the list' : 'You left the session',
          );
        }
      });

  Future<void> _endSession() => _run(() async {
        await ref.read(communityActionsProvider).endSession(widget.courseId, session.id);
        if (mounted) communitySnack(context, 'Session ended');
      });

  Future<void> _cancel() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel this session?'),
        content: Text(
          session.participantCount > 1
              ? 'Everyone who signed up will be notified that it is off.'
              : 'The session will be removed from the upcoming list.',
        ),
        shape: const RoundedRectangleBorder(borderRadius: CT.r16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Keep it'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: TextButton.styleFrom(foregroundColor: CT.danger),
            child: const Text('Cancel session'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _run(() async {
      await ref.read(communityActionsProvider).cancelSession(widget.courseId, session.id);
      if (mounted) communitySnack(context, 'Session cancelled');
    });
  }

  Future<void> _openRecording() => _run(() async {
        var url = session.recordingUrl;

        if (url == null || url.isEmpty) {
          final recording = await ref
              .read(communityActionsProvider)
              .fetchSessionRecording(widget.courseId, session.id);
          url = recording.url;
          if (url == null) {
            if (mounted) {
              communitySnack(
                context,
                recording.processing
                    ? 'The recording is still processing — check back in a few minutes'
                    : 'This session was not recorded',
              );
            }
            return;
          }
        }

        if (!mounted) return;
        await openExternalLink(
          context,
          url,
          title: 'Session recording',
          actionLabel: 'Watch',
        );
      });

  @override
  Widget build(BuildContext context) {
    final s = session;

    return CommunityCard(
      accent: s.isLive
          ? CT.danger
          : (s.isCancelled ? null : (s.isJoined ? CT.accent : null)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: s.isLive
                        ? [CT.danger, const Color(0xFFB91C1C)]
                        : (s.isCancelled
                            ? [CT.textHint, CT.textHint]
                            : CT.purpleGrad),
                  ),
                  borderRadius: CT.r12,
                ),
                child: Icon(
                  s.isLive
                      ? Icons.sensors_rounded
                      : (s.isCompleted
                          ? Icons.event_available_rounded
                          : (s.isCancelled
                              ? Icons.event_busy_rounded
                              : Icons.event_rounded)),
                  size: 18,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.topic,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        decoration:
                            s.isCancelled ? TextDecoration.lineThrough : null,
                        color: s.isCancelled
                            ? CT.subTextOf(context)
                            : CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _timingLabel(s),
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: s.isLive ? FontWeight.w700 : FontWeight.w500,
                        color: s.isLive ? CT.danger : CT.subTextOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (s.isLive) const LiveDot(),
              if (s.canModerate && !s.isCompleted && !s.isCancelled)
                IconButton(
                  onPressed: _isBusy ? null : _cancel,
                  icon: const Icon(Icons.close_rounded, size: 17),
                  color: CT.textHint,
                  visualDensity: VisualDensity.compact,
                  tooltip: 'Cancel session',
                ),
            ],
          ),
          if (s.description.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              s.description,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: CT.subTextOf(context),
              ),
            ),
          ],
          if (s.agenda.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...s.agenda.map((item) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Container(
                          width: 4,
                          height: 4,
                          decoration: const BoxDecoration(
                            color: CT.accent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          item,
                          style: TextStyle(
                            fontSize: 12.5,
                            height: 1.4,
                            color: CT.subTextOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CommunityChip(
                label: '${s.durationMinutes} min',
                icon: Icons.schedule_rounded,
                color: CT.info,
              ),
              CommunityChip(
                label: '${s.participantCount}/${s.maxParticipants} going',
                icon: Icons.people_alt_rounded,
                color: s.isFull ? CT.danger : CT.primary,
              ),
              CommunityChip(
                label: s.runsOnPlatform ? 'In-app video room' : 'External link',
                icon: s.runsOnPlatform
                    ? Icons.videocam_rounded
                    : Icons.open_in_new_rounded,
                color: s.runsOnPlatform ? CT.accent : CT.textSecondary,
              ),
              if (s.groupName != null)
                CommunityChip(
                  label: s.groupName!,
                  icon: Icons.groups_rounded,
                  color: CT.accent,
                ),
              if (s.hasRecording)
                const CommunityChip(
                  label: 'Recorded',
                  icon: Icons.smart_display_rounded,
                  color: CT.primary,
                ),
            ],
          ),
          if (s.participants.isNotEmpty) ...[
            const SizedBox(height: 12),
            MemberStack(members: s.participants, max: 6),
          ],
          const SizedBox(height: 14),
          _buildActions(context, s),
        ],
      ),
    );
  }

  /// One primary action, plus RSVP or End alongside it where it applies.
  Widget _buildActions(BuildContext context, StudySession s) {
    if (s.isCancelled) {
      return SessionNotice(
        icon: Icons.event_busy_rounded,
        text: 'This session was cancelled.',
        color: CT.textHint,
      );
    }

    if (s.isCompleted) {
      if (s.hasRecording || s.canModerate || s.hasAttended || s.isJoined) {
        return SessionActionButton(
          label: s.hasRecording ? 'Watch the recording' : 'Check for a recording',
          icon: Icons.smart_display_rounded,
          color: s.hasRecording ? CT.primary : CT.surfaceOf(context),
          foreground: s.hasRecording ? Colors.white : CT.textOf(context),
          isBusy: _isBusy,
          onTap: _openRecording,
        );
      }
      return SessionNotice(
        icon: Icons.event_available_rounded,
        text: 'This session has finished.',
        color: CT.textHint,
      );
    }

    // ── Live right now ──
    if (s.isLive) {
      // Never label a disabled button "Session full" unless it actually is —
      // saying so at 2/4 sent people looking for a problem that wasn't there.
      final blockedReason = s.canJoin
          ? null
          : (s.isFull
              ? 'Session full'
              : 'Cannot join right now');

      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: SessionActionButton(
                  label: blockedReason ?? 'Join now',
                  icon: Icons.videocam_rounded,
                  color: CT.danger,
                  isBusy: _isBusy,
                  onTap: s.canJoin ? _enterRoom : null,
                ),
              ),
              if (s.canModerate) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: _isBusy ? null : _endSession,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CT.danger,
                    side: const BorderSide(color: CT.danger),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                  child: const Text('End'),
                ),
              ],
            ],
          ),
          if (s.isFull && !s.canJoin) ...[
            const SizedBox(height: 9),
            SessionNotice(
              icon: Icons.group_off_rounded,
              text: 'This session has reached its ${s.maxParticipants}-person '
                  'limit. Ask the organiser to raise it, or catch the recording '
                  'afterwards.',
              color: CT.subTextOf(context),
            ),
          ],
        ],
      );
    }

    // ── I organise this: opening the room is my action, not RSVP ──
    if (s.canModerate) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SessionActionButton(
            label: 'Open the room',
            icon: Icons.play_circle_fill_rounded,
            color: CT.primary,
            isBusy: _isBusy,
            onTap: s.canStart ? _enterRoom : null,
          ),
          const SizedBox(height: 9),
          SessionNotice(
            icon: Icons.info_outline_rounded,
            text: _organiserHint(s),
            color: CT.subTextOf(context),
          ),
        ],
      );
    }

    // ── Upcoming, as an attendee ──
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SessionActionButton(
          label: s.isJoined
              ? 'You are going'
              : (s.isFull ? 'Session full' : 'Count me in'),
          icon: s.isJoined ? Icons.check_circle_rounded : Icons.add_rounded,
          color: s.isJoined ? CT.surfaceOf(context) : CT.accent,
          foreground: s.isJoined ? CT.textOf(context) : Colors.white,
          isBusy: _isBusy,
          onTap: (s.isFull && !s.isJoined) ? null : _toggleRsvp,
        ),
        const SizedBox(height: 9),
        SessionNotice(
          icon: Icons.notifications_active_rounded,
          text: 'We will notify you a day before, 30 minutes before, and the '
              'moment the organiser opens the room.',
          color: CT.subTextOf(context),
        ),
      ],
    );
  }

  /// Tells the organiser exactly what tapping "Open the room" will do, and
  /// when — a bare "you can open it later" left people hunting for a button.
  static String _organiserHint(StudySession s) {
    if (!s.canStart) {
      return 'This session\'s time has passed, so the room can no longer be opened.';
    }

    final until = s.timeUntilStart;
    final peers = s.participantCount - 1;
    final who = peers <= 0
        ? 'Nobody else has signed up yet.'
        : '$peers ${peers == 1 ? 'person' : 'people'} will be notified the '
            'moment you open it.';

    if (until == null || until == Duration.zero) {
      return 'Tap to open the room and start now. $who';
    }
    if (until.inMinutes < 60) {
      return 'Starts in ${until.inMinutes} min — you can open the room now to '
          'set up early. $who';
    }
    if (until.inHours < 24) {
      return 'Starts in ${until.inHours}h — open the room early if you want to '
          'set up. $who';
    }
    return 'Scheduled for ${CT.formatDateTime(s.scheduledAt)}. You can open the '
        'room whenever you are ready. $who';
  }

  static String _timingLabel(StudySession s) {
    if (s.isLive) {
      return 'Live now · started ${CT.timeAgo(s.startedAt ?? s.scheduledAt)}';
    }
    if (s.isCancelled) return 'Cancelled';
    if (s.isCompleted) return 'Finished ${CT.timeAgo(s.endedAt ?? s.scheduledAt)}';

    final until = s.timeUntilStart;
    if (until != null && until.inMinutes <= 60 && until.inSeconds > 0) {
      return 'Starts in ${until.inMinutes} min · ${CT.formatDateTime(s.scheduledAt)}';
    }
    return CT.formatDateTime(s.scheduledAt);
  }
}

/// Pulsing dot marking a session that is running right now.
class LiveDot extends StatefulWidget {
  const LiveDot();

  @override
  State<LiveDot> createState() => LiveDotState();
}

class LiveDotState extends State<LiveDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat(reverse: true);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: Tween<double>(begin: 0.45, end: 1).animate(_controller),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
        decoration: BoxDecoration(
          color: CT.danger,
          borderRadius: CT.r8,
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.circle, size: 7, color: Colors.white),
            SizedBox(width: 5),
            Text(
              'LIVE',
              style: TextStyle(
                fontSize: 9.5,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.8,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SessionActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final bool isBusy;
  final VoidCallback? onTap;

  const SessionActionButton({
    required this.label,
    required this.icon,
    required this.color,
    this.foreground = Colors.white,
    this.isBusy = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: isBusy ? null : onTap,
        icon: isBusy
            ? SizedBox(
                width: 15,
                height: 15,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation(foreground),
                ),
              )
            : Icon(icon, size: 17),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: foreground,
          disabledBackgroundColor: CT.surfaceOf(context),
          disabledForegroundColor: CT.textHint,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: const RoundedRectangleBorder(borderRadius: CT.r12),
          textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class SessionNotice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const SessionNotice({required this.icon, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 7),
        Expanded(
          child: Text(
            text,
            style: TextStyle(fontSize: 11, height: 1.45, color: color),
          ),
        ),
      ],
    );
  }
}

