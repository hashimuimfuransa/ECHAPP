import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';
import 'session_card.dart';
import 'sheets/create_session_sheet.dart';
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
                        child: SessionCard(
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

  Future<void> _create(BuildContext context) =>
      showCreateSessionSheet(context, widget.courseId);
}
