import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../providers/community_provider.dart';
import '../messages/direct_chat_screen.dart';
import 'community_theme.dart';
import 'group_workspace_screen.dart';

/// A member's public course profile.
///
/// Deliberately limited to what helps someone decide whether to study with
/// this person — what they are learning, how they contribute, which groups
/// they are in. No contact details, no precise activity.
Future<void> showMemberProfileSheet(
  BuildContext context,
  String courseId,
  String memberId,
) {
  return showCommunitySheet<void>(
    context: context,
    title: 'Student profile',
    initialSize: 0.6,
    builder: (ctx, controller) => _MemberProfileBody(
      courseId: courseId,
      memberId: memberId,
      scrollController: controller,
    ),
  );
}

class _MemberProfileBody extends ConsumerWidget {
  final String courseId;
  final String memberId;
  final ScrollController scrollController;

  const _MemberProfileBody({
    required this.courseId,
    required this.memberId,
    required this.scrollController,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(
      memberProfileProvider((courseId: courseId, memberId: memberId)),
    );

    return profileAsync.when(
      loading: () => const Center(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
        ),
      ),
      error: (error, _) => CommunityErrorView(
        error: error,
        onRetry: () => ref.invalidate(
          memberProfileProvider((courseId: courseId, memberId: memberId)),
        ),
      ),
      data: (profile) {
        final member = profile.member;
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
          children: [
            Row(
              children: [
                MemberAvatar(member: member, size: 64),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        member.fullName,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: CT.textOf(context),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (member.isTeacher)
                            const TeacherBadge()
                          else
                            Text(
                              'ECH Student',
                              style: TextStyle(
                                fontSize: 12,
                                color: CT.subTextOf(context),
                              ),
                            ),
                          const SizedBox(width: 8),
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              color: member.presence.isActive
                                  ? CT.primary
                                  : CT.textHint,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
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
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),
            _Block(
              label: 'Currently studying',
              child: Text(
                profile.currentlyStudying,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: CT.textOf(context),
                ),
              ),
            ),
            if (profile.progress != null && !member.isTeacher) ...[
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (profile.progress! / 100).clamp(0.0, 1.0),
                  minHeight: 6,
                  backgroundColor: CT.surfaceOf(context),
                  valueColor: const AlwaysStoppedAnimation(CT.primary),
                ),
              ),
              const SizedBox(height: 5),
              Text(
                '${profile.progress!.toStringAsFixed(0)}% through the course',
                style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
              ),
            ],
            if (member.interests.isNotEmpty) ...[
              const SizedBox(height: 18),
              _Block(
                label: 'Interests',
                child: Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: member.interests
                      .take(8)
                      .map((i) => CommunityChip(label: i, color: CT.info))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _MiniStat(
                    icon: Icons.workspaces_rounded,
                    value: '${profile.groupCount}',
                    label: profile.groupCount == 1 ? 'Group' : 'Groups',
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.forum_rounded,
                    value: '${profile.postCount}',
                    label: 'Posts',
                    color: CT.accent,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _MiniStat(
                    icon: Icons.reply_rounded,
                    value: '${profile.replyCount}',
                    label: 'Replies',
                    color: CT.info,
                  ),
                ),
              ],
            ),
            if (profile.lookingForPartner != null) ...[
              const SizedBox(height: 18),
              CommunityCard(
                accent: CT.warn,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.handshake_rounded,
                            size: 16, color: CT.warn),
                        const SizedBox(width: 8),
                        Text(
                          'Looking for a study partner',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: CT.textOf(context),
                          ),
                        ),
                      ],
                    ),
                    if (profile.lookingForPartner!.goal.isNotEmpty) ...[
                      const SizedBox(height: 9),
                      Text(
                        profile.lookingForPartner!.goal,
                        style: TextStyle(
                          fontSize: 12.5,
                          height: 1.45,
                          color: CT.subTextOf(context),
                        ),
                      ),
                    ],
                    if (profile.lookingForPartner!.availability.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 7,
                        runSpacing: 7,
                        children: profile.lookingForPartner!.availability
                            .map((a) => CommunityChip(label: a, color: CT.warn))
                            .toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            if (profile.groups.isNotEmpty) ...[
              const SizedBox(height: 18),
              _Block(
                label: 'Study groups in this course',
                child: Column(
                  children: profile.groups
                      .map((group) => Padding(
                            padding: const EdgeInsets.only(top: 8),
                            child: CommunityCard(
                              padding: const EdgeInsets.all(12),
                              onTap: () {
                                Navigator.of(context).pop();
                                openGroupWorkspace(context, courseId, group.id);
                              },
                              child: Row(
                                children: [
                                  const Icon(Icons.groups_2_rounded,
                                      size: 17, color: CT.primary),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(
                                      group.name,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: CT.textOf(context),
                                      ),
                                    ),
                                  ),
                                  Text(
                                    '${group.memberCount} members',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: CT.subTextOf(context),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ))
                      .toList(),
                ),
              ),
            ],
            const SizedBox(height: 22),
            if (!member.isMe)
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    Navigator.of(context).pop();
                    await openDirectChatWithUser(
                      context,
                      ref,
                      member.id,
                      displayName: member.fullName,
                      contextLabel: profile.currentlyStudying,
                      contextCourseId: courseId,
                    );
                  },
                  icon: const Icon(Icons.chat_bubble_rounded, size: 17),
                  label: Text(
                    member.isTeacher
                        ? 'Message your teacher'
                        : 'Message ${member.fullName.split(' ').first}',
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: CT.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                    textStyle: const TextStyle(
                        fontSize: 13.5, fontWeight: FontWeight.w800),
                  ),
                ),
              ),
            const SizedBox(height: 14),
            Text(
              member.isTeacher
                  ? 'For anything the whole class would benefit from, the '
                      'Discussions tab is a better place than a private message.'
                  : 'You can also invite ${member.fullName.split(' ').first} to a '
                      'study group from the Groups tab.',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.5,
                color: CT.subTextOf(context),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _Block extends StatelessWidget {
  final String label;
  final Widget child;

  const _Block({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.9,
            color: CT.subTextOf(context),
          ),
        ),
        const SizedBox(height: 7),
        child,
      ],
    );
  }
}

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const _MiniStat({
    required this.icon,
    required this.value,
    required this.label,
    this.color = CT.primary,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        color: CT.surfaceOf(context),
        borderRadius: CT.r12,
      ),
      child: Column(
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: CT.textOf(context),
            ),
          ),
          Text(
            label,
            style: TextStyle(fontSize: 10.5, color: CT.subTextOf(context)),
          ),
        ],
      ),
    );
  }
}
