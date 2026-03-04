import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:http_parser/http_parser.dart';
import 'package:path/path.dart' as path;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/api_config.dart';
import 'package:excellencecoachinghub/models/user.dart';

class PasswordResetResponse {
  final bool success;
  final String? message;

  PasswordResetResponse({
    required this.success,
    this.message,
  });

  factory PasswordResetResponse.fromJson(Map<String, dynamic> json) {
    return PasswordResetResponse(
      success: json['success'] ?? false,
      message: json['message'],
    );
  }
}

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();
  
  void _handleError(dynamic e, String defaultMessage) {
    if (e is SocketException) {
      throw Exception('Connection failed. Please check your internet connection and try again.');
    } else if (e is http.ClientException) {
      throw Exception('Network error occurred. Please check your network connection.');
    } else if (e is TimeoutException) {
      throw Exception('The request timed out. Please check your connection or try again later.');
    } else {
      throw Exception('$defaultMessage: ${e.toString()}');
    }
  }

  Future<AuthResponse> login(String email, String password, {String? deviceId}) async {
    try {
      final body = {
        'email': email,
        'password': password,
      };
      
      if (deviceId != null) {
        body['deviceId'] = deviceId;
      }
      
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Ensure data['data'] is properly formatted for fromJson
        if (data['data'] is Map<String, dynamic>) {
          return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // If it's already a string, parse it again
          final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
          return AuthResponse.fromJson(mapData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Login failed');
      }
    } catch (e) {
      _handleError(e, 'Login error');
      rethrow; // For static analysis, though _handleError always throws
    }
  }

  Future<AuthResponse> register(String fullName, String email, String password, String? phone) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'fullName': fullName,
          'email': email,
          'password': password,
          'phone': phone,
        }),
      ).timeout(const Duration(seconds: 30));

      if (response.statusCode == 201) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Ensure data['data'] is properly formatted for fromJson
        if (data['data'] is Map<String, dynamic>) {
          return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
        } else {
          // If it's already a string, parse it again
          final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
          return AuthResponse.fromJson(mapData);
        }
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Registration failed');
      }
    } catch (e) {
      _handleError(e, 'Registration error');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      // In a real implementation, you would call the logout endpoint
      // and invalidate the token on the server side
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
    } catch (e) {
      _handleError(e, 'Logout failed');
    }
  }

  Future<AuthResponse> firebaseLogin(String idToken, {String? fullName, String? deviceId}) async {
    print('AuthRepository.firebaseLogin called with idToken type: ${idToken.runtimeType}');
    print('AuthRepository.firebaseLogin idToken value: ${idToken.toString().length > 100 ? '${idToken.toString().substring(0, 100)}...' : idToken}');
    print('AuthRepository.firebaseLogin fullName parameter: ${fullName ?? 'null'}');
    print('AuthRepository.firebaseLogin deviceId parameter: ${deviceId ?? 'null'}');
    
    try {
      print('Attempting to encode JSON body');
      String encodedBody;
      try {
        final body = {
          'idToken': idToken,
        };
        if (fullName != null) {
          body['fullName'] = fullName;
          print('Adding fullName to request body: $fullName');
        }
        if (deviceId != null) {
          body['deviceId'] = deviceId;
          print('Adding deviceId to request body: $deviceId');
        }
        encodedBody = jsonEncode(body);
        print('Final request body: $encodedBody');
        print('JSON encoding successful');
      } catch (encodeError) {
        print('JSON encoding error: $encodeError');
        print('idToken value that caused error: $idToken');
        rethrow;
      }
      
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/firebase-login'),
        headers: {'Content-Type': 'application/json'},
        body: encodedBody,
      ).timeout(const Duration(seconds: 60));

      print('Firebase login response status: ${response.statusCode}');
      print('Firebase login response body: ${response.body}');
      
      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        print('Parsed response data: $data');
        print('Data type: ${data.runtimeType}');
        
        // Check if data is Map and has 'data' key
        if (data is Map<String, dynamic> && data.containsKey('data')) {
          print('Processing data[data]: ${data['data']}');
          print('Data[data] type: ${data['data'].runtimeType}');
          
          if (data['data'] is Map<String, dynamic>) {
            print('Processing as Map: ${data['data']}');
            return AuthResponse.fromJson(data['data'] as Map<String, dynamic>);
          } else {
            // If it's already a string, parse it again
            print('Processing as String: ${data['data']}');
            final mapData = jsonDecode(data['data'].toString()) as Map<String, dynamic>;
            return AuthResponse.fromJson(mapData);
          }
        } else {
          // Direct response without wrapper - fallback
          print('Direct response without wrapper');
          return AuthResponse.fromJson(data as Map<String, dynamic>);
        }
      } else {
        final errorData = jsonDecode(response.body);
        print('Error response: $errorData');
        throw Exception(errorData['message'] ?? 'Firebase authentication failed');
      }
    } catch (e) {
      print('Firebase login error: $e');
      print('Error type: ${e.runtimeType}');
      print('Error stack: ${e.toString().substring(0, e.toString().length < 500 ? e.toString().length : 500)}');
      
      _handleError(e, 'Firebase login error');
      rethrow;
    }
  }

  // Deprecated method - kept for backward compatibility
  @deprecated
  AuthResponse createFirebaseOnlyAuthResponse(User user) {
    return AuthResponse(
      user: user,
      token: 'firebase_only_token_${user.id}',
      refreshToken: 'firebase_refresh_token_${user.id}',
    );
  }

  Future<PasswordResetResponse> sendPasswordResetEmail(String email) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
        }),
      );

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Return a success response
        return PasswordResetResponse(
          success: true,
          message: data['message'] ?? 'Password reset email sent successfully!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to send password reset email');
      }
    } catch (e) {
      _handleError(e, 'Send password reset email error');
      rethrow;
    }
  }

  Future<PasswordResetResponse> resetPassword(String token, String newPassword) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode == 200) {
        if (!response.body.trim().startsWith('{') && !response.body.trim().startsWith('[')) {
          throw Exception('Server returned HTML instead of JSON. The backend might be waking up or misconfigured.');
        }
        final data = jsonDecode(response.body);
        // Return a success response
        return PasswordResetResponse(
          success: true,
          message: data['message'] ?? 'Password reset successfully!',
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to reset password');
      }
    } catch (e) {
      _handleError(e, 'Reset password error');
      rethrow;
    }
  }

  Future<bool> verifyResetToken(String token) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/verify-reset-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'token': token}),
      );

      if (response.statusCode == 200) {
        return true;
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Invalid or expired reset token');
      }
    } catch (e) {
      _handleError(e, 'Verify reset token error');
      rethrow;
    }
  }

  Future<User> getProfile() async {
    try {
      // This would typically use a stored token to fetch user profile
      // For Firebase-only auth, we could return a placeholder or throw an exception
      // since we're handling this differently in the auth provider
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
      throw Exception('Not implemented - would fetch user profile with token');
    } catch (e) {
      _handleError(e, 'Fetch profile error');
      rethrow;
    }
  }

  Future<AuthResponse> refreshToken(String refreshToken) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/refresh-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refreshToken': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final tokenData = data['data'] is Map<String, dynamic>
            ? data['data'] as Map<String, dynamic>
            : jsonDecode(data['data'].toString()) as Map<String, dynamic>;
        
        // Use a dummy user or handle the fact that refresh-token might not return user data
        // Based on backend code, it returns { token, refreshToken }
        return AuthResponse(
          token: tokenData['token'],
          refreshToken: tokenData['refreshToken'],
          user: User(id: '', fullName: '', email: '', role: '', createdAt: DateTime.now()), // Dummy user
        );
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to refresh token');
      }
    } catch (e) {
      _handleError(e, 'Refresh token error');
      rethrow;
    }
  }

  Future<User> updateProfile(String token, {String? fullName, String? phone, String? avatar}) async {
    try {
      final response = await _client.put(
        Uri.parse('${ApiConfig.baseUrl}/auth/profile'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          if (fullName != null) 'fullName': fullName,
          if (phone != null) 'phone': phone,
          if (avatar != null) 'avatar': avatar,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final userData = data['data'] is Map<String, dynamic> 
            ? data['data'] as Map<String, dynamic>
            : jsonDecode(data['data'].toString()) as Map<String, dynamic>;
        return User.fromJson(userData);
      } else {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to update profile');
      }
    } catch (e) {
      _handleError(e, 'Update profile error');
      rethrow;
    }
  }

  Future<String> uploadImage(String token, File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${ApiConfig.baseUrl}/upload/image'),
      );

      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      final stream = http.ByteStream(imageFile.openRead());
      final length = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'image',
        stream,
        length,
        filename: path.basename(imageFile.path),
        contentType: MediaType('image', path.extension(imageFile.path).replaceFirst('.', '')),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseData = await response.stream.bytesToString();

      if (response.statusCode == 200) {
        final data = jsonDecode(responseData);
        return data['data']['imageUrl'];
      } else {
        final errorData = jsonDecode(responseData);
        throw Exception(errorData['message'] ?? 'Failed to upload image');
      }
    } catch (e) {
      _handleError(e, 'Upload error');
      rethrow;
    }
  }

  Future<void> deleteAccount(String token) async {
    try {
      final response = await _client.delete(
        Uri.parse('${ApiConfig.baseUrl}/auth/delete-account'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode != 200) {
        final errorData = jsonDecode(response.body);
        throw Exception(errorData['message'] ?? 'Failed to delete account');
      }
    } catch (e) {
      _handleError(e, 'Delete account error');
      rethrow;
    }
  }
}

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());
