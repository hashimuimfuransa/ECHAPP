import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/app_localizations.dart';
import '../../../models/community.dart';
import '../../providers/community_provider.dart';
import '../../providers/messaging_provider.dart';
import '../messages/direct_chat_screen.dart';
import '../messages/messages_screen.dart' show showNewMessageSheet;
import 'community_chat_view.dart';
import 'community_theme.dart';
import 'group_workspace_screen.dart';

/// The Chat tab: every conversation the student has in one place — the public
/// course room, each of their study groups, and their direct chats.
///
/// A single long poll behind [chatInboxProvider] keeps all three live, so a
/// message lands here about a second after it is sent, whichever room it
/// belongs to.
class CommunityChatInboxView extends ConsumerStatefulWidget {
  final String courseId;

  const CommunityChatInboxView({super.key, required this.courseId});

  @override
  ConsumerState<CommunityChatInboxView> createState() =>
      _CommunityChatInboxViewState();
}

class _CommunityChatInboxViewState extends ConsumerState<CommunityChatInboxView> {
  /// all | public | groups | direct
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final notifier = ref.read(chatInboxProvider(widget.courseId).notifier);
      notifier.loadInbox();
      notifier.start();
      ref.read(communityPresenceProvider(widget.courseId)).start(area: 'chat');
    });
  }

  @override
  void dispose() {
    // The notifier is provider-scoped, so end the long poll explicitly when
    // the tab goes away rather than leaving it holding a request open.
    ref.read(chatInboxProvider(widget.courseId).notifier).stop();
    super.dispose();
  }

  List<ChatRoomSummary> _visibleRooms(ChatInboxState state) {
    return switch (_filter) {
      'public' => state.publicRooms,
      'groups' => state.groupRooms,
      'direct' => state.directRooms,
      _ => state.rooms,
    };
  }

  void _openRoom(ChatRoomSummary room) {
    final notifier = ref.read(chatInboxProvider(widget.courseId).notifier);
    notifier.markRoomRead(room.key);

    if (room.isDirect && room.conversationId != null) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            target: ChatTarget.conversation(room.conversationId!),
            contactName: room.title,
            contactAvatar: room.contact?.avatar,
            contactRole: room.subtitle,
          ),
        ),
      );
      return;
    }

    if (room.isGroup && room.groupId != null) {
      // The group's chat lives in its workspace, alongside its tasks and work.
      openGroupWorkspace(context, widget.courseId, room.groupId!);
      return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _CourseRoomScreen(
          courseId: widget.courseId,
          title: room.title,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(chatInboxProvider(widget.courseId));

    // Any room receiving messages refreshes the inbox ordering for free via
    // the sync payload; this listener only needs to keep badges honest.
    final rooms = _visibleRooms(state);

    return Column(
      children: [
        _LiveHeader(
          isLive: state.isLive,
          totalUnread: state.totalUnread,
          onNewMessage: () => showNewMessageSheet(context, ref),
        ),
        SizedBox(
          height: 44,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            children: [
              _filterChip('all', l10n.all, state.rooms.length),
              _filterChip('public', l10n.publicFilter, state.publicRooms.length),
              _filterChip('groups', l10n.communitySectionGroups, state.groupRooms.length),
              _filterChip('direct', l10n.directFilter, state.directRooms.length),
            ],
          ),
        ),
        Expanded(
          child: state.isLoading && state.rooms.isEmpty
              ? const Center(
                  child:
                      CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
                )
              : state.error != null && state.rooms.isEmpty
                  ? CommunityErrorView(
                      error: state.error!,
                      onRetry: () => ref
                          .read(chatInboxProvider(widget.courseId).notifier)
                          .loadInbox(),
                    )
                  : rooms.isEmpty
                      ? CommunityEmpty(
                          icon: Icons.forum_rounded,
                          title: switch (_filter) {
                            'direct' => l10n.noDirectChatsYet,
                            'groups' => l10n.notInGroupYetShort,
                            _ => l10n.noConversationsYet,
                          },
                          message: switch (_filter) {
                            'direct' =>
                              l10n.directChatsHint,
                            'groups' =>
                              l10n.groupChatsHint,
                            _ => l10n.startWithCourseChat,
                          },
                          actionLabel: _filter == 'direct' ? l10n.newMessage : null,
                          onAction: _filter == 'direct'
                              ? () => showNewMessageSheet(context, ref)
                              : null,
                        )
                      : RefreshIndicator(
                          color: CT.primary,
                          onRefresh: () => ref
                              .read(chatInboxProvider(widget.courseId).notifier)
                              .loadInbox(),
                          child: ListView.separated(
                            padding: const EdgeInsets.fromLTRB(16, 10, 16, 90),
                            itemCount: rooms.length,
                            separatorBuilder: (_, __) => const SizedBox(height: 8),
                            itemBuilder: (context, index) => _RoomTile(
                              room: rooms[index],
                              onTap: () => _openRoom(rooms[index]),
                            ),
                          ),
                        ),
        ),
      ],
    );
  }

  Widget _filterChip(String value, String label, int count) {
    final selected = _filter == value;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        selected: selected,
        onSelected: (_) => setState(() => _filter = value),
        label: Text(count > 0 ? '$label · $count' : label),
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

/// Live indicator plus the "new direct message" action.
class _LiveHeader extends StatelessWidget {
  final bool isLive;
  final int totalUnread;
  final VoidCallback onNewMessage;

  const _LiveHeader({
    required this.isLive,
    required this.totalUnread,
    required this.onNewMessage,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: isLive ? CT.primary : CT.textHint,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            isLive ? l10n.live : l10n.connecting,
            style: TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: isLive ? CT.primary : CT.subTextOf(context),
            ),
          ),
          if (totalUnread > 0) ...[
            const SizedBox(width: 10),
            Text(
              l10n.unreadCount(totalUnread.toString()),
              style: TextStyle(fontSize: 11.5, color: CT.subTextOf(context)),
            ),
          ],
          const Spacer(),
          TextButton.icon(
            onPressed: onNewMessage,
            icon: const Icon(Icons.edit_rounded, size: 15),
            label: Text(l10n.newMessage),
            style: TextButton.styleFrom(
              foregroundColor: CT.primary,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomTile extends StatelessWidget {
  final ChatRoomSummary room;
  final VoidCallback onTap;

  const _RoomTile({required this.room, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final unread = room.hasUnread;

    return CommunityCard(
      padding: const EdgeInsets.all(12),
      accent: unread ? CT.primary : null,
      onTap: onTap,
      child: Row(
        children: [
          _RoomAvatar(room: room),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        room.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                          color: CT.textOf(context),
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _RoomKindChip(room: room),
                    const Spacer(),
                    Text(
                      CT.timeAgo(context, room.lastMessageAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                        color: unread ? CT.primary : CT.textHint,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        room.preview,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: unread ? FontWeight.w600 : FontWeight.w400,
                          color: unread
                              ? CT.textOf(context)
                              : CT.subTextOf(context),
                        ),
                      ),
                    ),
                    if (unread) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          color: CT.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          room.unreadCount > 99 ? '99+' : '${room.unreadCount}',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _RoomAvatar extends StatelessWidget {
  final ChatRoomSummary room;
  const _RoomAvatar({required this.room});

  @override
  Widget build(BuildContext context) {
    if (room.isDirect && room.contact != null) {
      return MemberAvatar(member: room.contact!, size: 46);
    }

    final color = room.isPublic ? CT.primary : CT.avatarColor(room.key);
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color, color.withOpacity(0.72)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: CT.r12,
      ),
      child: Icon(
        room.isPublic ? Icons.campaign_rounded : Icons.groups_2_rounded,
        color: Colors.white,
        size: 22,
      ),
    );
  }
}

/// Tells public, group and private apart at a glance — the thing that makes a
/// mixed inbox readable.
class _RoomKindChip extends StatelessWidget {
  final ChatRoomSummary room;
  const _RoomKindChip({required this.room});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    if (room.isPublic) {
      return CommunityChip(
        label: l10n.publicFilter,
        icon: Icons.public_rounded,
        color: CT.primary,
      );
    }
    if (room.isGroup) {
      return CommunityChip(
        label: l10n.groupLabel,
        icon: Icons.groups_rounded,
        color: CT.accent,
      );
    }
    if (room.contact?.isTeacher == true) {
      return CommunityChip(
        label: l10n.teacher,
        icon: Icons.school_rounded,
        color: CT.teacher,
      );
    }
    return CommunityChip(
      label: l10n.privateLabel,
      icon: Icons.lock_rounded,
      color: CT.info,
    );
  }
}

/// The public course room, opened full-screen from the inbox.
class _CourseRoomScreen extends StatelessWidget {
  final String courseId;
  final String title;

  const _CourseRoomScreen({required this.courseId, required this.title});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 0,
        title: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: CT.heroGrad),
                borderRadius: CT.r12,
              ),
              child: const Icon(Icons.campaign_rounded,
                  color: Colors.white, size: 17),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: CT.textOf(context),
                    ),
                  ),
                  Text(
                    l10n.everyoneInThisCourse,
                    style: TextStyle(fontSize: 11, color: CT.subTextOf(context)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: CommunityChatView(courseId: courseId),
    );
  }
}
