import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/community.dart';
import '../../services/api/community_service.dart';

/// Riverpod wiring for the Course Community.
///
/// Everything is keyed by `courseId` through `family` providers so several
/// courses can be open without their state bleeding into each other.

final communityServiceProvider = Provider<CommunityService>((ref) {
  final service = CommunityService();
  ref.onDispose(service.dispose);
  return service;
});

// ─────────────────────────────────────────────
//  Dashboard
// ─────────────────────────────────────────────

final communityOverviewProvider =
    FutureProvider.family<CommunityOverview, String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getOverview(courseId);
});

/// Keeps the member's "Active now" badge alive while the Community tab is open.
///
/// The first ping fires immediately so a student shows up for their classmates
/// as soon as they arrive, then repeats just inside the backend's 5-minute
/// active window.
final communityPresenceProvider =
    Provider.family<CommunityPresenceHeartbeat, String>((ref, courseId) {
  final heartbeat = CommunityPresenceHeartbeat(
    ref.watch(communityServiceProvider),
    courseId,
  );
  ref.onDispose(heartbeat.stop);
  return heartbeat;
});

class CommunityPresenceHeartbeat {
  final CommunityService _service;
  final String _courseId;
  Timer? _timer;

  CommunityPresenceHeartbeat(this._service, this._courseId);

  static const _interval = Duration(minutes: 3);

  void start({String area = 'community'}) {
    if (_timer != null) return;
    _service.ping(_courseId, area: area);
    _timer = Timer.periodic(_interval, (_) => _service.ping(_courseId, area: area));
  }

  void stop() {
    _timer?.cancel();
    _timer = null;
  }
}

// ─────────────────────────────────────────────
//  People
// ─────────────────────────────────────────────

/// Filter arguments for the member directory.
class MemberQuery {
  final String courseId;
  final String search;
  final String filter; // all | active | students | teachers

  const MemberQuery(this.courseId, {this.search = '', this.filter = 'all'});

  @override
  bool operator ==(Object other) =>
      other is MemberQuery &&
      other.courseId == courseId &&
      other.search == search &&
      other.filter == filter;

  @override
  int get hashCode => Object.hash(courseId, search, filter);
}

final communityMembersProvider =
    FutureProvider.family<MemberDirectory, MemberQuery>((ref, query) async {
  return ref.watch(communityServiceProvider).getMembers(
        query.courseId,
        search: query.search,
        filter: query.filter,
      );
});

final memberProfileProvider =
    FutureProvider.family<MemberProfile, ({String courseId, String memberId})>(
        (ref, args) async {
  return ref
      .watch(communityServiceProvider)
      .getMemberProfile(args.courseId, args.memberId);
});

final studyPartnersProvider = FutureProvider.family<
    ({List<StudyPartnerCard> partners, StudyPartnerCard? mine}), String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getStudyPartners(courseId);
});

// ─────────────────────────────────────────────
//  Discussions
// ─────────────────────────────────────────────

class PostQuery {
  final String courseId;
  final CommunityPostType? type;
  final String? helpCategory;
  final String search;
  final bool unansweredOnly;
  final bool mineOnly;

  const PostQuery(
    this.courseId, {
    this.type,
    this.helpCategory,
    this.search = '',
    this.unansweredOnly = false,
    this.mineOnly = false,
  });

  @override
  bool operator ==(Object other) =>
      other is PostQuery &&
      other.courseId == courseId &&
      other.type == type &&
      other.helpCategory == helpCategory &&
      other.search == search &&
      other.unansweredOnly == unansweredOnly &&
      other.mineOnly == mineOnly;

  @override
  int get hashCode =>
      Object.hash(courseId, type, helpCategory, search, unansweredOnly, mineOnly);
}

final communityPostsProvider =
    FutureProvider.family<List<CommunityPost>, PostQuery>((ref, query) async {
  final result = await ref.watch(communityServiceProvider).getPosts(
        query.courseId,
        type: query.type,
        helpCategory: query.helpCategory,
        search: query.search,
        unansweredOnly: query.unansweredOnly,
        mineOnly: query.mineOnly,
      );
  return result.posts;
});

