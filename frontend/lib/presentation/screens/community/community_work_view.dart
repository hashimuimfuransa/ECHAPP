import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';
import 'group_workspace_screen.dart';
import 'sheets/create_group_sheet.dart';
import 'sheets/create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// "Work" section — assignments for students, plus the review queue for
/// teachers. Group assignments link straight to the group that owns them.
class CommunityWorkView extends ConsumerStatefulWidget {
  final String courseId;
  final bool isTeacher;

  const CommunityWorkView({
    super.key,
    required this.courseId,
    required this.isTeacher,
  });

  @override
  ConsumerState<CommunityWorkView> createState() => _CommunityWorkViewState();
}

class _CommunityWorkViewState extends ConsumerState<CommunityWorkView>
    with SingleTickerProviderStateMixin {
  TabController? _tabController;

  @override
  void initState() {
    super.initState();
    if (widget.isTeacher) {
      _tabController = TabController(length: 2, vsync: this);
    }
  }

  @override
  void dispose() {
    _tabController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isTeacher) return _AssignmentList(courseId: widget.courseId);

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
              Tab(text: 'Assignments'),
              Tab(text: 'Submissions'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _AssignmentList(courseId: widget.courseId, isTeacher: true),
              _SubmissionQueue(courseId: widget.courseId),
            ],
          ),
        ),
      ],
    );
  }
}

class _AssignmentList extends ConsumerWidget {
  final String courseId;
  final bool isTeacher;

  const _AssignmentList({required this.courseId, this.isTeacher = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignmentsAsync = ref.watch(communityAssignmentsProvider(courseId));

    return Stack(
      children: [
        assignmentsAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
          ),
          error: (error, _) => CommunityErrorView(
            error: error,
            onRetry: () => ref.invalidate(communityAssignmentsProvider(courseId)),
          ),
          data: (assignments) {
            if (assignments.isEmpty) {
              return CommunityEmpty(
                icon: Icons.assignment_rounded,
                title: 'No assignments yet',
                message: isTeacher
                    ? 'Publish coursework here and every student in the course '
                        'gets notified.'
                    : 'When your teacher publishes coursework it will appear here '
                        'with its deadline.',
                actionLabel: isTeacher ? 'Publish assignment' : null,
                onAction:
                    isTeacher ? () => _createAssignment(context, ref) : null,
              );
            }
            return RefreshIndicator(
              color: CT.primary,
              onRefresh: () async =>
                  ref.invalidate(communityAssignmentsProvider(courseId)),
              child: ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
                itemCount: assignments.length,
                itemBuilder: (context, index) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _AssignmentCard(
                    courseId: courseId,
                    assignment: assignments[index],
                    isTeacher: isTeacher,
                  ),
                ),
              ),
            );
          },
        ),
        if (isTeacher)
          Positioned(
            right: 16,
            bottom: 16,
            child: FloatingActionButton.extended(
              heroTag: 'community-new-assignment',
              onPressed: () => _createAssignment(context, ref),
              backgroundColor: CT.primary,
              foregroundColor: Colors.white,
              icon: const Icon(Icons.add_rounded),
              label: const Text('Assignment'),
            ),
          ),
      ],
    );
  }

  Future<void> _createAssignment(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Publish assignment',
      initialSize: 0.85,
      builder: (ctx, controller) => _AssignmentForm(
        courseId: courseId,
        scrollController: controller,
      ),
    );
  }
}

class _AssignmentCard extends ConsumerWidget {
  final String courseId;
  final CommunityAssignment assignment;
  final bool isTeacher;

