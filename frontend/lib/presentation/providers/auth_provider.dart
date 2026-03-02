import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'dart:io';
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/data/repositories/auth_repository.dart';
import 'package:excellencecoachinghub/utils/device_id_utils.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

final storageManagerProvider = Provider<StorageManager>((ref) => StorageManager());

class AuthState {
  final bool isLoading;
  final User? user;
  final String? error;

  AuthState({
    this.isLoading = false,
    this.user,
    this.error,
  });

  AuthState copyWith({
    bool? isLoading,
    User? user,
    String? error,
  }) {
    return AuthState(
      isLoading: isLoading ?? this.isLoading,
      user: user ?? this.user,
      error: error ?? this.error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final StorageManager _storageManager = StorageManager();
  final AuthRepository _authRepository = AuthRepository();

  AuthNotifier() : super(AuthState()) {
    // Check auth status on initialization
    checkAuthStatus();
  }

  Future<void> login(String email, String password) async {
    debugPrint('AuthProvider: Starting email/password login');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get device ID for device binding
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
        debugPrint('AuthProvider: Retrieved device ID: $deviceId');
      } catch (e) {
        debugPrint('AuthProvider: Error getting device ID: $e');
        // Continue without device ID if it fails
      }
      
      // Step 1: Login with Firebase Auth
      final userCredential = await FirebaseAuthService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        debugPrint('AuthProvider: Firebase login successful for ${firebaseUser.email}');
        
        // Step 2: Get Firebase ID token
        debugPrint('AuthProvider: Getting Firebase ID token');
        final idToken = await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        
        if (idToken == null) {
          debugPrint('AuthProvider: ERROR - idToken is null after login');
          throw Exception('Failed to get Firebase ID token after login');
        }
        
        // Step 3: Send token to backend for authentication
        debugPrint('AuthProvider: Sending token to backend for authentication');
        final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Step 4: Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        
        debugPrint('AuthProvider: Login completed successfully');
        
        // Set the user state and ensure navigation triggers
        state = state.copyWith(isLoading: false, user: authResponse.user, error: 'Welcome back! Login successful.');
        
        // Small delay to ensure state is properly propagated
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Login Provider Error: $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('Invalid email or password')) {
        errorMessage = 'Invalid email or password. Please check your credentials and try again.';
      } else if (errorMessage.contains('Account is deactivated')) {
        errorMessage = 'Your account has been deactivated. Please contact support.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Login failed')) {
        errorMessage = 'Login failed. Please try again.';
      } else {
        // Remove technical prefixes for cleaner user messages
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> register(String fullName, String email, String password, String? phone) async {
    debugPrint('AuthProvider: Starting registration process');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get device ID for device binding
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
        debugPrint('AuthProvider: Retrieved device ID: $deviceId');
      } catch (e) {
        debugPrint('AuthProvider: Error getting device ID: $e');
        // Continue without device ID if it fails
      }
      
      // Step 1: Register with Firebase Auth first
      debugPrint('AuthProvider: Registering with Firebase Auth');
      final userCredential = await FirebaseAuthService.registerWithEmailAndPassword(
        email: email,
        password: password,
        fullName: fullName,
      );
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        debugPrint('AuthProvider: Firebase registration successful for ${firebaseUser.email}');
        
        // Ensure the display name is properly set and user is reloaded
        await firebaseUser.reload();
        final updatedUser = firebase_auth.FirebaseAuth.instance.currentUser;
        debugPrint('AuthProvider: User reloaded, display name: ${updatedUser?.displayName}');
        
        // Step 2: Get Firebase ID token
        debugPrint('AuthProvider: Getting Firebase ID token');
        final idToken = await updatedUser?.getIdToken() ?? await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        
        if (idToken == null) {
          debugPrint('AuthProvider: ERROR - idToken is null after registration');
          throw Exception('Failed to get Firebase ID token after registration');
        }
        
        // Step 3: Send token to backend for user creation in MongoDB
        debugPrint('AuthProvider: Sending token to backend for authentication');
        final authResponse = await _authRepository.firebaseLogin(idToken, fullName: fullName, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Step 4: Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        
        debugPrint('AuthProvider: Registration completed successfully');
        state = state.copyWith(isLoading: false, user: authResponse.user, error: 'Registration successful! Welcome to ExcellenceCoachingHub.');
      } else {
        state = state.copyWith(isLoading: false, error: 'Registration failed. Please try again.');
      }
    } catch (e) {
      debugPrint('Registration Provider Error: $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('email-already-in-use')) {
        errorMessage = 'An account with this email already exists. Please try logging in instead.';
      } else if (errorMessage.contains('invalid-email')) {
        errorMessage = 'Please enter a valid email address.';
      } else if (errorMessage.contains('weak-password')) {
        errorMessage = 'Password is too weak. Please use a stronger password.';
      } else if (errorMessage.contains('operation-not-allowed')) {
        errorMessage = 'Email/password registration is not enabled.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Registration failed')) {
        errorMessage = 'Registration failed. Please try again or contact support.';
      } else {
        // Remove technical prefixes for cleaner user messages
        errorMessage = errorMessage.replaceFirst('Exception: ', '');
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<String> _refreshBackendToken() async {
    debugPrint('AuthProvider: Refreshing backend token');
    final firebaseUser = firebase_auth.FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) throw Exception('No authenticated user found. Please login again.');
    
    final idToken = await firebaseUser.getIdToken(true);
    if (idToken == null) throw Exception('Failed to get fresh Firebase ID token');
    
    String? deviceId;
    try {
      deviceId = await DeviceIdUtils.getAppDeviceId();
    } catch (e) {
      debugPrint('AuthProvider: Error getting device ID for refresh: $e');
    }
    
    final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
    
    await _storageManager.saveAccessToken(authResponse.token);
    await _storageManager.saveRefreshToken(authResponse.refreshToken);
    
    return authResponse.token;
  }

