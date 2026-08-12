import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../config/api_config.dart';
import '../../models/community.dart';
import '../infrastructure/api_client.dart';

/// Client for the Course Community API (`/api/community/:courseId/...`).
///
/// Every call is scoped to a course; the backend decides from the caller's
/// enrollment or teaching assignment whether they are a member and whether
/// they hold teacher powers.
class CommunityService {
  final ApiClient _apiClient;

  CommunityService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  String _base(String courseId) => ApiConfig.communityCourse(courseId);

  /// Unwraps `{ success, message, data }` and throws on a non-2xx status.
  ///
  /// The parameter is statically typed as [http.Response] on purpose:
  /// `validateStatus` comes from an extension, and extension methods only
  /// resolve against a static type — a `dynamic` parameter would compile but
  /// blow up at runtime with NoSuchMethodError.
  Map<String, dynamic> _unwrap(http.Response response) {
    response.validateStatus();

    final raw = response.body.trim();
    if (raw.isEmpty) return <String, dynamic>{};

    final Object? body;
    try {
      body = jsonDecode(raw);
    } catch (_) {
      throw ApiException('The community service returned an unreadable response');
    }

    if (body is! Map<String, dynamic>) {
      throw ApiException('Unexpected response from the community service');
    }
    if (body['success'] != true) {
      throw ApiException(body['message']?.toString() ?? 'Request failed');
    }
    final data = body['data'];
    return data is Map<String, dynamic> ? data : <String, dynamic>{};
  }

  // ── Dashboard, people & presence ──────────────────────────────

  Future<CommunityOverview> getOverview(String courseId) async {
    final response = await _apiClient.get('${_base(courseId)}/overview');
    return CommunityOverview.fromJson(_unwrap(response));
  }

  Future<MemberDirectory> getMembers(
    String courseId, {
    String search = '',
    String filter = 'all',
    int page = 1,
    int limit = 30,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/members',
      queryParams: {
        if (search.isNotEmpty) 'search': search,
        'filter': filter,
        'page': page,
        'limit': limit,
      },
    );
    return MemberDirectory.fromJson(_unwrap(response));
  }

  Future<MemberProfile> getMemberProfile(String courseId, String memberId) async {
    final response = await _apiClient.get('${_base(courseId)}/members/$memberId');
    return MemberProfile.fromJson(_unwrap(response));
  }

  /// Heartbeat so classmates can see "Active now". Failures are swallowed —
  /// presence is a nicety and must never interrupt studying.
  Future<int?> ping(String courseId, {String area = 'community'}) async {
    try {
      final response = await _apiClient.post(
        '${_base(courseId)}/presence/ping',
        body: {'area': area},
      );
      final data = _unwrap(response);
      return data['activeCount'] as int?;
    } catch (_) {
      return null;
    }
  }

  Future<bool> setPresenceVisibility(String courseId, bool isVisible) async {
    final response = await _apiClient.patch(
      '${_base(courseId)}/presence/visibility',
      body: {'isVisible': isVisible},
    );
    final data = _unwrap(response);
    return data['isVisible'] == true;
  }

  // ── Find study partners ───────────────────────────────────────

  Future<({List<StudyPartnerCard> partners, StudyPartnerCard? mine})> getStudyPartners(
    String courseId,
  ) async {
    final response = await _apiClient.get('${_base(courseId)}/partners');
    final data = _unwrap(response);
    return (
      partners: (data['partners'] as List? ?? [])
          .map((p) => StudyPartnerCard.fromJson(p as Map<String, dynamic>))
          .toList(),
      mine: data['myProfile'] != null
          ? StudyPartnerCard.fromJson(data['myProfile'] as Map<String, dynamic>)
          : null,
    );
  }

  Future<StudyPartnerCard> saveStudyPartnerProfile(
    String courseId, {
    required String goal,
    List<String> topics = const [],
    List<String> availability = const [],
    String note = '',
  }) async {
    final response = await _apiClient.put(
      '${_base(courseId)}/partners/me',
      body: {
        'goal': goal,
        'topics': topics,
        'availability': availability,
        'note': note,
        'isActive': true,
      },
    );
    return StudyPartnerCard.fromJson(_unwrap(response));
  }

