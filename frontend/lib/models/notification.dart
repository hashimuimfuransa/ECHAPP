class Notification {
  final String id;
  final String title;
  final String message;
  final String type; // 'info', 'success', 'warning', 'error', 'achievement', 'payment', 'course', 'exam'
  final DateTime timestamp;
  final bool isRead;
  final Map<String, dynamic>? data;
  final DateTime? readAt;

  Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.type,
    required this.timestamp,
    this.isRead = false,
    this.data,
    this.readAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      message: json['message'] ?? '',
      type: json['type'] ?? 'info',
      timestamp: json['timestamp'] != null 
          ? DateTime.parse(json['timestamp']) 
          : DateTime.now(),
      isRead: json['isRead'] ?? false,
      data: json['data'] is Map<String, dynamic> ? json['data'] : null,
      readAt: json['readAt'] != null 
          ? DateTime.parse(json['readAt']) 
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'message': message,
      'type': type,
      'timestamp': timestamp.toIso8601String(),
      'isRead': isRead,
      'data': data,
      'readAt': readAt?.toIso8601String(),
    };
  }
  
  Notification copyWith({bool? isRead, DateTime? readAt}) {
    return Notification(
      id: id,
      title: title,
      message: message,
      type: type,
      timestamp: timestamp,
      isRead: isRead ?? this.isRead,
      data: data,
      readAt: readAt ?? this.readAt,
    );
  }
}
