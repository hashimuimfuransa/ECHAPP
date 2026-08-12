import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';

/// Opens the recording review screen for a finished community study session.
void openSessionRecording(
  BuildContext context,
  String courseId,
  StudySession session,
) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SessionRecordingScreen(
        recording: RecordingRef(
          source: RecordingSource.community,
          courseId: courseId,
          sessionId: session.id,
        ),
        topic: session.topic,
      ),
    ),
  );
}

/// Opens the same screen for a teacher-led live class.
///
/// Live classes are not community sessions, but their recordings live on the
/// same BBB server and carry the same controls, so the teacher who scheduled
/// one reviews it here too.
void openLiveClassRecording(
  BuildContext context, {
  required String sessionId,
  required String title,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => SessionRecordingScreen(
        recording: RecordingRef(
          source: RecordingSource.liveClass,
          sessionId: sessionId,
        ),
        topic: title,
      ),
    ),
  );
}

/// Review a session recording.
///
/// The organiser lands here to check the recording came out usable before
/// deciding whether the group may keep a copy; everyone else gets the same
/// screen minus the controls.
class SessionRecordingScreen extends ConsumerWidget {
  final RecordingRef recording;
  final String topic;

  const SessionRecordingScreen({
    super.key,
    required this.recording,
    required this.topic,
  });

  RecordingRef get _key => recording;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recordingAsync = ref.watch(sessionRecordingProvider(_key));

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Session recording',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: CT.textOf(context),
              ),
            ),
            Text(
              topic,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
            ),
          ],
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(sessionRecordingProvider(_key)),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            color: CT.subTextOf(context),
            tooltip: 'Check again',
          ),
        ],
      ),
      body: recordingAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
        ),
        error: (error, _) => CommunityErrorView(
          error: error,
          onRetry: () => ref.invalidate(sessionRecordingProvider(_key)),
        ),
        data: (data) => _Body(
          ref: recording,
          topic: topic,
          recording: data,
          onRefresh: () => ref.invalidate(sessionRecordingProvider(_key)),
        ),
      ),
    );
  }
}

class _Body extends ConsumerWidget {
  final RecordingRef ref_;
  final String topic;
  final SessionRecording recording;
  final VoidCallback onRefresh;

  const _Body({
    required RecordingRef ref,
    required this.topic,
    required this.recording,
    required this.onRefresh,
  }) : ref_ = ref;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // BBB renders recordings after the room closes — usually minutes, but it
    // can be longer for a long session. This is a waiting state, not a failure.
    if (recording.isProcessing) {
      return _Notice(
        icon: Icons.hourglass_top_rounded,
        color: CT.warn,
        title: 'Still processing',
        message: 'The video server is still rendering this recording. It '
            'usually takes a few minutes after the room closes — longer for a '
            'long session.',
        actionLabel: 'Check again',
        onAction: onRefresh,
      );
    }

    if (recording.isUnavailable) {
      return const _Notice(
        icon: Icons.visibility_off_rounded,
        color: CT.textHint,
        title: 'Not shared',
        message: 'The organiser has not shared this recording.',
      );
    }

    if (!recording.isReady) {
      return const _Notice(
        icon: Icons.videocam_off_rounded,
        color: CT.textHint,
        title: 'No recording',
        message: 'This session was not recorded. Sessions run on an external '
            'meeting link are never recorded by the platform.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        _Summary(recording: recording),
        const SizedBox(height: 16),
        _PrimaryAction(
          label: 'Watch the recording',
          icon: Icons.play_circle_fill_rounded,
          color: CT.primary,
          onTap: () => openExternalLink(
            context,
            recording.playbackUrl!,
            title: topic,
            actionLabel: 'Watch',
            description: 'The recording opens in the video player.',
          ),
        ),
        const SizedBox(height: 10),
        if (recording.canDownload)
          _PrimaryAction(
            label: 'Download the video',
            icon: Icons.download_rounded,
            color: CT.info,
            onTap: () => openExternalLink(
              context,
              recording.downloadUrl!,
              title: 'Download recording',
              actionLabel: 'Download',
              description: 'Save the video so you can watch it offline.',
            ),
          )
        else if (recording.hasDownloadableFile)
          // A file exists but this viewer is not allowed it.
          _InfoRow(
            icon: Icons.lock_rounded,
            text: recording.isAdminOnlyDownload
                ? 'Course recordings can only be downloaded by an '
                    'administrator. You can watch this one in full here.'
                : 'The organiser has not made this recording downloadable.',
          )
        else
          _InfoRow(
            icon: Icons.info_outline_rounded,
            text: 'This recording can be watched online but not downloaded — '
                'the video server did not produce a downloadable file for it.',
          ),
        if (recording.formats.length > 1) ...[
          const SizedBox(height: 20),
          const SectionHeader(
            icon: Icons.video_library_rounded,
            title: 'Available formats',
          ),
          const SizedBox(height: 10),
          ...recording.formats.map((f) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _FormatRow(format: f, topic: topic),
              )),
        ],
        if (recording.canManage) ...[
          const SizedBox(height: 22),
          _OrganiserControls(target: ref_, recording: recording),
        ],
      ],
    );
  }
}

