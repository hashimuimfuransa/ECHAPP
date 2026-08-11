import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../models/direct_message.dart';
import '../../providers/messaging_provider.dart';
import '../community/community_theme.dart';
import 'direct_chat_screen.dart';

/// The inbox — every one-to-one conversation, newest first.
class MessagesScreen extends ConsumerWidget {
  const MessagesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inboxAsync = ref.watch(conversationsProvider);

    return Scaffold(
      backgroundColor: CT.bgOf(context),
      appBar: AppBar(
        backgroundColor: CT.cardOf(context),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: Text(
          'Messages',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: CT.textOf(context),
          ),
        ),
        actions: [
          IconButton(
            onPressed: () => ref.invalidate(conversationsProvider),
            icon: const Icon(Icons.refresh_rounded, size: 21),
            color: CT.subTextOf(context),
            tooltip: 'Refresh',
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        heroTag: 'new-message',
        onPressed: () => showNewMessageSheet(context, ref),
        backgroundColor: CT.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('New message'),
      ),
      body: inboxAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
        ),
        error: (error, _) => CommunityErrorView(
          error: error,
          onRetry: () => ref.invalidate(conversationsProvider),
        ),
        data: (inbox) {
          if (inbox.conversations.isEmpty) {
            return CommunityEmpty(
              icon: Icons.forum_rounded,
              title: 'No messages yet',
              message: 'Message a classmate or your teacher directly. You can '
                  'reach anyone you share a course with.',
              actionLabel: 'Start a conversation',
              onAction: () => showNewMessageSheet(context, ref),
            );
          }
          return RefreshIndicator(
            color: CT.primary,
            onRefresh: () async => ref.invalidate(conversationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
              itemCount: inbox.conversations.length,
              separatorBuilder: (_, __) => const SizedBox(height: 8),
              itemBuilder: (context, index) => _ConversationTile(
                conversation: inbox.conversations[index],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final DirectConversation conversation;

  const _ConversationTile({required this.conversation});

  @override
  Widget build(BuildContext context) {
    final contact = conversation.contact;
    final unread = conversation.hasUnread;

    return CommunityCard(
      padding: const EdgeInsets.all(12),
      accent: unread ? CT.primary : null,
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => DirectChatScreen(
            target: ChatTarget.conversation(conversation.id),
            contactName: contact?.fullName ?? 'Chat',
            contactAvatar: contact?.avatar,
            contactRole: contact?.roleLabel,
          ),
        ),
      ),
      child: Row(
        children: [
          _Avatar(contact: contact),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        contact?.fullName ?? 'ECH User',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: unread ? FontWeight.w800 : FontWeight.w700,
                          color: CT.textOf(context),
                        ),
                      ),
                    ),
                    if (contact?.isTeacher == true) ...[
                      const SizedBox(width: 7),
                      TeacherBadge(
                        label: contact!.role == 'admin' ? 'Support' : 'Teacher',
                      ),
                    ],
                    const Spacer(),
                    Text(
                      CT.timeAgo(conversation.lastMessageAt),
                      style: TextStyle(
                        fontSize: 10.5,
                        color: unread ? CT.primary : CT.textHint,
                        fontWeight: unread ? FontWeight.w700 : FontWeight.w400,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    if (conversation.isMuted) ...[
                      Icon(Icons.notifications_off_rounded,
                          size: 12, color: CT.textHint),
                      const SizedBox(width: 5),
                    ],
                    Expanded(
                      child: Text(
                        conversation.preview,
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
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        constraints: const BoxConstraints(minWidth: 20),
                        decoration: BoxDecoration(
                          color: CT.primary,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          conversation.unreadCount > 99
                              ? '99+'
                              : '${conversation.unreadCount}',
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

class _Avatar extends StatelessWidget {
  final MessageContact? contact;
  const _Avatar({this.contact});

  @override
  Widget build(BuildContext context) {
    final name = contact?.fullName ?? '?';
    final color = CT.avatarColor(contact?.id ?? name);
    final avatar = contact?.avatar;

    return Container(
      width: 46,
      height: 46,
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
              errorBuilder: (_, __, ___) => _initials(contact),
            )
          : _initials(contact),
    );
  }

  static Widget _initials(MessageContact? contact) => Center(
        child: Text(
          contact?.initials ?? '?',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w800,
            fontSize: 16,
          ),
        ),
      );
}

// ─────────────────────────────────────────────
//  New message
// ─────────────────────────────────────────────

/// Contact picker — everyone the user is allowed to message.
Future<void> showNewMessageSheet(BuildContext context, WidgetRef ref) {
  return showCommunitySheet<void>(
    context: context,
    title: 'New message',
    initialSize: 0.8,
    builder: (ctx, controller) => _ContactPicker(scrollController: controller),
  );
}

class _ContactPicker extends ConsumerStatefulWidget {
  final ScrollController scrollController;

  const _ContactPicker({required this.scrollController});

  @override
  ConsumerState<_ContactPicker> createState() => _ContactPickerState();
}

class _ContactPickerState extends ConsumerState<_ContactPicker> {
  String _search = '';

  @override
  Widget build(BuildContext context) {
    final contactsAsync = ref.watch(messageContactsProvider(_search));

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 10),
          child: TextField(
            onChanged: (value) => setState(() => _search = value),
            style: TextStyle(fontSize: 13.5, color: CT.textOf(context)),
            decoration: InputDecoration(
              hintText: 'Search by name',
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
          child: contactsAsync.when(
            loading: () => const Center(
              child: CircularProgressIndicator(strokeWidth: 2.4, color: CT.primary),
            ),
            error: (error, _) => CommunityErrorView(
              error: error,
              onRetry: () => ref.invalidate(messageContactsProvider(_search)),
            ),
            data: (contacts) {
              if (contacts.isEmpty) {
                return CommunityEmpty(
                  icon: Icons.person_search_rounded,
                  title: _search.isEmpty ? 'Nobody to message yet' : 'No matches',
                  message: _search.isEmpty
                      ? 'Enrol in a course and your classmates and teachers '
                          'will appear here.'
                      : 'Try a different name.',
                  compact: true,
                );
              }
              return ListView.builder(
                controller: widget.scrollController,
                padding: const EdgeInsets.fromLTRB(12, 0, 12, 20),
                itemCount: contacts.length,
                itemBuilder: (context, index) {
                  final contact = contacts[index];
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: CommunityCard(
                      padding: const EdgeInsets.all(12),
                      onTap: () {
                        // Close the picker first so the chat replaces it
                        // rather than stacking on top of a sheet.
                        Navigator.of(context).pop();
                        openDirectChatWithUser(
                          context,
                          ref,
                          contact.id,
                          displayName: contact.fullName,
                          avatarUrl: contact.avatar,
                          roleLabel: contact.roleLabel,
                        );
                      },
                      child: Row(
                        children: [
                          _Avatar(contact: contact),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Flexible(
                                      child: Text(
                                        contact.fullName,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 13.5,
                                          fontWeight: FontWeight.w700,
                                          color: CT.textOf(context),
                                        ),
                                      ),
                                    ),
                                    if (contact.isTeacher) ...[
                                      const SizedBox(width: 7),
                                      TeacherBadge(
                                        label: contact.role == 'admin'
                                            ? 'Support'
                                            : 'Teacher',
                                      ),
                                    ],
                                  ],
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  contact.hasConversation
                                      ? 'You have talked before'
                                      : contact.roleLabel,
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: CT.subTextOf(context),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Icon(Icons.chevron_right_rounded,
                              size: 20, color: CT.subTextOf(context)),
                        ],
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }
}
