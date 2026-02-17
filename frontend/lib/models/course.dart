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
  final int? accessDurationDays;

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
    this.accessDurationDays,
  });

  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      // If it's a Map, try to convert to string representation
      return value.toString();
    }
    // For other types, convert to string
    return value.toString();
  }

  factory Course.fromJson(Map<String, dynamic> json) {
    return Course(
      id: _getStringValue(json['id']) ?? _getStringValue(json['_id']) ?? '',
      title: _getStringValue(json['title']) ?? 'Untitled Course',
      description: _getStringValue(json['description']) ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      duration: json['duration'] as int? ?? 0,
      level: _getStringValue(json['level']) ?? 'Beginner',
      thumbnail: _getStringValue(json['thumbnail']),
      isPublished: json['isPublished'] as bool? ?? false,
      createdBy: json['createdBy'] is Map<String, dynamic>
          ? User.fromJson(json['createdBy'] as Map<String, dynamic>)
          : User(id: _getStringValue(json['createdBy']) ?? '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
      categoryId: _getStringValue(json['categoryId']),
      category: json['category'] is Map<String, dynamic>
          ? json['category'] as Map<String, dynamic>
          : _getStringValue(json['category']) is String
              ? {'id': _getStringValue(json['category'])}
              : null,
      createdAt: _parseDateTime(json['createdAt']),
      learningObjectives: json['learningObjectives'] is List
          ? List<String>.from((json['learningObjectives'] as List).map((e) => _getStringValue(e) ?? '').toList())
          : null,
      requirements: json['requirements'] is List
          ? List<String>.from((json['requirements'] as List).map((e) => _getStringValue(e) ?? '').toList())
          : null,
      accessDurationDays: json['accessDurationDays'] as int?,
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
      'accessDurationDays': accessDurationDays,
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
    } else if (dateValue is Map<String, dynamic>) {
      // Handle case where date is stored as an object (e.g., Firestore timestamp)
      try {
        // Check if it's a Firestore Timestamp-like object with seconds and nanoseconds
        if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
          int seconds = dateValue['seconds'] as int? ?? 0;
          int nanoseconds = dateValue['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else if (dateValue.containsKey('_seconds')) {
          // Alternative format with _seconds
          int seconds = dateValue['_seconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        // If conversion fails, return current time
        return DateTime.now();
      }
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