class _Summary extends StatelessWidget {
  final SessionRecording recording;
  const _Summary({required this.recording});

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: CT.heroGrad),
                  borderRadius: CT.r12,
                ),
                child: const Icon(Icons.smart_display_rounded,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Recording ready',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: CT.textOf(context),
                      ),
                    ),
                    if (recording.endedAt != null)
                      Text(
                        'Recorded ${CT.formatDateTime(context, recording.endedAt)}',
                        style: TextStyle(
                          fontSize: 11.5,
                          color: CT.subTextOf(context),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CommunityChip(
                label: recording.durationLabel,
                icon: Icons.schedule_rounded,
                color: CT.info,
              ),
              if (recording.participants > 0)
                CommunityChip(
                  label: '${recording.participants} attended',
                  icon: Icons.people_alt_rounded,
                  color: CT.primary,
                ),
              CommunityChip(
                label: recording.hasDownloadableFile
                    ? 'Downloadable'
                    : 'Streaming only',
                icon: recording.hasDownloadableFile
                    ? Icons.download_done_rounded
                    : Icons.cloud_rounded,
                color: recording.hasDownloadableFile ? CT.primary : CT.textSecondary,
              ),
              if (!recording.isPublished)
                const CommunityChip(
                  label: 'Hidden from members',
                  icon: Icons.visibility_off_rounded,
                  color: CT.warn,
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// The organiser's switches: share it, and allow copies.
class _OrganiserControls extends ConsumerStatefulWidget {
  final RecordingRef target;
  final SessionRecording recording;

  const _OrganiserControls({required this.target, required this.recording});

  @override
  ConsumerState<_OrganiserControls> createState() => _OrganiserControlsState();
}

class _OrganiserControlsState extends ConsumerState<_OrganiserControls> {
  bool _isBusy = false;

  Future<void> _update({bool? allowDownload, bool? isPublished}) async {
    setState(() => _isBusy = true);
    try {
      await ref.read(communityActionsProvider).updateSessionRecording(
            widget.target.courseId,
            widget.target.sessionId,
            source: widget.target.source,
            allowDownload: allowDownload,
            isPublished: isPublished,
          );
      if (!mounted) return;
      communitySnack(
        context,
        allowDownload == true
            ? 'Members can now download this recording'
            : allowDownload == false
                ? 'Download turned off'
                : isPublished == true
                    ? 'Recording shared with the group'
                    : 'Recording hidden from the group',
      );
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

  @override
  Widget build(BuildContext context) {
    final r = widget.recording;

    return CommunityCard(
      accent: CT.accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.tune_rounded, size: 17, color: CT.accent),
              const SizedBox(width: 9),
              Text(
                widget.target.source == RecordingSource.liveClass
                    ? 'You taught this class'
                    : 'You organised this session',
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w800,
                  color: CT.textOf(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            widget.target.source == RecordingSource.liveClass
                ? 'Check the recording plays properly, then decide what your '
                    'students can do with it.'
                : 'Check the recording plays properly, then decide what the '
                    'group can do with it.',
            style: TextStyle(
              fontSize: 12,
              height: 1.45,
              color: CT.subTextOf(context),
            ),
          ),
          const SizedBox(height: 8),
          SwitchListTile.adaptive(
            value: r.isPublished,
            onChanged: _isBusy ? null : (v) => _update(isPublished: v),
            activeColor: CT.primary,
            contentPadding: EdgeInsets.zero,
            title: Text(
              'Share with the group',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: CT.textOf(context),
              ),
            ),
            subtitle: Text(
              r.isPublished
                  ? 'Everyone who attended can watch it.'
                  : 'Only you can see this recording.',
              style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
            ),
          ),
          // Course recordings have a fixed download policy, so there is no
          // switch to offer — state the rule instead of implying a choice.
          if (r.isAdminOnlyDownload)
            _InfoRow(
              icon: r.isAdmin ? Icons.verified_user_rounded : Icons.lock_rounded,
              text: r.isAdmin
                  ? 'As an administrator you can download this recording. '
                      'Teachers and students watch it online.'
                  : 'Downloading course recordings is reserved for '
                      'administrators. Your students can watch this online '
                      'once it is shared.',
            )
          else
            SwitchListTile.adaptive(
              value: r.allowDownload,
              // Nothing to allow if the server produced no file.
              onChanged: (_isBusy || !r.hasDownloadableFile)
                  ? null
                  : (v) => _update(allowDownload: v),
              activeColor: CT.primary,
              contentPadding: EdgeInsets.zero,
              title: Text(
                'Allow downloads',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: r.hasDownloadableFile
                      ? CT.textOf(context)
                      : CT.textHint,
                ),
              ),
              subtitle: Text(
                !r.hasDownloadableFile
                    ? 'No downloadable file exists for this recording.'
                    : r.allowDownload
                        ? 'Members can save a copy and watch offline. They will be notified.'
                        : 'Members can watch online but not keep a copy.',
                style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
              ),
            ),
        ],
      ),
    );
  }
}

class _FormatRow extends StatelessWidget {
  final RecordingFormat format;
  final String topic;

  const _FormatRow({required this.format, required this.topic});

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      padding: const EdgeInsets.all(12),
      onTap: () => openExternalLink(
        context,
        format.url,
        title: topic,
        actionLabel: format.isVideo ? 'Download' : 'Watch',
      ),
      child: Row(
        children: [
          Icon(
            format.isVideo
                ? Icons.movie_rounded
                : Icons.slideshow_rounded,
            size: 18,
            color: format.isVideo ? CT.info : CT.accent,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  format.label,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CT.textOf(context),
                  ),
                ),
                if (format.sizeLabel.isNotEmpty)
                  Text(
                    format.sizeLabel,
                    style: TextStyle(
                      fontSize: 11,
                      color: CT.subTextOf(context),
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.open_in_new_rounded, size: 16, color: CT.subTextOf(context)),
        ],
      ),
    );
  }
}

class _PrimaryAction extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _PrimaryAction({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onTap,
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 14),
          shape: const RoundedRectangleBorder(borderRadius: CT.r12),
          textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: CT.surfaceOf(context),
        borderRadius: CT.r12,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 15, color: CT.subTextOf(context)),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                color: CT.subTextOf(context),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Notice extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _Notice({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityEmpty(
      icon: icon,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}
