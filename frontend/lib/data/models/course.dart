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
      return User.fromJson(json);
    } else if (json is Map<String, dynamic>) {
      // If it's a map, convert directly
      return User.fromMap(json);
    } else {
      throw Exception('Invalid type for User conversion: ${json.runtimeType}');
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