import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_chat_view.dart';
import 'community_theme.dart';
import 'member_profile_sheet.dart';
import 'sheets/create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// Opens a study group's workspace.
void openGroupWorkspace(BuildContext context, String courseId, String groupId) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => GroupWorkspaceScreen(courseId: courseId, groupId: groupId),
    ),
  );
}

/// A study group's shared workspace: chat, tasks, members, submissions and
/// sessions — everything the group needs to actually do the work together.
class GroupWorkspaceScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String groupId;

  const GroupWorkspaceScreen({
    super.key,
    required this.courseId,
    required this.groupId,
  });

  @override
  ConsumerState<GroupWorkspaceScreen> createState() => _GroupWorkspaceScreenState();
}

class _GroupWorkspaceScreenState extends ConsumerState<GroupWorkspaceScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 4, vsync: this);

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  ({String courseId, String groupId}) get _key =>
      (courseId: widget.courseId, groupId: widget.groupId);

  @override
  Widget build(BuildContext context) {
    final groupAsync = ref.watch(studyGroupProvider(_key));

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          groupAsync.valueOrNull?.summary.name ?? 'Study group',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CT.textOf(context),
          ),
        ),
        actions: [
          if (groupAsync.valueOrNull != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: CT.textOf(context)),
              onSelected: (value) => _onMenu(value, groupAsync.value!),
              itemBuilder: (context) => [
                if (groupAsync.value!.summary.isMine)
                  const PopupMenuItem(
                    value: 'leave',
                    child: Row(
                      children: [
                        Icon(Icons.logout_rounded, size: 18, color: CT.danger),
                        SizedBox(width: 10),
                        Text('Leave group'),
                      ],
                    ),
                  ),
                const PopupMenuItem(
                  value: 'refresh',
                  child: Row(
                    children: [
                      Icon(Icons.refresh_rounded, size: 18),
                      SizedBox(width: 10),
                      Text('Refresh'),
                    ],
                  ),
                ),
              ],
            ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: CT.primary,
          unselectedLabelColor: CT.subTextOf(context),
          indicatorColor: CT.primary,
          indicatorSize: TabBarIndicatorSize.tab,
          labelStyle: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w800),
          tabs: const [
            Tab(icon: Icon(Icons.chat_rounded, size: 17), text: 'Chat'),
            Tab(icon: Icon(Icons.checklist_rounded, size: 17), text: 'Tasks'),
            Tab(icon: Icon(Icons.people_alt_rounded, size: 17), text: 'Members'),
            Tab(icon: Icon(Icons.upload_file_rounded, size: 17), text: 'Work'),
          ],
        ),
      ),
      body: groupAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
        ),
        error: (error, _) => CommunityErrorView(
          error: error,
          onRetry: () => ref.invalidate(studyGroupProvider(_key)),
        ),
        data: (group) => TabBarView(
          controller: _tabController,
          children: [
            CommunityChatView(
              courseId: widget.courseId,
              groupId: widget.groupId,
              emptyMessage:
                  'This is your group\'s private chat. Plan who does what, and '
                  'share what you find.',
            ),
            _TasksTab(courseId: widget.courseId, group: group),
            _MembersTab(courseId: widget.courseId, group: group),
            _WorkTab(courseId: widget.courseId, group: group),
          ],
        ),
      ),
    );
  }

  Future<void> _onMenu(String value, StudyGroupDetail group) async {
    if (value == 'refresh') {
      ref.invalidate(studyGroupProvider(_key));
      return;
    }
    if (value == 'leave') {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Leave this group?'),
          content: Text(
            group.summary.isOwner
                ? 'You are the owner. Leaving hands ownership to the '
                    'longest-standing member.'
                : 'You will lose access to the group chat, tasks and submissions.',
          ),
          shape: const RoundedRectangleBorder(borderRadius: CT.r16),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: TextButton.styleFrom(foregroundColor: CT.danger),
              child: const Text('Leave'),
            ),
          ],
        ),
      );
      if (confirmed != true || !mounted) return;
      try {
        await ref
            .read(communityActionsProvider)
            .leaveGroup(widget.courseId, widget.groupId);
        if (!mounted) return;
        Navigator.of(context).pop();
        communitySnack(context, 'You left the group');
      } catch (e) {
        if (!mounted) return;
        communitySnack(context, e.toString(), isError: true);
      }
    }
  }
}

// ─────────────────────────────────────────────
//  Tasks
// ─────────────────────────────────────────────

class _TasksTab extends ConsumerWidget {
  final String courseId;
  final StudyGroupDetail group;

