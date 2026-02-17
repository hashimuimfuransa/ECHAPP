import 'user.dart';
import 'course.dart';

class Enrollment {
  final String id;
  final String userId;
  final String courseId;
  final DateTime enrollmentDate;
  final String completionStatus;
  final double progress;
  final List<String> completedLessons;
  final bool certificateEligible;
  final String? paymentId;
  final DateTime createdAt;
  final DateTime updatedAt;
  
  // Populated fields (from backend populate)
  final User? user;
  final Course? course;

  Enrollment({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.enrollmentDate,
    required this.completionStatus,
    required this.progress,
    required this.completedLessons,
    required this.certificateEligible,
    this.paymentId,
    required this.createdAt,
    required this.updatedAt,
    this.user,
    this.course,
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

  static Course? _parseCourseData(dynamic courseData) {
    if (courseData == null) return null;
    
    try {
      if (courseData is Map<String, dynamic>) {
        return Course.fromJson(courseData);
      } else {
        // If courseData is not a Map, create a minimal Course object with the available data
        return Course(
          id: '',
          title: _getStringValue(courseData) ?? 'Unknown Course',
          description: '',
          price: 0.0,
          duration: 0,
          level: 'Beginner',
          isPublished: false,
          createdBy: User(id: '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      // If parsing fails, return a default course
      return Course(
        id: '',
        title: 'Unknown Course',
        description: '',
        price: 0.0,
        duration: 0,
        level: 'Beginner',
        isPublished: false,
        createdBy: User(id: '', fullName: 'Unknown', email: '', role: 'user', createdAt: DateTime.now()),
        createdAt: DateTime.now(),
      );
    }
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

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: _getStringValue(json['_id']) ?? _getStringValue(json['id']) ?? '',
      userId: _getStringValue(json['userId']) ?? '',
      courseId: _getStringValue(json['courseId']) ?? '',
      enrollmentDate: _parseDateTime(json['enrollmentDate']),
      completionStatus: _getStringValue(json['completionStatus']) ?? 'enrolled',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: json['completedLessons'] is List
          ? (json['completedLessons'] as List).map((e) => _getStringValue(e)?.toString() ?? '').toList()
          : [],
      certificateEligible: json['certificateEligible'] as bool? ?? false,
      paymentId: _getStringValue(json['paymentId']),
      createdAt: _parseDateTime(json['createdAt']),
      updatedAt: _parseDateTime(json['updatedAt']),
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      course: _parseCourseData(json['course']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'userId': userId,
      'courseId': courseId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'completionStatus': completionStatus,
      'progress': progress,
      'completedLessons': completedLessons,
      'certificateEligible': certificateEligible,
      'paymentId': paymentId,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (user != null) 'user': user!.toJson(),
      if (course != null) 'course': course!.toJson(),
    };
  }

  // Helper getters
  bool get isCompleted => completionStatus == 'completed';
  bool get isInProgress => completionStatus == 'in-progress';
  bool get isEnrolled => completionStatus == 'enrolled';
  
  String get statusDisplay {
    switch (completionStatus) {
      case 'completed':
        return 'Completed';
      case 'in-progress':
        return 'In Progress';
      case 'enrolled':
        return 'Enrolled';
      default:
        return completionStatus;
    }
  }

  String get progressDisplay => '${progress.toStringAsFixed(1)}%';
}
