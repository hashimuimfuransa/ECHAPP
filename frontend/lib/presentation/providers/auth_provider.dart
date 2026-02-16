import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:excellencecoachinghub/models/user.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/data/repositories/auth_repository.dart';

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
        final authResponse = await _authRepository.firebaseLogin(idToken);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Step 4: Save tokens and user data
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        
        debugPrint('AuthProvider: Login completed successfully');
        
        // Set the user state and ensure navigation triggers
        state = state.copyWith(isLoading: false, user: authResponse.user, error: null);
        
        // Small delay to ensure state is properly propagated
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        state = state.copyWith(isLoading: false, error: 'Login failed');
      }
    } catch (e) {
      debugPrint('Login Provider Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> register(String fullName, String email, String password, String? phone) async {
    debugPrint('AuthProvider: Starting registration process');
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      // Register directly with backend which will send welcome email
      debugPrint('AuthProvider: Sending registration to backend API');
      final authResponse = await _authRepository.register(fullName, email, password, phone);
      
      // Save tokens and user data
      await _storageManager.saveAccessToken(authResponse.token);
      await _storageManager.saveRefreshToken(authResponse.refreshToken);
      await _storageManager.saveUserRole(authResponse.user.role);
      await _storageManager.saveUserId(authResponse.user.id);
      
      debugPrint('AuthProvider: Registration completed successfully');
      state = state.copyWith(isLoading: false, user: authResponse.user);
    } catch (e) {
      debugPrint('Registration Provider Error: $e');
      state = state.copyWith(isLoading: false, error: e.toString());
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
      debugPrint('AuthProvider: Calling Firebase service');
      final userCredential = await FirebaseAuthService.signInWithGoogle();
      debugPrint('AuthProvider: Firebase service returned: ${userCredential?.user?.email}');
      
      if (userCredential?.user != null) {
        final firebaseUser = userCredential!.user!;
        
        // Get Firebase ID token
        debugPrint('AuthProvider: About to call getIdToken()');
        final idToken = await firebaseUser.getIdToken();
        debugPrint('AuthProvider: Got Firebase ID token');
        debugPrint('AuthProvider: Token type: ${idToken.runtimeType}');
        debugPrint('AuthProvider: Token value: ${idToken.toString().length > 100 ? '${idToken.toString().substring(0, 100)}...' : idToken}');
        
        if (idToken == null) {
          debugPrint('AuthProvider: ERROR - idToken is null');
          throw Exception('Failed to get Firebase ID token');
        }
        
        // Verify that idToken is a String before passing to repository
        debugPrint('AuthProvider: Verifying idToken is String, runtimeType: ${idToken.runtimeType}');
        debugPrint('AuthProvider: idToken is confirmed to be a String');
              
        // Send token to backend for authentication
        final authResponse = await _authRepository.firebaseLogin(idToken);
        debugPrint('AuthProvider: Backend authentication successful');
        
        // Save tokens for future API requests
        await _storageManager.saveAccessToken(authResponse.token);
        await _storageManager.saveRefreshToken(authResponse.refreshToken);
        await _storageManager.saveUserRole(authResponse.user.role);
        await _storageManager.saveUserId(authResponse.user.id);
        
        debugPrint('AuthProvider: Setting success state');
        // Update state immediately
        state = state.copyWith(
          isLoading: false, 
          user: authResponse.user,
          error: null
        );
        debugPrint('AuthProvider: State updated - User: ${authResponse.user.email}, ID: ${authResponse.user.id}');
        
        // Small delay to ensure state is properly propagated for navigation
        await Future.delayed(const Duration(milliseconds: 50));
      } else {
        debugPrint('AuthProvider: Google Sign-In returned null');
        state = state.copyWith(isLoading: false, error: 'Google Sign-In cancelled');
      }
    } catch (e) {
      debugPrint('Google Sign-In Provider Error: $e');
      String errorMessage = e.toString();
      
      // Provide more user-friendly error messages for web-specific issues
      if (kIsWeb) {
        if (errorMessage.contains('popup_closed') || errorMessage.toLowerCase().contains('popup') && errorMessage.toLowerCase().contains('closed')) {
          errorMessage = 'Google Sign-In popup was closed. The legacy signIn method is deprecated on web. Please ensure pop-ups are allowed for this site and try again. A future update will implement the new button-based approach.';
        } else if (errorMessage.contains('popup') || errorMessage.toLowerCase().contains('blocked')) {
          errorMessage = 'Pop-up blocked. Please allow pop-ups for this site and try again.';
        } else if (errorMessage.toLowerCase().contains('domain') || errorMessage.toLowerCase().contains('authorized')) {
          errorMessage = 'Domain not authorized. Contact the administrator to configure Google Sign-In for this domain.';
        } else if (errorMessage.toLowerCase().contains('itp') || errorMessage.toLowerCase().contains('optimization')) {
          errorMessage = 'Browser security settings prevented sign-in. Try using a different browser or disabling privacy features.';
        } else if (errorMessage.toLowerCase().contains('deprecated') || errorMessage.toLowerCase().contains('discouraged')) {
          errorMessage = 'Using legacy Google Sign-In method on web. A future update will implement the new button-based approach as recommended by Google.';
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
