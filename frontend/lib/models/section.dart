class Section {
  final String id;
  final String courseId;
  final String title;
  final int order;

  Section({
    required this.id,
    required this.courseId,
    required this.title,
    required this.order,
  });

  factory Section.fromJson(Map<String, dynamic> json) {
    return Section(
      id: json['_id'] ?? json['id'] ?? '',
      courseId: json['courseId'] ?? '',
      title: json['title'] ?? '',
      order: json['order'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'courseId': courseId,
      'title': title,
      'order': order,
    };
  }
}
