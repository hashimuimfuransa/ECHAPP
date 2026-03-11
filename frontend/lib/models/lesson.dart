class Lesson {
  final String id;
  final String sectionId;
  final String courseId;
  final String title;
  final String? description;
  final String? videoId;
  final String? notes;
  final String? status;
  final int order;
  final int duration;

  Lesson({
    required this.id,
    required this.sectionId,
    required this.courseId,
    required this.title,
    this.description,
    this.videoId,
    this.notes,
    this.status,
    required this.order,
    required this.duration,
  });

  factory Lesson.fromJson(Map<String, dynamic> json) {
    return Lesson(
      id: json['_id'] ?? json['id'] ?? '',
      sectionId: json['sectionId'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] as String?,
      videoId: json['videoId'] as String?,
      notes: json['notes'] as String?,
      status: json['status'] as String?,
      order: json['order'] ?? 0,
      duration: json['duration'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'sectionId': sectionId,
      'courseId': courseId,
      'title': title,
      'description': description,
      'videoId': videoId,
      'notes': notes,
      'status': status,
      'order': order,
      'duration': duration,
    };
  }

  Lesson copyWith({
    String? id,
    String? sectionId,
    String? courseId,
    String? title,
    String? description,
    String? videoId,
    String? notes,
    String? status,
    int? order,
    int? duration,
  }) {
    return Lesson(
      id: id ?? this.id,
      sectionId: sectionId ?? this.sectionId,
      courseId: courseId ?? this.courseId,
      title: title ?? this.title,
      description: description ?? this.description,
      videoId: videoId ?? this.videoId,
      notes: notes ?? this.notes,
      status: status ?? this.status,
      order: order ?? this.order,
      duration: duration ?? this.duration,
    );
  }
}
