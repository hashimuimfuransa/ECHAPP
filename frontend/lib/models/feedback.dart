import 'user.dart';

class FeedbackModel {
  final String id;
  final String userId;
  final User? user;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  FeedbackModel({
    required this.id,
    required this.userId,
    this.user,
    required this.content,
    this.isRead = false,
    required this.createdAt,
  });

  factory FeedbackModel.fromJson(Map<String, dynamic> json) {
    return FeedbackModel(
      id: json['id'] ?? json['_id'] ?? '',
      userId: json['userId'] is String ? json['userId'] : (json['userId']?['id'] ?? json['userId']?['_id'] ?? ''),
      user: json['userId'] is Map<String, dynamic> ? User.fromJson(json['userId']) : null,
      content: json['content'] ?? '',
      isRead: json['isRead'] ?? false,
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'content': content,
      'isRead': isRead,
      'createdAt': createdAt.toIso8601String(),
    };
  }
}