  const _TasksTab({required this.courseId, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = group.tasks;
    final done = tasks.where((t) => t.isDone).length;
    final canEdit = group.summary.isMine || group.canManage;

    return Stack(
      children: [
        ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
          children: [
            if (tasks.isNotEmpty) ...[
              CommunityCard(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Group progress',
                            style: TextStyle(
                              fontSize: 12,
                              color: CT.subTextOf(context),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$done of ${tasks.length} tasks done',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: CT.textOf(context),
                            ),
                          ),
                          const SizedBox(height: 10),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: LinearProgressIndicator(
                              value: tasks.isEmpty ? 0 : done / tasks.length,
                              minHeight: 7,
                              backgroundColor: CT.surfaceOf(context),
                              valueColor:
                                  const AlwaysStoppedAnimation(CT.primary),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],
            if (tasks.isEmpty)
              CommunityEmpty(
                icon: Icons.checklist_rounded,
                title: 'No tasks yet',
                message: 'Break the work into steps so everyone knows what to do '
                    'and nothing gets missed.',
                actionLabel: canEdit ? 'Add first task' : null,
                onAction: canEdit ? () => _addTask(context, ref) : null,
              )
            else
              ...tasks.map((task) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _TaskTile(
                      courseId: courseId,
                      groupId: group.summary.id,
                      task: task,
                      canEdit: canEdit,
                    ),
                  )),
          ],
        ),
        if (canEdit && tasks.isNotEmpty)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'add-task',
              onPressed: () => _addTask(context, ref),
              backgroundColor: CT.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Task'),
            ),
          ),
      ],
    );
  }

  Future<void> _addTask(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Add group task',
      initialSize: 0.6,
      builder: (ctx, controller) => _AddTaskForm(
        courseId: courseId,
        group: group,
        scrollController: controller,
      ),
    );
  }
}

class _TaskTile extends ConsumerWidget {
  final String courseId;
  final String groupId;
  final GroupTask task;
  final bool canEdit;

