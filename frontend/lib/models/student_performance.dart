import 'user.dart';

/// Student Performance Model
/// Represents a student's enrollment with performance metrics
class StudentPerformance {
  final String enrollmentId;
  final DateTime enrollmentDate;
  final String completionStatus;
  final int progress;
  final bool certificateEligible;
  final int completedLessonsCount;
  final int totalLessons;
  final int quizAttempts;
  final double averageQuizScore;
  final DateTime? lastActivity;
  final User student;

  StudentPerformance({
    required this.enrollmentId,
    required this.enrollmentDate,
    required this.completionStatus,
    required this.progress,
    this.certificateEligible = false,
    this.completedLessonsCount = 0,
    this.totalLessons = 0,
    this.quizAttempts = 0,
    this.averageQuizScore = 0.0,
    this.lastActivity,
    required this.student,
  });

  factory StudentPerformance.fromJson(Map<String, dynamic> json) {
    return StudentPerformance(
      enrollmentId: json['enrollmentId'] ?? '',
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'])
          : DateTime.now(),
      completionStatus: json['completionStatus'] ?? 'enrolled',
      progress: json['progress'] ?? 0,
      certificateEligible: json['certificateEligible'] ?? false,
      completedLessonsCount: json['completedLessonsCount'] ?? 0,
      totalLessons: json['totalLessons'] ?? 0,
      quizAttempts: json['quizAttempts'] ?? 0,
      averageQuizScore: (json['averageQuizScore'] ?? 0.0).toDouble(),
      lastActivity: json['lastActivity'] != null
          ? DateTime.parse(json['lastActivity'])
          : null,
      student: json['student'] != null
          ? User.fromJson(json['student'])
          : User.empty(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'enrollmentId': enrollmentId,
      'enrollmentDate': enrollmentDate.toIso8601String(),
      'completionStatus': completionStatus,
      'progress': progress,
      'certificateEligible': certificateEligible,
      'completedLessonsCount': completedLessonsCount,
      'totalLessons': totalLessons,
      'quizAttempts': quizAttempts,
      'averageQuizScore': averageQuizScore,
      'lastActivity': lastActivity?.toIso8601String(),
      'student': student.toJson(),
    };
  }

  double get completionPercentage {
    if (totalLessons == 0) return 0;
    return (completedLessonsCount / totalLessons) * 100;
  }

  String get progressStatus {
    switch (completionStatus) {
      case 'completed':
        return 'Completed';
      case 'in-progress':
        return 'In Progress';
      default:
        return 'Enrolled';
    }
  }
}

/// Detailed Student Performance Model
class DetailedStudentPerformance {
  final User student;
  final EnrollmentInfo enrollment;
  final OverallStats overallStats;
  final List<SectionProgress> sectionProgress;
  final List<QuizHistory> quizHistory;
  final List<CompletedLesson> completedLessons;
  final List<AvailableSession> availableSessions;

  DetailedStudentPerformance({
    required this.student,
    required this.enrollment,
    required this.overallStats,
    required this.sectionProgress,
    required this.quizHistory,
    required this.completedLessons,
    required this.availableSessions,
  });

  factory DetailedStudentPerformance.fromJson(Map<String, dynamic> json) {
    return DetailedStudentPerformance(
      student: json['student'] != null
          ? User.fromJson(json['student'])
          : User.empty(),
      enrollment: json['enrollment'] != null
          ? EnrollmentInfo.fromJson(json['enrollment'])
          : EnrollmentInfo.empty(),
      overallStats: json['overallStats'] != null
          ? OverallStats.fromJson(json['overallStats'])
          : OverallStats.empty(),
      sectionProgress: json['sectionProgress'] != null
          ? (json['sectionProgress'] as List)
              .map((s) => SectionProgress.fromJson(s))
              .toList()
          : [],
      quizHistory: json['quizHistory'] != null
          ? (json['quizHistory'] as List)
              .map((q) => QuizHistory.fromJson(q))
              .toList()
          : [],
      completedLessons: json['completedLessons'] != null
          ? (json['completedLessons'] as List)
              .map((l) => CompletedLesson.fromJson(l))
              .toList()
          : [],
      availableSessions: json['availableSessions'] != null
          ? (json['availableSessions'] as List)
              .map((s) => AvailableSession.fromJson(s))
              .toList()
          : [],
    );
  }
}

/// Enrollment Info Model
class EnrollmentInfo {
  final DateTime enrollmentDate;
  final String completionStatus;
  final int progress;
  final bool certificateEligible;