  const _AssignmentCard({
    required this.courseId,
    required this.assignment,
    required this.isTeacher,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graded = assignment.mySubmission?.grade;
    final overdue = assignment.isOverdue;

    return CommunityCard(
      accent: graded != null
          ? CT.primary
          : (overdue && assignment.mySubmission == null && !isTeacher
              ? CT.danger
              : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: (assignment.isGroupAssignment ? CT.accent : CT.info)
                      .withOpacity(0.12),
                  borderRadius: CT.r12,
                ),
                child: Icon(
                  assignment.isGroupAssignment
                      ? Icons.groups_rounded
                      : Icons.person_rounded,
                  size: 18,
                  color: assignment.isGroupAssignment ? CT.accent : CT.info,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      assignment.title,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.3,
                        color: CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      assignment.isGroupAssignment
                          ? 'Group assignment · ${assignment.minGroupSize}–'
                              '${assignment.maxGroupSize} students'
                          : 'Individual assignment',
                      style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                    ),
                  ],
                ),
              ),
              if (isTeacher)
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert_rounded,
                      size: 18, color: CT.subTextOf(context)),
                  onSelected: (value) async {
                    if (value == 'delete') {
                      final confirmed = await showDialog<bool>(
                        context: context,
                        builder: (ctx) => AlertDialog(
                          title: const Text('Delete assignment?'),
                          content: const Text(
                              'All submissions for this assignment will also be '
                              'removed. This cannot be undone.'),
                          shape:
                              const RoundedRectangleBorder(borderRadius: CT.r16),
                          actions: [
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(false),
                              child: const Text('Cancel'),
                            ),
                            TextButton(
                              onPressed: () => Navigator.of(ctx).pop(true),
                              style:
                                  TextButton.styleFrom(foregroundColor: CT.danger),
                              child: const Text('Delete'),
                            ),
                          ],
                        ),
                      );
                      if (confirmed != true) return;
                      try {
                        await ref
                            .read(communityActionsProvider)
                            .deleteAssignment(courseId, assignment.id);
                        if (context.mounted) {
                          communitySnack(context, 'Assignment deleted');
                        }
                      } catch (e) {
                        if (context.mounted) {
                          communitySnack(context, e.toString(), isError: true);
                        }
                      }
                    }
                  },
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: 'delete',
                      child: Row(
                        children: [
                          Icon(Icons.delete_outline_rounded,
                              size: 18, color: CT.danger),
                          SizedBox(width: 10),
                          Text('Delete'),
                        ],
                      ),
                    ),
                  ],
                ),
            ],
          ),
          if (assignment.description.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              assignment.description,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.5,
                color: CT.subTextOf(context),
              ),
            ),
          ],
          const SizedBox(height: 13),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              CommunityChip(
                label: CT.dueLabel(assignment.dueDate),
                icon: Icons.schedule_rounded,
                color: overdue ? CT.danger : CT.warn,
              ),
              CommunityChip(
                label: '${assignment.maxMarks} marks',
                icon: Icons.star_rounded,
                color: CT.accent,
              ),
              if (isTeacher)
                CommunityChip(
                  label: '${assignment.submissionTotal} submitted'
                      '${assignment.submissionPending > 0 ? ' · ${assignment.submissionPending} to review' : ''}',
                  icon: Icons.inbox_rounded,
                  color: assignment.submissionPending > 0 ? CT.warn : CT.primary,
                )
              else
                CommunityChip(
                  label: assignment.studentStatusLabel,
                  icon: assignment.mySubmission == null
                      ? Icons.pending_outlined
                      : (graded != null
                          ? Icons.verified_rounded
                          : Icons.hourglass_top_rounded),
                  color: graded != null
                      ? CT.primary
                      : (assignment.mySubmission != null ? CT.warn : CT.textHint),
                ),
            ],
          ),
          if (!isTeacher) ...[
            if (graded != null) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: CT.primary.withOpacity(0.07),
                  borderRadius: CT.r12,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.emoji_events_rounded,
                            size: 18, color: CT.primary),
                        const SizedBox(width: 8),
                        Text(
                          '${_fmt(graded.score)} / ${assignment.maxMarks}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: CT.textOf(context),
                          ),
                        ),
                        const Spacer(),
                        Text(
                          'Returned ${CT.timeAgo(graded.gradedAt)}',
                          style:
                              TextStyle(fontSize: 10.5, color: CT.subTextOf(context)),
                        ),
                      ],
                    ),
                    if (graded.feedback.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        graded.feedback,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.5,
                          color: CT.subTextOf(context),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ] else if (assignment.needsGroup) ...[
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: CT.warn.withOpacity(0.08),
                  borderRadius: CT.r12,
                  border: Border.all(color: CT.warn.withOpacity(0.25)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.info_outline_rounded,
                            size: 16, color: CT.warn),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'You are not in a group yet',
                            style: TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w800,
                              color: CT.textOf(context),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: () => showCreateGroupSheet(
                              context,
                              ref,
                              courseId,
                              assignmentId: assignment.id,
                              suggestedName: assignment.title,
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: CT.warn,
                              side: const BorderSide(color: CT.warn),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: const RoundedRectangleBorder(
                                  borderRadius: CT.r12),
                            ),
                            child: const Text('Create a group'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                if (assignment.myGroup != null) ...[
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => openGroupWorkspace(
                          context, courseId, assignment.myGroup!.id),
                      icon: const Icon(Icons.groups_2_rounded, size: 16),
                      label: Text(
                        assignment.myGroup!.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: CT.accent,
                        side: const BorderSide(color: CT.accent),
                        padding: const EdgeInsets.symmetric(vertical: 11),
                        shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                ],
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: (assignment.isOverdue &&
                                !assignment.allowLateSubmission) ||
                            (assignment.isGroupAssignment &&
                                assignment.myGroup == null)
                        ? null
                        : () => _submit(context, ref),
                    icon: Icon(
                      assignment.mySubmission == null
                          ? Icons.upload_rounded
                          : Icons.refresh_rounded,
                      size: 16,
                    ),
                    label: Text(assignment.mySubmission == null
                        ? 'Submit work'
                        : 'Resubmit'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: CT.primary,
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
          ],
        ],
      ),
    );
  }

  static String _fmt(double value) =>
      value.truncateToDouble() == value ? value.toInt().toString() : value.toStringAsFixed(1);

  Future<void> _submit(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Submit "${assignment.title}"',
      initialSize: 0.65,
      builder: (ctx, controller) => _SubmitForm(
        courseId: courseId,
        assignment: assignment,
        scrollController: controller,
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Teacher: create assignment
// ─────────────────────────────────────────────

class _AssignmentForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;

  const _AssignmentForm({required this.courseId, required this.scrollController});

  @override
  ConsumerState<_AssignmentForm> createState() => _AssignmentFormState();
}

class _AssignmentFormState extends ConsumerState<_AssignmentForm> {
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _marksController = TextEditingController(text: '20');

  bool _isGroup = false;
  int _minGroupSize = 2;
  int _maxGroupSize = 6;
  DateTime? _dueDate;
  bool _allowLate = false;
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _marksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      setState(() => _error = 'Give the assignment a title.');
      return;
    }
    if (_dueDate == null) {
      setState(() => _error = 'Pick a deadline.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(communityActionsProvider).createAssignment(
            widget.courseId,
            title: _titleController.text.trim(),
            description: _descriptionController.text.trim(),
            type: _isGroup ? 'group' : 'individual',
            dueDate: _dueDate!,
            maxMarks: int.tryParse(_marksController.text.trim()) ?? 20,
            minGroupSize: _minGroupSize,
            maxGroupSize: _maxGroupSize,
            allowLateSubmission: _allowLate,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      communitySnack(context, 'Assignment published — students notified');
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
              communityTextField(
                context: context,
                controller: _titleController,
                label: 'Title',
                hint: 'e.g. Financial Management Case Study',
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _descriptionController,
                label: 'Instructions',
                hint: 'What should students analyse, produce and hand in?',
                maxLines: 5,
              ),
              const SizedBox(height: 18),
              Text(
                'Type',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _TypeOption(
                      label: 'Individual',
                      icon: Icons.person_rounded,
                      selected: !_isGroup,
                      onTap: () => setState(() => _isGroup = false),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _TypeOption(
                      label: 'Group work',
                      icon: Icons.groups_rounded,
                      selected: _isGroup,
                      onTap: () => setState(() => _isGroup = true),
                    ),
                  ),
                ],
              ),
              if (_isGroup) ...[
                const SizedBox(height: 16),
                Text(
                  'Group size: $_minGroupSize – $_maxGroupSize students',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: CT.subTextOf(context),
                  ),
                ),
                RangeSlider(
                  values: RangeValues(_minGroupSize.toDouble(), _maxGroupSize.toDouble()),
                  min: 2,
                  max: 12,
                  divisions: 10,
                  activeColor: CT.primary,
                  labels: RangeLabels('$_minGroupSize', '$_maxGroupSize'),
                  onChanged: (values) => setState(() {
                    _minGroupSize = values.start.round();
                    _maxGroupSize = values.end.round();
                  }),
                ),
              ],
              const SizedBox(height: 14),
              InkWell(
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date == null || !mounted) return;
                  final time = await showTimePicker(
                    context: context,
                    initialTime: const TimeOfDay(hour: 23, minute: 59),
                  );
                  setState(() => _dueDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        time?.hour ?? 23,
                        time?.minute ?? 59,
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
                      const Icon(Icons.event_rounded, size: 18, color: CT.primary),
                      const SizedBox(width: 11),
                      Text(
                        _dueDate == null
                            ? 'Set the deadline'
                            : CT.formatDateTime(_dueDate),
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _dueDate == null
                              ? CT.subTextOf(context)
                              : CT.textOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _marksController,
                label: 'Maximum marks',
                hint: '20',
                keyboardType: TextInputType.number,
              ),
              SwitchListTile.adaptive(
                value: _allowLate,
                onChanged: (value) => setState(() => _allowLate = value),
                activeColor: CT.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Allow late submissions',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CT.textOf(context),
                  ),
                ),
                subtitle: Text(
                  'Late work is flagged so you can still see who missed the deadline.',
                  style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
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
          label: 'Publish assignment',
          onSubmit: _submit,
        ),
      ],
    );
  }
}

