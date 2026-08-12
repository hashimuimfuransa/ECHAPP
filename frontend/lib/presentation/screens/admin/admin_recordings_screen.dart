import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/admin_recording.dart';
import '../../providers/admin_recordings_provider.dart';
import '../community/community_theme.dart';

/// Every recording on the platform, in one place.
///
/// Admins are the only role permitted to take a course recording off the
/// platform, so this is where they find and download them — previously that
/// meant opening each course's live sessions one at a time.
class AdminRecordingsScreen extends ConsumerStatefulWidget {
  const AdminRecordingsScreen({super.key});

  @override
  ConsumerState<AdminRecordingsScreen> createState() =>
      _AdminRecordingsScreenState();
}

class _AdminRecordingsScreenState extends ConsumerState<AdminRecordingsScreen> {
  RecordingQuery _query = const RecordingQuery();
  final _searchController = TextEditingController();
  String? _busyId;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _refreshOne(AdminRecording r) async {
    setState(() => _busyId = r.id);
    try {
      final ready = await ref
          .read(adminRecordingsServiceProvider)
          .refresh(r.kind, r.id);
      if (!mounted) return;
      communitySnack(
        context,
        ready
            ? 'Recording refreshed'
            : 'Still processing on the video server — try again shortly',
      );
      ref.invalidate(adminRecordingsProvider(_query));
    } catch (e) {
      if (mounted) {
        communitySnack(context, e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _togglePublished(AdminRecording r) async {
    setState(() => _busyId = r.id);
    try {
      await ref
          .read(adminRecordingsServiceProvider)
          .setPublished(r.kind, r.id, !r.isPublished);
      if (!mounted) return;
      communitySnack(
        context,
        r.isPublished ? 'Recording hidden from members' : 'Recording made visible',
      );
      ref.invalidate(adminRecordingsProvider(_query));
    } catch (e) {
      if (mounted) {
        communitySnack(context, e.toString().replaceFirst('Exception: ', ''),
            isError: true);
      }
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pageAsync = ref.watch(adminRecordingsProvider(_query));

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Recordings',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: CT.textOf(context),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(adminRecordingsProvider(_query)),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            color: CT.subTextOf(context),
            tooltip: 'Reload',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: TextField(
              controller: _searchController,
              onSubmitted: (v) =>
                  setState(() => _query = _query.copyWith(search: v.trim())),
              style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
              decoration: InputDecoration(
                hintText: 'Search by session title',
                hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
                prefixIcon: const Icon(Icons.search_rounded, size: 19),
                suffixIcon: _query.search.isEmpty
                    ? null
                    : IconButton(
                        onPressed: () {
                          _searchController.clear();
                          setState(
                              () => _query = _query.copyWith(search: ''));
                        },
                        icon: const Icon(Icons.close_rounded, size: 17),
                      ),
                filled: true,
                fillColor: CT.cardOf(context),
                contentPadding: const EdgeInsets.symmetric(vertical: 6),
                border: OutlineInputBorder(
                  borderRadius: CT.r12,
                  borderSide: BorderSide(color: CT.borderOf(context)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: CT.r12,
                  borderSide: BorderSide(color: CT.borderOf(context)),
                ),
                focusedBorder: const OutlineInputBorder(
                  borderRadius: CT.r12,
                  borderSide: BorderSide(color: CT.primary, width: 1.5),
                ),
              ),
            ),
          ),
          SizedBox(
            height: 42,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _kindChip('all', 'All'),
                _kindChip('live', 'Live classes'),
                _kindChip('study', 'Study sessions'),
              ],
            ),
          ),
          Expanded(
            child: pageAsync.when(
              loading: () => const Center(
                child:
                    CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
              ),
              error: (error, _) => CommunityErrorView(
                error: error,
                onRetry: () => ref.invalidate(adminRecordingsProvider(_query)),
              ),
              data: (page) {
                if (page.recordings.isEmpty) {
                  return CommunityEmpty(
                    icon: Icons.video_library_rounded,
                    title: _query.search.isNotEmpty
                        ? 'No recordings match that search'
                        : 'No recordings yet',
                    message: _query.search.isNotEmpty
                        ? 'Try a different title, or clear the search.'
                        : 'Recordings appear here once a live class or study '
                            'session has finished and the video server has '
                            'processed it.',
                  );
                }
                return RefreshIndicator(
                  color: CT.primary,
                  onRefresh: () async =>
                      ref.invalidate(adminRecordingsProvider(_query)),
                  child: ListView(
                    padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
                    children: [
                      _Stats(stats: page.stats),
                      const SizedBox(height: 14),
                      ...page.recordings.map((r) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _RecordingCard(
                              recording: r,
                              isBusy: _busyId == r.id,
                              onRefresh: () => _refreshOne(r),
                              onTogglePublished: () => _togglePublished(r),
                            ),
                          )),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _kindChip(String value, String label) {
    final selected = _query.kind == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _query = _query.copyWith(kind: value)),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : CT.textOf(context),
        ),
        selectedColor: CT.primary,
        backgroundColor: CT.cardOf(context),
        shape: const RoundedRectangleBorder(borderRadius: CT.r12),
        side: BorderSide(color: CT.borderOf(context)),
        showCheckmark: false,
      ),
    );
  }
}

class _Stats extends StatelessWidget {
  final AdminRecordingStats stats;
  const _Stats({required this.stats});

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
      child: Row(
        children: [
          CommunityStat(
            icon: Icons.video_library_rounded,
            value: '${stats.total}',
            label: 'recordings',
          ),
          const SizedBox(width: 16),
          CommunityStat(
            icon: Icons.cast_for_education_rounded,
            value: '${stats.liveClasses}',
            label: 'classes',
            color: CT.info,
          ),
          const SizedBox(width: 16),
          CommunityStat(
            icon: Icons.groups_rounded,
            value: '${stats.studySessions}',
            label: 'study',
            color: CT.accent,
          ),
          const SizedBox(width: 16),
          CommunityStat(
            icon: Icons.download_done_rounded,
            value: '${stats.downloadable}',
            label: 'downloadable',
            color: CT.primary,
          ),
        ],
      ),
    );
  }
}

class _RecordingCard extends StatelessWidget {
  final AdminRecording recording;
  final bool isBusy;
  final VoidCallback onRefresh;
  final VoidCallback onTogglePublished;

  const _RecordingCard({
    required this.recording,
    required this.isBusy,
    required this.onRefresh,
    required this.onTogglePublished,
  });

  @override
  Widget build(BuildContext context) {
    final r = recording;

    return CommunityCard(
      accent: r.isPublished ? null : CT.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: (r.isLiveClass ? CT.info : CT.accent).withOpacity(0.12),
                  borderRadius: CT.r12,
                ),
                child: Icon(
                  r.isLiveClass
                      ? Icons.cast_for_education_rounded
                      : Icons.groups_rounded,
                  size: 19,
                  color: r.isLiveClass ? CT.info : CT.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      r.title,
                      style: TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        height: 1.3,
                        color: CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      [
                        if (r.courseTitle != null) r.courseTitle!,
                        if (r.teacherName != null) r.teacherName!,
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 11.5,
                        color: CT.subTextOf(context),
                      ),
                    ),
                  ],
                ),
              ),
              if (isBusy)
                const Padding(
                  padding: EdgeInsets.all(6),
                  child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                )
              else
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 19, color: CT.subTextOf(context)),
                  onSelected: (v) {
                    if (v == 'refresh') onRefresh();
                    if (v == 'visibility') onTogglePublished();
                  },
                  itemBuilder: (context) => [
                    const PopupMenuItem(
                      value: 'refresh',
                      child: Row(
                        children: [
                          Icon(Icons.sync_rounded, size: 18),
                          SizedBox(width: 10),
                          Text('Refresh from server'),
                        ],
                      ),
                    ),
                    PopupMenuItem(
                      value: 'visibility',
                      child: Row(
                        children: [
                          Icon(
                            r.isPublished
                                ? Icons.visibility_off_rounded
                                : Icons.visibility_rounded,
                            size: 18,
                          ),
                          const SizedBox(width: 10),
                          Text(r.isPublished ? 'Hide from members' : 'Make visible'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CommunityChip(
                label: r.isLiveClass ? 'Live class' : 'Study session',
                icon: r.isLiveClass ? Icons.school_rounded : Icons.groups_rounded,
                color: r.isLiveClass ? CT.info : CT.accent,
              ),
              CommunityChip(
                label: r.durationLabel,
                icon: Icons.schedule_rounded,
                color: CT.textSecondary,
              ),
              if (r.participants > 0)
                CommunityChip(
                  label: '${r.participants} attended',
                  icon: Icons.people_alt_rounded,
                ),
              CommunityChip(
                label: CT.formatDate(context, r.endedAt ?? r.scheduledAt),
                icon: Icons.event_rounded,
                color: CT.textSecondary,
              ),
              if (!r.isPublished)
                const CommunityChip(
                  label: 'Hidden',
                  icon: Icons.visibility_off_rounded,
                  color: CT.warn,
                ),
            ],
          ),
          const SizedBox(height: 13),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: r.canWatch
                      ? () => openExternalLink(
                            context,
                            r.playbackUrl!,
                            title: r.title,
                            actionLabel: 'Watch',
                          )
                      : null,
                  icon: const Icon(Icons.play_circle_outline_rounded, size: 16),
                  label: const Text('Watch'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CT.primary,
                    side: const BorderSide(color: CT.primary),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  // Only admins reach this screen, so a file that exists is a
                  // file they may take.
                  onPressed: r.canDownload
                      ? () => openExternalLink(
                            context,
                            r.downloadUrl!,
                            title: 'Download recording',
                            actionLabel: 'Download',
                            description:
                                'Save the video file for ${r.title}.',
                          )
                      : null,
                  icon: const Icon(Icons.download_rounded, size: 16),
                  label: Text(r.canDownload ? 'Download' : 'No file'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.info,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: CT.surfaceOf(context),
                    disabledForegroundColor: CT.textHint,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                ),
              ),
            ],
          ),
          if (!r.hasDownloadableFile) ...[
            const SizedBox(height: 9),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 13, color: CT.subTextOf(context)),
                const SizedBox(width: 7),
                Expanded(
                  child: Text(
                    'No downloadable file — the video server did not produce '
                    'one. Try Refresh, or check that video playback is '
                    'installed on BigBlueButton.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.4,
                      color: CT.subTextOf(context),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
