import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../models/user.dart';

import '../infrastructure/api_client.dart';
import '../infrastructure/token_manager.dart';
import '../../config/api_config.dart';

/// Service for authentication-related API operations
class AuthService {
  final ApiClient _apiClient;
  final TokenManager _tokenManager;

  AuthService({
    ApiClient? apiClient,
    TokenManager? tokenManager,
  })  : _apiClient = apiClient ?? ApiClient(),
        _tokenManager = tokenManager ?? TokenManager();

  /// Firebase login - exchanges Firebase token for backend session
  Future<User> firebaseLogin() async {
    try {
      final token = await _tokenManager.getIdToken(forceRefresh: true);
      if (token == null) {
        throw ApiException.unauthorized('No authentication token available');
      }

      final response = await _apiClient.post(
        ApiConfig.firebaseLogin,
        body: {'idToken': token},
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(User.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to login: $e');
    }
  }

  /// Traditional email/password login
  Future<User> login(String email, String password) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.login,
        body: {
          'email': email,
          'password': password,
        },
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(User.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to login: $e');
    }
  }

  /// Register new user
  Future<User> register({
    required String fullName,
    required String email,
    required String password,
    String? phone,
  }) async {
    try {
      final response = await _apiClient.post(
        ApiConfig.register,
        body: {
          'fullName': fullName,
          'email': email,
          'password': password,
          if (phone != null) 'phone': phone,
        },
      );

      response.validateStatus();
      final apiResponse = response.toApiResponse(User.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to register: $e');
    }
  }

  /// Get current user profile
  Future<User> getProfile() async {
    try {
      final response = await _apiClient.get(ApiConfig.profile);
      response.validateStatus();
      
      final apiResponse = response.toApiResponse(User.fromJson);
      
      if (apiResponse.success && apiResponse.data != null) {
        return apiResponse.data!;
      } else {
        throw ApiException(apiResponse.message);
      }
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to fetch profile: $e');
    }
  }

  /// Logout current user
  Future<void> logout() async {
    try {
      await _apiClient.post(ApiConfig.logout);
      await _tokenManager.signOut();
    } catch (e) {
      // Even if logout fails, still sign out locally
      await _tokenManager.signOut();
      if (e is ApiException && e.statusCode != 401) {
        rethrow;
      }
    }
  }

  /// Check if user is authenticated
  bool get isAuthenticated => _tokenManager.isAuthenticated;

  /// Get current user
  firebase_auth.User? get currentUser => _tokenManager.currentUser;

  /// Listen to auth state changes
  Stream<firebase_auth.User?> get authStateChanges => _tokenManager.authStateChanges();

  /// Dispose of resources
  void dispose() {
    _apiClient.dispose();
  }
}
