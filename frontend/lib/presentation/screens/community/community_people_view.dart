import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import '../messages/direct_chat_screen.dart';
import 'community_theme.dart';
import 'member_profile_sheet.dart';
import 'sheets/create_post_sheet.dart' show communityTextField, CommunitySheetFooter;

/// "Students" section: the member directory plus Find Study Partners.
class CommunityPeopleView extends ConsumerStatefulWidget {
  final String courseId;

  const CommunityPeopleView({super.key, required this.courseId});

  @override
  ConsumerState<CommunityPeopleView> createState() => _CommunityPeopleViewState();
}

class _CommunityPeopleViewState extends ConsumerState<CommunityPeopleView>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController = TabController(length: 2, vsync: this);
  final _searchController = TextEditingController();
  String _search = '';
  String _filter = 'all';

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
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
              Tab(text: 'Everyone'),
              Tab(text: 'Study partners'),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildDirectory(),
              _StudyPartnersTab(courseId: widget.courseId),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDirectory() {
    final directoryAsync = ref.watch(
      communityMembersProvider(
        MemberQuery(widget.courseId, search: _search, filter: _filter),
      ),
    );

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
          child: TextField(
            controller: _searchController,
            onChanged: (value) => setState(() => _search = value),
            style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
            decoration: InputDecoration(
              hintText: 'Search classmates by name',
              hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
              prefixIcon: const Icon(Icons.search_rounded, size: 19),
              suffixIcon: _search.isEmpty
                  ? null
                  : IconButton(
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _search = '');
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
          height: 40,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('all', 'Everyone'),
              _filterChip('active', 'Active now'),
              _filterChip('students', 'Students'),
              _filterChip('teachers', 'Teachers'),
            ],
          ),
        ),
        Expanded(
          child: directoryAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
            ),
            error: (error, _) => CommunityErrorView(
              error: error,
              onRetry: () => ref.invalidate(communityMembersProvider),
            ),
            data: (directory) {
              if (directory.members.isEmpty) {
                return CommunityEmpty(
                  icon: Icons.person_search_rounded,
                  title: _filter == 'active'
                      ? 'Nobody is active right now'
                      : 'No students found',
                  message: _filter == 'active'
                      ? 'Check back later, or leave a question so classmates find '
                          'it when they come online.'
                      : 'Try a different name or clear the filters.',
                );
              }
              return RefreshIndicator(
                color: CT.primary,
                onRefresh: () async => ref.invalidate(communityMembersProvider),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 30),
                  children: [
                    Row(
                      children: [
                        CommunityStat(
                          icon: Icons.people_alt_rounded,
                          value: '${directory.enrolledCount}',
                          label: 'enrolled',
                        ),
                        const SizedBox(width: 18),
                        CommunityStat(
                          icon: Icons.bolt_rounded,
                          value: '${directory.activeCount}',
                          label: 'active now',
                          color: CT.warn,
                        ),
                        const SizedBox(width: 18),
                        CommunityStat(
                          icon: Icons.school_rounded,
                          value: '${directory.teacherCount}',
                          label: 'teachers',
                          color: CT.teacher,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    ...directory.members.map((member) => Padding(
                          padding: const EdgeInsets.only(bottom: 9),
                          child: _MemberCard(
                            courseId: widget.courseId,
                            member: member,
                          ),
                        )),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
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

class _MemberCard extends ConsumerWidget {
  final String courseId;
  final CommunityMember member;

  const _MemberCard({required this.courseId, required this.member});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityCard(
      padding: const EdgeInsets.all(13),
      accent: member.isTeacher ? CT.teacher : null,
      onTap: () => showMemberProfileSheet(context, courseId, member.id),
      child: Row(
        children: [
          MemberAvatar(member: member, size: 44),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        member.isMe ? '${member.fullName} (you)' : member.fullName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w800,
                          color: CT.textOf(context),
                        ),
                      ),
                    ),
                    if (member.isTeacher) ...[
                      const SizedBox(width: 7),
                      const TeacherBadge(),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: member.presence.isActive ? CT.primary : CT.textHint,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      member.presence.label,
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: member.presence.isActive
                            ? CT.primary
                            : CT.subTextOf(context),
                      ),
                    ),
                  ],
                ),
                if (member.interests.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 6,
                    runSpacing: 6,
                    children: member.interests
                        .take(3)
                        .map((i) => CommunityChip(label: i, color: CT.info))
                        .toList(),
                  ),
                ],
              ],
            ),
          ),
          // Straight into a private chat, without the profile detour.
          if (!member.isMe)
            IconButton(
              onPressed: () => openDirectChatWithUser(
                context,
                ref,
                member.id,
                displayName: member.fullName,
              ),
              icon: const Icon(Icons.chat_bubble_outline_rounded, size: 19),
              color: CT.primary,
              tooltip: 'Message ${member.fullName.split(' ').first}',
              visualDensity: VisualDensity.compact,
            )
          else
            Icon(Icons.chevron_right_rounded,
                size: 20, color: CT.subTextOf(context)),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Find study partners
