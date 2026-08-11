import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/direct_message.dart';
import '../../services/api/messaging_service.dart';

/// Riverpod wiring for one-to-one messaging.

final messagingServiceProvider = Provider<MessagingService>((ref) {
  final service = MessagingService();
  ref.onDispose(service.dispose);
  return service;
});

/// The inbox.
final conversationsProvider = FutureProvider<
    ({List<DirectConversation> conversations, int totalUnread})>((ref) async {
  return ref.watch(messagingServiceProvider).getConversations();
});

/// Badge count for the sidebar / nav.
final messagesUnreadProvider = FutureProvider<int>((ref) async {
  return ref.watch(messagingServiceProvider).getUnreadCount();
});

/// People the signed-in user may start a conversation with.
final messageContactsProvider =
    FutureProvider.family<List<MessageContact>, String>((ref, search) async {
  return ref.watch(messagingServiceProvider).getContacts(search: search);
});

// ─────────────────────────────────────────────
//  A single thread
// ─────────────────────────────────────────────

/// Identifies a chat thread by whichever handle the caller has.
///
/// The inbox knows the conversation; a "Message" button only knows the other
/// person. Accepting both lets the screen navigate instantly and resolve in
/// the background, instead of blocking on a round trip before it opens.
class ChatTarget {
  final String? conversationId;
  final String? userId;

  const ChatTarget.conversation(String id)
      : conversationId = id,
        userId = null;

  const ChatTarget.user(String id)
      : userId = id,
        conversationId = null;

  @override
  bool operator ==(Object other) =>
      other is ChatTarget &&
      other.conversationId == conversationId &&
      other.userId == userId;

  @override
  int get hashCode => Object.hash(conversationId, userId);
}

class DirectChatState {
  final DirectConversation? conversation;
  final List<DirectMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasMore;
  final String? error;

  const DirectChatState({
    this.conversation,
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore = false,
    this.error,
  });

  DirectChatState copyWith({
    DirectConversation? conversation,
    List<DirectMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasMore,
    String? error,
  }) {
    return DirectChatState(
      conversation: conversation ?? this.conversation,
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class DirectChatNotifier extends StateNotifier<DirectChatState> {
  final MessagingService _service;
  final Ref _ref;
  final ChatTarget _target;
  Timer? _poller;

  /// Filled in once the thread is known — either handed to us, or resolved
  /// from the other person's user id on first load.
  String? _conversationId;

  DirectChatNotifier(this._service, this._ref, this._target)
      : _conversationId = _target.conversationId,
        super(const DirectChatState());

  /// No socket layer yet — the open thread refreshes on a short timer.
  /// Swapping in a socket later only touches this notifier.
  static const _pollInterval = Duration(seconds: 10);

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      // Opening from a "Message" button gives us a user id, not a thread.
      // Resolving it also returns the first page, so this stays one round trip.
      if (_conversationId == null) {
        final opened = await _service.openConversation(_target.userId!);
        _conversationId = opened.conversation.id;
        if (!mounted) return;
        state = state.copyWith(
          conversation: opened.conversation,
          messages: opened.messages,
          hasMore: opened.hasMore,
          isLoading: false,
        );
        _ref.invalidate(messagesUnreadProvider);
        _ref.invalidate(conversationsProvider);
        return;
      }

      final result = await _service.getMessages(_conversationId!);
      if (!mounted) return;
      state = state.copyWith(
        conversation: result.conversation,
        messages: result.messages,
        hasMore: result.hasMore,
        isLoading: false,
      );
      // Opening the thread clears its unread badge server-side; refresh the
      // inbox so the count in the nav follows.
      _ref.invalidate(messagesUnreadProvider);
      _ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: silent ? null : e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  Future<void> loadOlder() async {
    final id = _conversationId;
    if (id == null || state.messages.isEmpty || !state.hasMore) return;
    final oldest = state.messages.first.createdAt;
    if (oldest == null) return;
    try {
      final result = await _service.getMessages(id, before: oldest);
      if (!mounted) return;
      state = state.copyWith(
        messages: [...result.messages, ...state.messages],
        hasMore: result.hasMore,
      );
    } catch (_) {
      // Paging back is best-effort; never disturb the open conversation.
    }
  }

  Future<bool> send(
    String content, {
    String? replyTo,
    String? contextLabel,
    String? contextCourseId,
  }) async {
    if (content.trim().isEmpty) return false;
    final id = _conversationId;
    if (id == null) {
      state = state.copyWith(error: 'Still opening the conversation — try again');
      return false;
    }
    state = state.copyWith(isSending: true, error: null);
    try {
      final message = await _service.sendMessage(
        id,
        content: content.trim(),
        replyTo: replyTo,
        contextLabel: contextLabel,
        contextCourseId: contextCourseId,
      );
      if (!mounted) return true;
      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
      );
      _ref.invalidate(conversationsProvider);
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(
        isSending: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      return false;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _service.deleteMessage(messageId);
      if (!mounted) return;
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != messageId).toList(),
      );
      _ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
    }
  }

  Future<void> setBlocked(bool blocked) async {
    final id = _conversationId;
    if (id == null) return;
    try {
      final updated = await _service.updateConversation(
        id,
        blocked: blocked,
      );
      if (!mounted) return;
      state = state.copyWith(conversation: updated);
      _ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> setMuted(bool muted) async {
    final id = _conversationId;
    if (id == null) return;
    try {
      final updated = await _service.updateConversation(
        id,
        muted: muted,
      );
      if (!mounted) return;
      state = state.copyWith(conversation: updated);
      _ref.invalidate(conversationsProvider);
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString().replaceFirst('Exception: ', ''));
    }
  }

  void startPolling() {
    _poller ??= Timer.periodic(_pollInterval, (_) => load(silent: true));
  }

  void stopPolling() {
    _poller?.cancel();
    _poller = null;
  }

  @override
  void dispose() {
    _poller?.cancel();
    super.dispose();
  }
}

final directChatProvider =
    StateNotifierProvider.family<DirectChatNotifier, DirectChatState, ChatTarget>(
        (ref, target) {
  return DirectChatNotifier(ref.watch(messagingServiceProvider), ref, target);
});
