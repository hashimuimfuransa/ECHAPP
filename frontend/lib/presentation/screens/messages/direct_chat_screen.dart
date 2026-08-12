import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/direct_message.dart';
import '../../providers/messaging_provider.dart';
import '../community/community_theme.dart';

/// Opens a one-to-one chat with someone.
///
/// Navigates immediately and lets the screen resolve the conversation, rather
/// than blocking behind a modal spinner: the caller only has a user id, and
/// waiting on a round trip before opening made the chat feel frozen.
void openDirectChatWithUser(
  BuildContext context,
  WidgetRef ref,
  String userId, {
  String? displayName,
  String? avatarUrl,
  String? roleLabel,
  String? contextLabel,
  String? contextCourseId,
}) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => DirectChatScreen(
        target: ChatTarget.user(userId),
        contactName: displayName ?? 'Chat',
        contactAvatar: avatarUrl,
        contactRole: roleLabel,
        contextLabel: contextLabel,
        contextCourseId: contextCourseId,
      ),
    ),
  );
}

/// A one-to-one conversation.
///
/// [target] may be a known conversation (from the inbox) or just the other
/// person (from a "Message" button) — the notifier resolves either.
class DirectChatScreen extends ConsumerStatefulWidget {
  final ChatTarget target;

  /// Shown in the app bar straight away, before the thread has loaded, so the
  /// screen never opens on an empty header.
  final String contactName;
  final String? contactAvatar;
  final String? contactRole;

  /// Optional "about X" tag attached to the first message, so a chat started
  /// from a course or group carries that context with it.
  final String? contextLabel;
  final String? contextCourseId;

  const DirectChatScreen({
    super.key,
    required this.target,
    required this.contactName,
    this.contactAvatar,
    this.contactRole,
    this.contextLabel,
    this.contextCourseId,
  });

  @override
  ConsumerState<DirectChatScreen> createState() => _DirectChatScreenState();
}

