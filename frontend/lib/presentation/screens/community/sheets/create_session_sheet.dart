import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../providers/community_provider.dart';
import '../community_theme.dart';
import 'create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// Schedules a study session.
///
/// Pass [lockedGroupId] to scope it to one study group — the group workspace
/// uses this so a team can plan a meeting without leaving their own screen,
/// and every active member is notified the moment it is created.
Future<bool> showCreateSessionSheet(
  BuildContext context,
  String courseId, {
  String? lockedGroupId,
  String? lockedGroupName,
}) async {
  final created = await showCommunitySheet<bool>(
    context: context,
    title: lockedGroupName == null
        ? 'Create study session'
        : 'Session for $lockedGroupName',
    initialSize: 0.8,
    builder: (ctx, controller) => _CreateSessionForm(
      courseId: courseId,
      scrollController: controller,
      lockedGroupId: lockedGroupId,
      lockedGroupName: lockedGroupName,
    ),
  );
  return created == true;
}

class _CreateSessionForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;
  final String? lockedGroupId;
  final String? lockedGroupName;

  const _CreateSessionForm({
    required this.courseId,
    required this.scrollController,
    this.lockedGroupId,
    this.lockedGroupName,
  });

  @override
  ConsumerState<_CreateSessionForm> createState() => _CreateSessionFormState();
}

class _CreateSessionFormState extends ConsumerState<_CreateSessionForm> {
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

  /// True when the sheet was opened from a group's workspace, in which case
  /// the group is fixed rather than something to pick.
  bool get _isGroupLocked => widget.lockedGroupId != null;

  @override
  void initState() {
    super.initState();
    _groupId = widget.lockedGroupId;
  }

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
      Navigator.of(context).pop(true);
      communitySnack(
        context,
        _groupId != null
            ? 'Session created — every group member has been notified'
            : 'Study session created',
      );
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
              // Opened from a group workspace the group is fixed, so show what
              // it is rather than asking the organiser to pick it again.
              if (_isGroupLocked)
                CommunityCard(
                  accent: CT.accent,
                  padding: const EdgeInsets.all(13),
                  child: Row(
                    children: [
                      const Icon(Icons.groups_rounded, size: 17, color: CT.accent),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Every active member of ${widget.lockedGroupName ?? 'this group'} '
                          'will be notified as soon as you create it.',
                          style: TextStyle(
                            fontSize: 11.5,
                            height: 1.45,
                            color: CT.subTextOf(context),
                          ),
                        ),
                      ),
                    ],
                  ),
                )
              else
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