  const _TaskTile({
    required this.courseId,
    required this.groupId,
    required this.task,
    required this.canEdit,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityCard(
      padding: const EdgeInsets.fromLTRB(8, 8, 12, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Checkbox(
            value: task.isDone,
            onChanged: canEdit
                ? (value) async {
                    try {
                      await ref.read(communityActionsProvider).toggleTask(
                            courseId,
                            groupId,
                            task.id,
                            value == true,
                          );
                    } catch (e) {
                      if (context.mounted) {
                        communitySnack(context, e.toString(), isError: true);
                      }
                    }
                  }
                : null,
            activeColor: CT.primary,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.title,
                    style: TextStyle(
                      fontSize: 13.5,
                      fontWeight: FontWeight.w700,
                      height: 1.35,
                      decoration: task.isDone ? TextDecoration.lineThrough : null,
                      color: task.isDone
                          ? CT.subTextOf(context)
                          : CT.textOf(context),
                    ),
                  ),
                  if (task.description.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      task.description,
                      style: TextStyle(
                        fontSize: 12,
                        height: 1.4,
                        color: CT.subTextOf(context),
                      ),
                    ),
                  ],
                  if (task.assignedTo.isNotEmpty || task.dueDate != null) ...[
                    const SizedBox(height: 9),
                    Row(
                      children: [
                        if (task.assignedTo.isNotEmpty) ...[
                          MemberStack(members: task.assignedTo, size: 22, max: 3),
                          const SizedBox(width: 10),
                        ],
                        if (task.dueDate != null)
                          CommunityChip(
                            label: CT.dueLabel(task.dueDate),
                            icon: Icons.schedule_rounded,
                            color: task.isDone
                                ? CT.primary
                                : (task.dueDate!.isBefore(DateTime.now())
                                    ? CT.danger
                                    : CT.warn),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
          if (canEdit)
            IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(communityActionsProvider)
                      .deleteTask(courseId, groupId, task.id);
                } catch (e) {
                  if (context.mounted) {
                    communitySnack(context, e.toString(), isError: true);
                  }
                }
              },
              icon: const Icon(Icons.close_rounded, size: 17),
              color: CT.textHint,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _AddTaskForm extends ConsumerStatefulWidget {
  final String courseId;
  final StudyGroupDetail group;
  final ScrollController scrollController;

  const _AddTaskForm({
    required this.courseId,
    required this.group,
    required this.scrollController,
  });

  @override
  ConsumerState<_AddTaskForm> createState() => _AddTaskFormState();
}

class _AddTaskFormState extends ConsumerState<_AddTaskForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final Set<String> _assignees = {};
  DateTime? _dueDate;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Describe the task first.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(communityActionsProvider).addTask(
            widget.courseId,
            widget.group.summary.id,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            assignedTo: _assignees.toList(),
            dueDate: _dueDate,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      communitySnack(context, 'Task added');
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
    final members =
        widget.group.members.where((m) => m.membershipStatus == 'active').toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            controller: widget.scrollController,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            children: [
              communityTextField(
                context: context,
                controller: _titleController,
                label: 'Task',
                hint: 'e.g. Solve questions 1–10',
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _descriptionController,
                label: 'Details (optional)',
                hint: 'Anything the others should know',
                maxLines: 3,
              ),
              const SizedBox(height: 16),
              Text(
                'Assign to',
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
                children: members.map((member) {
                  final selected = _assignees.contains(member.id);
                  return FilterChip(
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _assignees.add(member.id);
                      } else {
                        _assignees.remove(member.id);
                      }
                    }),
                    label: Text(member.fullName.split(' ').first),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : CT.textOf(context),
                    ),
                    selectedColor: CT.primary,
                    backgroundColor: CT.surfaceOf(context),
                    checkmarkColor: Colors.white,
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    side: BorderSide(color: CT.borderOf(context)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 18),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 3)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (picked != null) setState(() => _dueDate = picked);
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
                      const Icon(Icons.event_rounded, size: 18, color: CT.primary),
                      const SizedBox(width: 11),
                      Text(
                        _dueDate == null
                            ? 'Set a due date (optional)'
                            : CT.formatDate(_dueDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _dueDate == null
                              ? CT.subTextOf(context)
                              : CT.textOf(context),
                        ),
                      ),
                      const Spacer(),
                      if (_dueDate != null)
                        IconButton(
                          onPressed: () => setState(() => _dueDate = null),
                          icon: const Icon(Icons.close_rounded, size: 16),
                          color: CT.textHint,
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                ),
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
          label: 'Add task',
          onSubmit: _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Members
// ─────────────────────────────────────────────

class _MembersTab extends ConsumerWidget {
  final String courseId;
  final StudyGroupDetail group;

  const _MembersTab({required this.courseId, required this.group});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final active =
        group.members.where((m) => m.membershipStatus == 'active').toList();
    final pending = group.members
        .where((m) => m.membershipStatus == 'invited' || m.membershipStatus == 'requested')
        .toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        CommunityCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                group.summary.name,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: CT.textOf(context),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                group.summary.description.isEmpty
                    ? group.summary.purposeLabel
                    : group.summary.description,
                style: TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  CommunityChip(
                    label: '${active.length}/${group.summary.maxMembers} members',
                    icon: Icons.people_alt_rounded,
                  ),
                  CommunityChip(
                    label: group.summary.purposeLabel,
                    icon: Icons.flag_rounded,
                    color: CT.accent,
                  ),
                  CommunityChip(
                    label: group.summary.isOpen ? 'Open to join' : 'Invite only',
                    icon: group.summary.isOpen
                        ? Icons.lock_open_rounded
                        : Icons.lock_rounded,
                    color: CT.info,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        SectionHeader(
          icon: Icons.people_alt_rounded,
          title: 'Members',
          actionLabel: group.canManage ? 'Invite' : null,
          onAction: group.canManage ? () => _invite(context, ref) : null,
        ),
        const SizedBox(height: 10),
        ...active.map((member) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _MemberRow(
                courseId: courseId,
                groupId: group.summary.id,
                member: member,
                canManage: group.canManage,
              ),
            )),
        if (pending.isNotEmpty) ...[
          const SizedBox(height: 18),
          const SectionHeader(
            icon: Icons.hourglass_top_rounded,
            title: 'Pending',
            subtitle: 'Invited or waiting for approval',
          ),
          const SizedBox(height: 10),
          ...pending.map((member) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _MemberRow(
                  courseId: courseId,
                  groupId: group.summary.id,
                  member: member,
                  canManage: group.canManage,
                  isPending: true,
                ),
              )),
        ],
      ],
    );
  }

  Future<void> _invite(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Invite classmates',
      builder: (ctx, controller) => _InviteForm(
        courseId: courseId,
        group: group,
        scrollController: controller,
      ),
    );
  }
}

class _MemberRow extends ConsumerWidget {
  final String courseId;
  final String groupId;
  final CommunityMember member;
  final bool canManage;
  final bool isPending;

  const _MemberRow({
    required this.courseId,
    required this.groupId,
    required this.member,
    required this.canManage,
    this.isPending = false,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityCard(
      padding: const EdgeInsets.all(12),
      onTap: () => showMemberProfileSheet(context, courseId, member.id),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 38),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w700,
                          color: CT.textOf(context),
                        ),
                      ),
                    ),
                    if (member.groupRole == 'owner') ...[
                      const SizedBox(width: 7),
                      const CommunityChip(label: 'Owner', color: CT.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  isPending
                      ? (member.membershipStatus == 'invited'
                          ? 'Invitation sent'
                          : 'Requested to join')
                      : member.presence.label,
                  style: TextStyle(
                    fontSize: 11,
                    color: member.presence.isActive && !isPending
                        ? CT.primary
                        : CT.subTextOf(context),
                  ),
                ),
              ],
            ),
          ),
          if (canManage && member.groupRole != 'owner')
            IconButton(
              onPressed: () async {
                try {
                  await ref
                      .read(communityServiceProvider)
                      .removeGroupMember(courseId, groupId, member.id);
                  ref.invalidate(
                      studyGroupProvider((courseId: courseId, groupId: groupId)));
                } catch (e) {
                  if (context.mounted) {
                    communitySnack(context, e.toString(), isError: true);
                  }
                }
              },
              icon: const Icon(Icons.person_remove_rounded, size: 17),
              color: CT.textHint,
              visualDensity: VisualDensity.compact,
            ),
        ],
      ),
    );
  }
}

