import 'course.dart';

class Wishlist {
  final String id;
  final String userId;
  final List<String> courseIds;
  final List<Course> courses;
  final DateTime createdAt;
  final DateTime updatedAt;

  Wishlist({
    required this.id,
    required this.userId,
    required this.courseIds,
    required this.courses,
    required this.createdAt,
    required this.updatedAt,
  });

  Wishlist copyWith({
    String? id,
    String? userId,
    List<String>? courseIds,
    List<Course>? courses,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Wishlist(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      courseIds: courseIds ?? this.courseIds,
      courses: courses ?? this.courses,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'courseIds': courseIds,
      'courses': courses.map((course) => course.toJson()).toList(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory Wishlist.fromMap(Map<String, dynamic> map) {
    return Wishlist(
      id: map['id'] as String,
      userId: map['userId'] as String,
      courseIds: List<String>.from(map['courseIds'] as List),
      courses: (map['courses'] as List)
          .map((courseMap) => Course.fromJson(courseMap as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.parse(map['createdAt'] as String),
      updatedAt: DateTime.parse(map['updatedAt'] as String),
    );
  }
}
