class QuizSubmission {
  final String id;
  final String examId;
  final String userId;
  final int totalScore;
  final int maxScore;
  final int percentage;
  final bool passed;
  final bool needsManualGrading;
  final List<Map<String, dynamic>> results;
  final DateTime submittedAt;
  final String? examTitle;

  QuizSubmission({
    required this.id,
    required this.examId,
    required this.userId,
    required this.totalScore,
    required this.maxScore,
    required this.percentage,
    required this.passed,
    required this.needsManualGrading,
    required this.results,
    required this.submittedAt,
    this.examTitle,
  });

  factory QuizSubmission.fromJson(Map<String, dynamic> json) {
    return QuizSubmission(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? '',
      examId: json['examId']?.toString() ?? '',
      userId: json['userId']?.toString() ?? '',
      totalScore: json['totalScore'] ?? 0,
      maxScore: json['maxScore'] ?? 0,
      percentage: json['percentage'] ?? 0,
      passed: json['passed'] ?? false,
      needsManualGrading: json['needsManualGrading'] ?? false,
      results: List<Map<String, dynamic>>.from(json['results'] ?? []),
      submittedAt: DateTime.parse(json['submittedAt'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      examTitle: json['examId']?['title'] ?? json['examTitle'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'examId': examId,
      'userId': userId,
      'totalScore': totalScore,
      'maxScore': maxScore,
      'percentage': percentage,
      'passed': passed,
      'needsManualGrading': needsManualGrading,
      'results': results,
      'submittedAt': submittedAt.toIso8601String(),
      'examTitle': examTitle,
    };
  }
}
