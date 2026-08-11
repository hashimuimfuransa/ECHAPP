import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';
import 'sheets/create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// Shared resources and student-organised study sessions.
///
/// Resources are split into teacher-published (authoritative) and
/// student-shared (peer) so quality control stays visible.
class CommunityResourcesView extends ConsumerStatefulWidget {
  final String courseId;
  final bool isTeacher;

  const CommunityResourcesView({
    super.key,
    required this.courseId,
    required this.isTeacher,
  });

  @override
  ConsumerState<CommunityResourcesView> createState() =>
      _CommunityResourcesViewState();
}

class _CommunityResourcesViewState extends ConsumerState<CommunityResourcesView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: CT.cardOf(context),
          child: TabBar(
            controller: _tabController,
            labelColor: CT.primary,
            unselectedLabelColor: CT.subTextOf(context),
            indicatorColor: CT.primary,
            labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
            tabs: const [
              Tab(text: 'Resources'),
              Tab(text: 'Study sessions'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _ResourcesTab(
                courseId: widget.courseId,
                isTeacher: widget.isTeacher,
              ),
              _SessionsTab(courseId: widget.courseId),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Resources
// ─────────────────────────────────────────────

class _ResourcesTab extends ConsumerWidget {
  final String courseId;
  final bool isTeacher;

  const _ResourcesTab({required this.courseId, required this.isTeacher});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final libraryAsync = ref.watch(communityResourcesProvider(courseId));

    return Stack(
      children: [
        libraryAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
          ),
          error: (error, _) => CommunityErrorView(
            error: error,
            onRetry: () => ref.invalidate(communityResourcesProvider(courseId)),
          ),
          data: (library) {
            if (library.isEmpty) {
              return CommunityEmpty(
                icon: Icons.folder_shared_rounded,
                title: 'Nothing shared yet',
                message: isTeacher
                    ? 'Share lecture notes, guidelines or examples so every '
                        'student works from the same material.'
                    : 'Share a summary, a useful link or a video that helped you — '
                        'your classmates will thank you.',
                actionLabel: 'Share something',
                onAction: () => _share(context, ref),
              );
            }
            return RefreshIndicator(
              color: CT.primary,
              onRefresh: () async =>
                  ref.invalidate(communityResourcesProvider(courseId)),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                children: [
                  SectionHeader(
                    icon: Icons.verified_rounded,
                    title: 'Teacher resources',
                    subtitle: library.teacherResources.isEmpty
                        ? 'Nothing published yet'
                        : '${library.teacherResources.length} official '
                            '${library.teacherResources.length == 1 ? 'item' : 'items'}',
                  ),
                  const SizedBox(height: 12),
                  if (library.teacherResources.isEmpty)
                    const CommunityEmpty(
                      icon: Icons.school_rounded,
                      title: 'No teacher material yet',
                      message: 'Official notes and guidelines will appear here.',
                      compact: true,
                    )
                  else
                    ...library.teacherResources.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ResourceCard(
                            courseId: courseId,
                            resource: r,
                            isTeacher: isTeacher,
                          ),
                        )),
                  const SizedBox(height: 22),
                  SectionHeader(
                    icon: Icons.people_alt_rounded,
                    title: 'Student resources',
                    subtitle: library.studentResources.isEmpty
                        ? 'Nothing shared by classmates yet'
                        : '${library.studentResources.length} shared by classmates',
                  ),
                  const SizedBox(height: 12),
                  if (library.studentResources.isEmpty)
                    const CommunityEmpty(
                      icon: Icons.lightbulb_outline_rounded,
                      title: 'Be the first to share',
                      message: 'Post the summary or video that made a topic click.',
                      compact: true,
                    )
                  else
                    ...library.studentResources.map((r) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ResourceCard(
                            courseId: courseId,
                            resource: r,
                            isTeacher: isTeacher,
                          ),
                        )),
                ],
              ),
            );
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'community-share-resource',
            onPressed: () => _share(context, ref),
            backgroundColor: CT.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Share'),
          ),
        ),
      ],
    );
  }

  Future<void> _share(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Share a resource',
      initialSize: 0.7,
      builder: (ctx, controller) => _ShareResourceForm(
        courseId: courseId,
        scrollController: controller,
      ),
    );
  }
}

