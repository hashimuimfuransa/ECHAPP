import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/api_response.dart';
import '../../models/course.dart';

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
      print('ApiClient: Current user email: ${user?.email ?? 'null'}');
      
      if (user != null) {
        print('ApiClient: Attempting to get ID token...');
        // Force refresh to ensure we have a valid token
        final token = await user.getIdToken(true); // Force refresh
        print('ApiClient: Token acquired successfully, length: ${token?.length ?? 0}');
        if (token != null) {
          print('ApiClient: Token preview: ${token.substring(0, token.length > 50 ? 50 : token.length)}...');
          return {
            'Content-Type': 'application/json',
            'Authorization': 'Bearer $token',
          };
        } else {
          print('ApiClient: Token is null despite having user - this should not happen');
          // Fall through to return basic headers
        }
      } else {
        print('ApiClient: No current user found - request will be unauthenticated');
      }
    } catch (e) {
      print('ApiClient: Error getting auth token: $e');
      print('ApiClient: Stack trace: ${e is Error ? e.stackTrace : 'No stack trace'}');
    }
    
    // Return basic headers when no valid token is available
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
    // Convert all query parameters to strings to avoid Uri parsing errors
    final stringQueryParams = queryParams?.map(
      (key, value) => MapEntry(key, value.toString()),
    ) ?? {};
    
    print('ApiClient: Query parameters converted to strings: $stringQueryParams');
    
    final uri = Uri.parse(url).replace(queryParameters: stringQueryParams);
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

  /// Make HTTP POST request for file uploads (multipart form data)
  Future<http.Response> postFile(
    String url, {
    required String filePath,
    required String fieldName,
    Map<String, String>? additionalFields,
    Map<String, String>? headers,
  }) async {
    final authHeaders = await _getAuthHeaders();
    final mergedHeaders = {...authHeaders, ...?headers};

    // Remove Content-Type header as it will be set automatically for multipart
    mergedHeaders.remove('Content-Type');

    var request = http.MultipartRequest('POST', Uri.parse(url));
    
    // Add auth headers
    request.headers.addAll(mergedHeaders);
    
    // Add additional fields if provided
    if (additionalFields != null) {
      request.fields.addAll(additionalFields);
    }
    
    // Add file
    final file = await http.MultipartFile.fromPath(fieldName, filePath);
    request.files.add(file);

    final streamedResponse = await _httpClient.send(request);
    return http.Response.fromStream(streamedResponse);
  }

  /// Execute HTTP request with error handling, timeout, and retry mechanism
  Future<http.Response> _makeRequest(
    Future<http.Response> Function() requestFn,
  ) async {
    int maxRetries = 2;
    int retryCount = 0;
    
    while (true) {
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
        
        // Retry logic for network errors
        if (retryCount < maxRetries) {
          retryCount++;
          print('Retrying request... Attempt $retryCount of $maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // Exponential backoff
          continue;
        }
        
        throw ApiException.network('Network connection failed: $e');
      } on TimeoutException catch (e) {
        print('Request timeout: $e');
        
        // Retry logic for timeouts
        if (retryCount < maxRetries) {
          retryCount++;
          print('Retrying request due to timeout... Attempt $retryCount of $maxRetries');
          await Future.delayed(Duration(milliseconds: 1000 * retryCount)); // Exponential backoff
          continue;
        }
        
        throw ApiException.timeout('Request timed out after $_timeoutSeconds seconds');
      } catch (e) {
        print('Unexpected error: $e');
        throw ApiException.unknown('An unexpected error occurred: $e');
      }
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
      print('API Client: Parsing response body: $body');
      final json = jsonDecode(body) as Map<String, dynamic>;
      print('API Client: JSON parsed, success: ${json['success']}, data type: ${json['data']?.runtimeType}');
      List<T>? dataList;
      
      if (json['data'] != null) {
        if (json['data'] is List) {
          // Direct array response
          print('API Client: Data is direct list, length: ${(json['data'] as List).length}');
          dataList = (json['data'] as List)
              .map((item) => fromJsonT(item as Map<String, dynamic>))
              .toList();
        } else if (json['data'] is Map<String, dynamic>) {
          // Nested object response (like { courses: [...] })
          final dataMap = json['data'] as Map<String, dynamic>;
          print('API Client: Data is map, keys: ${dataMap.keys}');
          // Look for common list properties
          final listData = dataMap['courses'] ?? dataMap['data'] ?? dataMap['items'];
          if (listData != null && listData is List) {
            print('API Client: Found list data in courses/data/items, length: ${listData.length}');
            dataList = listData
                .map((item) => fromJsonT(item as Map<String, dynamic>))
                .toList();
          } else {
            print('API Client: No list data found in expected keys');
          }
        } else if (json['data'] is int || json['data'] is double || json['data'] is num) {
          // If data is a number (like a count), return empty list instead of crashing
          print('API Client: Data is a number (${json['data']}) instead of array, returning empty list');
          dataList = []; // Return empty list instead of crashing
        } else {
          // If data is neither a List nor a Map, it's probably an unexpected type like int
          print('API Client: Unexpected data type: ${json['data'].runtimeType}, value: ${json['data']}');
          dataList = []; // Return empty list instead of crashing
        }
      } else {
        print('API Client: No data found in response');
        dataList = []; // Return empty list if no data
      }
      
      // Additional safety check: if somehow dataList is still null after processing
      if (dataList == null) {
        print('API Client: dataList is null, setting to empty list');
        dataList = [];
      }
      
      print('API Client: Final dataList length: ${dataList.length ?? 0}');
      if (dataList.isNotEmpty) {
        // Print first item's thumbnail if it exists
        if (dataList[0] is Course) {
          final firstCourse = dataList[0] as Course;
          print('API Client: First course thumbnail: ${firstCourse.thumbnail ?? "null"}');
        }
      }
      
      return ApiResponse<List<T>>(
        success: json['success'] as bool? ?? false,
        message: json['message'] as String? ?? '',
        data: dataList,
        error: json['error'] != null 
            ? ApiError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
      );
    } catch (e) {
      print('API Client: Error parsing response: $e');
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