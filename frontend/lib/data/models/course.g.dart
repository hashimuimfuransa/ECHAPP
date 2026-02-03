// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'course.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$CourseImpl _$$CourseImplFromJson(Map<String, dynamic> json) => _$CourseImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      duration: (json['duration'] as num).toInt(),
      level: json['level'] as String,
      thumbnail: json['thumbnail'] as String?,
      isPublished: json['isPublished'] as bool,
      createdBy: const UserConverter().fromJson(json['createdBy'] as Object),
      categoryId: json['categoryId'] as String?,
      category: json['category'] as Map<String, dynamic>?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$$CourseImplToJson(_$CourseImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'description': instance.description,
      'price': instance.price,
      'duration': instance.duration,
      'level': instance.level,
      'thumbnail': instance.thumbnail,
      'isPublished': instance.isPublished,
      'createdBy': const UserConverter().toJson(instance.createdBy),
      'categoryId': instance.categoryId,
      'category': instance.category,
      'createdAt': instance.createdAt.toIso8601String(),
    };

_$CourseListResponseImpl _$$CourseListResponseImplFromJson(
        Map<String, dynamic> json) =>
    _$CourseListResponseImpl(
      courses: (json['courses'] as List<dynamic>)
          .map((e) => Course.fromJson(e as Map<String, dynamic>))
          .toList(),
      totalPages: (json['totalPages'] as num).toInt(),
      currentPage: (json['currentPage'] as num).toInt(),
      total: (json['total'] as num).toInt(),
    );

Map<String, dynamic> _$$CourseListResponseImplToJson(
        _$CourseListResponseImpl instance) =>
    <String, dynamic>{
      'courses': instance.courses,
      'totalPages': instance.totalPages,
      'currentPage': instance.currentPage,
      'total': instance.total,
    };

_$EnrollmentImpl _$$EnrollmentImplFromJson(Map<String, dynamic> json) =>
    _$EnrollmentImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      courseId: json['courseId'] as String,
      enrollmentDate: DateTime.parse(json['enrollmentDate'] as String),
      completionStatus: json['completionStatus'] as String,
      progress: (json['progress'] as num).toDouble(),
      completedLessons: (json['completedLessons'] as List<dynamic>)
          .map((e) => e as String)
          .toList(),
      certificateEligible: json['certificateEligible'] as bool,
    );

Map<String, dynamic> _$$EnrollmentImplToJson(_$EnrollmentImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'courseId': instance.courseId,
      'enrollmentDate': instance.enrollmentDate.toIso8601String(),
      'completionStatus': instance.completionStatus,
      'progress': instance.progress,
      'completedLessons': instance.completedLessons,
      'certificateEligible': instance.certificateEligible,
    };