  Future<void> removeStudyPartnerProfile(String courseId) async {
    final response = await _apiClient.delete('${_base(courseId)}/partners/me');
    _unwrap(response);
  }

  // ── Discussions, questions, help & announcements ──────────────

  Future<({List<CommunityPost> posts, int totalPages})> getPosts(
    String courseId, {
    CommunityPostType? type,
    String? helpCategory,
    String search = '',
    bool unansweredOnly = false,
    bool mineOnly = false,
    int page = 1,
    int limit = 20,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/posts',
      queryParams: {
        if (type != null) 'type': postTypeToApi(type),
        if (helpCategory != null) 'helpCategory': helpCategory,
        if (search.isNotEmpty) 'search': search,
        if (unansweredOnly) 'unanswered': 'true',
        if (mineOnly) 'mine': 'true',
        'page': page,
        'limit': limit,
      },
    );
    final data = _unwrap(response);
    final pagination = data['pagination'] as Map<String, dynamic>? ?? const {};
    return (
      posts: (data['posts'] as List? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      totalPages: (pagination['totalPages'] as num?)?.toInt() ?? 1,
    );
  }

  Future<CommunityPost> getPost(String courseId, String postId) async {
    final response = await _apiClient.get('${_base(courseId)}/posts/$postId');
    return CommunityPost.fromJson(_unwrap(response));
  }

  Future<CommunityPost> createPost(
    String courseId, {
    required CommunityPostType type,
    String? title,
    required String content,
    String? helpCategory,
    List<String> tags = const [],
    List<CommunityAttachment> attachments = const [],
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/posts',
      body: {
        'type': postTypeToApi(type),
        if (title != null && title.isNotEmpty) 'title': title,
        'content': content,
        if (helpCategory != null) 'helpCategory': helpCategory,
        'tags': tags,
        'attachments': attachments.map((a) => a.toJson()).toList(),
      },
    );
    return CommunityPost.fromJson(_unwrap(response));
  }

  Future<CommunityPost> updatePost(
    String courseId,
    String postId, {
    String? title,
    String? content,
    List<String>? tags,
  }) async {
    final response = await _apiClient.put(
      '${_base(courseId)}/posts/$postId',
      body: {
        if (title != null) 'title': title,
        if (content != null) 'content': content,
        if (tags != null) 'tags': tags,
      },
    );
    return CommunityPost.fromJson(_unwrap(response));
  }

  Future<void> deletePost(String courseId, String postId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/posts/$postId'));
  }

  Future<({bool liked, int likeCount})> toggleLike(
    String courseId,
    String postId, {
    String? replyId,
  }) async {
    final path = replyId == null
        ? '${_base(courseId)}/posts/$postId/like'
        : '${_base(courseId)}/posts/$postId/replies/$replyId/like';
    final data = _unwrap(await _apiClient.post(path, body: const <String, dynamic>{}));
    return (
      liked: data['liked'] == true,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  Future<PostReply> addReply(String courseId, String postId, String content) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/posts/$postId/replies',
      body: {'content': content},
    );
    return PostReply.fromJson(_unwrap(response));
  }

  Future<void> deleteReply(String courseId, String postId, String replyId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/posts/$postId/replies/$replyId'));
  }

  Future<bool> acceptReply(String courseId, String postId, String replyId) async {
    final data = _unwrap(await _apiClient.post(
      '${_base(courseId)}/posts/$postId/replies/$replyId/accept',
      body: const <String, dynamic>{},
    ));
    return data['accepted'] == true;
  }

  /// Teacher moderation: pin, close or resolve a thread.
  Future<void> moderatePost(
    String courseId,
    String postId, {
    bool? isPinned,
    bool? isClosed,
    bool? isResolved,
  }) async {
    _unwrap(await _apiClient.patch(
      '${_base(courseId)}/posts/$postId/moderate',
      body: {
        if (isPinned != null) 'isPinned': isPinned,
        if (isClosed != null) 'isClosed': isClosed,
        if (isResolved != null) 'isResolved': isResolved,
      },
    ));
  }

  // ── Study groups ──────────────────────────────────────────────

  Future<List<StudyGroupSummary>> getGroups(
    String courseId, {
    bool mineOnly = false,
    bool openOnly = false,
    String search = '',
    String? purpose,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/groups',
      queryParams: {
        if (mineOnly) 'mine': 'true',
        if (openOnly) 'openOnly': 'true',
        if (search.isNotEmpty) 'search': search,
        if (purpose != null) 'purpose': purpose,
      },
    );
    final data = _unwrap(response);
    return (data['groups'] as List? ?? [])
        .map((g) => StudyGroupSummary.fromJson(g as Map<String, dynamic>))
        .toList();
  }

  Future<StudyGroupDetail> getGroup(String courseId, String groupId) async {
    final response = await _apiClient.get('${_base(courseId)}/groups/$groupId');
    return StudyGroupDetail.fromJson(_unwrap(response));
  }

  Future<StudyGroupSummary> createGroup(
    String courseId, {
    required String name,
    String purpose = 'general',
    String description = '',
    int maxMembers = 6,
    List<String> inviteUserIds = const [],
    bool isOpen = true,
    String? assignmentId,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/groups',
      body: {
        'name': name,
        'purpose': purpose,
        'description': description,
        'maxMembers': maxMembers,
        'inviteUserIds': inviteUserIds,
        'isOpen': isOpen,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    return StudyGroupSummary.fromJson(_unwrap(response));
  }

  Future<StudyGroupSummary> updateGroup(
    String courseId,
    String groupId, {
    String? name,
    String? purpose,
    String? description,
    int? maxMembers,
    bool? isOpen,
  }) async {
    final response = await _apiClient.put(
      '${_base(courseId)}/groups/$groupId',
      body: {
        if (name != null) 'name': name,
        if (purpose != null) 'purpose': purpose,
        if (description != null) 'description': description,
        if (maxMembers != null) 'maxMembers': maxMembers,
        if (isOpen != null) 'isOpen': isOpen,
      },
    );
    return StudyGroupSummary.fromJson(_unwrap(response));
  }

  Future<void> deleteGroup(String courseId, String groupId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/groups/$groupId'));
  }

  Future<String> joinGroup(String courseId, String groupId) async {
    final data = _unwrap(
        await _apiClient.post('${_base(courseId)}/groups/$groupId/join', body: const <String, dynamic>{}));
    return data['status']?.toString() ?? 'active';
  }

  Future<void> leaveGroup(String courseId, String groupId) async {
    _unwrap(await _apiClient.post('${_base(courseId)}/groups/$groupId/leave', body: const <String, dynamic>{}));
  }

  Future<int> inviteToGroup(
    String courseId,
    String groupId,
    List<String> userIds,
  ) async {
    final data = _unwrap(await _apiClient.post(
      '${_base(courseId)}/groups/$groupId/invite',
      body: {'userIds': userIds},
    ));
    return (data['invited'] as num?)?.toInt() ?? 0;
  }

  Future<void> removeGroupMember(String courseId, String groupId, String memberId) async {
    _unwrap(await _apiClient
        .delete('${_base(courseId)}/groups/$groupId/members/$memberId'));
  }

  Future<GroupTask> addGroupTask(
    String courseId,
    String groupId, {
    required String title,
    String description = '',
    List<String> assignedTo = const [],
    DateTime? dueDate,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/groups/$groupId/tasks',
      body: {
        'title': title,
        'description': description,
        'assignedTo': assignedTo,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
      },
    );
    return GroupTask.fromJson(_unwrap(response));
  }

  Future<GroupTask> updateGroupTask(
    String courseId,
    String groupId,
    String taskId, {
    String? title,
    String? description,
    bool? isDone,
    DateTime? dueDate,
    List<String>? assignedTo,
  }) async {
    final response = await _apiClient.patch(
      '${_base(courseId)}/groups/$groupId/tasks/$taskId',
      body: {
        if (title != null) 'title': title,
        if (description != null) 'description': description,
        if (isDone != null) 'isDone': isDone,
        if (dueDate != null) 'dueDate': dueDate.toIso8601String(),
        if (assignedTo != null) 'assignedTo': assignedTo,
      },
    );
    return GroupTask.fromJson(_unwrap(response));
  }

  Future<void> deleteGroupTask(String courseId, String groupId, String taskId) async {
    _unwrap(await _apiClient
        .delete('${_base(courseId)}/groups/$groupId/tasks/$taskId'));
  }

  // ── Chat ──────────────────────────────────────────────────────

  Future<({List<CommunityChatMessage> messages, bool hasMore})> getMessages(
    String courseId, {
    String? groupId,
    DateTime? before,
    int limit = 40,
  }) async {
    final path = groupId == null
        ? '${_base(courseId)}/chat/messages'
        : '${_base(courseId)}/groups/$groupId/chat/messages';
    final response = await _apiClient.get(
      path,
      queryParams: {
        if (before != null) 'before': before.toIso8601String(),
        'limit': limit,
      },
    );
    final data = _unwrap(response);
    return (
      messages: (data['messages'] as List? ?? [])
          .map((m) => CommunityChatMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      hasMore: data['hasMore'] == true,
    );
  }

  Future<CommunityChatMessage> sendMessage(
    String courseId, {
    String? groupId,
    required String content,
    List<CommunityAttachment> attachments = const [],
    String? replyTo,
  }) async {
    final path = groupId == null
        ? '${_base(courseId)}/chat/messages'
        : '${_base(courseId)}/groups/$groupId/chat/messages';
    final response = await _apiClient.post(
      path,
      body: {
        'content': content,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        if (replyTo != null) 'replyTo': replyTo,
      },
    );
    return CommunityChatMessage.fromJson(_unwrap(response));
  }

  Future<void> deleteMessage(String courseId, String messageId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/chat/messages/$messageId'));
  }

  /// Every room the student can talk in: the public course room, their study
  /// groups, and their direct conversations — one list for the Chat tab.
  Future<({List<ChatRoomSummary> rooms, int totalUnread})> getChatInbox(
    String courseId,
  ) async {
    final data = _unwrap(await _apiClient.get('${_base(courseId)}/chat/inbox'));
    return (
      rooms: (data['rooms'] as List? ?? [])
          .map((r) => ChatRoomSummary.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalUnread: (data['totalUnread'] as num?)?.toInt() ?? 0,
    );
  }

  /// Long-polled delivery across every room at once.
  ///
  /// The request is held open by the server for up to [waitSeconds] and
  /// returns the moment anything arrives, so messages land in about a second
  /// without a socket layer. Call it again immediately with the returned
  /// cursor to keep the stream going.
  Future<({
    String cursor,
    List<ChatSyncMessage> messages,
    List<CommunityEvent> events,
    List<ChatRoomSummary> rooms,
    int totalUnread,
  })> syncChat(
    String courseId, {
    DateTime? since,
    int waitSeconds = 25,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/chat/sync',
      queryParams: {
        if (since != null) 'since': since.toIso8601String(),
        'wait': waitSeconds,
      },
    );
    final data = _unwrap(response);
    return (
      cursor: data['cursor'] as String? ?? '',
      messages: (data['messages'] as List? ?? [])
          .map((m) => ChatSyncMessage.fromJson(m as Map<String, dynamic>))
          .toList(),
      events: (data['events'] as List? ?? [])
          .map((e) => CommunityEvent.fromJson(e as Map<String, dynamic>))
          .toList(),
      rooms: (data['rooms'] as List? ?? [])
          .map((r) => ChatRoomSummary.fromJson(r as Map<String, dynamic>))
          .toList(),
      totalUnread: (data['totalUnread'] as num?)?.toInt() ?? 0,
    );
  }

  Future<({int course, Map<String, int> groups, int total})> getUnreadCounts(
    String courseId,
  ) async {
    final data = _unwrap(await _apiClient.get('${_base(courseId)}/chat/unread'));
    final groups = <String, int>{};
    (data['groups'] as Map<String, dynamic>? ?? const {}).forEach((key, value) {
      groups[key] = (value as num?)?.toInt() ?? 0;
    });
    return (
      course: (data['course'] as num?)?.toInt() ?? 0,
      groups: groups,
      total: (data['total'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Assignments & submissions ─────────────────────────────────

  Future<List<CommunityAssignment>> getAssignments(
    String courseId, {
    String status = 'all',
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/assignments',
      queryParams: {'status': status},
    );
    final data = _unwrap(response);
    return (data['assignments'] as List? ?? [])
        .map((a) => CommunityAssignment.fromJson(a as Map<String, dynamic>))
        .toList();
  }

  Future<CommunityAssignment> getAssignment(String courseId, String assignmentId) async {
    final response = await _apiClient.get('${_base(courseId)}/assignments/$assignmentId');
    return CommunityAssignment.fromJson(_unwrap(response));
  }

  Future<CommunityAssignment> createAssignment(
    String courseId, {
    required String title,
    String description = '',
    String type = 'individual',
    int minGroupSize = 2,
    int maxGroupSize = 6,
    required DateTime dueDate,
    int maxMarks = 20,
    List<CommunityAttachment> attachments = const [],
    bool allowLateSubmission = false,
    bool isPublished = true,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/assignments',
      body: {
        'title': title,
        'description': description,
        'type': type,
        'minGroupSize': minGroupSize,
        'maxGroupSize': maxGroupSize,
        'dueDate': dueDate.toIso8601String(),
        'maxMarks': maxMarks,
        'attachments': attachments.map((a) => a.toJson()).toList(),
        'allowLateSubmission': allowLateSubmission,
        'isPublished': isPublished,
      },
    );
    return CommunityAssignment.fromJson(_unwrap(response));
  }

  Future<CommunityAssignment> updateAssignment(
    String courseId,
    String assignmentId,
    Map<String, dynamic> changes,
  ) async {
    final response = await _apiClient.put(
      '${_base(courseId)}/assignments/$assignmentId',
      body: changes,
    );
    return CommunityAssignment.fromJson(_unwrap(response));
  }

  Future<void> deleteAssignment(String courseId, String assignmentId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/assignments/$assignmentId'));
  }

  Future<AssignmentSubmission> submitAssignment(
    String courseId,
    String assignmentId, {
    String? groupId,
    String comment = '',
    required List<CommunityAttachment> files,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/assignments/$assignmentId/submit',
      body: {
        if (groupId != null) 'groupId': groupId,
        'comment': comment,
        'files': files.map((f) => f.toJson()).toList(),
      },
    );
    return AssignmentSubmission.fromJson(_unwrap(response));
  }

  /// Teacher review queue.
  Future<List<AssignmentSubmission>> getSubmissions(
    String courseId, {
    String? status,
    String? assignmentId,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/submissions',
      queryParams: {
        if (status != null) 'status': status,
        if (assignmentId != null) 'assignmentId': assignmentId,
      },
    );
    final data = _unwrap(response);
    return (data['submissions'] as List? ?? [])
        .map((s) => AssignmentSubmission.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<AssignmentSubmission> gradeSubmission(
    String courseId,
    String submissionId, {
    required double score,
    String feedback = '',
    String status = 'returned',
  }) async {
    final response = await _apiClient.patch(
      '${_base(courseId)}/submissions/$submissionId/grade',
      body: {'score': score, 'feedback': feedback, 'status': status},
    );
    return AssignmentSubmission.fromJson(_unwrap(response));
  }

  // ── Resources ─────────────────────────────────────────────────

  Future<CommunityResourceLibrary> getResources(
    String courseId, {
    String? source,
    String? type,
    String search = '',
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/resources',
      queryParams: {
        if (source != null) 'source': source,
        if (type != null) 'type': type,
        if (search.isNotEmpty) 'search': search,
      },
    );
    return CommunityResourceLibrary.fromJson(_unwrap(response));
  }

  Future<CommunityResource> shareResource(
    String courseId, {
    required String title,
    String description = '',
    String type = 'link',
    String url = '',
    String body = '',
    String? fileName,
    String? mimeType,
    int? size,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/resources',
      body: {
        'title': title,
        'description': description,
        'type': type,
        'url': url,
        'body': body,
        if (fileName != null) 'fileName': fileName,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
      },
    );
    return CommunityResource.fromJson(_unwrap(response));
  }

  Future<void> deleteResource(String courseId, String resourceId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/resources/$resourceId'));
  }

  Future<bool> approveResource(String courseId, String resourceId, bool approve) async {
    final data = _unwrap(await _apiClient.patch(
      '${_base(courseId)}/resources/$resourceId/approve',
      body: {'isApproved': approve},
    ));
    return data['isApproved'] == true;
  }

  Future<({bool liked, int likeCount})> toggleResourceLike(
    String courseId,
    String resourceId,
  ) async {
    final data = _unwrap(await _apiClient
        .post('${_base(courseId)}/resources/$resourceId/like', body: const <String, dynamic>{}));
    return (
      liked: data['liked'] == true,
      likeCount: (data['likeCount'] as num?)?.toInt() ?? 0,
    );
  }

  // ── Study sessions ────────────────────────────────────────────

  Future<List<StudySession>> getSessions(
    String courseId, {
    String scope = 'upcoming',
    String? groupId,
  }) async {
    final response = await _apiClient.get(
      '${_base(courseId)}/sessions',
      queryParams: {
        'scope': scope,
        if (groupId != null) 'groupId': groupId,
      },
    );
    final data = _unwrap(response);
    return (data['sessions'] as List? ?? [])
        .map((s) => StudySession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<StudySession> createSession(
    String courseId, {
    required String topic,
    String description = '',
    required DateTime scheduledAt,
    int durationMinutes = 60,
    List<String> agenda = const [],
    int maxParticipants = 10,
    String meetingLink = '',
    String? groupId,
  }) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/sessions',
      body: {
        'topic': topic,
        'description': description,
        'scheduledAt': scheduledAt.toIso8601String(),
        'durationMinutes': durationMinutes,
        'agenda': agenda,
        'maxParticipants': maxParticipants,
        'meetingLink': meetingLink,
        if (groupId != null) 'groupId': groupId,
      },
    );
    return StudySession.fromJson(_unwrap(response));
  }

  /// Every upcoming or live study session across all the caller's courses.
  ///
  /// Not course-scoped — the home dashboard lists these beside teacher-led
  /// live sessions, so a group meeting is as visible as a class.
  Future<List<StudySession>> getMySessions() async {
    final data = _unwrap(await _apiClient.get('${ApiConfig.community}/my/sessions'));
    return (data['sessions'] as List? ?? [])
        .map((s) => StudySession.fromJson(s as Map<String, dynamic>))
        .toList();
  }

  Future<StudySession> getSession(String courseId, String sessionId) async {
    final response = await _apiClient.get('${_base(courseId)}/sessions/$sessionId');
    return StudySession.fromJson(_unwrap(response));
  }

  /// Toggle "I'm coming". Does not open the meeting room.
  Future<StudySession> rsvpSession(String courseId, String sessionId) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/sessions/$sessionId/rsvp',
      body: const <String, dynamic>{},
    );
    return StudySession.fromJson(_unwrap(response));
  }

  /// Ask for a meeting URL.
  ///
  /// For the organiser this *opens* the room (creating the BigBlueButton
  /// meeting on first call); for everyone else it fails with a clear message
  /// until the organiser has started it.
  Future<SessionJoinTicket> joinSessionRoom(String courseId, String sessionId) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/sessions/$sessionId/join',
      body: const <String, dynamic>{},
    );
    return SessionJoinTicket.fromJson(_unwrap(response));
  }

  /// Organiser closes the room and settles attendance.
  Future<StudySession> endSession(String courseId, String sessionId) async {
    final response = await _apiClient.post(
      '${_base(courseId)}/sessions/$sessionId/end',
      body: const <String, dynamic>{},
    );
    return StudySession.fromJson(_unwrap(response));
  }

  Future<StudySession> updateSession(
    String courseId,
    String sessionId,
    Map<String, dynamic> changes,
  ) async {
    final response = await _apiClient.put(
      '${_base(courseId)}/sessions/$sessionId',
      body: changes,
    );
    return StudySession.fromJson(_unwrap(response));
  }

  /// Recordings process asynchronously on the BBB server — a null URL with
  /// `processing: true` means "not ready yet", not "never recorded".
  Future<({String? url, int duration, bool processing})> getSessionRecording(
    String courseId,
    String sessionId,
  ) async {
    final data = _unwrap(
        await _apiClient.get('${_base(courseId)}/sessions/$sessionId/recording'));
    return (
      url: data['recordingUrl'] as String?,
      duration: (data['recordingDuration'] as num?)?.toInt() ?? 0,
      processing: data['processing'] == true,
    );
  }

  Future<void> cancelSession(String courseId, String sessionId) async {
    _unwrap(await _apiClient.delete('${_base(courseId)}/sessions/$sessionId'));
  }

  void dispose() => _apiClient.dispose();
}