class _TypeOption extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TypeOption({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: CT.r12,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? CT.primary.withOpacity(0.1) : CT.cardOf(context),
          borderRadius: CT.r12,
          border: Border.all(
            color: selected ? CT.primary : CT.borderOf(context),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, size: 20, color: selected ? CT.primary : CT.subTextOf(context)),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? CT.primary : CT.textOf(context),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Student: submit work
// ─────────────────────────────────────────────

class _SubmitForm extends ConsumerStatefulWidget {
  final String courseId;
  final CommunityAssignment assignment;
  final ScrollController scrollController;

  const _SubmitForm({
    required this.courseId,
    required this.assignment,
    required this.scrollController,
  });

  @override
  ConsumerState<_SubmitForm> createState() => _SubmitFormState();
}

class _SubmitFormState extends ConsumerState<_SubmitForm> {
  final _linkController = TextEditingController();
  final _nameController = TextEditingController();
  final _commentController = TextEditingController();
  final List<CommunityAttachment> _files = [];
  bool _isSubmitting = false;
  String? _error;

  @override
  void dispose() {
    _linkController.dispose();
    _nameController.dispose();
    _commentController.dispose();
    super.dispose();
  }

  void _addFile() {
    final url = _linkController.text.trim();
    if (url.isEmpty) {
      setState(() => _error = 'Paste the link to your work first.');
      return;
    }
    setState(() {
      _files.add(CommunityAttachment(
        name: _nameController.text.trim().isEmpty
            ? url.split('/').last
            : _nameController.text.trim(),
        url: url,
      ));
      _linkController.clear();
      _nameController.clear();
      _error = null;
    });
  }

  Future<void> _submit() async {
    if (_files.isEmpty) {
      setState(() => _error = 'Attach at least one file or link.');
      return;
    }
    setState(() {
      _isSubmitting = true;
      _error = null;
    });
    try {
      await ref.read(communityActionsProvider).submitAssignment(
            widget.courseId,
            widget.assignment.id,
            groupId: widget.assignment.isGroupAssignment
                ? widget.assignment.myGroup?.id
                : null,
            comment: _commentController.text.trim(),
            files: _files,
          );
      if (!mounted) return;
      Navigator.of(context).pop();
      communitySnack(context, 'Submitted to your teacher');
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
              if (widget.assignment.isGroupAssignment &&
                  widget.assignment.myGroup != null)
                CommunityCard(
                  accent: CT.accent,
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 17, color: CT.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Submitting for ${widget.assignment.myGroup!.name} · '
                          '${widget.assignment.myGroup!.memberCount} members',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: CT.textOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                'Attach your work',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Paste a link to your document (Drive, OneDrive, or a file you '
                'already uploaded).',
                style: TextStyle(
                  fontSize: 11.5,
                  height: 1.4,
                  color: CT.subTextOf(context),
                ),
              ),
              const SizedBox(height: 10),
              communityTextField(
                context: context,
                controller: _linkController,
                label: 'Link',
                hint: 'https://…',
                keyboardType: TextInputType.url,
              ),
              const SizedBox(height: 10),
              communityTextField(
                context: context,
                controller: _nameController,
                label: 'File name (optional)',
                hint: 'Financial_Case_Study.pdf',
              ),
              const SizedBox(height: 10),
              Align(
                alignment: Alignment.centerLeft,
                child: OutlinedButton.icon(
                  onPressed: _addFile,
                  icon: const Icon(Icons.attach_file_rounded, size: 16),
                  label: const Text('Add attachment'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CT.primary,
                    side: const BorderSide(color: CT.primary),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                ),
              ),
              if (_files.isNotEmpty) ...[
                const SizedBox(height: 14),
                ..._files.asMap().entries.map((entry) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: CommunityCard(
                        padding: const EdgeInsets.all(11),
                        child: Row(
                          children: [
                            const Icon(Icons.description_rounded,
                                size: 16, color: CT.info),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                entry.value.name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: CT.textOf(context),
                                ),
                              ),
                            ),
                            IconButton(
                              onPressed: () =>
                                  setState(() => _files.removeAt(entry.key)),
                              icon: const Icon(Icons.close_rounded, size: 16),
                              color: CT.textHint,
                              visualDensity: VisualDensity.compact,
                            ),
                          ],
                        ),
                      ),
                    )),
              ],
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _commentController,
                label: 'Note to your teacher (optional)',
                hint: 'e.g. We have completed our analysis.',
                maxLines: 3,
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
          label: 'Submit to teacher',
          onSubmit: _submit,
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Teacher: review queue
// ─────────────────────────────────────────────

class _SubmissionQueue extends ConsumerWidget {
  final String courseId;

  const _SubmissionQueue({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final submissionsAsync = ref.watch(communitySubmissionsProvider(courseId));

    return submissionsAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
      ),
      error: (error, _) => CommunityErrorView(
        error: error,
        onRetry: () => ref.invalidate(communitySubmissionsProvider(courseId)),
      ),
      data: (submissions) {
        if (submissions.isEmpty) {
          return const CommunityEmpty(
            icon: Icons.inbox_rounded,
            title: 'No submissions yet',
            message: 'Work students hand in appears here, newest first, ready '
                'for you to grade.',
          );
        }
        return RefreshIndicator(
          color: CT.primary,
          onRefresh: () async =>
              ref.invalidate(communitySubmissionsProvider(courseId)),
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: submissions.length,
            itemBuilder: (context, index) => Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: _ReviewCard(
                courseId: courseId,
                submission: submissions[index],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _ReviewCard extends ConsumerWidget {
  final String courseId;
  final AssignmentSubmission submission;

  const _ReviewCard({required this.courseId, required this.submission});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final graded = submission.grade != null;

    return CommunityCard(
      accent: graded ? CT.primary : CT.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      submission.assignmentTitle ?? 'Assignment',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      submission.groupName != null
                          ? '${submission.groupName} · ${submission.members.length} students'
                          : (submission.submittedBy?.fullName ?? 'Student'),
                      style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                    ),
                  ],
                ),
              ),
              CommunityChip(
                label: graded ? 'Graded' : 'Awaiting review',
                icon: graded
                    ? Icons.verified_rounded
                    : Icons.hourglass_top_rounded,
                color: graded ? CT.primary : CT.warn,
              ),
            ],
          ),
          const SizedBox(height: 11),
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
                      const Icon(Icons.description_rounded, size: 14, color: CT.info),
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
          if (submission.comment.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '"${submission.comment}"',
              style: TextStyle(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                height: 1.45,
                color: CT.subTextOf(context),
              ),
            ),
          ],
          if (graded) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: CT.primary.withOpacity(0.07),
                borderRadius: CT.r12,
              ),
              child: Row(
                children: [
                  const Icon(Icons.star_rounded, size: 17, color: CT.primary),
                  const SizedBox(width: 8),
                  Text(
                    '${submission.grade!.score}'
                    '${submission.assignmentMaxMarks != null ? ' / ${submission.assignmentMaxMarks}' : ''}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CT.textOf(context),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _grade(context, ref),
              icon: Icon(graded ? Icons.edit_rounded : Icons.rate_review_rounded,
                  size: 16),
              label: Text(graded ? 'Update grade' : 'Review & grade'),
              style: ElevatedButton.styleFrom(
                backgroundColor: graded ? CT.surfaceOf(context) : CT.primary,
                foregroundColor: graded ? CT.textOf(context) : Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: const RoundedRectangleBorder(borderRadius: CT.r12),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _grade(BuildContext context, WidgetRef ref) async {
    final scoreController = TextEditingController(
      text: submission.grade?.score.toString() ?? '',
    );
    final feedbackController =
        TextEditingController(text: submission.grade?.feedback ?? '');
    var isBusy = false;

    await showCommunitySheet<void>(
      context: context,
      title: 'Grade submission',
      initialSize: 0.6,
      builder: (ctx, controller) => StatefulBuilder(
        builder: (ctx, setSheetState) => Column(
          children: [
            Expanded(
              child: ListView(
                controller: controller,
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                children: [
                  Text(
                    submission.groupName != null
                        ? 'Group: ${submission.groupName}'
                        : (submission.submittedBy?.fullName ?? 'Student'),
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: CT.textOf(ctx),
                    ),
                  ),
                  if (submission.members.isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Wrap(
                      spacing: 7,
                      runSpacing: 7,
                      children: submission.members
                          .map((m) => CommunityChip(
                                label: m.fullName,
                                icon: Icons.check_rounded,
                              ))
                          .toList(),
                    ),
                  ],
                  const SizedBox(height: 18),
                  communityTextField(
                    context: ctx,
                    controller: scoreController,
                    label: 'Score'
                        '${submission.assignmentMaxMarks != null ? ' (out of ${submission.assignmentMaxMarks})' : ''}',
                    hint: '18',
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 14),
                  communityTextField(
                    context: ctx,
                    controller: feedbackController,
                    label: 'Feedback',
                    hint: 'What was strong, and what should improve next time?',
                    maxLines: 5,
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Every member of this submission receives the score and your '
                    'feedback as a notification.',
                    style: TextStyle(
                      fontSize: 11.5,
                      height: 1.45,
                      color: CT.subTextOf(ctx),
                    ),
                  ),
                ],
              ),
            ),
            CommunitySheetFooter(
              isBusy: isBusy,
              label: 'Return to students',
              onSubmit: () async {
                final score = double.tryParse(scoreController.text.trim());
                if (score == null) {
                  communitySnack(ctx, 'Enter a numeric score', isError: true);
                  return;
                }
                setSheetState(() => isBusy = true);
                try {
                  await ref.read(communityActionsProvider).gradeSubmission(
                        courseId,
                        submission.id,
                        score: score,
                        feedback: feedbackController.text.trim(),
                      );
                  if (ctx.mounted) Navigator.of(ctx).pop();
                  if (context.mounted) {
                    communitySnack(context, 'Grade returned to students');
                  }
                } catch (e) {
                  setSheetState(() => isBusy = false);
                  if (ctx.mounted) {
                    communitySnack(ctx, e.toString(), isError: true);
                  }
                }
              },
            ),
          ],
        ),
      ),
    );

    scoreController.dispose();
    feedbackController.dispose();
  }
}