class _DirectChatScreenState extends ConsumerState<DirectChatScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  DirectMessage? _replyTarget;
  bool _contextSent = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(directChatProvider(widget.target).notifier);
      notifier.load();
      notifier.startPolling();
    });
  }

  @override
  void dispose() {
    // The notifier is provider-scoped and outlives this widget, so stop its
    // timer explicitly rather than leaving it polling in the background.
    ref.read(directChatProvider(widget.target).notifier).stopPolling();
    _controller.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
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
        .read(directChatProvider(widget.target).notifier)
        .send(
          text,
          replyTo: replyTo,
          // Only tag the very first message with its origin.
          contextLabel: _contextSent ? null : widget.contextLabel,
          contextCourseId: _contextSent ? null : widget.contextCourseId,
        );

    if (sent) {
      _contextSent = true;
      _scrollToBottom();
    } else if (mounted) {
      final error = ref.read(directChatProvider(widget.target)).error;
      communitySnack(context, error ?? 'Message could not be sent', isError: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(directChatProvider(widget.target));
    final contact = state.conversation?.contact;

    ref.listen(directChatProvider(widget.target), (previous, next) {
      if ((previous?.messages.length ?? 0) < next.messages.length) {
        _scrollToBottom();
      }
    });

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            // Falls back to what the caller handed us, so the header is fully
            // drawn on the first frame instead of popping in once loaded.
            _ContactAvatar(
              contact: contact,
              name: widget.contactName,
              fallbackAvatar: widget.contactAvatar,
              size: 34,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact?.fullName ?? widget.contactName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CT.textOf(context),
                    ),
                  ),
                  if (contact != null || widget.contactRole != null)
                    Text(
                      contact?.roleLabel ?? widget.contactRole!,
                      style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                    ),
                ],
              ),
            ),
          ],
        ),
        actions: [
          if (state.conversation != null)
            PopupMenuButton<String>(
              icon: Icon(Icons.more_vert_rounded, color: CT.textOf(context)),
              onSelected: _onMenu,
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'mute',
                  child: Row(
                    children: [
                      Icon(
                        state.conversation!.isMuted
                            ? Icons.notifications_active_rounded
                            : Icons.notifications_off_rounded,
                        size: 18,
                      ),
                      const SizedBox(width: 10),
                      Text(state.conversation!.isMuted
                          ? 'Unmute notifications'
                          : 'Mute notifications'),
                    ],
                  ),
                ),
                PopupMenuItem(
                  value: 'block',
                  child: Row(
                    children: [
                      Icon(
                        state.conversation!.isBlockedByMe
                            ? Icons.lock_open_rounded
                            : Icons.block_rounded,
                        size: 18,
                        color: CT.danger,
                      ),
                      const SizedBox(width: 10),
                      Text(state.conversation!.isBlockedByMe ? 'Unblock' : 'Block'),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: state.isLoading && state.messages.isEmpty
                ? const Center(
                    child:
                        CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
                  )
                // Same reasoning as the course room: a failed load has to look
                // like a failure, not like an empty conversation.
                : state.error != null && state.messages.isEmpty
                    ? CommunityErrorView(
                        error: state.error!,
                        onRetry: () => ref
                            .read(directChatProvider(widget.target).notifier)
                            .load(),
                      )
                : state.messages.isEmpty
                    ? CommunityEmpty(
                        icon: Icons.chat_bubble_outline_rounded,
                        title: 'Say hello',
                        message: contact?.isTeacher == true
                            ? 'Ask your teacher a question directly. For anything '
                                'the whole class would benefit from, the course '
                                'discussions are a better place.'
                            : 'Start the conversation — agree on a study time, '
                                'or work through a question together.',
                      )
                    : RefreshIndicator(
                        color: CT.primary,
                        onRefresh: () => ref
                            .read(directChatProvider(widget.target).notifier)
                            .loadOlder(),
                        child: ListView.builder(
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(14, 14, 14, 8),
                          itemCount: state.messages.length,
                          itemBuilder: (context, index) {
                            final message = state.messages[index];
                            final previous =
                                index > 0 ? state.messages[index - 1] : null;
                            final showDay = previous == null ||
                                !_sameDay(previous.createdAt, message.createdAt);

                            return Column(
                              children: [
                                if (showDay) _DayDivider(date: message.createdAt),
                                _Bubble(
                                  message: message,
                                  onReply: () =>
                                      setState(() => _replyTarget = message),
                                  onDelete: message.isMine
                                      ? () => ref
                                          .read(directChatProvider(
                                                  widget.target)
                                              .notifier)
                                          .deleteMessage(message.id)
                                      : null,
                                ),
                              ],
                            );
                          },
                        ),
                      ),
          ),
          if (_replyTarget != null)
            _ReplyPreview(
              message: _replyTarget!,
              onCancel: () => setState(() => _replyTarget = null),
            ),
          if (state.conversation?.isBlocked == true)
            _BlockedBanner(
              blockedByMe: state.conversation!.isBlockedByMe,
              onUnblock: () => ref
                  .read(directChatProvider(widget.target).notifier)
                  .setBlocked(false),
            )
          else
            _Composer(
              controller: _controller,
              isSending: state.isSending,
              onSend: _send,
            ),
        ],
      ),
    );
  }

  Future<void> _onMenu(String value) async {
    final notifier = ref.read(directChatProvider(widget.target).notifier);
    final conversation = ref.read(directChatProvider(widget.target)).conversation;
    if (conversation == null) return;

    if (value == 'mute') {
      await notifier.setMuted(!conversation.isMuted);
      if (mounted) {
        communitySnack(
          context,
          conversation.isMuted ? 'Notifications on' : 'Notifications muted',
        );
      }
      return;
    }

    if (value == 'block') {
      if (conversation.isBlockedByMe) {
        await notifier.setBlocked(false);
        if (mounted) communitySnack(context, 'Unblocked');
        return;
      }
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Block ${conversation.contact?.fullName ?? 'this person'}?'),
          content: const Text(
            'They will not be able to send you messages, and you will not be '
            'able to message them until you unblock.',
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
              child: const Text('Block'),
            ),
          ],
        ),
      );
      if (confirmed == true) {
        await notifier.setBlocked(true);
        if (mounted) communitySnack(context, 'Blocked');
      }
    }
  }

  static bool _sameDay(DateTime? a, DateTime? b) {
    if (a == null || b == null) return false;
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}

class _ContactAvatar extends StatelessWidget {
  final MessageContact? contact;
  final String name;
  final String? fallbackAvatar;
  final double size;

  const _ContactAvatar({
    this.contact,
    required this.name,
    this.fallbackAvatar,
    this.size = 44,
  });

  @override
  Widget build(BuildContext context) {
    final displayName = contact?.fullName ?? name;
    final seed = contact?.id ?? displayName;
    final color = CT.avatarColor(seed);
    final avatar = contact?.avatar ?? fallbackAvatar;

    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: (avatar == null || avatar.isEmpty)
            ? LinearGradient(
                colors: [color, color.withOpacity(0.72)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        border: contact?.isTeacher == true
            ? Border.all(color: CT.teacher, width: 2)
            : null,
      ),
      child: (avatar != null && avatar.isNotEmpty)
          ? Image.network(
              avatar,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _initials(displayName, size),
            )
          : _initials(displayName, size),
    );
  }