final communityPostProvider =
    FutureProvider.family<CommunityPost, ({String courseId, String postId})>(
        (ref, args) async {
  return ref.watch(communityServiceProvider).getPost(args.courseId, args.postId);
});

// ─────────────────────────────────────────────
//  Groups
// ─────────────────────────────────────────────

class GroupQuery {
  final String courseId;
  final bool mineOnly;
  final bool openOnly;
  final String search;

  const GroupQuery(
    this.courseId, {
    this.mineOnly = false,
    this.openOnly = false,
    this.search = '',
  });

  @override
  bool operator ==(Object other) =>
      other is GroupQuery &&
      other.courseId == courseId &&
      other.mineOnly == mineOnly &&
      other.openOnly == openOnly &&
      other.search == search;

  @override
  int get hashCode => Object.hash(courseId, mineOnly, openOnly, search);
}

final communityGroupsProvider =
    FutureProvider.family<List<StudyGroupSummary>, GroupQuery>((ref, query) async {
  return ref.watch(communityServiceProvider).getGroups(
        query.courseId,
        mineOnly: query.mineOnly,
        openOnly: query.openOnly,
        search: query.search,
      );
});

final studyGroupProvider =
    FutureProvider.family<StudyGroupDetail, ({String courseId, String groupId})>(
        (ref, args) async {
  return ref.watch(communityServiceProvider).getGroup(args.courseId, args.groupId);
});

// ─────────────────────────────────────────────
//  Assignments
// ─────────────────────────────────────────────

final communityAssignmentsProvider =
    FutureProvider.family<List<CommunityAssignment>, String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getAssignments(courseId);
});

final communityAssignmentProvider = FutureProvider.family<CommunityAssignment,
    ({String courseId, String assignmentId})>((ref, args) async {
  return ref
      .watch(communityServiceProvider)
      .getAssignment(args.courseId, args.assignmentId);
});

final communitySubmissionsProvider =
    FutureProvider.family<List<AssignmentSubmission>, String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getSubmissions(courseId);
});

// ─────────────────────────────────────────────
//  Resources & sessions
// ─────────────────────────────────────────────

final communityResourcesProvider =
    FutureProvider.family<CommunityResourceLibrary, String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getResources(courseId);
});

final communitySessionsProvider =
    FutureProvider.family<List<StudySession>, ({String courseId, String scope})>(
        (ref, args) async {
  return ref.watch(communityServiceProvider).getSessions(args.courseId, scope: args.scope);
});

// ─────────────────────────────────────────────
//  Chat
// ─────────────────────────────────────────────

/// Chat room state — one notifier per (course, group?) room.
class ChatRoomState {
  final List<CommunityChatMessage> messages;
  final bool isLoading;
  final bool isSending;
  final bool hasMore;
  final String? error;

  const ChatRoomState({
    this.messages = const [],
    this.isLoading = false,
    this.isSending = false,
    this.hasMore = false,
    this.error,
  });

  ChatRoomState copyWith({
    List<CommunityChatMessage>? messages,
    bool? isLoading,
    bool? isSending,
    bool? hasMore,
    String? error,
  }) {
    return ChatRoomState(
      messages: messages ?? this.messages,
      isLoading: isLoading ?? this.isLoading,
      isSending: isSending ?? this.isSending,
      hasMore: hasMore ?? this.hasMore,
      error: error,
    );
  }
}

class ChatRoomKey {
  final String courseId;
  final String? groupId;

  const ChatRoomKey(this.courseId, [this.groupId]);

  @override
  bool operator ==(Object other) =>
      other is ChatRoomKey && other.courseId == courseId && other.groupId == groupId;

  @override
  int get hashCode => Object.hash(courseId, groupId);
}

