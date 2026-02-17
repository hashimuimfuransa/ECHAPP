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
    return Certificate(
      id: json['_id'] ?? json['id'],
      userId: json['userId'],
      courseId: json['courseId'],
      examId: json['examId'],
      score: (json['score'] is int) ? json['score'].toDouble() : json['score'],
      percentage: (json['percentage'] is int) ? json['percentage'].toDouble() : json['percentage'],
      issuedDate: DateTime.parse(json['issuedDate']),
      certificatePdfPath: json['certificatePdfPath'],
      serialNumber: json['serialNumber'],
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