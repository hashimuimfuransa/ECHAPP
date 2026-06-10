/// Live Session Model
/// Represents a BigBlueButton live session scheduled by a teacher
class LiveSession {
  final String id;
  final String teacherId;
  final String courseId;
  final String sectionId;
  final String? lessonId;
  final String title;
  final String? description;
  final DateTime scheduledAt;
  final int duration;
  final DateTime? expectedEndTime;
  final String? bbbMeetingId;
  final String? bbbInternalMeetingId;
  final String? bbbModeratorUrl;
  final String? bbbAttendeeUrl;
  final String? bbbModeratorPw;
  final String? bbbAttendeePw;
  final String status;
  final String? recordingUrl;
  final int recordingDuration;
  final String? recordingFormat;
  final DateTime? endedAt;
  final int maxParticipants;
  final SessionSettings settings;
  final int participantCount;
  final List<dynamic>? attendees;
  final List<dynamic>? attendedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // Populated fields
  final Map<String, dynamic>? course;
  final Map<String, dynamic>? section;
  final Map<String, dynamic>? lesson;
  final Map<String, dynamic>? teacher;

  LiveSession({
    required this.id,
    required this.teacherId,
    required this.courseId,
    required this.sectionId,
    this.lessonId,
    required this.title,
    this.description,
    required this.scheduledAt,
    required this.duration,
    this.expectedEndTime,
    this.bbbMeetingId,
    this.bbbInternalMeetingId,
    this.bbbModeratorUrl,
    this.bbbAttendeeUrl,
    this.bbbModeratorPw,
    this.bbbAttendeePw,
    this.status = 'scheduled',
    this.recordingUrl,
    this.recordingDuration = 0,
    this.recordingFormat,
    this.endedAt,
    this.maxParticipants = 100,
    required this.settings,
    this.participantCount = 0,
    this.attendees,
    this.attendedAt,
    this.createdAt,
    this.updatedAt,
    this.course,
    this.section,
    this.lesson,
    this.teacher,
  });

