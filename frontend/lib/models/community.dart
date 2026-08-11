/// Models for the Course Community — the collaboration layer that sits beside
/// the lessons of a course (students, discussions, groups, assignments,
/// resources and study sessions).
///
/// Every model here maps 1:1 to a payload from `/api/community/:courseId/...`.
library;

// ─────────────────────────────────────────────
//  People & presence
// ─────────────────────────────────────────────

/// Coarse activity status. The backend deliberately never reports what a
/// member is actually doing — only how recently they were seen.
enum PresenceStatus { active, recent, offline }

class MemberPresence {
  final PresenceStatus status;
  final DateTime? lastSeenAt;
  final int? minutesAgo;

  const MemberPresence({
    this.status = PresenceStatus.offline,
    this.lastSeenAt,
    this.minutesAgo,
  });

  factory MemberPresence.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const MemberPresence();
    return MemberPresence(
      status: switch (json['status'] as String?) {
        'active' => PresenceStatus.active,
        'recent' => PresenceStatus.recent,
        _ => PresenceStatus.offline,
      },
      lastSeenAt: _parseDate(json['lastSeenAt']),
      minutesAgo: _parseInt(json['minutesAgo']),
    );
  }

  bool get isActive => status == PresenceStatus.active;

  /// Short human label used under an avatar.
  String get label {
    switch (status) {
      case PresenceStatus.active:
        return 'Active now';
      case PresenceStatus.recent:
        final m = minutesAgo ?? 0;
        if (m < 1) return 'Just now';
        if (m < 60) return '$m min ago';
        return 'Recently active';
      case PresenceStatus.offline:
        if (lastSeenAt == null) return 'Offline';
        final diff = DateTime.now().difference(lastSeenAt!);
        if (diff.inHours < 24) return 'Today';
        if (diff.inDays == 1) return 'Yesterday';
        if (diff.inDays < 7) return '${diff.inDays} days ago';
        return 'A while ago';
    }
  }
}

class CommunityMember {
  final String id;
  final String fullName;
  final String? avatar;
  final String role;
  final List<String> interests;
  final MemberPresence presence;
  final bool isTeacher;
  final bool isMe;

  /// Only present on the group workspace payload.
  final String? groupRole;
  final String? membershipStatus;

  const CommunityMember({
    required this.id,
    required this.fullName,
    this.avatar,
    this.role = 'student',
    this.interests = const [],
    this.presence = const MemberPresence(),
    this.isTeacher = false,
    this.isMe = false,
    this.groupRole,
    this.membershipStatus,
  });

  factory CommunityMember.fromJson(Map<String, dynamic> json) {
    return CommunityMember(
      id: _str(json['id']) ?? _str(json['_id']) ?? '',
      fullName: _str(json['fullName']) ?? 'ECH Student',
      avatar: _str(json['avatar']),
      role: _str(json['role']) ?? 'student',
      interests: _stringList(json['interests']),
      presence: MemberPresence.fromJson(json['presence'] as Map<String, dynamic>?),
      isTeacher: json['isTeacher'] == true ||
          json['role'] == 'instructor' ||
          json['role'] == 'admin',
      isMe: json['isMe'] == true,
      groupRole: _str(json['groupRole']),
      membershipStatus: _str(json['status']),
    );
  }

  String get initials {
    final parts = fullName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.characters(2);
    return '${parts.first.characters(1)}${parts[1].characters(1)}';
  }
}

extension _Chars on String {
  String characters(int n) =>
      length <= n ? toUpperCase() : substring(0, n).toUpperCase();
}

/// A member's public course profile (View Profile sheet).
class MemberProfile {
  final CommunityMember member;
  final String currentlyStudying;
  final int enrolledCoursesCount;
  final double? progress;
  final DateTime? joinedCourseAt;
  final int groupCount;
  final List<StudyGroupSummary> groups;
  final int postCount;
  final int replyCount;
  final StudyPartnerCard? lookingForPartner;

  const MemberProfile({
    required this.member,
    required this.currentlyStudying,
    this.enrolledCoursesCount = 0,
    this.progress,
    this.joinedCourseAt,
    this.groupCount = 0,
    this.groups = const [],
    this.postCount = 0,
    this.replyCount = 0,
    this.lookingForPartner,
  });

  factory MemberProfile.fromJson(Map<String, dynamic> json) {
    final contributions = json['contributions'] as Map<String, dynamic>? ?? const {};
    final partner = json['lookingForPartner'] as Map<String, dynamic>?;
    return MemberProfile(
      member: CommunityMember.fromJson(json),
      currentlyStudying: _str(json['currentlyStudying']) ?? '',
      enrolledCoursesCount: _parseInt(json['enrolledCoursesCount']) ?? 0,
      progress: _parseDouble(json['progress']),
      joinedCourseAt: _parseDate(json['joinedCourseAt']),
      groupCount: _parseInt(json['groupCount']) ?? 0,
      groups: (json['groups'] as List? ?? [])
          .map((g) => StudyGroupSummary.fromJson(g as Map<String, dynamic>))
          .toList(),
      postCount: _parseInt(contributions['posts']) ?? 0,
      replyCount: _parseInt(contributions['replies']) ?? 0,
      lookingForPartner: partner == null
          ? null
          : StudyPartnerCard(
              goal: _str(partner['goal']) ?? '',
              topics: _stringList(partner['topics']),
              availability: _stringList(partner['availability']),
              note: _str(partner['note']) ?? '',
            ),
    );
  }
}

