class Video {
  final String id;
  final String title;
  final String? description;
  final String? url;
  final int duration; // in minutes
  final String courseId;
  final String? courseTitle;
  final String? videoId;
  final String? sectionId;
  final String? thumbnail;
  final DateTime createdAt;
  final DateTime updatedAt;

  Video({
    required this.id,
    required this.title,
    this.description,
    this.url,
    required this.duration,
    required this.courseId,
    this.courseTitle,
    this.videoId,
    this.sectionId,
    this.thumbnail,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Video.fromJson(Map<String, dynamic> json) {
    return Video(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'],
      url: json['url'],
      duration: json['duration'] as int? ?? 0,
      courseId: json['courseId'] ?? '',
      courseTitle: json['courseTitle'],
      videoId: json['videoId'],
      sectionId: json['sectionId'],
      thumbnail: json['thumbnail'],
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt'].toString()) : DateTime.now(),
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt'].toString()) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'title': title,
      'description': description,
      'url': url,
      'duration': duration,
      'courseId': courseId,
      'courseTitle': courseTitle,
      'videoId': videoId,
      'sectionId': sectionId,
      'thumbnail': thumbnail,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}