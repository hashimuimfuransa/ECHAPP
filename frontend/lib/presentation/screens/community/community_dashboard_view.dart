import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_section.dart';
import 'community_theme.dart';
import 'group_workspace_screen.dart';
import 'member_profile_sheet.dart';
import 'sheets/create_group_sheet.dart';
import 'sheets/create_post_sheet.dart';

/// The Community dashboard — the "heart" of the course community.
///
/// Answers, in one screen: who else is studying this, who can I work with,
/// what is everyone discussing, and what is due. Every block links deeper
/// into a dedicated section via [onOpenSection].
class CommunityDashboardView extends ConsumerStatefulWidget {
  final String courseId;
  final void Function(CommunitySection section) onOpenSection;

  /// Embedded inside the learning screen's Community tab, the dashboard drops
  /// its own padding at the top so it sits flush under the tab bar.
  final bool embedded;

  const CommunityDashboardView({
    super.key,
    required this.courseId,
    required this.onOpenSection,
    this.embedded = false,
  });

  @override
  ConsumerState<CommunityDashboardView> createState() => _CommunityDashboardViewState();
}

class _CommunityDashboardViewState extends ConsumerState<CommunityDashboardView> {
  @override
  void initState() {
    super.initState();
    // Announce this member as active so classmates can see them right away.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) ref.read(communityPresenceProvider(widget.courseId)).start();
    });
  }

  Future<void> _refresh() async {
    ref.invalidate(communityOverviewProvider(widget.courseId));
    await ref.read(communityOverviewProvider(widget.courseId).future);
  }

  @override
  Widget build(BuildContext context) {
    final overviewAsync = ref.watch(communityOverviewProvider(widget.courseId));

    return overviewAsync.when(
      loading: () => const _DashboardSkeleton(),
      error: (error, _) => CommunityErrorView(
        error: error,
        onRetry: () => ref.invalidate(communityOverviewProvider(widget.courseId)),
      ),
      data: (overview) => RefreshIndicator(
        onRefresh: _refresh,
        color: CT.primary,
        child: ListView(
          padding: EdgeInsets.fromLTRB(16, widget.embedded ? 12 : 16, 16, 90),
          children: [
            _Header(
              overview: overview,
              // Embedded in the learning screen, the header doubles as the way
              // out to the full-page community.
              onOpenFull: widget.embedded
                  ? () => widget.onOpenSection(CommunitySection.home)
                  : null,
            ),
            const SizedBox(height: 14),
            _QuickActions(
              overview: overview,
              courseId: widget.courseId,
              onOpenSection: widget.onOpenSection,
            ),
            const SizedBox(height: 20),
            if (overview.teachers.isNotEmpty) ...[
              _TeacherStrip(overview: overview, courseId: widget.courseId),
              const SizedBox(height: 20),
            ],
            if (overview.pinnedPosts.isNotEmpty) ...[
              _PinnedStrip(
                posts: overview.pinnedPosts,
                courseId: widget.courseId,
                onOpen: () => widget.onOpenSection(CommunitySection.discussions),
              ),
              const SizedBox(height: 20),
            ],
            _StudyingNow(
              overview: overview,
              courseId: widget.courseId,
              onViewAll: () => widget.onOpenSection(CommunitySection.people),
            ),
            const SizedBox(height: 20),
            _MyGroups(
              overview: overview,
              courseId: widget.courseId,
              onViewAll: () => widget.onOpenSection(CommunitySection.groups),
            ),
            const SizedBox(height: 20),
            _AssignmentsBlock(
              overview: overview,
              onViewAll: () => widget.onOpenSection(CommunitySection.work),
            ),
            const SizedBox(height: 20),
            _DiscussionsBlock(
              overview: overview,
              courseId: widget.courseId,
              onViewAll: () => widget.onOpenSection(CommunitySection.discussions),
            ),
            if (overview.nextSession != null) ...[
              const SizedBox(height: 20),
              _NextSession(
                session: overview.nextSession!,
                onOpen: () => widget.onOpenSection(CommunitySection.resources),
              ),
            ],
            if (widget.embedded) ...[
              const SizedBox(height: 22),
              _OpenFullCommunityButton(
                onTap: () => widget.onOpenSection(CommunitySection.home),
              ),
            ],
            const SizedBox(height: 24),
            _Tagline(courseTitle: overview.courseTitle),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Header
// ─────────────────────────────────────────────

class _Header extends StatelessWidget {
  final CommunityOverview overview;

  /// Set only when the dashboard is embedded — opens the full-page community.
  final VoidCallback? onOpenFull;

  const _Header({required this.overview, this.onOpenFull});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final stats = overview.stats;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: CT.heroGrad,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: CT.r20,
        boxShadow: [
          BoxShadow(
            color: CT.primary.withOpacity(0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: CT.r12,
                ),
                child: const Icon(Icons.groups_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.courseCommunity,
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.4,
                        color: Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      overview.courseTitle,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              if (overview.isTeacher)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.22),
                    borderRadius: CT.r8,
                  ),
                  child: Text(
                    l10n.teacher.toUpperCase(),
                    style: TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
              if (onOpenFull != null) ...[
                const SizedBox(width: 6),
                Material(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: CT.r12,
                  child: InkWell(
                    onTap: onOpenFull,
                    borderRadius: CT.r12,
                    child: const Padding(
                      padding: EdgeInsets.all(9),
                      child: Icon(Icons.open_in_full_rounded,
                          size: 17, color: Colors.white),
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.16),
              borderRadius: CT.r12,
            ),
            child: Row(
              children: [
                _HeaderStat(
                  value: '${stats.enrolledCount}',
                  label: stats.enrolledCount == 1 ? 'student' : 'students',
                  icon: Icons.people_alt_rounded,
                ),
                _divider(),
                _HeaderStat(
                  value: '${stats.activeCount}',
                  label: 'active now',
                  icon: Icons.circle,
                  iconSize: 9,
                ),
                _divider(),
                _HeaderStat(
                  value: '${stats.groupCount}',
                  label: stats.groupCount == 1 ? 'group' : 'groups',
                  icon: Icons.workspaces_rounded,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(
        width: 1,
        height: 26,
        margin: const EdgeInsets.symmetric(horizontal: 6),
        color: Colors.white24,
      );
}

class _HeaderStat extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final double iconSize;

  const _HeaderStat({
    required this.value,
    required this.label,
    required this.icon,
    this.iconSize = 13,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: iconSize, color: Colors.white),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    height: 1.1,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 1),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontSize: 10.5, color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Quick actions
// ─────────────────────────────────────────────

class _QuickActions extends ConsumerWidget {
  final CommunityOverview overview;
  final String courseId;
  final void Function(CommunitySection) onOpenSection;

  const _QuickActions({
    required this.overview,
    required this.courseId,
    required this.onOpenSection,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final actions = <Widget>[
      CommunityAction(
        icon: Icons.person_search_rounded,
        label: 'Find\nstudents',
        color: CT.info,
        onTap: () => onOpenSection(CommunitySection.people),
      ),
      CommunityAction(
        icon: Icons.group_add_rounded,
        label: 'Create\ngroup',
        color: CT.primary,
        onTap: () => _createGroup(context, ref),
      ),
      CommunityAction(
        icon: Icons.help_center_rounded,
        label: 'Ask a\nquestion',
        color: CT.warn,
        onTap: () => _ask(context, ref),
      ),
      CommunityAction(
        icon: Icons.forum_rounded,
        label: 'Course\nchat',
        color: CT.accent,
        badge: overview.stats.unreadChatCount,
        onTap: () => onOpenSection(CommunitySection.chat),
      ),
      if (overview.isTeacher)
        CommunityAction(
          icon: Icons.campaign_rounded,
          label: 'Post\nnotice',
          color: CT.danger,
          onTap: () => _announce(context, ref),
        )
      else
        CommunityAction(
          icon: Icons.edit_note_rounded,
          label: 'Start\npost',
          color: CT.danger,
          onTap: () => _post(context, ref),
        ),
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(children: actions),
    );
  }

  Future<void> _createGroup(BuildContext context, WidgetRef ref) async {
    final created = await showCreateGroupSheet(context, ref, courseId);
    if (created && context.mounted) onOpenSection(CommunitySection.groups);
  }

  Future<void> _ask(BuildContext context, WidgetRef ref) async {
    final created = await showCreatePostSheet(
      context,
      ref,
      courseId,
      initialType: CommunityPostType.question,
    );
    if (created && context.mounted) onOpenSection(CommunitySection.discussions);
  }

  Future<void> _post(BuildContext context, WidgetRef ref) async {
    final created = await showCreatePostSheet(context, ref, courseId);
    if (created && context.mounted) onOpenSection(CommunitySection.discussions);
  }

  Future<void> _announce(BuildContext context, WidgetRef ref) async {
    final created = await showCreatePostSheet(
      context,
      ref,
      courseId,
      initialType: CommunityPostType.announcement,
      isTeacher: true,
    );
    if (created && context.mounted) onOpenSection(CommunitySection.discussions);
  }
}

// ─────────────────────────────────────────────
//  Teacher strip
// ─────────────────────────────────────────────

class _TeacherStrip extends StatelessWidget {
  final CommunityOverview overview;
  final String courseId;

  const _TeacherStrip({required this.overview, required this.courseId});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CommunityCard(
      accent: CT.teacher,
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          const Icon(Icons.school_rounded, size: 18, color: CT.teacher),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  overview.teachers.length == 1 ? l10n.yourTeacher : l10n.yourTeachers,
                  style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                ),
                const SizedBox(height: 2),
                Text(
                  overview.teachers.map((t) => t.fullName).join(', '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CT.textOf(context),
                  ),
                ),
              ],
            ),
          ),
          // A single teacher stays tappable straight through to their profile;
          // several overlap in the shared avatar stack.
          if (overview.teachers.length == 1)
            GestureDetector(
              onTap: () => showMemberProfileSheet(
                  context, courseId, overview.teachers.first.id),
              child: MemberAvatar(member: overview.teachers.first, size: 34),
            )
          else
            MemberStack(members: overview.teachers, max: 3, size: 34),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Pinned announcements
// ─────────────────────────────────────────────

class _PinnedStrip extends StatelessWidget {
  final List<CommunityPost> posts;
  final String courseId;
  final VoidCallback onOpen;

  const _PinnedStrip({
    required this.posts,
    required this.courseId,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.push_pin_rounded,
          title: l10n.pinnedByTeacher,
          actionLabel: 'All',
          onAction: onOpen,
        ),
        const SizedBox(height: 10),
        ...posts.map((post) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: CommunityCard(
                accent: CT.warn,
                padding: const EdgeInsets.all(13),
                onTap: onOpen,
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: CT.warn.withOpacity(0.12),
                        borderRadius: CT.r8,
                      ),
                      child: const Icon(Icons.campaign_rounded,
                          size: 15, color: CT.warn),
                    ),
                    const SizedBox(width: 11),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            post.title ?? l10n.announcement,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: CT.textOf(context),
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            post.content,
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
                    Icon(Icons.chevron_right_rounded,
                        size: 18, color: CT.subTextOf(context)),
                  ],
                ),
              ),
            )),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  Students learning now
// ─────────────────────────────────────────────

class _StudyingNow extends StatelessWidget {
  final CommunityOverview overview;
  final String courseId;
  final VoidCallback onViewAll;

  const _StudyingNow({
    required this.overview,
    required this.courseId,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final members = overview.activeMembers;
    final stats = overview.stats;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.bolt_rounded,
          title: l10n.studentsLearningNow,
          subtitle:
              '${stats.enrolledCount} enrolled · ${stats.activeCount} active right now',
          actionLabel: 'View all',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (members.isEmpty)
          CommunityCard(
            padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: CT.info.withOpacity(0.1),
                    borderRadius: CT.r12,
                  ),
                  child: const Icon(Icons.nightlight_round,
                      size: 18, color: CT.info),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Nobody else is studying right now — you are ahead of the class. '
                    'Leave a question and classmates will find it later.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.45,
                      color: CT.subTextOf(context),
                    ),
                  ),
                ),
              ],
            ),
          )
        else
          SizedBox(
            height: 104,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              itemCount: members.length,
              separatorBuilder: (_, __) => const SizedBox(width: 14),
              itemBuilder: (context, index) {
                final member = members[index];
                return InkWell(
                  onTap: () =>
                      showMemberProfileSheet(context, courseId, member.id),
                  borderRadius: CT.r12,
                  child: SizedBox(
                    width: 68,
                    child: Column(
                      children: [
                        MemberAvatar(member: member, size: 52),
                        const SizedBox(height: 7),
                        Text(
                          member.fullName.split(' ').first,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: CT.textOf(context),
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          member.presence.label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 9.5,
                            fontWeight: FontWeight.w600,
                            color: member.presence.isActive
                                ? CT.primary
                                : CT.subTextOf(context),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────
//  My groups
// ─────────────────────────────────────────────

class _MyGroups extends ConsumerWidget {
  final CommunityOverview overview;
  final String courseId;
  final VoidCallback onViewAll;

  const _MyGroups({
    required this.overview,
    required this.courseId,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final groups = overview.myGroups;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.workspaces_rounded,
          title: l10n.myGroups,
          subtitle: groups.isEmpty
              ? 'Work through the course with classmates'
              : '${groups.length} active ${groups.length == 1 ? 'group' : 'groups'}',
          actionLabel: 'Browse',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (groups.isEmpty)
          CommunityCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.notInGroupYet,
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: CT.textOf(context),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Groups give you a shared task list, a private chat and one place '
                  'to submit group assignments.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.45,
                    color: CT.subTextOf(context),
                  ),
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final created =
                              await showCreateGroupSheet(context, ref, courseId);
                          if (created && context.mounted) onViewAll();
                        },
                        icon: const Icon(Icons.add_rounded, size: 17),
                        label: const Text('Create group'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: CT.primary,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: onViewAll,
                        icon: const Icon(Icons.search_rounded, size: 17),
                        label: const Text('Find one'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: CT.primary,
                          side: const BorderSide(color: CT.primary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
        else
          ...groups.map((group) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: GroupTile(courseId: courseId, group: group),
              )),
      ],
    );
  }
}

/// Reused by the dashboard and the Groups section.
class GroupTile extends StatelessWidget {
  final String courseId;
  final StudyGroupSummary group;
  final VoidCallback? onTap;
  final Widget? trailing;

  const GroupTile({
    super.key,
    required this.courseId,
    required this.group,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap ?? () => openGroupWorkspace(context, courseId, group.id),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  CT.avatarColor(group.id),
                  CT.avatarColor(group.id).withOpacity(0.7),
                ],
              ),
              borderRadius: CT.r12,
            ),
            child: const Icon(Icons.groups_2_rounded, color: Colors.white, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        group.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CT.textOf(context),
                        ),
                      ),
                    ),
                    if (group.isOwner) ...[
                      const SizedBox(width: 6),
                      const CommunityChip(label: 'Owner', color: CT.accent),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  [
                    '${group.memberCount}/${group.maxMembers} members',
                    if (group.taskCount > 0)
                      '${group.openTaskCount} open ${group.openTaskCount == 1 ? 'task' : 'tasks'}',
                    group.purposeLabel,
                  ].join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                ),
                if (group.memberPreview.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  MemberStack(members: group.memberPreview),
                ],
              ],
            ),
          ),
          trailing ??
              Icon(Icons.chevron_right_rounded,
                  size: 20, color: CT.subTextOf(context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Assignments
// ─────────────────────────────────────────────

class _AssignmentsBlock extends StatelessWidget {
  final CommunityOverview overview;
  final VoidCallback onViewAll;

  const _AssignmentsBlock({required this.overview, required this.onViewAll});

  @override
  Widget build(BuildContext context) {
    final assignments = overview.upcomingAssignments;
    final pending = overview.stats.pendingCount;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.assignment_rounded,
          title: overview.isTeacher ? 'Coursework' : 'My assignments',
          subtitle: overview.isTeacher
              ? (pending == 0
                  ? 'Nothing waiting for review'
                  : '$pending submission${pending == 1 ? '' : 's'} awaiting review')
              : (pending == 0
                  ? 'You are up to date'
                  : '$pending open ${pending == 1 ? 'assignment' : 'assignments'}'),
          actionLabel: 'Open',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (assignments.isEmpty)
          CommunityCard(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(9),
                  decoration: BoxDecoration(
                    color: CT.primary.withOpacity(0.1),
                    borderRadius: CT.r12,
                  ),
                  child: const Icon(Icons.check_circle_rounded,
                      size: 18, color: CT.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    overview.isTeacher
                        ? 'No coursework published yet. Publish one from the Work tab.'
                        : 'No assignments are due right now.',
                    style: TextStyle(fontSize: 12.5, color: CT.subTextOf(context)),
                  ),
                ),
              ],
            ),
          )
        else
          ...assignments.take(3).map((a) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: CommunityCard(
                  padding: const EdgeInsets.all(13),
                  onTap: onViewAll,
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: (a.isGroupAssignment ? CT.accent : CT.info)
                              .withOpacity(0.12),
                          borderRadius: CT.r8,
                        ),
                        child: Icon(
                          a.isGroupAssignment
                              ? Icons.groups_rounded
                              : Icons.person_rounded,
                          size: 16,
                          color: a.isGroupAssignment ? CT.accent : CT.info,
                        ),
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              a.title,
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
                              '${a.isGroupAssignment ? 'Group work' : 'Individual'} · '
                              '${CT.dueLabel(context, a.dueDate)} · ${a.maxMarks} marks',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 11,
                                color: CT.subTextOf(context),
                              ),
                            ),
                          ],
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

// ─────────────────────────────────────────────
//  Discussions
// ─────────────────────────────────────────────

class _DiscussionsBlock extends ConsumerWidget {
  final CommunityOverview overview;
  final String courseId;
  final VoidCallback onViewAll;

  const _DiscussionsBlock({
    required this.overview,
    required this.courseId,
    required this.onViewAll,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final posts = overview.recentDiscussions;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(
          icon: Icons.chat_bubble_rounded,
          title: l10n.courseDiscussions,
          subtitle: '${overview.stats.discussionCount} threads in this course',
          actionLabel: 'View all',
          onAction: onViewAll,
        ),
        const SizedBox(height: 12),
        if (posts.isEmpty)
          CommunityEmpty(
            icon: Icons.forum_rounded,
            title: l10n.noDiscussionsYet,
            message: 'Be the first to ask something — a classmate or your teacher '
                'will pick it up.',
            actionLabel: l10n.startDiscussion,
            compact: true,
            onAction: () async {
              final created = await showCreatePostSheet(context, ref, courseId);
              if (created && context.mounted) onViewAll();
            },
          )
        else
          ...posts.map((post) => Padding(
                padding: const EdgeInsets.only(bottom: 9),
                child: DiscussionTile(post: post, onTap: onViewAll),
              )),
      ],
    );
  }
}

/// Compact discussion row, shared with the Discussions section.
class DiscussionTile extends StatelessWidget {
  final CommunityPost post;
  final VoidCallback onTap;

  const DiscussionTile({super.key, required this.post, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CommunityCard(
      padding: const EdgeInsets.all(13),
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.author != null) ...[
                MemberAvatar(member: post.author!, size: 26),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  post.author?.fullName ?? 'ECH Student',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: CT.subTextOf(context),
                  ),
                ),
              ),
              if (post.isByTeacher) const TeacherBadge(),
              if (post.isPinned) ...[
                const SizedBox(width: 5),
                const Icon(Icons.push_pin_rounded, size: 13, color: CT.warn),
              ],
            ],
          ),
          const SizedBox(height: 9),
          Text(
            post.title ?? post.content,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
              color: CT.textOf(context),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Icon(Icons.mode_comment_outlined,
                  size: 13, color: CT.subTextOf(context)),
              const SizedBox(width: 4),
              Text(
                '${post.replyCount}',
                style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
              ),
              const SizedBox(width: 12),
              Icon(Icons.favorite_border_rounded,
                  size: 13, color: CT.subTextOf(context)),
              const SizedBox(width: 4),
              Text(
                '${post.likeCount}',
                style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
              ),
              const Spacer(),
              if (post.hasTeacherAnswer)
                CommunityChip(
                  label: l10n.teacherAnswered,
                  icon: Icons.verified_rounded,
                  color: CT.teacher,
                )
              else if (post.isResolved)
                CommunityChip(
                  label: l10n.resolved,
                  icon: Icons.check_rounded,
                )
              else
                Text(
                  CT.timeAgo(context, post.lastActivityAt ?? post.createdAt),
                  style: TextStyle(fontSize: 10.5, color: CT.textHint),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Next session
// ─────────────────────────────────────────────

class _NextSession extends StatelessWidget {
  final StudySession session;
  final VoidCallback onOpen;

  const _NextSession({required this.session, required this.onOpen});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isLive = session.isLive;
    return CommunityCard(
      accent: isLive ? CT.danger : CT.accent,
      onTap: onOpen,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: isLive
                    ? [CT.danger, const Color(0xFFB91C1C)]
                    : CT.purpleGrad,
              ),
              borderRadius: CT.r12,
            ),
            child: Icon(
              isLive ? Icons.sensors_rounded : Icons.event_rounded,
              color: Colors.white,
              size: 19,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isLive ? l10n.studySessionLiveNow : l10n.nextStudySession,
                  style: TextStyle(
                    fontSize: 10.5,
                    fontWeight: isLive ? FontWeight.w800 : FontWeight.w500,
                    color: isLive ? CT.danger : CT.subTextOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  session.topic,
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
                  isLive
                      ? '${session.participantCount} in the room · tap to join'
                      : '${CT.formatDateTime(context, session.scheduledAt)} · '
                          '${session.participantCount} going',
                  style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                ),
              ],
            ),
          ),
          if (isLive)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(color: CT.danger, borderRadius: CT.r8),
              child: const Text(
                'LIVE',
                style: TextStyle(
                  fontSize: 9.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Bottom call-to-action shown only in the embedded (learning screen) view —
/// the dashboard is a summary, and this opens the full community with every
/// section: students, discussions, chat, groups, work and resources.
class _OpenFullCommunityButton extends StatelessWidget {
  final VoidCallback onTap;

  const _OpenFullCommunityButton({required this.onTap});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return CommunityCard(
      accent: CT.primary,
      onTap: onTap,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: CT.heroGrad),
              borderRadius: CT.r12,
            ),
            child: const Icon(Icons.open_in_full_rounded,
                size: 18, color: Colors.white),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  l10n.openFullCommunity,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: CT.textOf(context),
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  l10n.openFullCommunitySubtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 20, color: CT.subTextOf(context)),
        ],
      ),
    );
  }
}

class _Tagline extends StatelessWidget {
  final String courseTitle;
  const _Tagline({required this.courseTitle});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Center(
      child: Column(
        children: [
          Text(
            l10n.echCourseCommunity,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: CT.subTextOf(context),
            ),
          ),
          const SizedBox(height: 3),
          Text(
            l10n.communityTagline,
            style: TextStyle(fontSize: 11, color: CT.textHint),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Loading skeleton
// ─────────────────────────────────────────────

class _DashboardSkeleton extends StatelessWidget {
  const _DashboardSkeleton();

  @override
  Widget build(BuildContext context) {
    Widget block(double height) => Container(
          height: height,
          margin: const EdgeInsets.only(bottom: 14),
          decoration: BoxDecoration(
            color: CT.surfaceOf(context),
            borderRadius: CT.r16,
          ),
        );

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        block(128),
        block(70),
        block(110),
        block(96),
        block(96),
      ],
    );
  }
}