  Future<String> _getOrRefreshAccessToken() async {
    String? token = await _storageManager.getAccessToken();
    if (token == null) {
      return await _refreshBackendToken();
    }
    return token;
  }

  Future<void> updateProfile({String? fullName, String? phone, File? imageFile}) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      String token = await _getOrRefreshAccessToken();

      String? avatarUrl;
      if (imageFile != null) {
        try {
          avatarUrl = await _authRepository.uploadImage(token, imageFile);
        } catch (uploadError) {
          // If upload fails with auth or connection error, try to refresh token once
          if (uploadError.toString().contains('Not authorized') || 
              uploadError.toString().contains('invalid token') ||
              uploadError.toString().contains('SocketException')) {
            debugPrint('AuthProvider: Upload failed, attempting token refresh and retry');
            token = await _refreshBackendToken();
            avatarUrl = await _authRepository.uploadImage(token, imageFile);
          } else {
            rethrow;
          }
        }
      }

      try {
        final updatedUser = await _authRepository.updateProfile(
          token,
          fullName: fullName,
          phone: phone,
          avatar: avatarUrl,
        );
        state = state.copyWith(isLoading: false, user: updatedUser, error: 'Profile updated successfully!');
      } catch (updateError) {
        // If profile update fails with auth error, try to refresh token once
        if (updateError.toString().contains('Not authorized') || 
            updateError.toString().contains('invalid token')) {
          debugPrint('AuthProvider: Profile update failed, attempting token refresh and retry');
          token = await _refreshBackendToken();
          final updatedUser = await _authRepository.updateProfile(
            token,
            fullName: fullName,
            phone: phone,
            avatar: avatarUrl,
          );
          state = state.copyWith(isLoading: false, user: updatedUser, error: 'Profile updated successfully!');
        } else {
          rethrow;
        }
      }
    } catch (e) {
      debugPrint('AuthProvider Update Profile Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> updatePassword(String currentPassword, String newPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await FirebaseAuthService.updatePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
      );
      state = state.copyWith(isLoading: false, error: 'Password updated successfully!');
    } catch (e) {
      debugPrint('AuthProvider Update Password Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> deleteAccount(String currentPassword) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final token = await _getOrRefreshAccessToken();

      // Step 1: Delete from backend
      try {
        await _authRepository.deleteAccount(token);
      } catch (e) {
        if (e.toString().contains('Not authorized') || e.toString().contains('invalid token')) {
          final newToken = await _refreshBackendToken();
          await _authRepository.deleteAccount(newToken);
        } else {
          rethrow;
        }
      }
      debugPrint('AuthProvider: Backend account deletion successful');

      // Step 2: Delete from Firebase
      await FirebaseAuthService.deleteAccount(currentPassword: currentPassword);
      debugPrint('AuthProvider: Firebase account deletion successful');

      // Step 3: Clear local storage and state
      await _storageManager.clearAll();
      state = AuthState();
      debugPrint('AuthProvider: Account deletion completed successfully');
    } catch (e) {
      debugPrint('AuthProvider Delete Account Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString().replaceFirst('Exception: ', ''));
      rethrow;
    }
  }

  Future<void> logout() async {
    debugPrint('AuthProvider: Starting logout process');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Sign out from Firebase
      await FirebaseAuthService.signOut();
      debugPrint('AuthProvider: Firebase sign out successful');
    } catch (e) {
      debugPrint('AuthProvider: Firebase sign out error (continuing anyway): $e');
      // Don't throw error - we want to clear local data regardless
    }
    
    try {
      // Clear all local storage
      await _storageManager.clearAll();
      debugPrint('AuthProvider: Local storage cleared');
    } catch (e) {
      debugPrint('AuthProvider: Storage clear error: $e');
    }
    
    // Reset state
    state = AuthState();
    debugPrint('AuthProvider: Logout completed successfully');
  }

  Future<void> signInWithGoogle() async {
    debugPrint('AuthProvider: Starting Google Sign-In');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Get device ID for device binding
      String? deviceId;
      try {
        deviceId = await DeviceIdUtils.getAppDeviceId();
        debugPrint('AuthProvider: Retrieved device ID: $deviceId');
      } catch (e) {
        debugPrint('AuthProvider: Error getting device ID: $e');
      }
      
      debugPrint('AuthProvider: Calling Firebase service');
      final userCredential = await FirebaseAuthService.signInWithGoogle();
      debugPrint('AuthProvider: Firebase service returned: ${userCredential?.user?.email}');
      
      if (userCredential?.user == null) {
        debugPrint('AuthProvider: Google Sign-In returned null - user cancelled');
        state = state.copyWith(isLoading: false, error: 'Google Sign-In cancelled');
        return;
      }

      final firebaseUser = userCredential!.user!;
      
      try {
        // Get Firebase ID token
        debugPrint('AuthProvider: About to call getIdToken()');
        final idToken = await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        
        if (idToken == null || idToken.toString().isEmpty) {
          throw Exception('Failed to get valid Firebase ID token');
        }
        
        // Send token to backend for authentication
        debugPrint('AuthProvider: Sending token to backend');
        final authResponse = await _authRepository.firebaseLogin(idToken, deviceId: deviceId);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Save tokens for future API requests
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        
        debugPrint('AuthProvider: Setting success state');
        state = state.copyWith(
          isLoading: false, 
          user: authResponse.user,
          error: null
        );
        debugPrint('AuthProvider: State updated - User: ${authResponse.user.email}');
      } catch (tokenError) {
        debugPrint('AuthProvider: Token/Backend Error: $tokenError');
        
        // Sign out from Firebase if backend auth fails
        try {
          await FirebaseAuthService.signOut();
        } catch (_) {}
        
        String errorMessage = tokenError.toString();
        if (errorMessage.contains('Network') || errorMessage.toLowerCase().contains('socket')) {
          errorMessage = 'Network connection failed. Please check your internet connection and try again.';
        } else if (errorMessage.contains('backend') || errorMessage.contains('firebase-login')) {
          errorMessage = 'Server authentication failed. Please try again.';
        }
        
        state = state.copyWith(isLoading: false, error: errorMessage);
      }
    } catch (e) {
      debugPrint('AuthProvider Google Sign-In Error: $e');
      String errorMessage = e.toString();
      
      // Handle specific error codes
      if (errorMessage.contains('ApiException: 10')) {
        errorMessage = 'Google Sign-In is not properly configured. Please contact support.';
      } else if (errorMessage.contains('sign_in_failed')) {
        errorMessage = 'Google Sign-In failed. Please check your account and try again.';
      } else if (kIsWeb) {
        if (errorMessage.contains('popup_closed') || (errorMessage.toLowerCase().contains('popup') && errorMessage.toLowerCase().contains('closed'))) {
          errorMessage = 'Google Sign-In popup was closed. Please try again.';
        } else if (errorMessage.contains('popup_blocked')) {
          errorMessage = 'Pop-up blocked. Please allow pop-ups and try again.';
        }
      }
      
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<void> sendPasswordResetEmail(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      debugPrint('AuthProvider: Sending password reset email to $email via backend API');
      
      // Call backend API to send password reset email using SendGrid
      final response = await _authRepository.sendPasswordResetEmail(email);
      
      // Success - show confirmation message
      state = state.copyWith(
        isLoading: false, 
        error: response.message ?? 'Password reset email sent successfully! Please check your inbox (including spam folder) and follow the instructions to reset your password.'
      );
          
      debugPrint('AuthProvider: Password reset email sent successfully via backend API');
    } catch (e) {
      debugPrint('AuthProvider: Password reset failed - $e');
      String errorMessage = e.toString();
      
      // Provide user-friendly error messages
      if (errorMessage.contains('Please enter a valid email address')) {
        errorMessage = 'Please enter a valid email address';
      } else if (errorMessage.contains('Too many requests')) {
        errorMessage = 'Too many requests. Please wait a few minutes before trying again.';
      } else if (errorMessage.contains('Network error')) {
        errorMessage = 'Network connection error. Please check your internet connection and try again.';
      } else if (errorMessage.contains('Failed to send')) {
        errorMessage = 'Unable to send password reset email. Please try again or contact support.';
      }
      
      // Check if the state is still valid before updating
      state = state.copyWith(isLoading: false, error: errorMessage);
    }
  }

  Future<PasswordResetResponse> resetPassword(String token, String newPassword) async {
    try {
      debugPrint('AuthProvider: Resetting password with token: ${token.substring(0, math.min(10, token.length))}...');
      
      // Call backend API to reset password
      final response = await _authRepository.resetPassword(token, newPassword);
      
      debugPrint('AuthProvider: Password reset successfully');
      return response;
    } catch (e) {
      debugPrint('AuthProvider: Password reset failed - $e');
      rethrow;
    }
  }

  Future<bool> verifyResetToken(String token) async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final result = await _authRepository.verifyResetToken(token);
      state = state.copyWith(isLoading: false);
      return result;
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
      rethrow;
    }
  }

  Future<void> checkAuthStatus() async {
    try {
      final firebaseUser = FirebaseAuthService.getCurrentUser();
      
      if (firebaseUser != null) {
        debugPrint('AuthProvider: Firebase user found: ${firebaseUser.email}');
        
        // Check if we have stored tokens and user data
        final storedUserId = await _storageManager.getUserId();
        final storedUserRole = await _storageManager.getUserRole();
        final storedToken = await _storageManager.getAccessToken();
        
        if (storedUserId != null && 
            storedUserRole != null && 
            storedToken != null && 
            storedUserId == firebaseUser.uid) {
          
          debugPrint('AuthProvider: Valid session found for user: $storedUserId');
          // Recreate user from stored data
          final user = User(
            id: firebaseUser.uid,
            fullName: firebaseUser.displayName ?? '',
            email: firebaseUser.email ?? '',
            phone: firebaseUser.phoneNumber,
            role: storedUserRole,
            createdAt: DateTime.fromMillisecondsSinceEpoch(firebaseUser.metadata.creationTime?.millisecondsSinceEpoch ?? DateTime.now().millisecondsSinceEpoch),
          );
          state = state.copyWith(user: user);
        } else {
          debugPrint('AuthProvider: Incomplete session data. storedUserId: $storedUserId, storedUserRole: $storedUserRole, storedToken: ${storedToken != null}');
          // User is signed in to Firebase but we don't have complete backend tokens
          // This could happen if app was closed after Firebase login but before backend auth
          // For now, we'll clear the state and require re-authentication
          await _storageManager.clearAll();
          await FirebaseAuthService.signOut();
          state = AuthState();
        }
      } else {
        debugPrint('AuthProvider: No Firebase user found');
      }
    } catch (e) {
      debugPrint('AuthProvider: Error checking auth status: $e');
      // Clear storage if there's an error
      await _storageManager.clearAll();
      state = AuthState();
    }
  }

  bool get isAuthenticated => state.user != null && FirebaseAuthService.isSignedIn();
  bool get isAdmin => state.user?.role == 'admin';
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});