/// The "looking for a study partner" card a student opts into publishing.
class StudyPartnerCard {
  final String? id;
  final CommunityMember? member;
  final String goal;
  final List<String> topics;
  final List<String> availability;
  final String note;
  final bool isActive;

  const StudyPartnerCard({
    this.id,
    this.member,
    this.goal = '',
    this.topics = const [],
    this.availability = const [],
    this.note = '',
    this.isActive = true,
  });

  factory StudyPartnerCard.fromJson(Map<String, dynamic> json) {
    return StudyPartnerCard(
      id: _str(json['id']),
      member: json['member'] != null
          ? CommunityMember.fromJson(json['member'] as Map<String, dynamic>)
          : null,
      goal: _str(json['goal']) ?? '',
      topics: _stringList(json['topics']),
      availability: _stringList(json['availability']),
      note: _str(json['note']) ?? '',
      isActive: json['isActive'] != false,
    );
  }
}

// ─────────────────────────────────────────────
//  Discussions, questions, help & announcements
// ─────────────────────────────────────────────

enum CommunityPostType { discussion, question, announcement, help }

CommunityPostType _postTypeFrom(String? value) => switch (value) {
      'question' => CommunityPostType.question,
      'announcement' => CommunityPostType.announcement,
      'help' => CommunityPostType.help,
      _ => CommunityPostType.discussion,
    };

String postTypeToApi(CommunityPostType type) => switch (type) {
      CommunityPostType.question => 'question',
      CommunityPostType.announcement => 'announcement',
      CommunityPostType.help => 'help',
      CommunityPostType.discussion => 'discussion',
    };

/// The help categories offered by the "What do you need help with?" picker.
enum HelpCategory { concept, assignment, question, studyPartner, technical, resource, teacher }

String helpCategoryToApi(HelpCategory c) => switch (c) {
      HelpCategory.concept => 'concept',
      HelpCategory.assignment => 'assignment',
      HelpCategory.question => 'question',
      HelpCategory.studyPartner => 'study_partner',
      HelpCategory.technical => 'technical',
      HelpCategory.resource => 'resource',
      HelpCategory.teacher => 'teacher',
    };

String helpCategoryLabel(String? apiValue) => switch (apiValue) {
      'concept' => 'Course concept',
      'assignment' => 'Assignment',
      'question' => 'Difficult question',
      'study_partner' => 'Find study partner',
      'technical' => 'Technical issue',
      'resource' => 'Resource',
      'teacher' => 'Ask teacher',
      _ => 'General',
    };

class CommunityPost {
  final String id;
  final CommunityPostType type;
  final String? helpCategory;
  final String? title;
  final String content;
  final CommunityMember? author;
  final String authorRole;
  final int replyCount;
  final int likeCount;
  final bool isLikedByMe;
  final bool hasTeacherAnswer;
  final bool isPinned;
  final bool isResolved;
  final bool isClosed;
  final int viewCount;
  final List<String> tags;
  final List<CommunityAttachment> attachments;
  final DateTime? createdAt;
  final DateTime? lastActivityAt;
  final List<PostReply> replies;

  const CommunityPost({
    required this.id,
    this.type = CommunityPostType.discussion,
    this.helpCategory,
    this.title,
    this.content = '',
    this.author,
    this.authorRole = 'student',
    this.replyCount = 0,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.hasTeacherAnswer = false,
    this.isPinned = false,
    this.isResolved = false,
    this.isClosed = false,
    this.viewCount = 0,
    this.tags = const [],
    this.attachments = const [],
    this.createdAt,
    this.lastActivityAt,
    this.replies = const [],
  });

