import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';
import 'member_profile_sheet.dart';

void openPostDetail(
  BuildContext context,
  String courseId,
  String postId, {
  bool isTeacher = false,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => PostDetailScreen(
        courseId: courseId,
        postId: postId,
        isTeacher: isTeacher,
      ),
    ),
  );
}

/// A discussion thread. Teacher answers and the accepted answer float to the
/// top so students can tell official guidance from peer opinion at a glance.
class PostDetailScreen extends ConsumerStatefulWidget {
  final String courseId;
  final String postId;
  final bool isTeacher;

  const PostDetailScreen({
    super.key,
    required this.courseId,
    required this.postId,
    this.isTeacher = false,
  });

  @override
  ConsumerState<PostDetailScreen> createState() => _PostDetailScreenState();
}

class _PostDetailScreenState extends ConsumerState<PostDetailScreen> {
  final _replyController = TextEditingController();
  bool _isReplying = false;

  ({String courseId, String postId}) get _key =>
      (courseId: widget.courseId, postId: widget.postId);

  @override
  void dispose() {
    _replyController.dispose();
    super.dispose();
  }

  Future<void> _reply() async {
    final text = _replyController.text.trim();
    if (text.isEmpty) return;
    setState(() => _isReplying = true);
    try {
      await ref
          .read(communityActionsProvider)
          .addReply(widget.courseId, widget.postId, text);
      _replyController.clear();
      if (mounted) FocusScope.of(context).unfocus();
    } catch (e) {
      if (mounted) communitySnack(context, e.toString(), isError: true);
    } finally {
      if (mounted) setState(() => _isReplying = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final postAsync = ref.watch(communityPostProvider(_key));

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          switch (postAsync.valueOrNull?.type) {
            CommunityPostType.question => 'Question',
            CommunityPostType.announcement => 'Announcement',
            CommunityPostType.help => 'Help request',
            _ => 'Discussion',
          },
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: CT.textOf(context),
          ),
        ),
        actions: [
          if (widget.isTeacher && postAsync.valueOrNull != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: CT.textOf(context)),
              onSelected: (value) => _moderate(value, postAsync.value!),
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'pin',
                  child: Row(
                    children: [
                      const Icon(Icons.push_pin_rounded, size: 18, color: CT.warn),
                      const SizedBox(width: 10),
                      Text(postAsync.value!.isPinned ? 'Unpin' : 'Pin to top'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'close',
                  child: Row(
                    children: [
                      const Icon(Icons.lock_rounded, size: 18),
                      const SizedBox(width: 10),
                      Text(postAsync.value!.isClosed
                          ? 'Reopen thread'
                          : 'Close thread'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: postAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
        ),
        error: (error, _) => CommunityErrorView(
          error: error,
          onRetry: () => ref.invalidate(communityPostProvider(_key)),
        ),
        data: (post) => Column(
          children: [
            Expanded(
              child: RefreshIndicator(
                color: CT.primary,
                onRefresh: () async => ref.invalidate(communityPostProvider(_key)),
                child: ListView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
                  children: [
                    _PostHeader(
                      courseId: widget.courseId,
                      post: post,
                      onToggleLike: () => ref
                          .read(communityActionsProvider)
                          .toggleLike(widget.courseId, post.id),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Text(
                          post.replies.isEmpty
                              ? 'No replies yet'
                              : '${post.replies.length} '
                                  '${post.replies.length == 1 ? 'reply' : 'replies'}',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: CT.textOf(context),
                          ),
                        ),
                        const Spacer(),
                        if (post.hasTeacherAnswer)
                          const CommunityChip(
                            label: 'Teacher answered',
                            icon: Icons.verified_rounded,
                            color: CT.teacher,
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    if (post.replies.isEmpty)
                      CommunityEmpty(
                        icon: Icons.mode_comment_outlined,
                        title: 'Be the first to reply',
                        message: post.type == CommunityPostType.question
                            ? 'Even a partial answer helps — someone else can build '
                                'on it.'
                            : 'Add your thoughts to get the conversation going.',
                        compact: true,
                      )
                    else
                      ...post.replies.map((reply) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ReplyCard(
                              courseId: widget.courseId,
                              post: post,
                              reply: reply,
                              canAccept: widget.isTeacher ||
                                  post.author?.id ==
                                      ref
                                          .watch(communityOverviewProvider(
                                              widget.courseId))
                                          .valueOrNull
                                          ?.myId,
                            ),
                          )),
                  ],
                ),
              ),
            ),
            if (post.isClosed && !widget.isTeacher)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                color: CT.surfaceOf(context),
                child: Text(
                  'This thread was closed by the teacher.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 12.5, color: CT.subTextOf(context)),
                ),
              )
            else
              _ReplyComposer(
                controller: _replyController,
                isBusy: _isReplying,
                onSend: _reply,
              ),
          ],
        ),
      ),
    );
  }

  Future<void> _moderate(String action, CommunityPost post) async {
    try {
      await ref.read(communityActionsProvider).moderatePost(
            widget.courseId,
            post.id,
            isPinned: action == 'pin' ? !post.isPinned : null,
            isClosed: action == 'close' ? !post.isClosed : null,
          );
      if (mounted) communitySnack(context, 'Thread updated');
    } catch (e) {
      if (mounted) communitySnack(context, e.toString(), isError: true);
    }
  }
}

class _PostHeader extends StatelessWidget {
  final String courseId;
  final CommunityPost post;
  final VoidCallback onToggleLike;

  const _PostHeader({
    required this.courseId,
    required this.post,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    return CommunityCard(
      accent: post.isPinned ? CT.warn : null,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (post.author != null) ...[
                GestureDetector(
                  onTap: () =>
                      showMemberProfileSheet(context, courseId, post.author!.id),
                  child: MemberAvatar(member: post.author!, size: 40),
                ),
                const SizedBox(width: 12),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            post.author?.fullName ?? 'ECH Student',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w800,
                              color: CT.textOf(context),
                            ),
                          ),
                        ),
                        if (post.isByTeacher) ...[
                          const SizedBox(width: 7),
                          const TeacherBadge(),
                        ],
                      ],
                    ),
                    Text(
                      CT.timeAgo(context, post.createdAt),
                      style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                    ),
                  ],
                ),
              ),
              if (post.isPinned)
                const Icon(Icons.push_pin_rounded, size: 16, color: CT.warn),
            ],
          ),
          const SizedBox(height: 14),
          if (post.helpCategory != null) ...[
            CommunityChip(
              label: helpCategoryLabel(post.helpCategory),
              icon: Icons.help_outline_rounded,
              color: CT.warn,
            ),
            const SizedBox(height: 10),
          ],
          if (post.title != null) ...[
            Text(
              post.title!,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                height: 1.3,
                letterSpacing: -0.4,
                color: CT.textOf(context),
              ),
            ),
            const SizedBox(height: 8),
          ],
          Text(
            post.content,
            style: TextStyle(
              fontSize: 13.5,
              height: 1.6,
              color: CT.textOf(context),
            ),
          ),
          if (post.tags.isNotEmpty) ...[
            const SizedBox(height: 14),
            Wrap(
              spacing: 7,
              runSpacing: 7,
              children: post.tags
                  .map((tag) => CommunityChip(label: '#$tag', color: CT.info))
                  .toList(),
            ),
          ],
          const SizedBox(height: 16),
          Row(
            children: [
              InkWell(
                onTap: onToggleLike,
                borderRadius: CT.r8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  child: Row(
                    children: [
                      Icon(
                        post.isLikedByMe
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        size: 17,
                        color: post.isLikedByMe ? CT.danger : CT.subTextOf(context),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '${post.likeCount}',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: post.isLikedByMe
                              ? CT.danger
                              : CT.subTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Icon(Icons.visibility_outlined,
                  size: 15, color: CT.subTextOf(context)),
              const SizedBox(width: 5),
              Text(
                '${post.viewCount}',
                style: TextStyle(fontSize: 12, color: CT.subTextOf(context)),
              ),
              const Spacer(),
              if (post.isResolved)
                const CommunityChip(label: 'Resolved', icon: Icons.check_rounded),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyCard extends ConsumerWidget {
  final String courseId;
  final CommunityPost post;
  final PostReply reply;
  final bool canAccept;

  const _ReplyCard({
    required this.courseId,
    required this.post,
    required this.reply,
    required this.canAccept,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return CommunityCard(
      accent: reply.isAccepted
          ? CT.primary
          : (reply.isTeacherAnswer ? CT.teacher : null),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (reply.isAccepted || reply.isTeacherAnswer) ...[
            Row(
              children: [
                if (reply.isTeacherAnswer)
                  const CommunityChip(
                    label: 'Teacher answer',
                    icon: Icons.school_rounded,
                    color: CT.teacher,
                    filled: true,
                  ),
                if (reply.isAccepted) ...[
                  if (reply.isTeacherAnswer) const SizedBox(width: 7),
                  const CommunityChip(
                    label: 'Accepted answer',
                    icon: Icons.check_circle_rounded,
                    filled: true,
                  ),
                ],
              ],
            ),
            const SizedBox(height: 11),
          ],
          Row(
            children: [
              if (reply.author != null) ...[
                GestureDetector(
                  onTap: () =>
                      showMemberProfileSheet(context, courseId, reply.author!.id),
                  child: MemberAvatar(member: reply.author!, size: 30),
                ),
                const SizedBox(width: 10),
              ],
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      reply.author?.fullName ?? 'ECH Student',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: CT.textOf(context),
                      ),
                    ),
                    Text(
                      CT.timeAgo(context, reply.createdAt),
                      style: const TextStyle(fontSize: 10.5, color: CT.textHint),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            reply.content,
            style: TextStyle(
              fontSize: 13,
              height: 1.55,
              color: CT.textOf(context),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              InkWell(
                onTap: () => ref
                    .read(communityActionsProvider)
                    .toggleLike(courseId, post.id, replyId: reply.id),
                borderRadius: CT.r8,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        reply.isLikedByMe
                            ? Icons.thumb_up_rounded
                            : Icons.thumb_up_outlined,
                        size: 15,
                        color: reply.isLikedByMe
                            ? CT.primary
                            : CT.subTextOf(context),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        '${reply.likeCount}',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: reply.isLikedByMe
                              ? CT.primary
                              : CT.subTextOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const Spacer(),
              if (canAccept)
                TextButton.icon(
                  onPressed: () async {
                    try {
                      await ref
                          .read(communityActionsProvider)
                          .acceptReply(courseId, post.id, reply.id);
                    } catch (e) {
                      if (context.mounted) {
                        communitySnack(context, e.toString(), isError: true);
                      }
                    }
                  },
                  icon: Icon(
                    reply.isAccepted
                        ? Icons.check_circle_rounded
                        : Icons.check_circle_outline_rounded,
                    size: 16,
                  ),
                  label: Text(reply.isAccepted ? 'Accepted' : 'Accept answer'),
                  style: TextButton.styleFrom(
                    foregroundColor: reply.isAccepted ? CT.primary : CT.subTextOf(context),
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    textStyle: const TextStyle(
                        fontSize: 11.5, fontWeight: FontWeight.w700),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ReplyComposer extends StatelessWidget {
  final TextEditingController controller;
  final bool isBusy;
  final VoidCallback onSend;

  const _ReplyComposer({
    required this.controller,
    required this.isBusy,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: CT.cardOf(context),
        border: Border(top: BorderSide(color: CT.borderOf(context))),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Expanded(
              child: TextField(
                controller: controller,
                minLines: 1,
                maxLines: 4,
                style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Write a reply…',
                  hintStyle: const TextStyle(fontSize: 13, color: CT.textHint),
                  filled: true,
                  fillColor: CT.surfaceOf(context),
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(22),
                    borderSide: BorderSide.none,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Material(
              color: CT.primary,
              shape: const CircleBorder(),
              child: InkWell(
                customBorder: const CircleBorder(),
                onTap: isBusy ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: isBusy
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            valueColor: AlwaysStoppedAnimation(Colors.white),
                          ),
                        )
                      : const Icon(Icons.send_rounded,
                          size: 19, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
