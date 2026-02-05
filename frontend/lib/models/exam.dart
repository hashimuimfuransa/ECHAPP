class Exam {
  final String id;
  final String courseId;
  final String title;
  final String type;
  final int passingScore;
  final int timeLimit;
  final bool isPublished;
  final int questionsCount;
  final int attempts;
  final DateTime createdAt;
  final DateTime updatedAt;

  // Getters for compatibility with existing UI
  int get questions => questionsCount;
  int get duration => timeLimit;

  Exam({
    required this.id,
    required this.courseId,
    required this.title,
    required this.type,
    required this.passingScore,
    required this.timeLimit,
    required this.isPublished,
    required this.questionsCount,
    required this.attempts,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Exam.fromJson(Map<String, dynamic> json) {
    return Exam(
      id: json['_id'] as String,
      courseId: json['courseId'] is String 
          ? json['courseId'] as String
          : (json['courseId'] as Map<String, dynamic>)['_id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      passingScore: json['passingScore'] as int,
      timeLimit: json['timeLimit'] as int,
      isPublished: json['isPublished'] as bool? ?? false,
      questionsCount: json['questionsCount'] as int? ?? 0,
      attempts: json['attempts'] as int? ?? 0,
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'title': title,
      'type': type,
      'passingScore': passingScore,
      'timeLimit': timeLimit,
      'isPublished': isPublished,
      'questionsCount': questionsCount,
      'attempts': attempts,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }
}