class _ResourceCard extends ConsumerWidget {
  final String courseId;
  final CommunityResource resource;
  final bool isTeacher;

  const _ResourceCard({
    required this.courseId,
    required this.resource,
    required this.isTeacher,
  });

  IconData get _icon => switch (resource.type) {
        'document' => Icons.description_rounded,
        'video' => Icons.play_circle_rounded,
        'note' => Icons.sticky_note_2_rounded,
        _ => Icons.link_rounded,
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = resource.isFromTeacher ? CT.teacher : CT.info;

    return CommunityCard(
      accent: resource.isFromTeacher ? CT.teacher : null,
      onTap: resource.type == 'note' ? null : () => _open(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: CT.r12,
                ),
                child: Icon(_icon, size: 18, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      resource.title,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${resource.uploadedBy?.fullName ?? 'Someone'} · '
                      '${CT.timeAgo(resource.createdAt)}',
                      style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                    ),
                  ],
                ),
              ),
              if (isTeacher || resource.isMine)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: CT.subTextOf(context)),
                  onSelected: (value) => _onMenu(value, context, ref),
                  itemBuilder: (context) => [
                    if (isTeacher && !resource.isFromTeacher)
                      PopupMenuItem(
                        value: 'approve',
                        child: Row(
                          children: [
                            Icon(
                              resource.isApproved
                                  ? Icons.remove_circle_outline_rounded
                                  : Icons.verified_rounded,
                              size: 18,
                              color: CT.primary,
                            ),
                            const SizedBox(width: 10),
                            Text(resource.isApproved
                                ? 'Remove approval'
                                : 'Approve'),
                          ],
                        ),
                      ),
                    const PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: CT.danger),
                          SizedBox(width: 10),
                          Text('Remove'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (resource.description.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              resource.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: CT.subTextOf(context),
              ),
            ),
          ],
          if (resource.type == 'note' && (resource.body ?? '').isNotEmpty) ...[
            const SizedBox(height: 11),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CT.surfaceOf(context),
                borderRadius: CT.r12,
              ),
              child: Text(
                resource.body!,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.55,
                  color: CT.textOf(context),
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => ref
                    .read(communityActionsProvider)
                    .toggleResourceLike(courseId, resource.id),
                borderRadius: CT.r8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        resource.isLikedByMe
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 15,
                        color: resource.isLikedByMe
                            ? CT.primary
                            : CT.subTextOf(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${resource.likeCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: resource.isLikedByMe
                              ? CT.primary
                              : CT.subTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (resource.isFromTeacher)
                const CommunityChip(
                  label: 'Teacher approved',
                  icon: Icons.verified_rounded,
                  color: CT.teacher,
                )
              else if (resource.isApproved)
                const CommunityChip(
                  label: 'Teacher approved',
                  icon: Icons.check_circle_rounded,
                )
              else
                const CommunityChip(
                  label: 'Peer shared',
                  icon: Icons.people_alt_rounded,
                  color: CT.info,
                ),
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _open(BuildContext context) async {
    final url = resource.url;
    if (url == null || url.isEmpty) return;
    await openExternalLink(
      context,
      url,
      title: resource.title,
      actionLabel: 'Open resource',
    );
  }

  Future<void> _onMenu(String value, BuildContext context, WidgetRef ref) async {
    try {
      if (value == 'approve') {
        await ref
            .read(communityActionsProvider)
            .approveResource(courseId, resource.id, !resource.isApproved);
        if (context.mounted) communitySnack(context, 'Resource updated');
      } else if (value == 'delete') {
        await ref
            .read(communityActionsProvider)
            .deleteResource(courseId, resource.id);
        if (context.mounted) communitySnack(context, 'Resource removed');
      }
    } catch (e) {
      if (context.mounted) communitySnack(context, e.toString(), isError: true);
    }
  }
}

class _ShareResourceForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;

  const _ShareResourceForm({
    required this.courseId,
    required this.scrollController,
  });

  @override
  ConsumerState<_ShareResourceForm> createState() => _ShareResourceFormState();
}

class _ShareResourceFormState extends ConsumerState<_ShareResourceForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _urlController = TextEditingController();
  final _bodyController = TextEditingController();

  String _type = 'link';
  bool _isSubmitting = false;
  String? _error;

  static const _types = {
    'link': ('Link', Icons.link_rounded),
    'document': ('Document', Icons.description_rounded),
    'video': ('Video', Icons.play_circle_rounded),
    'note': ('Note', Icons.sticky_note_2_rounded),
  };

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _urlController.dispose();
    _bodyController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Give the resource a title.');
      return;
    }
    if (_type == 'note' && _bodyController.text.trim().isEmpty) {
      setState(() => _error = 'Write your note.');
      return;
    }
    if (_type != 'note' && _urlController.text.trim().isEmpty) {
      setState(() => _error = 'Paste the link to the resource.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(communityActionsProvider).shareResource(
            widget.courseId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _type,
            url: _urlController.text.trim(),
            body: _bodyController.text.trim(),
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      communitySnack(context, 'Shared with the community');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              Text(
                'Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: _types.entries.map((entry) {
                  final selected = _type == entry.key;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _type = entry.key),
                    avatar: Icon(
                      entry.value.$2,
                      size: 15,
                      color: selected ? Colors.white : CT.subTextOf(context),
                    ),
                    label: Text(entry.value.$1),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: selected ? Colors.white : CT.textOf(context),
                    ),
                    selectedColor: CT.primary,
                    backgroundColor: CT.surfaceOf(context),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    side: BorderSide(color: CT.borderOf(context)),
                    showCheckmark: false,
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              communityTextField(
                context: context,
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Chapter 4 summary notes',
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _descriptionController,
                label: 'Why is this useful? (optional)',
                hint: 'One line so classmates know what they are opening',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              if (_type == 'note')
                communityTextField(
                  context: context,
                  controller: _bodyController,
                  label: 'Your note',
                  hint: 'Write the summary, formula or explanation',
                  maxLines: 8,
                )
              else
                communityTextField(
                  context: context,
                  controller: _urlController,
                  label: 'Link',
                  hint: 'https://…',
                  keyboardType: TextInputType.url,
                ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: CT.danger)),
              ],
            ],
          ),
        ),
        CommunitySheetFooter(
          isBusy: _isSubmitting,
          label: 'Share with the class',
          onSubmit: _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Study sessions
// ─────────────────────────────────────────────

class _SessionsTab extends ConsumerStatefulWidget {
  final String courseId;

  const _SessionsTab({required this.courseId});

  @override
  ConsumerState<_SessionsTab> createState() => _SessionsTabState();
}

class _SessionsTabState extends ConsumerState<_SessionsTab> {
  String _scope = 'upcoming';

  @override
  Widget build(BuildContext context) {
    final sessionsAsync = ref.watch(
      communitySessionsProvider((courseId: widget.courseId, scope: _scope)),
    );

    return Stack(
      children: [
        Column(
          children: [
            SizedBox(
              height: 52,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
                children: [
                  _scopeChip('upcoming', 'Upcoming'),
                  _scopeChip('mine', 'Mine'),
                  _scopeChip('past', 'Past'),
                ],
              ),
            ),
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
                ),
                error: (error, _) => CommunityErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(communitySessionsProvider),
                ),
                data: (sessions) {
                  if (sessions.isEmpty) {
                    return CommunityEmpty(
                      icon: Icons.calendar_month_rounded,
                      title: _scope == 'past'
                          ? 'No past sessions'
                          : 'No study sessions planned',
                      message: 'Pick a topic and a time, and classmates can join '
                          'you to work through it together.',
                      actionLabel:
                          _scope == 'past' ? null : 'Create study session',
                      onAction: _scope == 'past' ? null : () => _create(context),
                    );
                  }
                  return RefreshIndicator(
                    color: CT.primary,
                    onRefresh: () async =>
                        ref.invalidate(communitySessionsProvider),
                    child: ListView.builder(
                      padding: const EdgeInsets.fromLTRB(16, 6, 16, 96),
                      itemCount: sessions.length,
                      itemBuilder: (context, index) => Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: _SessionCard(
                          courseId: widget.courseId,
                          session: sessions[index],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: FloatingActionButton.extended(
            heroTag: 'community-new-session',
            onPressed: () => _create(context),
            backgroundColor: CT.accent,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.event_rounded),
            label: const Text('Session'),
          ),
        ),
      ],
    );
  }

  Widget _scopeChip(String value, String label) {
    final selected = _scope == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _scope = value),
        label: Text(label),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: selected ? Colors.white : CT.textOf(context),
        ),
        selectedColor: CT.accent,
        backgroundColor: CT.cardOf(context),
        shape: const RoundedRectangleBorder(borderRadius: CT.r12),
        side: BorderSide(color: CT.borderOf(context)),
        showCheckmark: false,
      ),
    );
  }

  Future<void> _create(BuildContext context) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Create study session',
      initialSize: 0.8,
      builder: (ctx, controller) => _SessionForm(
        courseId: widget.courseId,
        scrollController: controller,
      ),
    );
  }
}

