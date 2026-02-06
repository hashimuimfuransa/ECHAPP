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

  factory Enrollment.fromJson(Map<String, dynamic> json) {
    return Enrollment(
      id: json['_id'] as String? ?? json['id'] as String? ?? '',
      userId: json['userId'] as String? ?? '',
      courseId: json['courseId'] as String? ?? '',
      enrollmentDate: json['enrollmentDate'] != null 
          ? DateTime.parse(json['enrollmentDate'].toString())
          : DateTime.now(),
      completionStatus: json['completionStatus'] as String? ?? 'enrolled',
      progress: (json['progress'] as num?)?.toDouble() ?? 0.0,
      completedLessons: json['completedLessons'] is List
          ? (json['completedLessons'] as List).map((e) => e.toString()).toList()
          : [],
      certificateEligible: json['certificateEligible'] as bool? ?? false,
      paymentId: json['paymentId'] as String?,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'].toString())
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'].toString())
          : DateTime.now(),
      user: json['user'] != null 
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
      course: json['course'] != null 
          ? Course.fromJson(json['course'] as Map<String, dynamic>)
          : null,
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