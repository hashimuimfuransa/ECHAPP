/// Teacher Assignment Model
/// Represents the assignment of a teacher to a course
class TeacherAssignment {
  final String id;
  final String teacherId;
  final String courseId;
  final String assignedBy;
  final DateTime assignedAt;
  final bool isActive;
  final String? notes;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  TeacherAssignment({
    required this.id,
    required this.teacherId,
    required this.courseId,
    required this.assignedBy,
    required this.assignedAt,
    this.isActive = true,
    this.notes,
    this.createdAt,
    this.updatedAt,
  });

  factory TeacherAssignment.fromJson(Map<String, dynamic> json) {
    return TeacherAssignment(
      id: json['_id'] ?? json['id'] ?? '',
      teacherId: json['teacherId'] ?? '',
      courseId: json['courseId'] ?? '',
      assignedBy: json['assignedBy'] ?? '',
      assignedAt: json['assignedAt'] != null
          ? DateTime.parse(json['assignedAt'])
          : DateTime.now(),
      isActive: json['isActive'] ?? true,
      notes: json['notes'],
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'])
          : null,
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'teacherId': teacherId,
      'courseId': courseId,
      'assignedBy': assignedBy,
      'assignedAt': assignedAt.toIso8601String(),
      'isActive': isActive,
      'notes': notes,
      'createdAt': createdAt?.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }
}