  factory LiveSession.fromJson(Map<String, dynamic> json) {
    return LiveSession(
      id: json['_id'] ?? json['id'] ?? '',
      teacherId: (json['teacherId'] is Map
          ? json['teacherId']['_id'] ?? json['teacherId']['id'] ?? ''
          : json['teacherId'] ?? '') as String,
      courseId: (json['courseId'] is Map
          ? json['courseId']['_id'] ?? json['courseId']['id'] ?? ''
          : json['courseId'] ?? '') as String,
      sectionId: (json['sectionId'] is Map
          ? json['sectionId']['_id'] ?? json['sectionId']['id'] ?? ''
          : json['sectionId'] ?? '') as String,
      lessonId: json['lessonId'] is Map
          ? (json['lessonId']['_id'] ?? json['lessonId']['id']) as String?
          : json['lessonId'] as String?,
      title: json['title'] is String ? json['title'] : '',
      description: json['description'] is String ? json['description'] : null,
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt']).toLocal()
          : DateTime.now(),
      duration: json['duration'] ?? 60,
      expectedEndTime: json['expectedEndTime'] != null
          ? DateTime.parse(json['expectedEndTime']).toLocal()
          : null,
      bbbMeetingId: json['bbbMeetingId'] is String ? json['bbbMeetingId'] : null,
      bbbInternalMeetingId: json['bbbInternalMeetingId'] is String ? json['bbbInternalMeetingId'] : null,
      bbbModeratorUrl: json['bbbModeratorUrl'] is String ? json['bbbModeratorUrl'] : null,
      bbbAttendeeUrl: json['bbbAttendeeUrl'] is String ? json['bbbAttendeeUrl'] : null,
      bbbModeratorPw: json['bbbModeratorPw'] is String ? json['bbbModeratorPw'] : null,
      bbbAttendeePw: json['bbbAttendeePw'] is String ? json['bbbAttendeePw'] : null,
      status: json['status'] is String ? json['status'] : 'scheduled',
      recordingUrl: json['recordingUrl'] is String ? json['recordingUrl'] : null,
      recordingDuration: json['recordingDuration'] ?? 0,
      recordingFormat: json['recordingFormat'] is String ? json['recordingFormat'] : null,
      endedAt: json['endedAt'] != null
          ? DateTime.parse(json['endedAt']).toLocal()
          : null,
      maxParticipants: json['maxParticipants'] ?? 100,
      settings: json['settings'] != null
          ? SessionSettings.fromJson(json['settings'])
          : SessionSettings(),
      participantCount: json['participantCount'] ?? 0,
      attendees: json['attendees'] != null ? List<dynamic>.from(json['attendees']) : null,
      attendedAt: json['attendedAt'] != null ? List<dynamic>.from(json['attendedAt']) : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt']).toLocal()
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt']).toLocal()
          : null,
      course: json['courseId'] is Map ? json['courseId'] : null,
      section: json['sectionId'] is Map ? json['sectionId'] : null,
      lesson: json['lessonId'] is Map ? json['lessonId'] : null,
      teacher: json['teacherId'] is Map ? json['teacherId'] : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teacherId': teacherId,
      'courseId': courseId,
      'sectionId': sectionId,
      'lessonId': lessonId,
      'title': title,
      'description': description,
      'scheduledAt': scheduledAt.toIso8601String(),
      'duration': duration,
      'bbbMeetingId': bbbMeetingId,
      'bbbInternalMeetingId': bbbInternalMeetingId,
      'bbbModeratorUrl': bbbModeratorUrl,
      'bbbAttendeeUrl': bbbAttendeeUrl,
      'bbbModeratorPw': bbbModeratorPw,
      'bbbAttendeePw': bbbAttendeePw,
      'status': status,
      'recordingUrl': recordingUrl,
      'recordingDuration': recordingDuration,
      'recordingFormat': recordingFormat,
      'endedAt': endedAt?.toIso8601String(),
      'maxParticipants': maxParticipants,
      'settings': settings.toJson(),
      'participantCount': participantCount,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  bool get isScheduled => status == 'scheduled';
  bool get isLive => status == 'live';
  bool get isEnded => status == 'ended';
  bool get isCancelled => status == 'cancelled';
  bool get hasRecording => recordingUrl != null && recordingUrl!.isNotEmpty;

  // Use backend-provided expectedEndTime if available, otherwise calculate it
  DateTime get calculatedEndTime => expectedEndTime ?? scheduledAt.add(Duration(minutes: duration));

  /// e.g. "Started 12 min ago · Ends at 15:30"
  /// or "Starts at 14:00 · Ends at 15:00"
  String get timeProgressInfo {
    final now = DateTime.now();
    final endTime = calculatedEndTime;
    final endStr = _hhmm(endTime);
    if (isLive || scheduledAt.isBefore(now)) {
      final elapsed = now.difference(scheduledAt);
      final elapsedStr = elapsed.inMinutes < 60
          ? '${elapsed.inMinutes} min ago'
          : '${elapsed.inHours}h ${elapsed.inMinutes % 60}m ago';
      return 'Started $elapsedStr · Ends at $endStr';
    } else {
      return 'Starts at ${_hhmm(scheduledAt)} · Ends at $endStr';
    }
  }

  static String _hhmm(DateTime dt) =>
      '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';

  String get formattedDuration {
    final hours = duration ~/ 60;
    final minutes = duration % 60;
    if (hours > 0) {
      return minutes > 0 ? '${hours}h ${minutes}m' : '${hours}h';
    }
    return '${minutes}m';
  }

  String get formattedScheduledDate {
    return '${scheduledAt.day}/${scheduledAt.month}/${scheduledAt.year}';
  }

  String get formattedScheduledTime {
    final now = DateTime.now();
    final difference = scheduledAt.difference(now);
    
    if (difference.inDays > 0) {
      return 'In ${difference.inDays} day${difference.inDays > 1 ? 's' : ''}';
    } else if (difference.inHours > 0) {
      return 'In ${difference.inHours} hour${difference.inHours > 1 ? 's' : ''}';
    } else if (difference.inMinutes > 0) {
      return 'In ${difference.inMinutes} min';
    } else if (difference.isNegative) {
      return 'Started';
    }
    return 'Starting soon';
  }
}

/// Session Settings Model
class SessionSettings {
  final bool enableChat;
  final bool enableWebcam;
  final bool muteOnEntry;
  final bool allowRecording;
  final bool waitingRoom;

  SessionSettings({
    this.enableChat = true,
    this.enableWebcam = true,
    this.muteOnEntry = true,
    this.allowRecording = true,
    this.waitingRoom = false,
  });

  factory SessionSettings.fromJson(Map<String, dynamic> json) {
    return SessionSettings(
      enableChat: json['enableChat'] ?? true,
      enableWebcam: json['enableWebcam'] ?? true,
      muteOnEntry: json['muteOnEntry'] ?? true,
      allowRecording: json['allowRecording'] ?? true,
      waitingRoom: json['waitingRoom'] ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enableChat': enableChat,
      'enableWebcam': enableWebcam,
      'muteOnEntry': muteOnEntry,
      'allowRecording': allowRecording,
      'waitingRoom': waitingRoom,
    };
  }
}
