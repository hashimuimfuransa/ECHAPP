import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/api_response.dart';

/// Centralized HTTP client with interceptors and error handling
class ApiClient {
  static const int _timeoutSeconds = 30;
  final http.Client _httpClient;
  
  ApiClient({http.Client? httpClient}) 
      : _httpClient = httpClient ?? http.Client();

  /// Get authorization header with Firebase ID token
  Future<Map<String, String>> _getAuthHeaders() async {
    try {
      final user = firebase_auth.FirebaseAuth.instance.currentUser;
      print('ApiClient: Current user: ${user?.uid ?? 'null'}');
      if (user != null) {
        // Only force refresh if we haven't recently refreshed
        final token = await user.getIdToken(false); // Don't force refresh every time
        print('ApiClient: Token acquired successfully');
        return {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        };
      } else {
        print('ApiClient: No current user found');
      }
    } catch (e) {
      print('Error getting auth token: $e');
    }
    
    return {
      'Content-Type': 'application/json',
    };
  }

  /// Make HTTP GET request
  Future<http.Response> get(
    String url, {
    Map<String, String>? headers,
    Map<String, dynamic>? queryParams,
  }) async {
    final uri = Uri.parse(url).replace(queryParameters: queryParams);
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};
    
    return _makeRequest(() => _httpClient.get(uri, headers: mergedHeaders));
  }

  /// Make HTTP POST request
  Future<http.Response> post(
    String url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};
    final encodedBody = body is Map ? jsonEncode(body) : body?.toString();
    
    return _makeRequest(() => _httpClient.post(
      Uri.parse(url),
      headers: mergedHeaders,
      body: encodedBody,
    ));
  }

  /// Make HTTP PUT request
  Future<http.Response> put(
    String url, {
    Object? body,
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};
    final encodedBody = body is Map ? jsonEncode(body) : body?.toString();
    
    return _makeRequest(() => _httpClient.put(
      Uri.parse(url),
      headers: mergedHeaders,
      body: encodedBody,
    ));
  }

  /// Make HTTP DELETE request
  Future<http.Response> delete(
    String url, {
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};
    
    return _makeRequest(() => _httpClient.delete(
      Uri.parse(url),
      headers: mergedHeaders,
    ));
  }

  /// Execute HTTP request with error handling and timeout
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    try {
      final response = await requestFn().timeout(
        Duration(seconds: _timeoutSeconds),
      );
      
      // Log request for debugging
      print('API Request: ${response.request?.method} ${response.request?.url}');
      print('Response Status: ${response.statusCode}');
      
      return response;
    } on http.ClientException catch (e) {
      print('Network error: $e');
      throw ApiException.network('Network connection failed: $e');
    } on TimeoutException catch (e) {
      print('Request timeout: $e');
      throw ApiException.timeout('Request timed out after $_timeoutSeconds seconds');
    } catch (e) {
      print('Unexpected error: $e');
      throw ApiException.unknown('An unexpected error occurred: $e');
    }
  }

  /// Dispose of the HTTP client
  void dispose() {
    _httpClient.close();
  }
}

/// Custom exceptions for API errors
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  
  ApiException(this.message, [this.statusCode]);

  factory ApiException.network(String message) => ApiException(message, -1);
  factory ApiException.timeout(String message) => ApiException(message, -2);
  factory ApiException.unauthorized(String message) => ApiException(message, 401);
  factory ApiException.forbidden(String message) => ApiException(message, 403);
  factory ApiException.notFound(String message) => ApiException(message, 404);
  factory ApiException.serverError(String message) => ApiException(message, 500);
  factory ApiException.unknown(String message) => ApiException(message, 0);

  @override
  String toString() => 'ApiException: $message (Status: $statusCode)';
}

/// Extension to handle API response parsing
extension ApiResponseExtension on http.Response {
  /// Parse successful response into ApiResponse<T>
  ApiResponse<T> toApiResponse<T>(T Function(Map<String, dynamic>) fromJsonT) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return ApiResponse.fromJson(json, fromJsonT);
    } catch (e) {
      throw ApiException('Failed to parse response: $e', statusCode);
    }
  }

  /// Parse successful response into ApiResponse<List<T>>
  ApiResponse<List<T>> toApiResponseList<T>(T Function(Map<String, dynamic>) fromJsonT) {
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      return ApiResponse<List<T>>(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        data: json['data'] != null && json['data'] is List
            ? (json['data'] as List)
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList()
            : null,
        error: json['error'] != null 
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      throw ApiException('Failed to parse response: $e', statusCode);
    }
  }

  /// Check if response indicates success
  bool get isSuccess => statusCode >= 200 && statusCode < 300;

  /// Throw appropriate exception based on status code
  void validateStatus() {
    if (isSuccess) return;
    
    String message;
    try {
      final json = jsonDecode(body) as Map<String, dynamic>;
      message = json['message'] as String? ?? 'Request failed';
    } catch (e) {
      message = body.isEmpty ? 'Empty response' : 'Invalid response format';
    }

    switch (statusCode) {
      case 400:
        throw ApiException(message, statusCode);
      case 401:
        throw ApiException.unauthorized(message);
      case 403:
        throw ApiException.forbidden(message);
      case 404:
        throw ApiException.notFound(message);
      case 500:
        throw ApiException.serverError(message);
      default:
        throw ApiException(message, statusCode);
    }
  }
}