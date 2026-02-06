import 'user.dart';

class Course {
  final String id;
  final String title;
  final String description;
  final double price;
  final int duration;
  final String level;
  final String? thumbnail;
  final bool isPublished;
  final User createdBy;
  final String? categoryId;
  final Map<String, dynamic>? category;
  final DateTime createdAt;
  final List<String>? learningObjectives;
  final List<String>? requirements;

  Course({
    required this.id,
    required this.title,
    required this.description,
    required this.price,
    required this.duration,
    required this.level,
    this.thumbnail,
    required this.isPublished,
    required this.createdBy,
    this.categoryId,
    this.category,
    required this.createdAt,
    this.learningObjectives,
    this.requirements,
  });

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: json['id'] as String? ?? json['_id']?.toString() ?? '',
      title: json['title']?.toString() ?? 'Untitled Course',
      description: json['description'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as int? ?? 0,
      level: json['level'] as String? ?? 'Beginner',
      thumbnail: json['thumbnail'] as String?,
      isPublished: json['isPublished'] as bool? ?? false,
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? User.fromJson(json['createdBy'] as Map<String, dynamic>)
          : User(id: json['createdBy']?.toString() ?? '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
      categoryId: json['categoryId'] as String?,
      category: json['category'] is Map<String, dynamic>
          ? json['category'] as Map<String, dynamic>
          : json['category'] is String
              ? {'id': json['category']}
              : null,
      createdAt: _parseDateTime(json['createdAt']),
      learningObjectives: json['learningObjectives'] is List
          ? List<String>.from(json['learningObjectives'])
          : null,
      requirements: json['requirements'] is List
          ? List<String>.from(json['requirements'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'price': price,
      'duration': duration,
      'level': level,
      'thumbnail': thumbnail,
      'isPublished': isPublished,
      'createdBy': createdBy.toJson(),
      'categoryId': categoryId,
      'category': category,
      'createdAt': createdAt.toIso8601String(),
      'learningObjectives': learningObjectives,
      'requirements': requirements,
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    }
    
    return DateTime.now();
  }

  @override
  String toString() {
    return 'Course(id: $id, title: $title, price: $price, level: $level)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Course &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}