class Certificate {
  final String id;
  final String userId;
  final String courseId;
  final String examId;
  final double score;
  final double percentage;
  final DateTime issuedDate;
  final String certificatePdfPath;
  final String serialNumber;
  final bool isValid;

  Certificate({
    required this.id,
    required this.userId,
    required this.courseId,
    required this.examId,
    required this.score,
    required this.percentage,
    required this.issuedDate,
    required this.certificatePdfPath,
    required this.serialNumber,
    required this.isValid,
  });

  factory Certificate.fromJson(Map<String, dynamic> json) {
    // Handle potentially populated fields
    String parseId(dynamic value) {
      if (value is String) {
        return value;
      } else if (value is Map<String, dynamic>) {
        return (value['_id'] ?? value['id'] ?? '').toString();
      }
      return value?.toString() ?? '';
    }

    return Certificate(
      id: parseId(json['_id'] ?? json['id']),
      userId: parseId(json['userId']),
      courseId: parseId(json['courseId']),
      examId: parseId(json['examId']),
      score: (json['score'] is num) ? json['score'].toDouble() : 0.0,
      percentage: (json['percentage'] is num) ? json['percentage'].toDouble() : 0.0,
      issuedDate: DateTime.parse(json['issuedDate'] ?? json['createdAt'] ?? DateTime.now().toIso8601String()),
      certificatePdfPath: json['certificatePdfPath'] ?? '',
      serialNumber: json['serialNumber'] ?? '',
      isValid: json['isValid'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'courseId': courseId,
      'examId': examId,
      'score': score,
      'percentage': percentage,
      'issuedDate': issuedDate.toIso8601String(),
      'certificatePdfPath': certificatePdfPath,
      'serialNumber': serialNumber,
      'isValid': isValid,
    };
  }
}