  EnrollmentInfo({
    required this.enrollmentDate,
    required this.completionStatus,
    required this.progress,
    required this.certificateEligible,
  });

  factory EnrollmentInfo.fromJson(Map<String, dynamic> json) {
    return EnrollmentInfo(
      enrollmentDate: json['enrollmentDate'] != null
          ? DateTime.parse(json['enrollmentDate'])
          : DateTime.now(),
      completionStatus: json['completionStatus'] ?? 'enrolled',
      progress: json['progress'] ?? 0,
      certificateEligible: json['certificateEligible'] ?? false,
    );
  }

  factory EnrollmentInfo.empty() {
    return EnrollmentInfo(
      enrollmentDate: DateTime.now(),
      completionStatus: 'enrolled',
      progress: 0,
      certificateEligible: false,
    );
  }
}

/// Overall Stats Model
class OverallStats {
  final int totalLessons;
  final int completedLessons;
  final int overallProgress;
  final int quizAttempts;
  final double averageQuizScore;
  final int passedQuizzes;

  OverallStats({
    required this.totalLessons,
    required this.completedLessons,
    required this.overallProgress,
    required this.quizAttempts,
    required this.averageQuizScore,
    required this.passedQuizzes,
  });

  factory OverallStats.fromJson(Map<String, dynamic> json) {
    return OverallStats(
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      overallProgress: json['overallProgress'] ?? 0,
      quizAttempts: json['quizAttempts'] ?? 0,
      averageQuizScore: (json['averageQuizScore'] ?? 0.0).toDouble(),
      passedQuizzes: json['passedQuizzes'] ?? 0,
    );
  }

  factory OverallStats.empty() {
    return OverallStats(
      totalLessons: 0,
      completedLessons: 0,
      overallProgress: 0,
      quizAttempts: 0,
      averageQuizScore: 0.0,
      passedQuizzes: 0,
    );
  }
}

/// Section Progress Model
class SectionProgress {
  final String sectionId;
  final String sectionTitle;
  final int totalLessons;
  final int completedLessons;
  final int progress;

  SectionProgress({
    required this.sectionId,
    required this.sectionTitle,
    required this.totalLessons,
    required this.completedLessons,
    required this.progress,
  });

  factory SectionProgress.fromJson(Map<String, dynamic> json) {
    return SectionProgress(
      sectionId: json['sectionId'] ?? '',
      sectionTitle: json['sectionTitle'] ?? '',
      totalLessons: json['totalLessons'] ?? 0,
      completedLessons: json['completedLessons'] ?? 0,
      progress: json['progress'] ?? 0,
    );
  }
}

/// Quiz History Model
class QuizHistory {
  final String? quizId;
  final String? quizTitle;
  final double score;
  final bool passed;
  final DateTime submittedAt;
  final int? timeSpent;

  QuizHistory({
    this.quizId,
    this.quizTitle,
    required this.score,
    required this.passed,
    required this.submittedAt,
    this.timeSpent,
  });

  factory QuizHistory.fromJson(Map<String, dynamic> json) {
    return QuizHistory(
      quizId: json['quizId'],
      quizTitle: json['quizTitle'],
      score: (json['score'] ?? 0.0).toDouble(),
      passed: json['passed'] ?? false,
      submittedAt: json['submittedAt'] != null
          ? DateTime.parse(json['submittedAt'])
          : DateTime.now(),
      timeSpent: json['timeSpent'],
    );
  }
}

/// Completed Lesson Model
class CompletedLesson {
  final String lessonId;
  final String title;
  final String sectionId;

  CompletedLesson({
    required this.lessonId,
    required this.title,
    required this.sectionId,
  });

  factory CompletedLesson.fromJson(Map<String, dynamic> json) {
    return CompletedLesson(
      lessonId: json['lessonId'] ?? '',
      title: json['title'] ?? '',
      sectionId: json['sectionId'] ?? '',
    );
  }
}

/// Available Session Model
class AvailableSession {
  final String id;
  final String title;
  final DateTime scheduledAt;

  AvailableSession({
    required this.id,
    required this.title,
    required this.scheduledAt,
  });

  factory AvailableSession.fromJson(Map<String, dynamic> json) {
    return AvailableSession(
      id: json['_id'] ?? json['id'] ?? '',
      title: json['title'] ?? '',
      scheduledAt: json['scheduledAt'] != null
          ? DateTime.parse(json['scheduledAt'])
          : DateTime.now(),
    );
  }
}
