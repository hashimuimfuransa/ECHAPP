/// Models for one-to-one messaging — students, teachers and admins.
///
/// Conversations are not tied to a course: the inbox spans everything, and the
/// backend decides per message whether the two people are still allowed to
/// talk (they share a course, or one of them is an admin).
library;

/// A person you can message.
class MessageContact {
  final String id;
  final String fullName;
  final String? avatar;
  final String role;
  final bool isTeacher;
  final DateTime? lastActive;

  /// True when a thread with this person already exists.
  final bool hasConversation;
  final DateTime? lastMessageAt;

  const MessageContact({
    required this.id,
    required this.fullName,
    this.avatar,
    this.role = 'student',
    this.isTeacher = false,
    this.lastActive,
    this.hasConversation = false,
    this.lastMessageAt,
  });

  factory MessageContact.fromJson(Map<String, dynamic> json) => MessageContact(
        id: _str(json['id']) ?? '',
        fullName: _str(json['fullName']) ?? 'ECH User',
        avatar: _str(json['avatar']),
        role: _str(json['role']) ?? 'student',
        isTeacher: json['isTeacher'] == true,
        lastActive: _parseDate(json['lastActive']),
        hasConversation: json['hasConversation'] == true,
        lastMessageAt: _parseDate(json['lastMessageAt']),
      );

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts.first[0]}${parts[1][0]}'.toUpperCase();
  }

  String get roleLabel {
    if (role == 'admin') return 'ECH Support';
    if (role == 'instructor') return 'Teacher';
    return 'Student';
  }
}

/// An inbox row.
class DirectConversation {
  final String id;
  final MessageContact? contact;
  final String? lastMessagePreview;
  final DateTime? lastMessageAt;
  final bool lastMessageIsMine;
  final bool lastMessageHasAttachment;
  final int unreadCount;
  final bool isMuted;
  final bool isBlockedByMe;

  /// Either side has blocked — the composer stays disabled.
  final bool isBlocked;

  const DirectConversation({
    required this.id,
    this.contact,
    this.lastMessagePreview,
    this.lastMessageAt,
    this.lastMessageIsMine = false,
    this.lastMessageHasAttachment = false,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isBlockedByMe = false,
    this.isBlocked = false,
  });

  factory DirectConversation.fromJson(Map<String, dynamic> json) {
    final last = json['lastMessage'] as Map<String, dynamic>?;
    return DirectConversation(
      id: _str(json['id']) ?? '',
      contact: json['contact'] != null
          ? MessageContact.fromJson(json['contact'] as Map<String, dynamic>)
          : null,
      lastMessagePreview: last != null ? _str(last['content']) : null,
      lastMessageAt: _parseDate(json['lastMessageAt']),
      lastMessageIsMine: last != null && last['isMine'] == true,
      lastMessageHasAttachment: last != null && last['hasAttachment'] == true,
      unreadCount: _parseInt(json['unreadCount']) ?? 0,
      isMuted: json['isMuted'] == true,
      isBlockedByMe: json['isBlockedByMe'] == true,
      isBlocked: json['isBlocked'] == true,
    );
  }

  bool get hasUnread => unreadCount > 0;

  /// What the inbox row shows under the name.
  String get preview {
    if (isBlocked) return 'Blocked';
    final text = (lastMessagePreview ?? '').trim();
    if (text.isEmpty) {
      return lastMessageHasAttachment ? '📎 Attachment' : 'Say hello';
    }
    return lastMessageIsMine ? 'You: $text' : text;
  }
}

class DirectMessage {
  final String id;
  final String? content;
  final List<MessageAttachment> attachments;
  final bool isMine;
  final MessageContact? sender;
  final String? contextLabel;
  final String? contextCourseId;
  final String? replyToId;
  final String? replyToContent;
  final bool isRead;
  final bool isDeleted;
  final DateTime? createdAt;

  const DirectMessage({
    required this.id,
    this.content,
    this.attachments = const [],
    this.isMine = false,
    this.sender,
    this.contextLabel,
    this.contextCourseId,
    this.replyToId,
    this.replyToContent,
    this.isRead = false,
    this.isDeleted = false,
    this.createdAt,
  });

  factory DirectMessage.fromJson(Map<String, dynamic> json) {
    final context = json['context'] as Map<String, dynamic>?;
    final replyTo = json['replyTo'] as Map<String, dynamic>?;
    return DirectMessage(
      id: _str(json['id']) ?? '',
      content: _str(json['content']),
      attachments: (json['attachments'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(MessageAttachment.fromJson)
          .toList(),
      isMine: json['isMine'] == true,
      sender: json['sender'] != null
          ? MessageContact.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      contextLabel: context != null ? _str(context['label']) : null,
      contextCourseId: context != null ? _str(context['courseId']) : null,
      replyToId: replyTo != null ? _str(replyTo['id']) : null,
      replyToContent: replyTo != null ? _str(replyTo['content']) : null,
      isRead: json['isRead'] == true,
      isDeleted: json['isDeleted'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class MessageAttachment {
  final String name;
  final String url;
  final String? mimeType;
  final int? size;

  const MessageAttachment({
    required this.name,
    required this.url,
    this.mimeType,
    this.size,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) => MessageAttachment(
        name: _str(json['name']) ?? 'Attachment',
        url: _str(json['url']) ?? '',
        mimeType: _str(json['mimeType']),
        size: _parseInt(json['size']),
      );

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
      };
}

// ── helpers ──────────────────────────────────────────────────────

String? _str(dynamic value) {
  if (value == null) return null;
  if (value is String) return value.isEmpty ? null : value;
  return value.toString();
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}
