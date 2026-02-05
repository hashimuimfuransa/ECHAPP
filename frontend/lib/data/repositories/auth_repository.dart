import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellence_coaching_hub/config/api_config.dart';
import 'package:excellence_coaching_hub/models/user.dart';

class AuthRepository {
  final http.Client _client;

  AuthRepository({http.Client? client}) : _client = client ?? http.Client();

  Future<AuthResponse> login(String email, String password) async {
    try {
      final response = await _client.post(
        Uri.parse('${ApiConfig.baseUrl}/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
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
      throw Exception('Network error: ${e.toString()}');
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
      );

      if (response.statusCode == 201) {
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
      throw Exception('Network error: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    try {
      // In a real implementation, you would call the logout endpoint
      // and invalidate the token on the server side
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
    } catch (e) {
      throw Exception('Logout failed: ${e.toString()}');
    }
  }

  Future<AuthResponse> firebaseLogin(String idToken) async {
    print('AuthRepository.firebaseLogin called with idToken type: ${idToken.runtimeType}');
    print('AuthRepository.firebaseLogin idToken value: ${idToken.toString().length > 100 ? '${idToken.toString().substring(0, 100)}...' : idToken}');
    
    try {
      print('Attempting to encode JSON body');
      String encodedBody;
      try {
        encodedBody = jsonEncode({'idToken': idToken});
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
      );

      print('Firebase login response status: ${response.statusCode}');
      print('Firebase login response body: ${response.body}');
      
      if (response.statusCode == 200) {
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
      
      // Re-throw with more context
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

  Future<User> getProfile() async {
    try {
      // This would typically use a stored token to fetch user profile
      // For Firebase-only auth, we could return a placeholder or throw an exception
      // since we're handling this differently in the auth provider
      await Future.delayed(const Duration(milliseconds: 100)); // Simulate API call
      throw Exception('Not implemented - would fetch user profile with token');
    } catch (e) {
      throw Exception('Failed to fetch profile: ${e.toString()}');
    }
  }
}

// Provider for AuthRepository
final authRepositoryProvider = Provider<AuthRepository>((ref) => AuthRepository());