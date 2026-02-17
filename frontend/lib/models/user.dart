
class User {
  final String id;
  final String fullName;
  final String email;
  final String? phone;
  final String role;
  final String? deviceId;
  final DateTime createdAt;

  User({
    required this.id,
    required this.fullName,
    required this.email,
    this.phone,
    required this.role,
    this.deviceId,
    required this.createdAt,
  });

  static String? _getStringValue(dynamic value) {
    if (value == null) return null;
    if (value is String) return value;
    if (value is Map<String, dynamic>) {
      // If it's a Map, try to convert to string representation
      return value.toString();
    }
    // For other types, convert to string
    return value.toString();
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: _getStringValue(json['id']) ?? _getStringValue(json['_id']) ?? '',
      fullName: _getStringValue(json['fullName']) ?? 'Unknown User',
      email: _getStringValue(json['email']) ?? '',
      phone: _getStringValue(json['phone']),
      role: _getStringValue(json['role']) ?? 'user',
      deviceId: _getStringValue(json['deviceId']),
      createdAt: _parseDateTime(json['createdAt']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'fullName': fullName,
      'email': email,
      'phone': phone,
      'role': role,
      'deviceId': deviceId,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  static DateTime _parseDateTime(dynamic dateValue) {
    if (dateValue == null) return DateTime.now();
    
    if (dateValue is String) {
      try {
        return DateTime.parse(dateValue);
      } catch (e) {
        return DateTime.now();
      }
    } else if (dateValue is int) {
      return DateTime.fromMillisecondsSinceEpoch(dateValue);
    } else if (dateValue is DateTime) {
      return dateValue;
    } else if (dateValue is Map<String, dynamic>) {
      // Handle case where date is stored as an object (e.g., Firestore timestamp)
      try {
        // Check if it's a Firestore Timestamp-like object with seconds and nanoseconds
        if (dateValue.containsKey('seconds') && dateValue.containsKey('nanoseconds')) {
          int seconds = dateValue['seconds'] as int? ?? 0;
          int nanoseconds = dateValue['nanoseconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000 + (nanoseconds ~/ 1000000));
        } else if (dateValue.containsKey('_seconds')) {
          // Alternative format with _seconds
          int seconds = dateValue['_seconds'] as int? ?? 0;
          return DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
        }
      } catch (e) {
        // If conversion fails, return current time
        return DateTime.now();
      }
    }
    
    return DateTime.now();
  }

  @override
  String toString() {
    return 'User(id: $id, fullName: $fullName, email: $email, role: $role)';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is User &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// Authentication response model
class AuthResponse {
  final User user;
  final String token;
  final String refreshToken;

  AuthResponse({
    required this.user,
    required this.token,
    required this.refreshToken,
  });

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      user: User.fromJson(json['user'] as Map<String, dynamic>),
      token: json['token'] as String,
      refreshToken: json['refreshToken'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user': user.toJson(),
      'token': token,
      'refreshToken': refreshToken,
    };
  }

  @override
  String toString() {
    return 'AuthResponse(user: $user, token: $token)';
  }
}