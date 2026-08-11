import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/direct_message.dart';
import '../infrastructure/api_client.dart';

/// Client for one-to-one messaging (`/api/messages/...`).
class MessagingService {
  final ApiClient _apiClient;

  MessagingService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  String get _base => ApiConfig.messages;

  /// Statically typed so the `validateStatus` extension resolves — a `dynamic`
  /// receiver would compile and then fail at runtime.
  Map<String, dynamic> _unwrap(http.Response response) {
    response.validateStatus();

    final raw = response.body.trim();
    if (raw.isEmpty) return <String, dynamic>{};

    final Object? body;
    try {
      body = jsonDecode(raw);
    } catch (_) {
      throw ApiException('The messaging service returned an unreadable response');
    }

    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from the messaging service');
    }
    if (body['success'] != true) {
      throw ApiException(body['message']?.toString() ?? 'Request failed');
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  /// People this user is allowed to start a conversation with.
  Future<List<MessageContact>> getContacts({String search = ''}) async {
    final response = await _apiClient.get(
      '$_base/contacts',
      queryParams: {if (search.isNotEmpty) 'search': search},
    );
    final data = _unwrap(response);
    return (data['contacts'] as List? ?? [])
        .map((c) => MessageContact.fromJson(c as Map<String, dynamic>))
        .toList();
  }

  Future<({List<DirectConversation> conversations, int totalUnread})>
      getConversations() async {
    final data = _unwrap(await _apiClient.get('$_base/conversations'));
    return (
      conversations: (data['conversations'] as List? ?? [])
          .map((c) => DirectConversation.fromJson(c as Map<String, dynamic>))
          .toList(),
      totalUnread: (data['totalUnread'] as num?)?.toInt() ?? 0,
    );
  }

  /// Opens (or resumes) the thread with someone. Idempotent.
  Future<DirectConversation> openConversation(String userId) async {
    final response = await _apiClient.post(
      '$_base/conversations',
      body: {'userId': userId},
    );
    return DirectConversation.fromJson(_unwrap(response));
  }

  Future<({DirectConversation conversation, List<DirectMessage> messages, bool hasMore})>
      getMessages(String conversationId, {DateTime? before, int limit = 40}) async {
    final response = await _apiClient.get(
      '$_base/conversations/$conversationId/messages',
      queryParams: {
        if (before != null) 'before': before.toIso8601String(),
        'limit': limit,
      },
    );
    final data = _unwrap(response);
    return (
      conversation: DirectConversation.fromJson(
          data['conversation'] as Map<String, dynamic>? ?? const {}),
      messages: (data['messages'] as List? ?? [])
          .map((m) => DirectMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      hasMore: data['hasMore'] == true,
    );
  }

  Future<DirectMessage> sendMessage(
    String conversationId, {
    required String content,
    List<MessageAttachment> attachments = const [],
    String? replyTo,
    String? contextLabel,
    String? contextCourseId,
  }) async {
    final response = await _apiClient.post(
      '$_base/conversations/$conversationId/messages',
      body: {
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        if (replyTo != null) 'replyTo': replyTo,
        if (contextLabel != null)
          'context': {
            'label': contextLabel,
            if (contextCourseId != null) 'courseId': contextCourseId,
          },
      },
    );
    return DirectMessage.fromJson(_unwrap(response));
  }

  Future<void> deleteMessage(String messageId) async {
    _unwrap(await _apiClient.delete('$_base/messages/$messageId'));
  }

  /// Block, unblock, mute or hide a conversation.
  Future<DirectConversation> updateConversation(
    String conversationId, {
    bool? blocked,
    bool? muted,
    bool? hidden,
  }) async {
    final response = await _apiClient.patch(
      '$_base/conversations/$conversationId',
      body: {
        if (blocked != null) 'blocked': blocked,
        if (muted != null) 'muted': muted,
        if (hidden != null) 'hidden': hidden,
      },
    );
    return DirectConversation.fromJson(_unwrap(response));
  }

  Future<int> getUnreadCount() async {
    final data = _unwrap(await _apiClient.get('$_base/unread'));
    return (data['unreadCount'] as num?)?.toInt() ?? 0;
  }

  void dispose() => _apiClient.dispose();
}
