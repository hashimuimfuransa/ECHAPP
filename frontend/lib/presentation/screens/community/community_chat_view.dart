import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import 'community_theme.dart';
import 'member_profile_sheet.dart';

/// Course-contextual chat. Used both for the shared course room
/// (`groupId == null`) and for a study group's private room.
class CommunityChatView extends ConsumerStatefulWidget {
  final String courseId;
  final String? groupId;
  final String emptyMessage;

  const CommunityChatView({
    super.key,
    required this.courseId,
    this.groupId,
    this.emptyMessage =
        'No messages yet. Ask about a lesson, share what clicked for you, '
        'or offer to help someone.',
  });

  @override
  ConsumerState<CommunityChatView> createState() => _CommunityChatViewState();
}

class _CommunityChatViewState extends ConsumerState<CommunityChatView> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  CommunityChatMessage? _replyTarget;

  ChatRoomKey get _key => ChatRoomKey(widget.courseId, widget.groupId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(chatRoomProvider(_key).notifier);
      notifier.load();
      notifier.startPolling();
      ref
          .read(communityPresenceProvider(widget.courseId))
          .start(area: widget.groupId == null ? 'chat' : 'group');
    });
  }

  @override
  void dispose() {
    // The notifier outlives this widget (it is provider-scoped), so stop the
    // timer explicitly rather than leaving it polling in the background.
    ref.read(chatRoomProvider(_key).notifier).stopPolling();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!_scrollController.hasClients) return;
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeOut,
      );
    });
  }

  Future<void> _send() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    _controller.clear();
    final replyTo = _replyTarget?.id;
    setState(() => _replyTarget = null);

    final sent = await ref
        .read(chatRoomProvider(_key).notifier)
        .send(text, replyTo: replyTo);
    if (sent) {
      _scrollToBottom();
    } else if (mounted) {
      communitySnack(context, 'Message could not be sent', isError: true);
    }
  }

  /// Which room this view is, in the sync stream's naming.
  String get _roomKey =>
      widget.groupId == null ? 'course' : 'group:${widget.groupId}';

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(chatRoomProvider(_key));

    // The community-wide long poll knows about a new message roughly a second
    // after it is sent; reload the moment it reports one for this room rather
    // than waiting for this view's own slower refresh.
    ref.listen(
      chatInboxProvider(widget.courseId).select((s) => s.revision[_roomKey] ?? 0),
      (previous, next) {
        if (previous != null && next > previous) {
          ref.read(chatRoomProvider(_key).notifier).load(silent: true);
        }
      },
    );

    ref.listen(chatRoomProvider(_key), (previous, next) {
      if ((previous?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Column(
      children: [
        Expanded(
          child: state.isLoading && state.messages.isEmpty
              ? const Center(
                  child: CircularProgressIndicator(
                      strokeWidth: 2.4, color: CT.primary),
                )
              // A failed load must not masquerade as an empty room: showing
              // "start the conversation" here hid a broken request and made it
              // look like other people's messages were missing.
              : state.error != null && state.messages.isEmpty
                  ? CommunityErrorView(
                      error: state.error!,
                      onRetry: () =>
                          ref.read(chatRoomProvider(_key).notifier).load(),
                    )
              : state.messages.isEmpty
                  ? CommunityEmpty(
                      icon: Icons.forum_rounded,
                      title: 'Start the conversation',
                      message: widget.emptyMessage,
                    )
                  : RefreshIndicator(
                      color: CT.primary,
                      onRefresh: () =>
                          ref.read(chatRoomProvider(_key).notifier).loadOlder(),
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                        itemCount: state.messages.length,
                        itemBuilder: (context, index) {
                          final message = state.messages[index];
                          final previous =
                              index > 0 ? state.messages[index - 1] : null;
                          final showHeader = previous == null ||
                              previous.sender?.id != message.sender?.id;
                          final showDay = previous == null ||
                              !_sameDay(previous.createdAt, message.createdAt);

                          return Column(
                            children: [
                              if (showDay)
                                _DayDivider(date: message.createdAt),
                              _MessageBubble(
                                courseId: widget.courseId,
                                message: message,
                                showHeader: showHeader,
                                onReply: () =>
                                    setState(() => _replyTarget = message),
                                onDelete: message.isMine
                                    ? () => ref
                                        .read(chatRoomProvider(_key).notifier)
                                        .deleteMessage(message.id)
                                    : null,
                              ),
                            ],
                          );
                        },
                      ),
                    ),
        ),
        if (_replyTarget != null) _ReplyPreview(
          message: _replyTarget!,
          onCancel: () => setState(() => _replyTarget = null),
        ),
        _Composer(
          controller: _controller,
          isSending: state.isSending,
          onSend: _send,
        ),
      ],
    );
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _DayDivider extends StatelessWidget {
  final DateTime? date;
  const _DayDivider({required this.date});

  @override
  Widget build(BuildContext context) {
    if (date == null) return const SizedBox.shrink();
    final now = DateTime.now();
    final isToday =
        date!.year == now.year && date!.month == now.month && date!.day == now.day;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(child: Divider(color: CT.borderOf(context))),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            child: Text(
              isToday ? 'Today' : CT.formatDate(context, date),
              style: TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: CT.subTextOf(context),
              ),
            ),
          ),
          Expanded(child: Divider(color: CT.borderOf(context))),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final String courseId;
  final CommunityChatMessage message;
  final bool showHeader;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _MessageBubble({
    required this.courseId,
    required this.message,
    required this.showHeader,
    required this.onReply,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final bubbleColor = isMine
        ? CT.primary
        : (message.isTeacher
            ? CT.teacher.withOpacity(CT.isDark(context) ? 0.25 : 0.1)
            : CT.cardOf(context));
    final textColor = isMine ? Colors.white : CT.textOf(context);

    return Padding(
      padding: EdgeInsets.only(top: showHeader ? 10 : 3, bottom: 1),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          if (!isMine)
            SizedBox(
              width: 34,
              child: showHeader && message.sender != null
                  ? GestureDetector(
                      onTap: () => showMemberProfileSheet(
                          context, courseId, message.sender!.id),
                      child: MemberAvatar(member: message.sender!, size: 30),
                    )
                  : null,
            ),
          if (!isMine) const SizedBox(width: 6),
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              child: Column(
                crossAxisAlignment:
                    isMine ? CrossAxisAlignment.end : CrossAxisAlignment.start,
                children: [
                  if (showHeader && !isMine)
                    Padding(
                      padding: const EdgeInsets.only(left: 4, bottom: 3),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            message.sender?.fullName ?? 'ECH Student',
                            style: TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: CT.subTextOf(context),
                            ),
                          ),
                          if (message.isTeacher) ...[
                            const SizedBox(width: 6),
                            const TeacherBadge(),
                          ],
                        ],
                      ),
                    ),
                  Container(
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.72,
                    ),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                    decoration: BoxDecoration(
                      color: bubbleColor,
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(14),
                        topRight: const Radius.circular(14),
                        bottomLeft: Radius.circular(isMine ? 14 : 4),
                        bottomRight: Radius.circular(isMine ? 4 : 14),
                      ),
                      border: isMine
                          ? null
                          : Border.all(color: CT.borderOf(context)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (message.replyToId != null) ...[
                          Container(
                            padding: const EdgeInsets.all(8),
                            margin: const EdgeInsets.only(bottom: 7),
                            decoration: BoxDecoration(
                              color: (isMine ? Colors.white : CT.primary)
                                  .withOpacity(0.12),
                              borderRadius: CT.r8,
                              border: Border(
                                left: BorderSide(
                                  color: isMine ? Colors.white70 : CT.primary,
                                  width: 3,
                                ),
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  message.replyToSender ?? 'Reply',
                                  style: TextStyle(
                                    fontSize: 10.5,
                                    fontWeight: FontWeight.w700,
                                    color: isMine
                                        ? Colors.white70
                                        : CT.subTextOf(context),
                                  ),
                                ),
                                Text(
                                  message.replyToContent ?? '',
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isMine
                                        ? Colors.white70
                                        : CT.subTextOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        Text(
                          message.isDeleted
                              ? 'This message was removed'
                              : (message.content ?? ''),
                          style: TextStyle(
                            fontSize: 13.5,
                            height: 1.4,
                            fontStyle:
                                message.isDeleted ? FontStyle.italic : null,
                            color: message.isDeleted
                                ? (isMine ? Colors.white70 : CT.textHint)
                                : textColor,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          CT.timeAgo(context, message.createdAt),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isMine ? Colors.white70 : CT.textHint,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _showActions(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: CT.cardOf(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(18)),
      ),
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.reply_rounded, color: CT.primary),
              title: const Text('Reply'),
              onTap: () {
                Navigator.of(ctx).pop();
                onReply();
              },
            ),
            if (onDelete != null)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: CT.danger),
                title: const Text('Delete message'),
                onTap: () {
                  Navigator.of(ctx).pop();
                  onDelete!();
                },
              ),
          ],
        ),
      ),
    );
  }
}

class _ReplyPreview extends StatelessWidget {
  final CommunityChatMessage message;
  final VoidCallback onCancel;

  const _ReplyPreview({required this.message, required this.onCancel});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(14, 8, 6, 8),
      color: CT.surfaceOf(context),
      child: Row(
        children: [
          Container(width: 3, height: 32, color: CT.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Replying to ${message.sender?.fullName ?? 'message'}',
                  style: const TextStyle(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w700,
                    color: CT.primary,
                  ),
                ),
                Text(
                  message.content ?? '',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 12, color: CT.subTextOf(context)),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onCancel,
            icon: const Icon(Icons.close_rounded, size: 18),
            color: CT.subTextOf(context),
          ),
        ],
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool isSending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.isSending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
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
                maxLines: 5,
                textInputAction: TextInputAction.newline,
                style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
                decoration: InputDecoration(
                  hintText: 'Write a message…',
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
                onTap: isSending ? null : onSend,
                child: Padding(
                  padding: const EdgeInsets.all(11),
                  child: isSending
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