// ─────────────────────────────────────────────

class _StudyPartnersTab extends ConsumerWidget {
  final String courseId;

  const _StudyPartnersTab({required this.courseId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final partnersAsync = ref.watch(studyPartnersProvider(courseId));

    return partnersAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
      ),
      error: (error, _) => CommunityErrorView(
        error: error,
        onRetry: () => ref.invalidate(studyPartnersProvider(courseId)),
      ),
      data: (data) {
        return RefreshIndicator(
          color: CT.primary,
          onRefresh: () async => ref.invalidate(studyPartnersProvider(courseId)),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              _MyPartnerCard(courseId: courseId, mine: data.mine),
              const SizedBox(height: 20),
              SectionHeader(
                icon: Icons.handshake_rounded,
                title: 'Students looking for partners',
                subtitle: data.partners.isEmpty
                    ? 'Nobody has published a card yet'
                    : '${data.partners.length} classmate(s) want to study together',
              ),
              const SizedBox(height: 12),
              if (data.partners.isEmpty)
                const CommunityEmpty(
                  icon: Icons.groups_rounded,
                  title: 'No study partners listed yet',
                  message: 'Publish your own card above — classmates who join later '
                      'will see it and can reach out.',
                  compact: true,
                )
              else
                ...data.partners.map((partner) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _PartnerCard(courseId: courseId, partner: partner),
                    )),
            ],
          ),
        );
      },
    );
  }
}

class _MyPartnerCard extends ConsumerWidget {
  final String courseId;
  final StudyPartnerCard? mine;

  const _MyPartnerCard({required this.courseId, this.mine});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final published = mine != null && mine!.isActive;

