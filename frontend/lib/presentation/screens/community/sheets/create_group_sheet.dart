import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../models/community.dart';
import '../../../providers/community_provider.dart';
import '../community_theme.dart';
import 'create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// "Create study group" flow — name, purpose, size, and an inline classmate
/// picker so a group can be formed and staffed in one pass.
///
/// Returns `true` when a group was created.
Future<bool> showCreateGroupSheet(
  BuildContext context,
  WidgetRef ref,
  String courseId, {
  String? assignmentId,
  String? suggestedName,
  List<String> preselectedMemberIds = const [],
}) async {
  final result = await showCommunitySheet<bool>(
    context: context,
    title: 'Create study group',
    initialSize: 0.85,
    builder: (ctx, controller) => _CreateGroupForm(
      courseId: courseId,
      scrollController: controller,
      assignmentId: assignmentId,
      suggestedName: suggestedName,
      preselectedMemberIds: preselectedMemberIds,
    ),
  );
  return result == true;
}

class _CreateGroupForm extends ConsumerStatefulWidget {
  final String courseId;
  final ScrollController scrollController;
  final String? assignmentId;
  final String? suggestedName;
  final List<String> preselectedMemberIds;

  const _CreateGroupForm({
    required this.courseId,
    required this.scrollController,
    this.assignmentId,
    this.suggestedName,
    this.preselectedMemberIds = const [],
  });

  @override
  ConsumerState<_CreateGroupForm> createState() => _CreateGroupFormState();
}

class _CreateGroupFormState extends ConsumerState<_CreateGroupForm> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _searchController = TextEditingController();

  String _purpose = 'exam_prep';
  int _maxMembers = 6;
  bool _isOpen = true;
  bool _isSubmitting = false;
  String? _error;
  late final Set<String> _invited = {...widget.preselectedMemberIds};
  String _search = '';

  @override
  void initState() {
    super.initState();
    if (widget.suggestedName != null) _nameController.text = widget.suggestedName!;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _error = 'Give your group a name.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _error = null;
    });

    try {
      await ref.read(communityActionsProvider).createGroup(
            widget.courseId,
            name: name,
            purpose: _purpose,
            description: _descriptionController.text.trim(),
            maxMembers: _maxMembers,
            inviteUserIds: _invited.toList(),
            isOpen: _isOpen,
          );
      if (!mounted) return;
      Navigator.of(context).pop(true);
      communitySnack(
        context,
        _invited.isEmpty
            ? 'Group created'
            : 'Group created — ${_invited.length} classmate(s) invited',
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
    final membersAsync = ref.watch(
      communityMembersProvider(
        MemberQuery(widget.courseId, search: _search, filter: 'students'),
      ),
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
                controller: _nameController,
                label: 'Group name',
                hint: 'e.g. Financial Management Revision',
              ),
              const SizedBox(height: 16),
              Text(
                'Purpose',
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
                children: groupPurposeLabels.entries.map((entry) {
                  final selected = _purpose == entry.key;
                  return ChoiceChip(
                    selected: selected,
                    onSelected: (_) => setState(() => _purpose = entry.key),
                    label: Text(entry.value),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
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
                controller: _descriptionController,
                label: 'What will you work on?',
                hint: 'e.g. Revise chapters 1–5 together before the August exam.',
                maxLines: 3,
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Text(
                    'Maximum members',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CT.subTextOf(context),
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                    decoration: BoxDecoration(
                      color: CT.primary.withOpacity(0.12),
                      borderRadius: CT.r8,
                    ),
                    child: Text(
                      '$_maxMembers',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: CT.primary,
                      ),
                    ),
                  ),
                ],
              ),
              Slider(
                value: _maxMembers.toDouble(),
                min: 2,
                max: 20,
                divisions: 18,
                activeColor: CT.primary,
                label: '$_maxMembers',
                onChanged: (value) => setState(() => _maxMembers = value.round()),
              ),
              SwitchListTile.adaptive(
                value: _isOpen,
                onChanged: (value) => setState(() => _isOpen = value),
                activeColor: CT.primary,
                contentPadding: EdgeInsets.zero,
                title: Text(
                  'Open to anyone in the course',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: CT.textOf(context),
                  ),
                ),
                subtitle: Text(
                  _isOpen
                      ? 'Classmates can join directly from the Groups list.'
                      : 'Only people you invite can join.',
                  style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Text(
                    'Invite classmates',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: CT.subTextOf(context),
                    ),
                  ),
                  const Spacer(),
                  if (_invited.isNotEmpty)
                    CommunityChip(label: '${_invited.length} selected'),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _searchController,
                onChanged: (value) => setState(() => _search = value),
                style: TextStyle(fontSize: 13, color: CT.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Search classmates',
                  hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
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
                  focusedBorder: const OutlineInputBorder(
                    borderRadius: CT.r12,
                    borderSide: BorderSide(color: CT.primary, width: 1.5),
                  ),
                ),
              ),
              const SizedBox(height: 10),
              membersAsync.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 22),
                  child: Center(
                    child: SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                  ),
                ),
                error: (e, _) => Text(
                  'Could not load classmates.',
                  style: TextStyle(fontSize: 12, color: CT.subTextOf(context)),
                ),
                data: (directory) {
                  final selectable =
                      directory.members.where((m) => !m.isMe && !m.isTeacher).toList();
                  if (selectable.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      child: Text(
                        'No classmates match that search. You can always invite '
                        'people after creating the group.',
                        style: TextStyle(
                          fontSize: 12,
                          height: 1.4,
                          color: CT.subTextOf(context),
                        ),
                      ),
                    );
                  }
                  return Column(
                    children: selectable.take(30).map((member) {
                      final selected = _invited.contains(member.id);
                      // The owner takes one seat, so invitations stop one short.
                      final atCapacity =
                          !selected && _invited.length >= _maxMembers - 1;
                      return CheckboxListTile(
                        value: selected,
                        onChanged: atCapacity
                            ? null
                            : (value) => setState(() {
                                  if (value == true) {
                                    _invited.add(member.id);
                                  } else {
                                    _invited.remove(member.id);
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
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    member.fullName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: CT.textOf(context),
                                    ),
                                  ),
                                  Text(
                                    member.presence.label,
                                    style: TextStyle(
                                      fontSize: 10.5,
                                      color: member.presence.isActive
                                          ? CT.primary
                                          : CT.subTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    }).toList(),
                  );
                },
              ),
              if (_error != null) ...[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: const TextStyle(fontSize: 12, color: CT.danger),
                ),
              ],
            ],
          ),
        ),
        CommunitySheetFooter(
          isBusy: _isSubmitting,
          label: 'Create group',
          onSubmit: _submit,
        ),
      ],
    );
  }
}