class ChatRoomNotifier extends StateNotifier<ChatRoomState> {
  final CommunityService _service;
  final ChatRoomKey _key;
  Timer? _poller;

  ChatRoomNotifier(this._service, this._key) : super(const ChatRoomState());

  /// Chat has no socket layer yet, so the room refreshes on a short timer
  /// while it is on screen. Swapping this for a socket later only touches
  /// this notifier.
  static const _pollInterval = Duration(seconds: 12);

  Future<void> load({bool silent = false}) async {
    if (!silent) state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getMessages(_key.courseId, groupId: _key.groupId);
      if (!mounted) return;
      state = state.copyWith(
        messages: result.messages,
        hasMore: result.hasMore,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(isLoading: false, error: silent ? null : e.toString());
    }
  }

  /// Fetches the page of messages older than the ones already held.
  Future<void> loadOlder() async {
    if (state.messages.isEmpty || !state.hasMore) return;
    final oldest = state.messages.first.createdAt;
    if (oldest == null) return;
    try {
      final result =
          await _service.getMessages(_key.courseId, groupId: _key.groupId, before: oldest);
      if (!mounted) return;
      state = state.copyWith(
        messages: [...result.messages, ...state.messages],
        hasMore: result.hasMore,
      );
    } catch (_) {
      // Silent: failing to page back should not disturb the open conversation.
    }
  }

  Future<bool> send(String content, {String? replyTo}) async {
    if (content.trim().isEmpty) return false;
    state = state.copyWith(isSending: true, error: null);
    try {
      final message = await _service.sendMessage(
        _key.courseId,
        groupId: _key.groupId,
        content: content.trim(),
        replyTo: replyTo,
      );
      if (!mounted) return true;
      state = state.copyWith(
        messages: [...state.messages, message],
        isSending: false,
      );
      return true;
    } catch (e) {
      if (!mounted) return false;
      state = state.copyWith(isSending: false, error: e.toString());
      return false;
    }
  }