/// A study session, with its full meeting lifecycle.
///
/// The organiser opens the room (which creates the BigBlueButton meeting and
/// notifies everyone attending); classmates join once it is live; afterwards
/// the recording appears here.
class _SessionCard extends ConsumerStatefulWidget {
  final String courseId;
  final StudySession session;

  const _SessionCard({required this.courseId, required this.session});

  @override
  ConsumerState<_SessionCard> createState() => _SessionCardState();
}

class _SessionCardState extends ConsumerState<_SessionCard> {
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
              if (s.isLive) const _LiveDot(),
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
      return _Notice(
        icon: Icons.event_busy_rounded,
        text: 'This session was cancelled.',
        color: CT.textHint,
      );
    }

    if (s.isCompleted) {
      if (s.hasRecording || s.canModerate || s.hasAttended || s.isJoined) {
        return _PrimaryButton(
          label: s.hasRecording ? 'Watch the recording' : 'Check for a recording',
          icon: Icons.smart_display_rounded,
          color: s.hasRecording ? CT.primary : CT.surfaceOf(context),
          foreground: s.hasRecording ? Colors.white : CT.textOf(context),
          isBusy: _isBusy,
          onTap: _openRecording,
        );
      }
      return _Notice(
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
                child: _PrimaryButton(
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
            _Notice(
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
          _PrimaryButton(
            label: 'Open the room',
            icon: Icons.play_circle_fill_rounded,
            color: CT.primary,
            isBusy: _isBusy,
            onTap: s.canStart ? _enterRoom : null,
          ),
          const SizedBox(height: 9),
          _Notice(
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
        _PrimaryButton(
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
        _Notice(
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
class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
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

class _PrimaryButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final Color foreground;
  final bool isBusy;
  final VoidCallback? onTap;

  const _PrimaryButton({
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

class _Notice extends StatelessWidget {
  final IconData icon;
  final String text;
  final Color color;

  const _Notice({required this.icon, required this.text, required this.color});

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


class _SessionForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;

  const _SessionForm({required this.courseId, required this.scrollController});

  @override
  ConsumerState<_SessionForm> createState() => _SessionFormState();
}

class _SessionFormState extends ConsumerState<_SessionForm> {
  final _topicController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _agendaController = TextEditingController();
  final _linkController = TextEditingController();

  DateTime? _scheduledAt;
  int _duration = 60;
  int _maxParticipants = 8;
  String? _groupId;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _topicController.dispose();
    _descriptionController.dispose();
    _agendaController.dispose();
    _linkController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_topicController.text.trim().isEmpty) {
      setState(() => _error = 'What is the session about?');
      return;
    }
    if (_scheduledAt == null) {
      setState(() => _error = 'Pick a date and time.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(communityActionsProvider).createSession(
            widget.courseId,
            topic: _topicController.text.trim(),
            description: _descriptionController.text.trim(),
            scheduledAt: _scheduledAt!,
            durationMinutes: _duration,
            agenda: _agendaController.text
                .split('\n')
                .map((line) => line.trim())
                .where((line) => line.isNotEmpty)
                .toList(),
            maxParticipants: _maxParticipants,
            meetingLink: _linkController.text.trim(),
            groupId: _groupId,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      communitySnack(context, 'Study session created');
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isSubmitting = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final groupsAsync = ref.watch(
      communityGroupsProvider(GroupQuery(widget.courseId, mineOnly: true)),
    );

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              communityTextField(
                context: context,
                controller: _topicController,
                label: 'Topic',
                hint: 'e.g. Chapter 4 revision',
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _descriptionController,
                label: 'What will you cover? (optional)',
                hint: 'A sentence so people know if it is for them',
                maxLines: 2,
              ),
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 1)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 180)),
                  );
                  if (date == null || !mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 14, minute: 0),
                  );
                  setState(() => _scheduledAt = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? 14,
                        time?.minute ?? 0,
                      ));
                },
                borderRadius: CT.r12,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                  decoration: BoxDecoration(
                    color: CT.cardOf(context),
                    borderRadius: CT.r12,
                    border: Border.all(color: CT.borderOf(context)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.event_rounded, size: 18, color: CT.accent),
                      const SizedBox(width: 11),
                      Text(
                        _scheduledAt == null
                            ? 'Pick date and time'
                            : CT.formatDateTime(_scheduledAt),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _scheduledAt == null
                              ? CT.subTextOf(context)
                              : CT.textOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              Text(
                'Duration: $_duration minutes',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              Slider(
                value: _duration.toDouble(),
                min: 15,
                max: 180,
                divisions: 11,
                activeColor: CT.accent,
                label: '$_duration min',
                onChanged: (value) => setState(() => _duration = value.round()),
              ),
              Text(
                'Maximum participants: $_maxParticipants',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              Slider(
                value: _maxParticipants.toDouble(),
                min: 2,
                max: 30,
                divisions: 28,
                activeColor: CT.accent,
                label: '$_maxParticipants',
                onChanged: (value) =>
                    setState(() => _maxParticipants = value.round()),
              ),
              const SizedBox(height: 6),
              communityTextField(
                context: context,
                controller: _agendaController,
                label: 'Agenda (one item per line)',
                hint: 'Review formulas\nSolve questions\nPrepare assignment',
                maxLines: 4,
              ),
              const SizedBox(height: 14),
              // Left empty, the session gets a platform video room on the same
              // BigBlueButton server the teacher's live classes use.
              CommunityCard(
                padding: const EdgeInsets.all(13),
                accent: CT.accent,
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.videocam_rounded, size: 17, color: CT.accent),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Leave the link below empty and this session gets its own '
                        'in-app video room. You open it when it is time, and '
                        'everyone attending gets notified.',
                        style: TextStyle(
                          fontSize: 11.5,
                          height: 1.45,
                          color: CT.subTextOf(context),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              communityTextField(
                context: context,
                controller: _linkController,
                label: 'Use my own meeting link instead (optional)',
                hint: 'Paste a Meet / Zoom link to use that instead',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 16),
              groupsAsync.maybeWhen(
                data: (groups) {
                  if (groups.isEmpty) return const SizedBox.shrink();
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Link to a group (optional)',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: CT.subTextOf(context),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          ChoiceChip(
                            selected: _groupId == null,
                            onSelected: (_) => setState(() => _groupId = null),
                            label: const Text('Open to the course'),
                            labelStyle: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: _groupId == null
                                  ? Colors.white
                                  : CT.textOf(context),
                            ),
                            selectedColor: CT.accent,
                            backgroundColor: CT.surfaceOf(context),
                            shape:
                                const RoundedRectangleBorder(borderRadius: CT.r12),
                            side: BorderSide(color: CT.borderOf(context)),
                            showCheckmark: false,
                          ),
                          ...groups.map((group) {
                            final selected = _groupId == group.id;
                            return ChoiceChip(
                              selected: selected,
                              onSelected: (_) =>
                                  setState(() => _groupId = group.id),
                              label: Text(group.name),
                              labelStyle: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color:
                                    selected ? Colors.white : CT.textOf(context),
                              ),
                              selectedColor: CT.accent,
                              backgroundColor: CT.surfaceOf(context),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: CT.r12),
                              side: BorderSide(color: CT.borderOf(context)),
                              showCheckmark: false,
                            );
                          }),
                        ],
                      ),
                    ],
                  );
                },
                orElse: () => const SizedBox.shrink(),
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(fontSize: 12, color: CT.danger)),
              ],
            ],
          ),
        ),
        CommunitySheetFooter(
          isBusy: _isSubmitting,
          label: 'Create session',
          onSubmit: _submit,
        ),
      ],
    );
  }
}
