import 'package:freezed_annotation/freezed_annotation.dart';
import 'dart:convert';
import 'user.dart';

part 'course.freezed.dart';
part 'course.g.dart';

class UserConverter implements JsonConverter<User, Object> {
  const UserConverter();

  @override
  User fromJson(Object json) {
    if (json is String) {
      // If it's a string, parse it as JSON
      try {
        return User.fromJson(json);
      } catch (e) {
        // If parsing as JSON fails, treat as ID string
        return User(
          id: json,
          fullName: 'Unknown User', // Default name if only ID is provided
          email: '', // Default email
          role: 'user', // Default role
          createdAt: DateTime.now(), // Default date
        );
      }
    } else if (json is Map<String, dynamic>) {
      // If it's a map, convert directly, but handle MongoDB's _id field
      var userMap = Map<String, dynamic>.from(json);
      // Convert MongoDB _id to id for the User model
      if (userMap.containsKey('_id')) {
        userMap['id'] = userMap['_id'].toString(); // Ensure it's a string
        userMap.remove('_id');
      }
      // Handle createdAt conversion if it's a string
      if (userMap.containsKey('createdAt') && userMap['createdAt'] is String) {
        try {
          userMap['createdAt'] = DateTime.parse(userMap['createdAt']);
        } catch (e) {
          userMap['createdAt'] = DateTime.now();
        }
      } else if (userMap.containsKey('createdAt') && userMap['createdAt'] is int) {
        // Handle timestamp (int) format
        try {
          userMap['createdAt'] = DateTime.fromMillisecondsSinceEpoch(userMap['createdAt']);
        } catch (e) {
          userMap['createdAt'] = DateTime.now();
        }
      }
      return User.fromMap(userMap);
    } else if (json is Map) {
      // Handle case where json is a Map with dynamic keys
      Map<String, dynamic> dynamicJson = Map<String, dynamic>.from(json);
      // Convert MongoDB _id to id for the User model
      if (dynamicJson.containsKey('_id')) {
        dynamicJson['id'] = dynamicJson['_id'].toString(); // Ensure it's a string
        dynamicJson.remove('_id');
      }
      // Handle createdAt conversion if it's a string
      if (dynamicJson.containsKey('createdAt') && dynamicJson['createdAt'] is String) {
        try {
          dynamicJson['createdAt'] = DateTime.parse(dynamicJson['createdAt']);
        } catch (e) {
          dynamicJson['createdAt'] = DateTime.now();
        }
      } else if (dynamicJson.containsKey('createdAt') && dynamicJson['createdAt'] is int) {
        // Handle timestamp (int) format
        try {
          dynamicJson['createdAt'] = DateTime.fromMillisecondsSinceEpoch(dynamicJson['createdAt']);
        } catch (e) {
          dynamicJson['createdAt'] = DateTime.now();
        }
      }
      return User.fromMap(dynamicJson);
    } else {
      // Handle case where json might be just an ID string or other format
      // Create a default user with the ID
      return User(
        id: json.toString(),
        fullName: 'Unknown User',
        email: '',
        role: 'user',
        createdAt: DateTime.now(),
      );
    }
  }

  @override
  Object toJson(User user) => user.toMap();
}

@freezed
class Course with _$Course {
  const factory Course({
    required String id,
    required String title,
    required String description,
    required double price,
    required int duration,
    required String level,
    String? thumbnail,
    required bool isPublished,
    @UserConverter() required User createdBy,
    String? categoryId,
    Map<String, dynamic>? category,
    required DateTime createdAt,
  }) = _Course;

  factory Course.fromJson(Map<String, dynamic> json) => _$CourseFromJson(json);
}

@freezed
class CourseListResponse with _$CourseListResponse {
  const factory CourseListResponse({
    required List<Course> courses,
    required int totalPages,
    required int currentPage,
    required int total,
  }) = _CourseListResponse;

  factory CourseListResponse.fromJson(Map<String, dynamic> json) =>
      _$CourseListResponseFromJson(json);
}

@freezed
class Enrollment with _$Enrollment {
  const factory Enrollment({
    required String id,
    required String userId,
    required String courseId,
    required DateTime enrollmentDate,
    required String completionStatus,
    required double progress,
    required List<String> completedLessons,
    required bool certificateEligible,
  }) = _Enrollment;

  factory Enrollment.fromJson(Map<String, dynamic> json) =>
      _$EnrollmentFromJson(json);
}