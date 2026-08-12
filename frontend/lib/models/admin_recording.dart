/// A recording in the admin library — either a teacher-led live class or a
/// peer study session. Admins see both in one list.
library;

class AdminRecording {
  final String id;

  /// `live` (teacher class) or `study` (peer session).
  final String kind;
  final String title;
  final String? courseId;
  final String? courseTitle;
  final String? teacherName;
  final DateTime? scheduledAt;
  final DateTime? endedAt;
  final int durationMinutes;
  final int participants;
  final String? playbackUrl;
  final String? downloadUrl;
  final bool hasDownloadableFile;
  final bool isPublished;

  const AdminRecording({
    required this.id,
    required this.kind,
    required this.title,
    this.courseId,
    this.courseTitle,
    this.teacherName,
    this.scheduledAt,
    this.endedAt,
    this.durationMinutes = 0,
    this.participants = 0,
    this.playbackUrl,
    this.downloadUrl,
    this.hasDownloadableFile = false,
    this.isPublished = true,
  });

  factory AdminRecording.fromJson(Map<String, dynamic> json) => AdminRecording(
        id: _str(json['id']) ?? '',
        kind: _str(json['kind']) ?? 'live',
        title: _str(json['title']) ?? 'Untitled session',
        courseId: _str(json['courseId']),
        courseTitle: _str(json['courseTitle']),
        teacherName: _str(json['teacherName']),
        scheduledAt: _date(json['scheduledAt']),
        endedAt: _date(json['endedAt']),
        durationMinutes: _int(json['durationMinutes']) ?? 0,
        participants: _int(json['participants']) ?? 0,
        playbackUrl: _str(json['playbackUrl']),
        downloadUrl: _str(json['downloadUrl']),
        hasDownloadableFile: json['hasDownloadableFile'] == true,
        isPublished: json['isPublished'] != false,
      );

  bool get isLiveClass => kind == 'live';
  bool get canWatch => (playbackUrl ?? '').isNotEmpty;
  bool get canDownload => (downloadUrl ?? '').isNotEmpty;

  String get durationLabel {
    if (durationMinutes <= 0) return '—';
    if (durationMinutes < 60) return '$durationMinutes min';
    final h = durationMinutes ~/ 60;
    final m = durationMinutes % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

/// Headline counts shown above the list.
class AdminRecordingStats {
  final int total;
  final int liveClasses;
  final int studySessions;
  final int downloadable;

  const AdminRecordingStats({
    this.total = 0,
    this.liveClasses = 0,
    this.studySessions = 0,
    this.downloadable = 0,
  });

  factory AdminRecordingStats.fromJson(Map<String, dynamic> json) =>
      AdminRecordingStats(
        total: _int(json['total']) ?? 0,
        liveClasses: _int(json['liveClasses']) ?? 0,
        studySessions: _int(json['studySessions']) ?? 0,
        downloadable: _int(json['downloadable']) ?? 0,
      );
}

class AdminRecordingPage {
  final List<AdminRecording> recordings;
  final AdminRecordingStats stats;
  final int page;
  final int totalPages;

  const AdminRecordingPage({
    this.recordings = const [],
    this.stats = const AdminRecordingStats(),
    this.page = 1,
    this.totalPages = 1,
  });

  factory AdminRecordingPage.fromJson(Map<String, dynamic> json) {
    final pagination = json['pagination'] as Map<String, dynamic>? ?? const {};
    return AdminRecordingPage(
      recordings: (json['recordings'] as List? ?? [])
          .whereType<Map<String, dynamic>>()
          .map(AdminRecording.fromJson)
          .toList(),
      stats: AdminRecordingStats.fromJson(
          json['stats'] as Map<String, dynamic>? ?? const {}),
      page: _int(pagination['page']) ?? 1,
      totalPages: _int(pagination['totalPages']) ?? 1,
    );
  }
}

String? _str(dynamic v) {
  if (v == null) return null;
  if (v is String) return v.isEmpty ? null : v;
  return v.toString();
}

int? _int(dynamic v) {
  if (v == null) return null;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString());
}

DateTime? _date(dynamic v) {
  if (v == null) return null;
  if (v is DateTime) return v;
  return DateTime.tryParse(v.toString());
}