    return CommunityCard(
      accent: published ? CT.primary : CT.warn,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                published ? Icons.check_circle_rounded : Icons.campaign_rounded,
                size: 18,
                color: published ? CT.primary : CT.warn,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  published
                      ? 'You are listed as looking for a partner'
                      : 'Let classmates know you want a study partner',
                  style: TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w800,
                    color: CT.textOf(context),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            published
                ? (mine!.goal.isEmpty ? 'No goal set' : mine!.goal)
                : 'Share what you want to work on and when you are free. Only '
                    'people in this course can see it, and you can remove it '
                    'at any time.',
            style: TextStyle(
              fontSize: 12.5,
              height: 1.45,
              color: CT.subTextOf(context),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () => _edit(context, ref),
                  icon: Icon(published ? Icons.edit_rounded : Icons.add_rounded,
                      size: 17),
                  label: Text(published ? 'Edit my card' : 'Publish my card'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                ),
              ),
              if (published) ...[
                const SizedBox(width: 10),
                OutlinedButton(
                  onPressed: () async {
                    try {
                      await ref
                          .read(communityActionsProvider)
                          .removeStudyPartnerProfile(courseId);
                      if (context.mounted) {
                        communitySnack(context, 'Removed from the partner list');
                      }
                    } catch (e) {
                      if (context.mounted) {
                        communitySnack(context, e.toString(), isError: true);
                      }
                    }
                  },
                  style: OutlinedButton.styleFrom(
                    foregroundColor: CT.danger,
                    side: const BorderSide(color: CT.danger),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                  ),
                  child: const Text('Remove'),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Future<void> _edit(BuildContext context, WidgetRef ref) async {
    await showCommunitySheet<void>(
      context: context,
      title: 'Find a study partner',
      initialSize: 0.7,
      builder: (ctx, controller) => _PartnerForm(
        courseId: courseId,
        existing: mine,
        scrollController: controller,
      ),
    );
  }
}

class _PartnerForm extends ConsumerStatefulWidget {
  final String courseId;
  final StudyPartnerCard? existing;
  final ScrollController scrollController;

  const _PartnerForm({
    required this.courseId,
    this.existing,
    required this.scrollController,
  });

  @override
  ConsumerState<_PartnerForm> createState() => _PartnerFormState();
}

class _PartnerFormState extends ConsumerState<_PartnerForm> {
  late final _goalController =
      TextEditingController(text: widget.existing?.goal ?? '');
  late final _topicsController =
      TextEditingController(text: (widget.existing?.topics ?? []).join(', '));
  late final _noteController =
      TextEditingController(text: widget.existing?.note ?? '');
  late final Set<String> _availability = {...?widget.existing?.availability};
  bool _isSubmitting = false;

  static const _slots = ['mornings', 'afternoons', 'evenings', 'weekends', 'flexible'];

  @override
  void dispose() {
    _goalController.dispose();
    _topicsController.dispose();
    _noteController.dispose();
    super.dispose();
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
                controller: _goalController,
                label: 'What are you working towards?',
                hint: 'e.g. Prepare for the August exam',
              ),
              const SizedBox(height: 14),
              communityTextField(
                context: context,
                controller: _topicsController,
                label: 'Topics (comma separated)',
                hint: 'NPV, ratios, cash flow',
              ),
              const SizedBox(height: 18),
              Text(
                'When are you usually free?',
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
                children: _slots.map((slot) {
                  final selected = _availability.contains(slot);
                  return FilterChip(
                    selected: selected,
                    onSelected: (value) => setState(() {
                      if (value) {
                        _availability.add(slot);
                      } else {
                        _availability.remove(slot);
                      }
                    }),
                    label: Text(slot[0].toUpperCase() + slot.substring(1)),
                    labelStyle: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: selected ? Colors.white : CT.textOf(context),
                    ),
                    selectedColor: CT.primary,
                    checkmarkColor: Colors.white,
                    backgroundColor: CT.surfaceOf(context),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    side: BorderSide(color: CT.borderOf(context)),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),
              communityTextField(
                context: context,
                controller: _noteController,
                label: 'Anything else (optional)',
                hint: 'e.g. I prefer working through past papers together.',
                maxLines: 3,
              ),
            ],
          ),
        ),
        CommunitySheetFooter(
          isBusy: _isSubmitting,
          label: 'Publish my card',
          onSubmit: () async {
            setState(() => _isSubmitting = true);
            try {
              await ref.read(communityActionsProvider).saveStudyPartnerProfile(
                    widget.courseId,
                    goal: _goalController.text.trim(),
                    topics: _topicsController.text
                        .split(',')
                        .map((t) => t.trim())
                        .where((t) => t.isNotEmpty)
                        .toList(),
                    availability: _availability.toList(),
                    note: _noteController.text.trim(),
                  );
              if (!mounted) return;
              Navigator.of(context).pop();
              communitySnack(context, 'Your study partner card is live');
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

class _PartnerCard extends StatelessWidget {
  final String courseId;
  final StudyPartnerCard partner;

  const _PartnerCard({required this.courseId, required this.partner});

  @override
  Widget build(BuildContext context) {
    final member = partner.member;
    return CommunityCard(
      onTap: member == null
          ? null
          : () => showMemberProfileSheet(context, courseId, member.id),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (member != null) ...[
                MemberAvatar(member: member, size: 40),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member?.fullName ?? 'ECH Student',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: CT.textOf(context),
                      ),
                    ),
                    Text(
                      member?.presence.label ?? '',
                      style: TextStyle(
                        fontSize: 11,
                        color: member?.presence.isActive == true
                            ? CT.primary
                            : CT.subTextOf(context),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (partner.goal.isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(
              'Goal',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: CT.subTextOf(context),
              ),
            ),
            const SizedBox(height: 3),
            Text(
              partner.goal,
              style: TextStyle(
                fontSize: 12.5,
                height: 1.4,
                color: CT.textOf(context),
              ),
            ),
          ],
          if (partner.topics.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: partner.topics
                  .map((t) => CommunityChip(label: t, color: CT.info))
                  .toList(),
            ),
          ],
          if (partner.availability.isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(Icons.schedule_rounded, size: 13, color: CT.subTextOf(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Available: ${partner.availability.join(', ')}',
                    style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
                  ),
                ),
              ],
            ),
          ],
          if (partner.note.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              partner.note,
              style: TextStyle(
                fontSize: 12,
                height: 1.45,
                fontStyle: FontStyle.italic,
                color: CT.subTextOf(context),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