  static Widget _initials(String name, double size) {
    final parts = name.trim().split(RegExp(r'\s+'));
    final initials = parts.isEmpty || parts.first.isEmpty
        ? '?'
        : (parts.length == 1
            ? parts.first.substring(0, parts.first.length >= 2 ? 2 : 1)
            : '${parts.first[0]}${parts[1][0]}');
    return Center(
      child: Text(
        initials.toUpperCase(),
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w800,
          fontSize: size * 0.36,
        ),
      ),
    );
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

class _Bubble extends StatelessWidget {
  final DirectMessage message;
  final VoidCallback onReply;
  final VoidCallback? onDelete;

  const _Bubble({required this.message, required this.onReply, this.onDelete});

  @override
  Widget build(BuildContext context) {
    final isMine = message.isMine;
    final textColor = isMine ? Colors.white : CT.textOf(context);

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 2),
      child: Row(
        mainAxisAlignment:
            isMine ? MainAxisAlignment.end : MainAxisAlignment.start,
        children: [
          Flexible(
            child: GestureDetector(
              onLongPress: () => _showActions(context),
              child: Container(
                constraints: BoxConstraints(
                  maxWidth: MediaQuery.of(context).size.width * 0.75,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 9),
                decoration: BoxDecoration(
                  color: isMine ? CT.primary : CT.cardOf(context),
                  borderRadius: BorderRadius.only(
                    topLeft: const Radius.circular(14),
                    topRight: const Radius.circular(14),
                    bottomLeft: Radius.circular(isMine ? 14 : 4),
                    bottomRight: Radius.circular(isMine ? 4 : 14),
                  ),
                  border: isMine ? null : Border.all(color: CT.borderOf(context)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (message.contextLabel != null) ...[
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color: (isMine ? Colors.white : CT.primary)
                              .withOpacity(0.15),
                          borderRadius: CT.r8,
                        ),
                        child: Text(
                          'About ${message.contextLabel}',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: isMine ? Colors.white : CT.primary,
                          ),
                        ),
                      ),
                    ],
                    if (message.replyToId != null) ...[
                      Container(
                        padding: const EdgeInsets.all(8),
                        margin: const EdgeInsets.only(bottom: 7),
                        decoration: BoxDecoration(
                          color:
                              (isMine ? Colors.white : CT.primary).withOpacity(0.12),
                          borderRadius: CT.r8,
                          border: Border(
                            left: BorderSide(
                              color: isMine ? Colors.white70 : CT.primary,
                              width: 3,
                            ),
                          ),
                        ),
                        child: Text(
                          message.replyToContent ?? 'Message',
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.5,
                            color: isMine ? Colors.white70 : CT.subTextOf(context),
                          ),
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
                        fontStyle: message.isDeleted ? FontStyle.italic : null,
                        color: message.isDeleted
                            ? (isMine ? Colors.white70 : CT.textHint)
                            : textColor,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          CT.timeAgo(context, message.createdAt),
                          style: TextStyle(
                            fontSize: 9.5,
                            color: isMine ? Colors.white70 : CT.textHint,
                          ),
                        ),
                        if (isMine) ...[
                          const SizedBox(width: 4),
                          Icon(
                            message.isRead
                                ? Icons.done_all_rounded
                                : Icons.done_rounded,
                            size: 12,
                            color: Colors.white70,
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
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
                leading:
                    const Icon(Icons.delete_outline_rounded, color: CT.danger),
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
  final DirectMessage message;
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
                const Text(
                  'Replying',
                  style: TextStyle(
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

class _BlockedBanner extends StatelessWidget {
  final bool blockedByMe;
  final VoidCallback onUnblock;

  const _BlockedBanner({required this.blockedByMe, required this.onUnblock});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      color: CT.surfaceOf(context),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              blockedByMe
                  ? 'You blocked this person.'
                  : 'You can no longer send messages in this conversation.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 12.5, color: CT.subTextOf(context)),
            ),
            if (blockedByMe) ...[
              const SizedBox(height: 10),
              OutlinedButton(
                onPressed: onUnblock,
                style: OutlinedButton.styleFrom(
                  foregroundColor: CT.primary,
                  side: const BorderSide(color: CT.primary),
                  shape: const RoundedRectangleBorder(borderRadius: CT.r12),
                ),
                child: const Text('Unblock'),
              ),
            ],
          ],
        ),
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
