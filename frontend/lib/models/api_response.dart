/// Standard API response wrapper that matches backend contract
class ApiResponse<T> {
  final bool success;
  final String message;
  final T? data;
  final ApiError? error;

  ApiResponse({
    required this.success,
    required this.message,
    this.data,
    this.error,
  });

  factory ApiResponse.fromJson(
    Map<String, dynamic> json,
    T Function(Map<String, dynamic>) fromJsonT,
  ) {
    return ApiResponse<T>(
      success: json['success'] as bool? ?? false,
      message: json['message'] as String? ?? '',
      data: json['data'] != null 
          ? (json['data'] is Map<String, dynamic> 
              ? fromJsonT(json['data'] as Map<String, dynamic>)
              : json['data'] is List
                  ? json['data'] as T
                  : null)
          : null,
      error: json['error'] != null 
          ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'success': success,
      'message': message,
      'data': data,
      'error': error?.toJson(),
    };
  }
}

/// Standard API error model
class ApiError {
  final String? code;
  final String? message;
  final dynamic details;

  ApiError({
    this.code,
    this.message,
    this.details,
  });

  factory ApiError.fromJson(Map<String, dynamic> json) {
    return ApiError(
      code: json['code'] as String?,
      message: json['message'] as String? ?? 'Unknown error',
      details: json['details'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'code': code,
      'message': message,
      'details': details,
    };
  }

  @override
  String toString() => 'ApiError(code: $code, message: $message)';
}