  factory CommunityPost.fromJson(Map<String, dynamic> json) {
    return CommunityPost(
      id: _str(json['id']) ?? '',
      type: _postTypeFrom(_str(json['type'])),
      helpCategory: _str(json['helpCategory']),
      title: _str(json['title']),
      content: _str(json['content']) ?? '',
      author: json['author'] != null
          ? CommunityMember.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      authorRole: _str(json['authorRole']) ?? 'student',
      replyCount: _parseInt(json['replyCount']) ?? 0,
      likeCount: _parseInt(json['likeCount']) ?? 0,
      isLikedByMe: json['isLikedByMe'] == true,
      hasTeacherAnswer: json['hasTeacherAnswer'] == true,
      isPinned: json['isPinned'] == true,
      isResolved: json['isResolved'] == true,
      isClosed: json['isClosed'] == true,
      viewCount: _parseInt(json['viewCount']) ?? 0,
      tags: _stringList(json['tags']),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => CommunityAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      createdAt: _parseDate(json['createdAt']),
      lastActivityAt: _parseDate(json['lastActivityAt']),
      replies: (json['replies'] as List? ?? [])
          .map((r) => PostReply.fromJson(r as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isByTeacher => authorRole == 'instructor' || authorRole == 'admin';

  CommunityPost copyWith({
    int? likeCount,
    bool? isLikedByMe,
    bool? isPinned,
    bool? isResolved,
    bool? isClosed,
    int? replyCount,
    List<PostReply>? replies,
  }) {
    return CommunityPost(
      id: id,
      type: type,
      helpCategory: helpCategory,
      title: title,
      content: content,
      author: author,
      authorRole: authorRole,
      replyCount: replyCount ?? this.replyCount,
      likeCount: likeCount ?? this.likeCount,
      isLikedByMe: isLikedByMe ?? this.isLikedByMe,
      hasTeacherAnswer: hasTeacherAnswer,
      isPinned: isPinned ?? this.isPinned,
      isResolved: isResolved ?? this.isResolved,
      isClosed: isClosed ?? this.isClosed,
      viewCount: viewCount,
      tags: tags,
      attachments: attachments,
      createdAt: createdAt,
      lastActivityAt: lastActivityAt,
      replies: replies ?? this.replies,
    );
  }
}

class PostReply {
  final String id;
  final String content;
  final CommunityMember? author;
  final String authorRole;
  final bool isTeacherAnswer;
  final bool isAccepted;
  final int likeCount;
  final bool isLikedByMe;
  final DateTime? createdAt;

  const PostReply({
    required this.id,
    this.content = '',
    this.author,
    this.authorRole = 'student',
    this.isTeacherAnswer = false,
    this.isAccepted = false,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.createdAt,
  });

  factory PostReply.fromJson(Map<String, dynamic> json) {
    return PostReply(
      id: _str(json['id']) ?? '',
      content: _str(json['content']) ?? '',
      author: json['author'] != null
          ? CommunityMember.fromJson(json['author'] as Map<String, dynamic>)
          : null,
      authorRole: _str(json['authorRole']) ?? 'student',
      isTeacherAnswer: json['isTeacherAnswer'] == true,
      isAccepted: json['isAccepted'] == true,
      likeCount: _parseInt(json['likeCount']) ?? 0,
      isLikedByMe: json['isLikedByMe'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

class CommunityAttachment {
  final String name;
  final String url;
  final String? mimeType;
  final int? size;

  const CommunityAttachment({
    required this.name,
    required this.url,
    this.mimeType,
    this.size,
  });

  factory CommunityAttachment.fromJson(Map<String, dynamic> json) {
    return CommunityAttachment(
      name: _str(json['name']) ?? 'Attachment',
      url: _str(json['url']) ?? '',
      mimeType: _str(json['mimeType']),
      size: _parseInt(json['size']),
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'url': url,
        if (mimeType != null) 'mimeType': mimeType,
        if (size != null) 'size': size,
      };
}

// ─────────────────────────────────────────────
//  Study groups
// ─────────────────────────────────────────────

const Map<String, String> groupPurposeLabels = {
  'exam_prep': 'Exam preparation',
  'assignment': 'Assignment work',
  'revision': 'Revision',
  'project': 'Project',
  'practice': 'Practice',
  'general': 'General study',
};

class StudyGroupSummary {
  final String id;
  final String name;
  final String purpose;
  final String description;
  final int memberCount;
  final int maxMembers;
  final bool isOpen;
  final bool isFull;
  final int taskCount;
  final int openTaskCount;
  final String? myStatus;
  final String? myRole;
  final String? assignmentId;
  final DateTime? lastActivityAt;
  final List<CommunityMember> memberPreview;

  const StudyGroupSummary({
    required this.id,
    required this.name,
    this.purpose = 'general',
    this.description = '',
    this.memberCount = 0,
    this.maxMembers = 6,
    this.isOpen = true,
    this.isFull = false,
    this.taskCount = 0,
    this.openTaskCount = 0,
    this.myStatus,
    this.myRole,
    this.assignmentId,
    this.lastActivityAt,
    this.memberPreview = const [],
  });

  factory StudyGroupSummary.fromJson(Map<String, dynamic> json) {
    return StudyGroupSummary(
      id: _str(json['id']) ?? '',
      name: _str(json['name']) ?? 'Study group',
      purpose: _str(json['purpose']) ?? 'general',
      description: _str(json['description']) ?? '',
      memberCount: _parseInt(json['memberCount']) ?? 0,
      maxMembers: _parseInt(json['maxMembers']) ?? 6,
      isOpen: json['isOpen'] != false,
      isFull: json['isFull'] == true,
      taskCount: _parseInt(json['taskCount']) ?? 0,
      openTaskCount: _parseInt(json['openTaskCount']) ?? 0,
      myStatus: _str(json['myStatus']),
      myRole: _str(json['myRole']),
      assignmentId: _str(json['assignmentId']),
      lastActivityAt: _parseDate(json['lastActivityAt']),
      memberPreview: (json['memberPreview'] as List? ?? [])
          .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
    );
  }

  bool get isMine => myStatus == 'active';
  bool get isInvited => myStatus == 'invited';
  bool get isOwner => myRole == 'owner' && isMine;
  String get purposeLabel => groupPurposeLabels[purpose] ?? 'General study';
}

/// The full group workspace: members, tasks, submissions and sessions.
class StudyGroupDetail {
  final StudyGroupSummary summary;
  final bool canManage;
  final bool isTeacherView;
  final List<CommunityMember> members;
  final List<GroupTask> tasks;
  final List<AssignmentSubmission> submissions;
  final List<StudySession> sessions;

  const StudyGroupDetail({
    required this.summary,
    this.canManage = false,
    this.isTeacherView = false,
    this.members = const [],
    this.tasks = const [],
    this.submissions = const [],
    this.sessions = const [],
  });

  factory StudyGroupDetail.fromJson(Map<String, dynamic> json) {
    return StudyGroupDetail(
      summary: StudyGroupSummary.fromJson(json),
      canManage: json['canManage'] == true,
      isTeacherView: json['isTeacherView'] == true,
      members: (json['members'] as List? ?? [])
          .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      tasks: (json['tasks'] as List? ?? [])
          .map((t) => GroupTask.fromJson(t as Map<String, dynamic>))
          .toList(),
      submissions: (json['submissions'] as List? ?? [])
          .map((s) => AssignmentSubmission.fromJson(s as Map<String, dynamic>))
          .toList(),
      sessions: (json['sessions'] as List? ?? [])
          .map((s) => StudySession.fromJson(s as Map<String, dynamic>))
          .toList(),
    );
  }
}

class GroupTask {
  final String id;
  final String title;
  final String description;
  final bool isDone;
  final DateTime? dueDate;
  final List<CommunityMember> assignedTo;
  final DateTime? completedAt;

  const GroupTask({
    required this.id,
    required this.title,
    this.description = '',
    this.isDone = false,
    this.dueDate,
    this.assignedTo = const [],
    this.completedAt,
  });

  factory GroupTask.fromJson(Map<String, dynamic> json) {
    return GroupTask(
      id: _str(json['id']) ?? '',
      title: _str(json['title']) ?? '',
      description: _str(json['description']) ?? '',
      isDone: json['isDone'] == true,
      dueDate: _parseDate(json['dueDate']),
      assignedTo: (json['assignedTo'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CommunityMember.fromJson)
          .toList(),
      completedAt: _parseDate(json['completedAt']),
    );
  }
}

// ─────────────────────────────────────────────
//  Chat
// ─────────────────────────────────────────────

class CommunityChatMessage {
  final String id;
  final String scope;
  final String? groupId;
  final String? content;
  final List<CommunityAttachment> attachments;
  final CommunityMember? sender;
  final bool isTeacher;
  final bool isMine;
  final bool isDeleted;
  final String? replyToId;
  final String? replyToContent;
  final String? replyToSender;
  final DateTime? createdAt;

  const CommunityChatMessage({
    required this.id,
    this.scope = 'course',
    this.groupId,
    this.content,
    this.attachments = const [],
    this.sender,
    this.isTeacher = false,
    this.isMine = false,
    this.isDeleted = false,
    this.replyToId,
    this.replyToContent,
    this.replyToSender,
    this.createdAt,
  });

  factory CommunityChatMessage.fromJson(Map<String, dynamic> json) {
    final replyTo = json['replyTo'] as Map<String, dynamic>?;
    return CommunityChatMessage(
      id: _str(json['id']) ?? '',
      scope: _str(json['scope']) ?? 'course',
      groupId: _str(json['groupId']),
      content: _str(json['content']),
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => CommunityAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      sender: json['sender'] != null
          ? CommunityMember.fromJson(json['sender'] as Map<String, dynamic>)
          : null,
      isTeacher: json['isTeacher'] == true,
      isMine: json['isMine'] == true,
      isDeleted: json['isDeleted'] == true,
      replyToId: replyTo != null ? _str(replyTo['id']) : null,
      replyToContent: replyTo != null ? _str(replyTo['content']) : null,
      replyToSender: replyTo != null ? _str(replyTo['senderName']) : null,
      createdAt: _parseDate(json['createdAt']),
    );
  }
}

// ─────────────────────────────────────────────
//  Assignments & submissions
// ─────────────────────────────────────────────

class CommunityAssignment {
  final String id;
  final String title;
  final String description;
  final String type; // individual | group
  final int minGroupSize;
  final int maxGroupSize;
  final DateTime? dueDate;
  final int maxMarks;
  final List<CommunityAttachment> attachments;
  final bool allowLateSubmission;
  final bool isPublished;
  final bool isOverdue;
  final AssignmentSubmission? mySubmission;
  final int submissionTotal;
  final int submissionPending;
  final StudyGroupSummary? myGroup;
  final bool needsGroup;
  final List<AssignmentSubmission> submissions;
  final AssignmentStats? stats;

  const CommunityAssignment({
    required this.id,
    required this.title,
    this.description = '',
    this.type = 'individual',
    this.minGroupSize = 2,
    this.maxGroupSize = 6,
    this.dueDate,
    this.maxMarks = 20,
    this.attachments = const [],
    this.allowLateSubmission = false,
    this.isPublished = true,
    this.isOverdue = false,
    this.mySubmission,
    this.submissionTotal = 0,
    this.submissionPending = 0,
    this.myGroup,
    this.needsGroup = false,
    this.submissions = const [],
    this.stats,
  });

  factory CommunityAssignment.fromJson(Map<String, dynamic> json) {
    final counts = json['submissionCounts'] as Map<String, dynamic>? ?? const {};
    return CommunityAssignment(
      id: _str(json['id']) ?? '',
      title: _str(json['title']) ?? '',
      description: _str(json['description']) ?? '',
      type: _str(json['type']) ?? 'individual',
      minGroupSize: _parseInt(json['minGroupSize']) ?? 2,
      maxGroupSize: _parseInt(json['maxGroupSize']) ?? 6,
      dueDate: _parseDate(json['dueDate']),
      maxMarks: _parseInt(json['maxMarks']) ?? 20,
      attachments: (json['attachments'] as List? ?? [])
          .map((a) => CommunityAttachment.fromJson(a as Map<String, dynamic>))
          .toList(),
      allowLateSubmission: json['allowLateSubmission'] == true,
      isPublished: json['isPublished'] != false,
      isOverdue: json['isOverdue'] == true,
      mySubmission: json['mySubmission'] != null
          ? AssignmentSubmission.fromJson(json['mySubmission'] as Map<String, dynamic>)
          : null,
      submissionTotal: _parseInt(counts['total']) ?? 0,
      submissionPending: _parseInt(counts['pending']) ?? 0,
      myGroup: json['myGroup'] != null
          ? StudyGroupSummary.fromJson(json['myGroup'] as Map<String, dynamic>)
          : null,
      needsGroup: json['needsGroup'] == true,
      submissions: (json['submissions'] as List? ?? [])
          .map((s) => AssignmentSubmission.fromJson(s as Map<String, dynamic>))
          .toList(),
      stats: json['stats'] != null
          ? AssignmentStats.fromJson(json['stats'] as Map<String, dynamic>)
          : null,
    );
  }

  bool get isGroupAssignment => type == 'group';

  /// Where this assignment sits for the current student.
  String get studentStatusLabel {
    if (mySubmission == null) return isOverdue ? 'Missed' : 'Not submitted';
    if (mySubmission!.grade != null) return 'Graded';
    return 'Awaiting review';
  }
}

class AssignmentStats {
  final int enrolledCount;
  final int submissionCount;
  final int submittedStudentCount;
  final int pendingReview;
  final int graded;

  const AssignmentStats({
    this.enrolledCount = 0,
    this.submissionCount = 0,
    this.submittedStudentCount = 0,
    this.pendingReview = 0,
    this.graded = 0,
  });

  factory AssignmentStats.fromJson(Map<String, dynamic> json) => AssignmentStats(
        enrolledCount: _parseInt(json['enrolledCount']) ?? 0,
        submissionCount: _parseInt(json['submissionCount']) ?? 0,
        submittedStudentCount: _parseInt(json['submittedStudentCount']) ?? 0,
        pendingReview: _parseInt(json['pendingReview']) ?? 0,
        graded: _parseInt(json['graded']) ?? 0,
      );
}

class AssignmentSubmission {
  final String id;
  final String assignmentId;
  final String? assignmentTitle;
  final int? assignmentMaxMarks;
  final String? groupId;
  final String? groupName;
  final CommunityMember? submittedBy;
  final List<CommunityMember> members;
  final String comment;
  final List<CommunityAttachment> files;
  final String status;
  final bool isLate;
  final DateTime? submittedAt;
  final SubmissionGrade? grade;

  const AssignmentSubmission({
    required this.id,
    required this.assignmentId,
    this.assignmentTitle,
    this.assignmentMaxMarks,
    this.groupId,
    this.groupName,
    this.submittedBy,
    this.members = const [],
    this.comment = '',
    this.files = const [],
    this.status = 'submitted',
    this.isLate = false,
    this.submittedAt,
    this.grade,
  });

  factory AssignmentSubmission.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>?;
    final assignment = json['assignment'] as Map<String, dynamic>?;
    return AssignmentSubmission(
      id: _str(json['id']) ?? '',
      assignmentId: _str(json['assignmentId']) ??
          (assignment != null ? _str(assignment['id']) ?? '' : ''),
      assignmentTitle: assignment != null ? _str(assignment['title']) : null,
      assignmentMaxMarks: assignment != null ? _parseInt(assignment['maxMarks']) : null,
      groupId: group != null ? _str(group['id']) : null,
      groupName: group != null ? _str(group['name']) : null,
      submittedBy: json['submittedBy'] != null
          ? CommunityMember.fromJson(json['submittedBy'] as Map<String, dynamic>)
          : null,
      members: (json['members'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CommunityMember.fromJson)
          .toList(),
      comment: _str(json['comment']) ?? '',
      files: (json['files'] as List? ?? [])
          .map((f) => CommunityAttachment.fromJson(f as Map<String, dynamic>))
          .toList(),
      status: _str(json['status']) ?? 'submitted',
      isLate: json['isLate'] == true,
      submittedAt: _parseDate(json['submittedAt']),
      grade: json['grade'] != null
          ? SubmissionGrade.fromJson(json['grade'] as Map<String, dynamic>)
          : null,
    );
  }
}

class SubmissionGrade {
  final double score;
  final String feedback;
  final DateTime? gradedAt;
  final CommunityMember? gradedBy;

  const SubmissionGrade({
    required this.score,
    this.feedback = '',
    this.gradedAt,
    this.gradedBy,
  });

  factory SubmissionGrade.fromJson(Map<String, dynamic> json) => SubmissionGrade(
        score: _parseDouble(json['score']) ?? 0,
        feedback: _str(json['feedback']) ?? '',
        gradedAt: _parseDate(json['gradedAt']),
        gradedBy: json['gradedBy'] != null
            ? CommunityMember.fromJson(json['gradedBy'] as Map<String, dynamic>)
            : null,
      );
}

// ─────────────────────────────────────────────
//  Resources & study sessions
// ─────────────────────────────────────────────

class CommunityResource {
  final String id;
  final String title;
  final String description;
  final String type; // document | link | video | note
  final String source; // teacher | student
  final String? url;
  final String? body;
  final String? fileName;
  final CommunityMember? uploadedBy;
  final bool isApproved;
  final bool isMine;
  final int likeCount;
  final bool isLikedByMe;
  final DateTime? createdAt;

  const CommunityResource({
    required this.id,
    required this.title,
    this.description = '',
    this.type = 'link',
    this.source = 'student',
    this.url,
    this.body,
    this.fileName,
    this.uploadedBy,
    this.isApproved = false,
    this.isMine = false,
    this.likeCount = 0,
    this.isLikedByMe = false,
    this.createdAt,
  });

  factory CommunityResource.fromJson(Map<String, dynamic> json) {
    return CommunityResource(
      id: _str(json['id']) ?? '',
      title: _str(json['title']) ?? '',
      description: _str(json['description']) ?? '',
      type: _str(json['type']) ?? 'link',
      source: _str(json['source']) ?? 'student',
      url: _str(json['url']),
      body: _str(json['body']),
      fileName: _str(json['fileName']),
      uploadedBy: json['uploadedBy'] != null
          ? CommunityMember.fromJson(json['uploadedBy'] as Map<String, dynamic>)
          : null,
      isApproved: json['isApproved'] == true,
      isMine: json['isMine'] == true,
      likeCount: _parseInt(json['likeCount']) ?? 0,
      isLikedByMe: json['isLikedByMe'] == true,
      createdAt: _parseDate(json['createdAt']),
    );
  }

  bool get isFromTeacher => source == 'teacher';
}

/// A peer study meeting. Runs on the platform's BigBlueButton server unless
/// the organiser supplied their own link (`meetingProvider == 'external'`).
class StudySession {
  final String id;
  final String topic;
  final String description;
  final DateTime? scheduledAt;
  final DateTime? expectedEndAt;
  final int durationMinutes;
  final List<String> agenda;
  final int maxParticipants;
  final int participantCount;
  final List<CommunityMember> participants;

  /// I said I am coming (RSVP) — distinct from having entered the room.
  final bool isJoined;
  final bool hasAttended;

  /// scheduled | live | completed | cancelled
  final String status;
  final bool isLive;
  final bool isPast;

  /// bbb | external
  final String meetingProvider;
  final String? meetingLink;
  final DateTime? startedAt;
  final DateTime? endedAt;

  final String? recordingUrl;
  final int recordingDuration;

  final String? groupId;
  final String? groupName;
  final CommunityMember? organiser;
  final bool isMine;

  /// I organise this session, or I teach this course.
  final bool canModerate;

  /// The room can be opened right now (organiser only, once the window opens).
  final bool canStart;

  /// I can enter the room right now.
  final bool canJoin;
  final bool isWithinJoinWindow;

  const StudySession({
    required this.id,
    required this.topic,
    this.description = '',
    this.scheduledAt,
    this.expectedEndAt,
    this.durationMinutes = 60,
    this.agenda = const [],
    this.maxParticipants = 10,
    this.participantCount = 0,
    this.participants = const [],
    this.isJoined = false,
    this.hasAttended = false,
    this.status = 'scheduled',
    this.isLive = false,
    this.isPast = false,
    this.meetingProvider = 'bbb',
    this.meetingLink,
    this.startedAt,
    this.endedAt,
    this.recordingUrl,
    this.recordingDuration = 0,
    this.groupId,
    this.groupName,
    this.organiser,
    this.isMine = false,
    this.canModerate = false,
    this.canStart = false,
    this.canJoin = false,
    this.isWithinJoinWindow = false,
  });

  factory StudySession.fromJson(Map<String, dynamic> json) {
    final group = json['group'] as Map<String, dynamic>?;
    return StudySession(
      id: _str(json['id']) ?? '',
      topic: _str(json['topic']) ?? '',
      description: _str(json['description']) ?? '',
      scheduledAt: _parseDate(json['scheduledAt']),
      expectedEndAt: _parseDate(json['expectedEndAt']),
      durationMinutes: _parseInt(json['durationMinutes']) ?? 60,
      agenda: _stringList(json['agenda']),
      maxParticipants: _parseInt(json['maxParticipants']) ?? 10,
      participantCount: _parseInt(json['participantCount']) ?? 0,
      participants: (json['participants'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(CommunityMember.fromJson)
          .toList(),
      isJoined: json['isJoined'] == true,
      hasAttended: json['hasAttended'] == true,
      status: _str(json['status']) ?? 'scheduled',
      isLive: json['isLive'] == true,
      isPast: json['isPast'] == true,
      meetingProvider: _str(json['meetingProvider']) ?? 'bbb',
      meetingLink: _str(json['meetingLink']),
      startedAt: _parseDate(json['startedAt']),
      endedAt: _parseDate(json['endedAt']),
      recordingUrl: _str(json['recordingUrl']),
      recordingDuration: _parseInt(json['recordingDuration']) ?? 0,
      groupId: group != null ? _str(group['id']) : null,
      groupName: group != null ? _str(group['name']) : null,
      organiser: json['organiser'] != null
          ? CommunityMember.fromJson(json['organiser'] as Map<String, dynamic>)
          : null,
      isMine: json['isMine'] == true,
      canModerate: json['canModerate'] == true,
      canStart: json['canStart'] == true,
      canJoin: json['canJoin'] == true,
      isWithinJoinWindow: json['isWithinJoinWindow'] == true,
    );
  }

  bool get isCancelled => status == 'cancelled';
  bool get isCompleted => status == 'completed';
  bool get isFull => participantCount >= maxParticipants;
  bool get runsOnPlatform => meetingProvider == 'bbb';
  bool get hasRecording => (recordingUrl ?? '').isNotEmpty;

  /// Countdown shown before the room opens ("Opens in 12 min").
  Duration? get timeUntilStart {
    if (scheduledAt == null) return null;
    final diff = scheduledAt!.difference(DateTime.now());
    return diff.isNegative ? Duration.zero : diff;
  }
}

/// What the backend hands back when you ask to enter a session's room.
class SessionJoinTicket {
  final String provider;
  final String joinUrl;
  final bool isModerator;
  final String status;

  const SessionJoinTicket({
    required this.provider,
    required this.joinUrl,
    this.isModerator = false,
    this.status = 'live',
  });

  factory SessionJoinTicket.fromJson(Map<String, dynamic> json) => SessionJoinTicket(
        provider: _str(json['provider']) ?? 'bbb',
        joinUrl: _str(json['joinUrl']) ?? '',
        isModerator: json['isModerator'] == true,
        status: _str(json['status']) ?? 'live',
      );
}

// ─────────────────────────────────────────────
//  Dashboard payload
// ─────────────────────────────────────────────

class CommunityStats {
  final int enrolledCount;
  final int activeCount;
  final int teacherCount;
  final int groupCount;
  final int discussionCount;
  final int unreadChatCount;

  /// Teachers: submissions awaiting review. Students: assignments not yet done.
  final int pendingCount;

  const CommunityStats({
    this.enrolledCount = 0,
    this.activeCount = 0,
    this.teacherCount = 0,
    this.groupCount = 0,
    this.discussionCount = 0,
    this.unreadChatCount = 0,
    this.pendingCount = 0,
  });

  factory CommunityStats.fromJson(Map<String, dynamic> json) => CommunityStats(
        enrolledCount: _parseInt(json['enrolledCount']) ?? 0,
        activeCount: _parseInt(json['activeCount']) ?? 0,
        teacherCount: _parseInt(json['teacherCount']) ?? 0,
        groupCount: _parseInt(json['groupCount']) ?? 0,
        discussionCount: _parseInt(json['discussionCount']) ?? 0,
        unreadChatCount: _parseInt(json['unreadChatCount']) ?? 0,
        pendingCount: _parseInt(json['pendingCount']) ?? 0,
      );
}

class CommunityOverview {
  final String courseId;
  final String courseTitle;
  final String myId;
  final String myRole;
  final bool isTeacher;
  final CommunityStats stats;
  final List<CommunityMember> teachers;
  final List<CommunityMember> activeMembers;
  final List<StudyGroupSummary> myGroups;
  final List<CommunityPost> pinnedPosts;
  final List<CommunityPost> recentDiscussions;
  final List<CommunityAssignment> upcomingAssignments;
  final StudySession? nextSession;

  const CommunityOverview({
    required this.courseId,
    required this.courseTitle,
    required this.myId,
    this.myRole = 'student',
    this.isTeacher = false,
    this.stats = const CommunityStats(),
    this.teachers = const [],
    this.activeMembers = const [],
    this.myGroups = const [],
    this.pinnedPosts = const [],
    this.recentDiscussions = const [],
    this.upcomingAssignments = const [],
    this.nextSession,
  });

  factory CommunityOverview.fromJson(Map<String, dynamic> json) {
    final course = json['course'] as Map<String, dynamic>? ?? const {};
    final me = json['me'] as Map<String, dynamic>? ?? const {};
    return CommunityOverview(
      courseId: _str(course['id']) ?? '',
      courseTitle: _str(course['title']) ?? 'Course',
      myId: _str(me['id']) ?? '',
      myRole: _str(me['role']) ?? 'student',
      isTeacher: me['isTeacher'] == true,
      stats: CommunityStats.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {}),
      teachers: (json['teachers'] as List? ?? [])
          .map((t) => CommunityMember.fromJson(t as Map<String, dynamic>))
          .toList(),
      activeMembers: (json['activeMembers'] as List? ?? [])
          .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      myGroups: (json['myGroups'] as List? ?? [])
          .map((g) => StudyGroupSummary.fromJson(g as Map<String, dynamic>))
          .toList(),
      pinnedPosts: (json['pinnedPosts'] as List? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      recentDiscussions: (json['recentDiscussions'] as List? ?? [])
          .map((p) => CommunityPost.fromJson(p as Map<String, dynamic>))
          .toList(),
      upcomingAssignments: (json['upcomingAssignments'] as List? ?? [])
          .map((a) => CommunityAssignment.fromJson(a as Map<String, dynamic>))
          .toList(),
      nextSession: json['nextSession'] != null
          ? StudySession.fromJson(json['nextSession'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MemberDirectory {
  final List<CommunityMember> members;
  final int total;
  final int page;
  final int totalPages;
  final int enrolledCount;
  final int activeCount;
  final int teacherCount;

  const MemberDirectory({
    this.members = const [],
    this.total = 0,
    this.page = 1,
    this.totalPages = 1,
    this.enrolledCount = 0,
    this.activeCount = 0,
    this.teacherCount = 0,
  });

  factory MemberDirectory.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    final counts = json['counts'] as Map<String, dynamic>? ?? const {};
    return MemberDirectory(
      members: (json['members'] as List? ?? [])
          .map((m) => CommunityMember.fromJson(m as Map<String, dynamic>))
          .toList(),
      total: _parseInt(pagination['total']) ?? 0,
      page: _parseInt(pagination['page']) ?? 1,
      totalPages: _parseInt(pagination['totalPages']) ?? 1,
      enrolledCount: _parseInt(counts['enrolled']) ?? 0,
      activeCount: _parseInt(counts['active']) ?? 0,
      teacherCount: _parseInt(counts['teachers']) ?? 0,
    );
  }
}

/// Split view of shared resources: authoritative vs peer-shared.
class CommunityResourceLibrary {
  final List<CommunityResource> teacherResources;
  final List<CommunityResource> studentResources;

  const CommunityResourceLibrary({
    this.teacherResources = const [],
    this.studentResources = const [],
  });

  factory CommunityResourceLibrary.fromJson(Map<String, dynamic> json) =>
      CommunityResourceLibrary(
        teacherResources: (json['teacherResources'] as List? ?? [])
            .map((r) => CommunityResource.fromJson(r as Map<String, dynamic>))
            .toList(),
        studentResources: (json['studentResources'] as List? ?? [])
            .map((r) => CommunityResource.fromJson(r as Map<String, dynamic>))
            .toList(),
      );

  bool get isEmpty => teacherResources.isEmpty && studentResources.isEmpty;
}

// ─────────────────────────────────────────────
//  JSON helpers
// ─────────────────────────────────────────────

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

double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}

DateTime? _parseDate(dynamic value) {
  if (value == null) return null;
  if (value is DateTime) return value;
  if (value is int) return DateTime.fromMillisecondsSinceEpoch(value);
  return DateTime.tryParse(value.toString());
}

List<String> _stringList(dynamic value) {
  if (value is List) {
    return value.map((e) => e.toString()).where((e) => e.isNotEmpty).toList();
  }
  return const [];
}
