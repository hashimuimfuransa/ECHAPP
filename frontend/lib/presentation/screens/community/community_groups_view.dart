import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_dashboard_view.dart' show GroupTile;
import 'community_theme.dart';
import 'group_workspace_screen.dart';
import 'sheets/create_group_sheet.dart';

/// Study groups: the ones I belong to, and the ones I could join.
class CommunityGroupsView extends ConsumerStatefulWidget {
  final String courseId;

  const CommunityGroupsView({super.key, required this.courseId});

  @override
  ConsumerState<CommunityGroupsView> createState() => _CommunityGroupsViewState();
}

class _CommunityGroupsViewState extends ConsumerState<CommunityGroupsView> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final allAsync = ref.watch(
      communityGroupsProvider(GroupQuery(widget.courseId, search: _search)),
    );

    return Stack(
      children: [
        Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
              child: TextField(
                onChanged: (value) => setState(() => _search = value),
                style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Search study groups',
                  hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
                  prefixIcon: const Icon(Icons.search_rounded, size: 19),
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
            Expanded(
              child: allAsync.when(
                loading: () => const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
                ),
                error: (error, _) => CommunityErrorView(
                  error: error,
                  onRetry: () => ref.invalidate(communityGroupsProvider),
                ),
                data: (groups) {
                  final mine = groups.where((g) => g.isMine).toList();
                  final invited = groups.where((g) => g.isInvited).toList();
                  final open = groups
                      .where((g) => !g.isMine && !g.isInvited && g.isOpen && !g.isFull)
                      .toList();
                  final others = groups
                      .where((g) =>
                          !g.isMine && !g.isInvited && (!g.isOpen || g.isFull))
                      .toList();

                  if (groups.isEmpty) {
                    return CommunityEmpty(
                      icon: Icons.workspaces_rounded,
                      title: 'No study groups yet',
                      message: 'Start the first one. Give it a purpose — exam prep, '
                          'an assignment, weekly revision — and invite classmates.',
                      actionLabel: 'Create a group',
                      onAction: () => showCreateGroupSheet(
                          context, ref, widget.courseId),
                    );
                  }

                  return RefreshIndicator(
                    color: CT.primary,
                    onRefresh: () async => ref.invalidate(communityGroupsProvider),
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
                      children: [
                        if (invited.isNotEmpty) ...[
                          const SectionHeader(
                            icon: Icons.mark_email_unread_rounded,
                            title: 'Invitations',
                            subtitle: 'Classmates want you on their team',
                          ),
                          const SizedBox(height: 10),
                          ...invited.map((group) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _JoinableGroupCard(
                                  courseId: widget.courseId,
                                  group: group,
                                  actionLabel: 'Accept',
                                ),
                              )),
                          const SizedBox(height: 18),
                        ],
                        SectionHeader(
                          icon: Icons.groups_2_rounded,
                          title: 'My groups',
                          subtitle: mine.isEmpty
                              ? 'You have not joined a group yet'
                              : '${mine.length} active',
                        ),
                        const SizedBox(height: 10),
                        if (mine.isEmpty)
                          const CommunityEmpty(
                            icon: Icons.group_add_rounded,
                            title: 'Not in a group yet',
                            message: 'Join an open group below, or create your own.',
                            compact: true,
                          )
                        else
                          ...mine.map((group) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: GroupTile(
                                  courseId: widget.courseId,
                                  group: group,
                                ),
                              )),
                        const SizedBox(height: 20),
                        SectionHeader(
                          icon: Icons.explore_rounded,
                          title: 'Open groups',
                          subtitle: open.isEmpty
                              ? 'No groups are open right now'
                              : '${open.length} accepting members',
                        ),
                        const SizedBox(height: 10),
                        if (open.isEmpty)
                          const CommunityEmpty(
                            icon: Icons.lock_outline_rounded,
                            title: 'Nothing open right now',
                            message: 'Create your own group and invite classmates.',
                            compact: true,
                          )
                        else
                          ...open.map((group) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _JoinableGroupCard(
                                  courseId: widget.courseId,
                                  group: group,
                                  actionLabel: 'Join',
                                ),
                              )),
                        if (others.isNotEmpty) ...[
                          const SizedBox(height: 20),
                          const SectionHeader(
                            icon: Icons.lock_rounded,
                            title: 'Other groups',
                            subtitle: 'Full or invite-only',
                          ),
                          const SizedBox(height: 10),
                          ...others.map((group) => Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _JoinableGroupCard(
                                  courseId: widget.courseId,
                                  group: group,
                                  actionLabel:
                                      group.isFull ? 'Full' : 'Request',
                                  enabled: !group.isFull,
                                ),
                              )),
                        ],
                      ],
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
            heroTag: 'community-new-group',
            onPressed: () => showCreateGroupSheet(context, ref, widget.courseId),
            backgroundColor: CT.primary,
            foregroundColor: Colors.white,
            icon: const Icon(Icons.group_add_rounded),
            label: const Text('New group'),
          ),
        ),
      ],
    );
  }
}

class _JoinableGroupCard extends ConsumerStatefulWidget {
  final String courseId;
  final StudyGroupSummary group;
  final String actionLabel;
  final bool enabled;

  const _JoinableGroupCard({
    required this.courseId,
    required this.group,
    required this.actionLabel,
    this.enabled = true,
  });

  @override
  ConsumerState<_JoinableGroupCard> createState() => _JoinableGroupCardState();
}

class _JoinableGroupCardState extends ConsumerState<_JoinableGroupCard> {
  bool _isBusy = false;

  Future<void> _join() async {
    setState(() => _isBusy = true);
    try {
      final status = await ref
          .read(communityActionsProvider)
          .joinGroup(widget.courseId, widget.group.id);
      if (!mounted) return;
      communitySnack(
        context,
        status == 'active' ? 'You joined ${widget.group.name}' : 'Request sent',
      );
      if (status == 'active' && mounted) {
        openGroupWorkspace(context, widget.courseId, widget.group.id);
      }
    } catch (e) {
      if (mounted) communitySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final group = widget.group;
    return CommunityCard(
      padding: const EdgeInsets.all(14),
      accent: group.isInvited ? CT.warn : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: CT.avatarColor(group.id).withOpacity(0.15),
                  borderRadius: CT.r12,
                ),
                child: Icon(Icons.groups_2_rounded,
                    color: CT.avatarColor(group.id), size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      group.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CT.textOf(context),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${group.purposeLabel} · '
                      '${group.memberCount}/${group.maxMembers} members',
                      style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (group.description.isNotEmpty) ...[
            const SizedBox(height: 11),
            Text(
              group.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.45,
                color: CT.subTextOf(context),
              ),
            ),
          ],
          const SizedBox(height: 13),
          Row(
            children: [
              if (group.memberPreview.isNotEmpty)
                MemberStack(members: group.memberPreview),
              const Spacer(),
              SizedBox(
                height: 34,
                child: ElevatedButton(
                  onPressed: widget.enabled && !_isBusy ? _join : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor: CT.surfaceOf(context),
                    disabledForegroundColor: CT.textHint,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    textStyle: const TextStyle(
                        fontSize: 12.5, fontWeight: FontWeight.w800),
                  ),
                  child: _isBusy
                      ? const SizedBox(
                          width: 15,
                          height: 15,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : Text(widget.actionLabel),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