class _InviteForm extends ConsumerStatefulWidget {
  final String courseId;
  final StudyGroupDetail group;
  final ScrollController scrollController;

  const _InviteForm({
    required this.courseId,
    required this.group,
    required this.scrollController,
  });

  @override
  ConsumerState<_InviteForm> createState() => _InviteFormState();
}

class _InviteFormState extends ConsumerState<_InviteForm> {
  final Set<String> _selected = {};
  String _search = '';
  bool _isSubmitting = false;

  @override
  Widget build(BuildContext context) {
    final existing = widget.group.members.map((m) => m.id).toSet();
    final membersAsync = ref.watch(
      communityMembersProvider(
        MemberQuery(widget.courseId, search: _search, filter: 'students'),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 8),
          child: TextField(
            onChanged: (value) => setState(() => _search = value),
            style: TextStyle(fontSize: 13, color: CT.textOf(context)),
            decoration: InputDecoration(
              hintText: 'Search classmates',
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              filled: true,
              fillColor: CT.cardOf(context),
              contentPadding: const EdgeInsets.symmetric(vertical: 4),
              border: OutlineInputBorder(
                borderRadius: CT.r12,
                borderSide: BorderSide(color: CT.borderOf(context)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: CT.r12,
                borderSide: BorderSide(color: CT.borderOf(context)),
              ),
            ),
          ),
        ),
        Expanded(
          child: membersAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2, color: CT.primary),
            ),
            error: (e, _) => CommunityErrorView(
              error: e,
              onRetry: () => ref.invalidate(communityMembersProvider),
            ),
            data: (directory) {
              final candidates = directory.members
                  .where((m) => !m.isMe && !m.isTeacher && !existing.contains(m.id))
                  .toList();
              if (candidates.isEmpty) {
                return const CommunityEmpty(
                  icon: Icons.person_search_rounded,
                  title: 'Nobody left to invite',
                  message: 'Everyone matching your search is already in this group.',
                  compact: true,
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.symmetric(horizontal: 20),
                itemCount: candidates.length,
                itemBuilder: (context, index) {
                  final member = candidates[index];
                  final selected = _selected.contains(member.id);
                  return CheckboxListTile(
                    value: selected,
                    onChanged: (value) => setState(() {
                      if (value == true) {
                        _selected.add(member.id);
                      } else {
                        _selected.remove(member.id);
                      }
                    }),
                    activeColor: CT.primary,
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    dense: true,
                    title: Row(
                      children: [
                        MemberAvatar(member: member, size: 30),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            member.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: CT.textOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                },
              );
            },
          ),
        ),
        CommunitySheetFooter(
          isBusy: _isSubmitting,
          label: _selected.isEmpty
              ? 'Select classmates'
              : 'Invite ${_selected.length} classmate(s)',
          onSubmit: () async {
            if (_selected.isEmpty) return;
            setState(() => _isSubmitting = true);
            try {
              final count = await ref.read(communityActionsProvider).inviteToGroup(
                    widget.courseId,
                    widget.group.summary.id,
                    _selected.toList(),
                  );
              if (!mounted) return;
              Navigator.of(context).pop();
              communitySnack(context, '$count invitation(s) sent');
            } catch (e) {
              if (!mounted) return;
              setState(() => _isSubmitting = false);
              communitySnack(context, e.toString(), isError: true);
            }
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Group work (submissions + sessions)
// ─────────────────────────────────────────────

class _WorkTab extends StatelessWidget {
  final String courseId;
  final StudyGroupDetail group;

  const _WorkTab({required this.courseId, required this.group});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        const SectionHeader(
          icon: Icons.upload_file_rounded,
          title: 'Submissions',
          subtitle: 'Group assignments this team has handed in',
        ),
        const SizedBox(height: 12),
        if (group.submissions.isEmpty)
          const CommunityEmpty(
            icon: Icons.inbox_rounded,
            title: 'Nothing submitted yet',
            message: 'Group assignments you submit from the Work tab appear here '
                'with the teacher\'s grade and feedback.',
            compact: true,
          )
        else
          ...group.submissions.map((submission) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SubmissionCard(submission: submission),
              )),
        const SizedBox(height: 22),
        const SectionHeader(
          icon: Icons.event_rounded,
          title: 'Study sessions',
          subtitle: 'Meetings this group has planned',
        ),
        const SizedBox(height: 12),
        if (group.sessions.isEmpty)
          const CommunityEmpty(
            icon: Icons.calendar_month_rounded,
            title: 'No sessions planned',
            message: 'Schedule one from the Resources tab of the community.',
            compact: true,
          )
        else
          ...group.sessions.map((session) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: CommunityCard(
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(9),
                        decoration: BoxDecoration(
                          color: (session.isLive ? CT.danger : CT.accent)
                              .withOpacity(0.12),
                          borderRadius: CT.r8,
                        ),
                        child: Icon(
                          session.isLive
                              ? Icons.sensors_rounded
                              : Icons.event_rounded,
                          size: 16,
                          color: session.isLive ? CT.danger : CT.accent,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              session.topic,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13.5,
                                fontWeight: FontWeight.w800,
                                color: CT.textOf(context),
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              session.isLive
                                  ? 'Live now · ${session.participantCount} in the room'
                                  : '${CT.formatDateTime(session.scheduledAt)} · '
                                      '${session.participantCount} going',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: session.isLive
                                    ? FontWeight.w700
                                    : FontWeight.w400,
                                color: session.isLive
                                    ? CT.danger
                                    : CT.subTextOf(context),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (session.isLive)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: CT.danger,
                            borderRadius: CT.r8,
                          ),
                          child: const Text(
                            'LIVE',
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.8,
                              color: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              )),
      ],
    );
  }
}

class _SubmissionCard extends StatelessWidget {
  final AssignmentSubmission submission;

  const _SubmissionCard({required this.submission});

  @override
  Widget build(BuildContext context) {
    final graded = submission.grade != null;
    return CommunityCard(
      accent: graded ? CT.primary : CT.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  submission.assignmentTitle ?? 'Assignment',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CT.textOf(context),
                  ),
                ),
              ),
              CommunityChip(
                label: graded ? 'Graded' : 'Awaiting review',
                icon: graded ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                color: graded ? CT.primary : CT.warn,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'Submitted ${CT.formatDateTime(submission.submittedAt)}'
            '${submission.isLate ? ' · late' : ''}',
            style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
          ),
          if (submission.files.isNotEmpty) ...[
            const SizedBox(height: 10),
            ...submission.files.map((file) => Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Row(
                    children: [
                      const Icon(Icons.description_rounded,
                          size: 14, color: CT.info),
                      const SizedBox(width: 7),
                      Expanded(
                        child: Text(
                          file.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 12,
                            color: CT.subTextOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )),
          ],
          if (graded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CT.primary.withOpacity(0.07),
                borderRadius: CT.r12,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.star_rounded, size: 17, color: CT.primary),
                      const SizedBox(width: 7),
                      Text(
                        '${submission.grade!.score.toStringAsFixed(submission.grade!.score.truncateToDouble() == submission.grade!.score ? 0 : 1)}'
                        '${submission.assignmentMaxMarks != null ? ' / ${submission.assignmentMaxMarks}' : ''}',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: CT.textOf(context),
                        ),
                      ),
                    ],
                  ),
                  if (submission.grade!.feedback.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      submission.grade!.feedback,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.45,
                        color: CT.subTextOf(context),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}
