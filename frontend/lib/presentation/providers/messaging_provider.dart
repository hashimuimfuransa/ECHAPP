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
  final String _conversationId;
  Timer? _poller;

  DirectChatNotifier(this._service, this._ref, this._conversationId)
      : super(const DirectChatState());

  /// No socket layer yet — the open thread refreshes on a short timer.
  /// Swapping in a socket later only touches this notifier.
  static const _pollInterval = Duration(seconds: 10);

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getMessages(_conversationId);
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
    if (state.messages.isEmpty || !state.hasMore) return;
    final oldest = state.messages.first.createdAt;
    if (oldest == null) return;
    try {
      final result = await _service.getMessages(_conversationId, before: oldest);
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
    state = state.copyWith(isSending: true, error: null);
    try {
      final message = await _service.sendMessage(
        _conversationId,
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
    try {
      final updated = await _service.updateConversation(
        _conversationId,
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
    try {
      final updated = await _service.updateConversation(
        _conversationId,
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
    StateNotifierProvider.family<DirectChatNotifier, DirectChatState, String>(
        (ref, conversationId) {
  return DirectChatNotifier(
    ref.watch(messagingServiceProvider),
    ref,
    conversationId,
  );
});

/// Opens (or resumes) the thread with a person and returns its id, so callers
/// can navigate straight into the chat screen.
final openConversationProvider =
    FutureProvider.family<DirectConversation, String>((ref, userId) async {
  final conversation =
      await ref.watch(messagingServiceProvider).openConversation(userId);
  ref.invalidate(conversationsProvider);
  return conversation;
});