  Future<void> deleteMessage(String messageId) async {
    try {
      await _service.deleteMessage(_key.courseId, messageId);
      if (!mounted) return;
      state = state.copyWith(
        messages: state.messages.where((m) => m.id != messageId).toList(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(error: e.toString());
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

final chatRoomProvider =
    StateNotifierProvider.family<ChatRoomNotifier, ChatRoomState, ChatRoomKey>(
        (ref, key) {
  return ChatRoomNotifier(ref.watch(communityServiceProvider), key);
});

final chatUnreadProvider = FutureProvider.family<
    ({int course, Map<String, int> groups, int total}), String>((ref, courseId) async {
  return ref.watch(communityServiceProvider).getUnreadCounts(courseId);
});

// ─────────────────────────────────────────────
//  Live chat inbox (public + groups + direct)
// ─────────────────────────────────────────────

class ChatInboxState {
  final List<ChatRoomSummary> rooms;
  final int totalUnread;
  final bool isLoading;
  final String? error;

  /// True while the long poll is connected and delivering.
  final bool isLive;

  /// Bumped per room whenever new messages arrive, so an open room can
  /// reload itself without every room listening to the whole message list.
  final Map<String, int> revision;

  const ChatInboxState({
    this.rooms = const [],
    this.totalUnread = 0,
    this.isLoading = false,
    this.error,
    this.isLive = false,
    this.revision = const {},
  });

  ChatInboxState copyWith({
    List<ChatRoomSummary>? rooms,
    int? totalUnread,
    bool? isLoading,
    String? error,
    bool? isLive,
    Map<String, int>? revision,
  }) {
    return ChatInboxState(
      rooms: rooms ?? this.rooms,
      totalUnread: totalUnread ?? this.totalUnread,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      isLive: isLive ?? this.isLive,
      revision: revision ?? this.revision,
    );
  }

  List<ChatRoomSummary> get publicRooms =>
      rooms.where((r) => r.isPublic).toList();
  List<ChatRoomSummary> get groupRooms => rooms.where((r) => r.isGroup).toList();
  List<ChatRoomSummary> get directRooms =>
      rooms.where((r) => r.isDirect).toList();
}

/// Drives the Chat tab: loads every room once, then holds a long poll open so
/// messages from the course room, study groups and direct chats all arrive as
/// they are sent.
class ChatInboxNotifier extends StateNotifier<ChatInboxState> {
  final CommunityService _service;
  final Ref _ref;
  final String _courseId;

  bool _running = false;
  DateTime? _cursor;

  ChatInboxNotifier(this._service, this._ref, this._courseId)
      : super(const ChatInboxState());

  /// How long the server holds each poll open before returning empty.
  static const _holdSeconds = 25;

  /// Backoff after a failed poll, so a flaky connection does not hammer.
  static const _retryDelay = Duration(seconds: 4);

  Future<void> loadInbox() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final result = await _service.getChatInbox(_courseId);
      if (!mounted) return;
      state = state.copyWith(
        rooms: result.rooms,
        totalUnread: result.totalUnread,
        isLoading: false,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }

  /// Starts the delivery loop. Safe to call repeatedly.
  void start() {
    if (_running) return;
    _running = true;
    _cursor ??= DateTime.now().toUtc();
    _loop();
  }

  void stop() {
    _running = false;
    if (mounted) state = state.copyWith(isLive: false);
  }

  Future<void> _loop() async {
    while (_running && mounted) {
      try {
        final result = await _service.syncChat(
          _courseId,
          since: _cursor,
          waitSeconds: _holdSeconds,
        );
        if (!_running || !mounted) return;

        if (result.cursor.isNotEmpty) {
          _cursor = DateTime.tryParse(result.cursor) ?? _cursor;
        }

        // Workspace changes (a session opened, work submitted or graded, a
        // task ticked) refresh the screens that show them, so a group's Work
        // tab updates without anyone reopening it.
        if (result.events.isNotEmpty) _applyEvents(result.events);

        if (result.messages.isEmpty) {
          // Quiet window — the server simply timed out its hold.
          state = state.copyWith(isLive: true, error: null);
          continue;
        }

        // Bump the revision of every room that received something, so an
        // open thread knows to pull the new messages in.
        final revision = Map<String, int>.from(state.revision);
        for (final message in result.messages) {
          revision[message.roomKey] = (revision[message.roomKey] ?? 0) + 1;
        }

        state = state.copyWith(
          rooms: result.rooms.isNotEmpty ? result.rooms : state.rooms,
          totalUnread: result.totalUnread,
          revision: revision,
          isLive: true,
          error: null,
        );
      } catch (e) {
        if (!_running || !mounted) return;
        state = state.copyWith(isLive: false);
        await Future.delayed(_retryDelay);
      }
    }
  }

  /// Turns live events into targeted invalidations.
  ///
  /// Deliberately narrow: a graded submission should not force the whole
  /// community to refetch, so each event only touches the providers that
  /// actually render it.
  void _applyEvents(List<CommunityEvent> events) {
    var touchesDashboard = false;
    final groupIds = <String>{};

    for (final event in events) {
      if (event.groupId != null) groupIds.add(event.groupId!);

      switch (event.type) {
        case 'session':
          _ref.invalidate(communitySessionsProvider);
          touchesDashboard = true;
          break;
        case 'submission':
        case 'submission_graded':
          _ref.invalidate(communitySubmissionsProvider(_courseId));
          _ref.invalidate(communityAssignmentsProvider(_courseId));
          touchesDashboard = true;
          break;
        case 'assignment':
          _ref.invalidate(communityAssignmentsProvider(_courseId));
          touchesDashboard = true;
          break;
        case 'group':
          _ref.invalidate(communityGroupsProvider);
          break;
      }
    }

    // Refresh each affected group's workspace — tasks, members, submissions
    // and sessions all live on this one provider.
    for (final groupId in groupIds) {
      _ref.invalidate(studyGroupProvider((courseId: _courseId, groupId: groupId)));
    }

    if (touchesDashboard) {
      _ref.invalidate(communityOverviewProvider(_courseId));
    }
  }

  /// Clears a room's badge locally the moment it is opened, so the UI does not
  /// wait for the next sync to catch up with what the server already knows.
  void markRoomRead(String roomKey) {
    final rooms = state.rooms.map((room) {
      if (room.key != roomKey || room.unreadCount == 0) return room;
      return ChatRoomSummary(
        key: room.key,
        type: room.type,
        title: room.title,
        subtitle: room.subtitle,
        lastMessageContent: room.lastMessageContent,
        lastMessageSender: room.lastMessageSender,
        lastMessageHasAttachment: room.lastMessageHasAttachment,
        lastMessageAt: room.lastMessageAt,
        unreadCount: 0,
        groupId: room.groupId,
        conversationId: room.conversationId,
        contact: room.contact,
      );
    }).toList();

    state = state.copyWith(
      rooms: rooms,
      totalUnread: rooms.fold<int>(0, (sum, r) => sum + r.unreadCount),
    );
  }

  @override
  void dispose() {
    _running = false;
    super.dispose();
  }
}

final chatInboxProvider =
    StateNotifierProvider.family<ChatInboxNotifier, ChatInboxState, String>(
        (ref, courseId) {
  final notifier =
      ChatInboxNotifier(ref.watch(communityServiceProvider), ref, courseId);
  ref.onDispose(notifier.stop);
  return notifier;
});

// ─────────────────────────────────────────────
//  Mutations
// ─────────────────────────────────────────────

/// Write-side actions. Kept apart from the read providers so a mutation can
/// invalidate exactly the queries it affects.
class CommunityActions {
  final Ref _ref;
  final CommunityService _service;

  CommunityActions(this._ref, this._service);

  void _refreshFeed(String courseId) {
    _ref.invalidate(communityOverviewProvider(courseId));
  }

  // Discussions
  Future<CommunityPost> createPost(
    String courseId, {
    required CommunityPostType type,
    String? title,
    required String content,
    String? helpCategory,
    List<String> tags = const [],
  }) async {
    final post = await _service.createPost(
      courseId,
      type: type,
      title: title,
      content: content,
      helpCategory: helpCategory,
      tags: tags,
    );
    _refreshFeed(courseId);
    _ref.invalidate(communityPostsProvider);
    return post;
  }

  Future<void> deletePost(String courseId, String postId) async {
    await _service.deletePost(courseId, postId);
    _refreshFeed(courseId);
    _ref.invalidate(communityPostsProvider);
  }

  Future<PostReply> addReply(String courseId, String postId, String content) async {
    final reply = await _service.addReply(courseId, postId, content);
    _ref.invalidate(communityPostProvider((courseId: courseId, postId: postId)));
    _ref.invalidate(communityPostsProvider);
    return reply;
  }

  Future<void> toggleLike(String courseId, String postId, {String? replyId}) async {
    await _service.toggleLike(courseId, postId, replyId: replyId);
    _ref.invalidate(communityPostProvider((courseId: courseId, postId: postId)));
  }

  Future<void> acceptReply(String courseId, String postId, String replyId) async {
    await _service.acceptReply(courseId, postId, replyId);
    _ref.invalidate(communityPostProvider((courseId: courseId, postId: postId)));
    _ref.invalidate(communityPostsProvider);
  }

  Future<void> moderatePost(
    String courseId,
    String postId, {
    bool? isPinned,
    bool? isClosed,
    bool? isResolved,
  }) async {
    await _service.moderatePost(
      courseId,
      postId,
      isPinned: isPinned,
      isClosed: isClosed,
      isResolved: isResolved,
    );
    _refreshFeed(courseId);
    _ref.invalidate(communityPostsProvider);
    _ref.invalidate(communityPostProvider((courseId: courseId, postId: postId)));
  }

  // Groups
  Future<StudyGroupSummary> createGroup(
    String courseId, {
    required String name,
    String purpose = 'general',
    String description = '',
    int maxMembers = 6,
    List<String> inviteUserIds = const [],
    bool isOpen = true,
  }) async {
    final group = await _service.createGroup(
      courseId,
      name: name,
      purpose: purpose,
      description: description,
      maxMembers: maxMembers,
      inviteUserIds: inviteUserIds,
      isOpen: isOpen,
    );
    _refreshFeed(courseId);
    _ref.invalidate(communityGroupsProvider);
    return group;
  }

  Future<String> joinGroup(String courseId, String groupId) async {
    final status = await _service.joinGroup(courseId, groupId);
    _refreshFeed(courseId);
    _ref.invalidate(communityGroupsProvider);
    _ref.invalidate(studyGroupProvider((courseId: courseId, groupId: groupId)));
    return status;
  }

  Future<void> leaveGroup(String courseId, String groupId) async {
    await _service.leaveGroup(courseId, groupId);
    _refreshFeed(courseId);
    _ref.invalidate(communityGroupsProvider);
  }

  Future<int> inviteToGroup(String courseId, String groupId, List<String> userIds) async {
    final count = await _service.inviteToGroup(courseId, groupId, userIds);
    _ref.invalidate(studyGroupProvider((courseId: courseId, groupId: groupId)));
    return count;
  }

  Future<void> addTask(
    String courseId,
    String groupId, {
    required String title,
    String description = '',
    List<String> assignedTo = const [],
    DateTime? dueDate,
  }) async {
    await _service.addGroupTask(
      courseId,
      groupId,
      title: title,
      description: description,
      assignedTo: assignedTo,
      dueDate: dueDate,
    );
    _ref.invalidate(studyGroupProvider((courseId: courseId, groupId: groupId)));
    _refreshFeed(courseId);
  }

  Future<void> toggleTask(
    String courseId,
    String groupId,
    String taskId,
    bool isDone,
  ) async {
    await _service.updateGroupTask(courseId, groupId, taskId, isDone: isDone);
    _ref.invalidate(studyGroupProvider((courseId: courseId, groupId: groupId)));
    _refreshFeed(courseId);
  }

  Future<void> deleteTask(String courseId, String groupId, String taskId) async {
    await _service.deleteGroupTask(courseId, groupId, taskId);
    _ref.invalidate(studyGroupProvider((courseId: courseId, groupId: groupId)));
  }

  // Assignments
  Future<CommunityAssignment> createAssignment(
    String courseId, {
    required String title,
    String description = '',
    String type = 'individual',
    required DateTime dueDate,
    int maxMarks = 20,
    int minGroupSize = 2,
    int maxGroupSize = 6,
    bool allowLateSubmission = false,
  }) async {
    final assignment = await _service.createAssignment(
      courseId,
      title: title,
      description: description,
      type: type,
      dueDate: dueDate,
      maxMarks: maxMarks,
      minGroupSize: minGroupSize,
      maxGroupSize: maxGroupSize,
      allowLateSubmission: allowLateSubmission,
    );
    _ref.invalidate(communityAssignmentsProvider(courseId));
    _refreshFeed(courseId);
    return assignment;
  }

  Future<void> deleteAssignment(String courseId, String assignmentId) async {
    await _service.deleteAssignment(courseId, assignmentId);
    _ref.invalidate(communityAssignmentsProvider(courseId));
    _refreshFeed(courseId);
  }

  Future<AssignmentSubmission> submitAssignment(
    String courseId,
    String assignmentId, {
    String? groupId,
    String comment = '',
    required List<CommunityAttachment> files,
  }) async {
    final submission = await _service.submitAssignment(
      courseId,
      assignmentId,
      groupId: groupId,
      comment: comment,
      files: files,
    );
    _ref.invalidate(communityAssignmentsProvider(courseId));
    _ref.invalidate(
        communityAssignmentProvider((courseId: courseId, assignmentId: assignmentId)));
    _refreshFeed(courseId);
    return submission;
  }

  Future<void> gradeSubmission(
    String courseId,
    String submissionId, {
    required double score,
    String feedback = '',
  }) async {
    await _service.gradeSubmission(courseId, submissionId,
        score: score, feedback: feedback);
    _ref.invalidate(communitySubmissionsProvider(courseId));
    _ref.invalidate(communityAssignmentsProvider(courseId));
    _refreshFeed(courseId);
  }

  // Resources
  Future<void> shareResource(
    String courseId, {
    required String title,
    String description = '',
    String type = 'link',
    String url = '',
    String body = '',
  }) async {
    await _service.shareResource(
      courseId,
      title: title,
      description: description,
      type: type,
      url: url,
      body: body,
    );
    _ref.invalidate(communityResourcesProvider(courseId));
  }

  Future<void> deleteResource(String courseId, String resourceId) async {
    await _service.deleteResource(courseId, resourceId);
    _ref.invalidate(communityResourcesProvider(courseId));
  }

  Future<void> approveResource(String courseId, String resourceId, bool approve) async {
    await _service.approveResource(courseId, resourceId, approve);
    _ref.invalidate(communityResourcesProvider(courseId));
  }

  Future<void> toggleResourceLike(String courseId, String resourceId) async {
    await _service.toggleResourceLike(courseId, resourceId);
    _ref.invalidate(communityResourcesProvider(courseId));
  }

  // Sessions
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
    final session = await _service.createSession(
      courseId,
      topic: topic,
      description: description,
      scheduledAt: scheduledAt,
      durationMinutes: durationMinutes,
      agenda: agenda,
      maxParticipants: maxParticipants,
      meetingLink: meetingLink,
      groupId: groupId,
    );
    _ref.invalidate(communitySessionsProvider);
    _refreshFeed(courseId);
    return session;
  }

  Future<StudySession> rsvpSession(String courseId, String sessionId) async {
    final session = await _service.rsvpSession(courseId, sessionId);
    _ref.invalidate(communitySessionsProvider);
    _refreshFeed(courseId);
    return session;
  }

  /// Returns the meeting URL to open. For the organiser this also opens the
  /// room, which flips the session live and notifies everyone attending.
  Future<SessionJoinTicket> joinSessionRoom(String courseId, String sessionId) async {
    final ticket = await _service.joinSessionRoom(courseId, sessionId);
    _ref.invalidate(communitySessionsProvider);
    _refreshFeed(courseId);
    return ticket;
  }

  Future<void> endSession(String courseId, String sessionId) async {
    await _service.endSession(courseId, sessionId);
    _ref.invalidate(communitySessionsProvider);
    _refreshFeed(courseId);
  }

  Future<({String? url, int duration, bool processing})> fetchSessionRecording(
    String courseId,
    String sessionId,
  ) async {
    final recording = await _service.getSessionRecording(courseId, sessionId);
    if (recording.url != null) _ref.invalidate(communitySessionsProvider);
    return recording;
  }

  Future<void> cancelSession(String courseId, String sessionId) async {
    await _service.cancelSession(courseId, sessionId);
    _ref.invalidate(communitySessionsProvider);
    _refreshFeed(courseId);
  }

  // Study partners
  Future<void> saveStudyPartnerProfile(
    String courseId, {
    required String goal,
    List<String> topics = const [],
    List<String> availability = const [],
    String note = '',
  }) async {
    await _service.saveStudyPartnerProfile(
      courseId,
      goal: goal,
      topics: topics,
      availability: availability,
      note: note,
    );
    _ref.invalidate(studyPartnersProvider(courseId));
  }

  Future<void> removeStudyPartnerProfile(String courseId) async {
    await _service.removeStudyPartnerProfile(courseId);
    _ref.invalidate(studyPartnersProvider(courseId));
  }
}

final communityActionsProvider = Provider<CommunityActions>((ref) {
  return CommunityActions(ref, ref.watch(communityServiceProvider));
});
