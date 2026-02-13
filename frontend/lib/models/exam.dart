class Exam {
  final String id;
  final String courseId;
  final String sectionId; // Added sectionId field
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
    required this.sectionId,
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
    // Handle courseId - can be String, Map, or null
    String courseId = '';
    if (json['courseId'] != null) {
      if (json['courseId'] is String) {
        courseId = json['courseId'] as String;
      } else if (json['courseId'] is Map<String, dynamic>) {
        courseId = (json['courseId'] as Map<String, dynamic>)['_id'] as String? ?? '';
      }
    }
    
    // Handle sectionId - can be String, Map, or null
    String sectionId = '';
    if (json['sectionId'] != null) {
      if (json['sectionId'] is String) {
        sectionId = json['sectionId'] as String;
      } else if (json['sectionId'] is Map<String, dynamic>) {
        sectionId = (json['sectionId'] as Map<String, dynamic>)['_id'] as String? ?? '';
      }
    }
    
    // Handle title - can be in nested courseId object
    String title = '';
    if (json['title'] != null) {
      title = json['title'] as String;
    } else if (json['courseId'] is Map<String, dynamic> && json['courseId']['title'] != null) {
      title = json['courseId']['title'] as String;
    }
    
    // Handle type - can be in nested examId object
    String type = 'quiz';
    if (json['type'] != null) {
      type = json['type'] as String;
    } else if (json['examId'] is Map<String, dynamic> && json['examId']['type'] != null) {
      type = json['examId']['type'] as String;
    }
    
    return Exam(
      id: json['_id'] as String? ?? '',
      courseId: courseId,
      sectionId: sectionId,
      title: title,
      type: type,
      passingScore: (json['passingScore'] is num) ? json['passingScore'].toInt() : json['passingScore'] as int? ?? 0,
      timeLimit: (json['timeLimit'] is num) ? json['timeLimit'].toInt() : json['timeLimit'] as int? ?? 0,
      isPublished: json['isPublished'] as bool? ?? false,
      questionsCount: (json['questionsCount'] is num) ? json['questionsCount'].toInt() : json['questionsCount'] as int? ?? 0,
      attempts: (json['attempts'] is num) ? json['attempts'].toInt() : json['attempts'] as int? ?? 0,
      createdAt: json['createdAt'] != null 
          ? DateTime.parse(json['createdAt'] as String) 
          : (json['submittedAt'] != null 
              ? DateTime.parse(json['submittedAt'] as String) 
              : DateTime.now()),
      updatedAt: json['updatedAt'] != null 
          ? DateTime.parse(json['updatedAt'] as String) 
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'courseId': courseId,
      'sectionId': sectionId, // Added sectionId to JSON
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