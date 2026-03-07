import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/firebase_options.dart';
import 'package:excellencecoachinghub/services/google_sign_in_desktop_service.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:flutter/material.dart';

class FirebaseAuthService {
  static firebase_auth.FirebaseAuth get _auth => firebase_auth.FirebaseAuth.instance;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    try {
      debugPrint('FirebaseAuthService: Initializing Firebase with timeout...');
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ).timeout(const Duration(seconds: 15));
      debugPrint('FirebaseAuthService: Firebase initialization complete');
    } catch (e) {
      debugPrint('FirebaseAuthService: Firebase initialization error: $e');
      rethrow;
    }
  }

  // Email/Password Registration
  static Future<firebase_auth.UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      // Input validation
      if (email.isEmpty) {
        throw Exception('Email address is required.');
      }
      if (password.isEmpty) {
        throw Exception('Password is required.');
      }
      if (fullName.isEmpty) {
        throw Exception('Full name is required.');
      }
      
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        throw Exception('Please enter a valid email address.');
      }
      
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        debugPrint('FirebaseAuthService: Set display name to: $fullName');
        // Add a small delay to ensure the update is processed
        await Future.delayed(Duration(milliseconds: 500));
        await userCredential.user!.reload();
        debugPrint('FirebaseAuthService: User reloaded, display name is now: ${userCredential.user!.displayName}');
      }
      
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Registration Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Registration Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Registration failed. Please try again.');
    }
  }

  // Email/Password Login
  static Future<firebase_auth.UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      // Input validation
      if (email.isEmpty) {
        throw Exception('Email address is required.');
      }
      if (password.isEmpty) {
        throw Exception('Password is required.');
      }
      
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        throw Exception('Please enter a valid email address.');
      }
      
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Login Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Login Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Login failed. Please try again.');
    }
  }

  // Password Reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      debugPrint('Sending password reset email to: $email');
      
      // Validate email format
      if (!RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(email)) {
        throw Exception('Please enter a valid email address');
      }
      
      await _auth.sendPasswordResetEmail(email: email);
      debugPrint('Password reset email sent successfully to: $email');
      
      // Additional debugging - check if email was actually sent
      debugPrint('Firebase password reset email request completed for: $email');
      
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code} - ${e.message}');
      
      // Handle specific Firebase auth errors
      switch (e.code) {
        case 'invalid-email':
          throw Exception('The email address is invalid.');
        case 'user-not-found':
          // Don't reveal if user exists for security
          // But we'll still show success message to prevent user enumeration
          debugPrint('User not found for email: $email, but showing success for security');
          return; // Don't throw error, let success flow continue
        case 'too-many-requests':
          debugPrint('Too many requests for email: $email');
          throw Exception('Too many requests. Please try again later.');
        case 'network-request-failed':
          debugPrint('Network error for email: $email');
          throw Exception('Network error. Please check your connection.');
        default:
          debugPrint('Unknown error for email: $email, error: ${e.message}');
          throw Exception('Failed to send password reset email. Please try again.');
      }
    } catch (e) {
      debugPrint('General Password Reset Error for email $email: $e');
      throw Exception('Failed to send password reset email. Please try again.');
    }
  }

  // Update Password
  static Future<void> updatePassword({
    required String currentPassword,
    required String newPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user signed in.');
      }

      // Re-authenticate user before updating password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.updatePassword(newPassword);
      debugPrint('FirebaseAuthService: Password updated successfully');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Password Update Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Password Update Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to update password. Please try again.');
    }
  }

  // Sign Out
  static Future<void> signOut() async {
    try {
      await _auth.signOut();
    } catch (e) {
      debugPrint('Sign Out Error: $e');
      throw Exception('Failed to sign out. Please try again.');
    }
  }

  // Get Current User
  static firebase_auth.User? getCurrentUser() {
    return _auth.currentUser;
  }

  // Check if User is Signed In
  static bool isSignedIn() {
    return _auth.currentUser != null;
  }

  // Refresh User Data
  static Future<void> reloadUser() async {
    try {
      await _auth.currentUser?.reload();
    } catch (e) {
      debugPrint('Reload User Error: $e');
    }
  }

  // Get user's custom claims (including role)
  static Future<Map<String, dynamic>?> getUserCustomClaims() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final idTokenResult = await user.getIdTokenResult();
        return idTokenResult.claims;
      }
      return null;
    } catch (e) {
      debugPrint('Error getting custom claims: $e');
      return null;
    }
  }

  // Get user's role from custom claims
  static Future<String> getUserRole() async {
    try {
      final claims = await getUserCustomClaims();
      return claims?['role'] as String? ?? 'student';
    } catch (e) {
      debugPrint('Error getting user role: $e');
      return 'student';
    }
  }

  // Delete Account
  static Future<void> deleteAccount({
    required String currentPassword,
  }) async {
    try {
      final user = _auth.currentUser;
      if (user == null || user.email == null) {
        throw Exception('No user signed in.');
      }

      // Re-authenticate user before deleting account
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: user.email!,
        password: currentPassword,
      );

      await user.reauthenticateWithCredential(credential);
      await user.delete();
      debugPrint('FirebaseAuthService: Account deleted successfully from Firebase');
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Account Deletion Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Account Deletion Error: $e');
      if (e is Exception) rethrow;
      throw Exception('Failed to delete account. Please try again.');
    }
  }

  // Google Sign-In
  static Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    debugPrint('Starting Google Sign-In process...');
    debugPrint('Platform: ${kIsWeb ? 'Web' : 'Native'}, TargetPlatform: $defaultTargetPlatform');
    
    try {
      // Handle Windows desktop separately
      if (defaultTargetPlatform == TargetPlatform.windows) {
        debugPrint('Using desktop Google Sign-In for Windows...');
        // Import is at the top, but we need to use it conditionally
        // Import GoogleSignInDesktopService at top first
        return await _signInWithGoogleDesktop();
      }

      GoogleSignIn googleSignIn;
      
      // Configure GoogleSignIn differently for web vs mobile
      if (kIsWeb) {
        // For web, we need to specify the client ID explicitly
        // Use the web client ID from Firebase config
        googleSignIn = GoogleSignIn(
          clientId: '216678536759-0ac2284f1b0657b32b91b2.apps.googleusercontent.com',
          scopes: [
            'email',
            'profile',
          ],
        );
      } else {
        // For mobile platforms, use the Android client ID from Firebase config
        googleSignIn = GoogleSignIn(
          clientId: '216678536759-d4onuunfvjsv27lvb70urfogcltqr2c0.apps.googleusercontent.com',
          scopes: [
            'email',
            'profile',
          ],
        );
      }
      
      // Trigger the authentication flow
      debugPrint('Showing Google Sign-In dialog...');
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      
      if (googleUser == null) {
        // User canceled the sign-in
        debugPrint('Google Sign-In cancelled by user');
        return null;
      }

      debugPrint('Google account selected: ${googleUser.email}');
      
      // Obtain the auth details from the request
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      debugPrint('Google authentication obtained');

      // Create a new credential
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      debugPrint('Signing in with Firebase credential...');
      // Sign in with credential - this will create account if it doesn't exist
      final userCredential = await _auth.signInWithCredential(credential);
      
      debugPrint('Firebase sign-in successful');
      
      // If this is a new user, update their profile
      if (userCredential.additionalUserInfo?.isNewUser == true) {
        debugPrint('New user detected, updating profile...');
        await userCredential.user?.updateDisplayName(googleUser.displayName);
        await userCredential.user?.updatePhotoURL(googleUser.photoUrl);
        await userCredential.user?.reload();
        debugPrint('Profile updated for new user');
      }
      
      debugPrint('Google Sign-In completed successfully');
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Google Sign-In Firebase Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Google Sign-In Error: $e');
      // For web-specific errors, provide more descriptive messages
      if (kIsWeb) {
        debugPrint('This error occurred on web platform. Make sure:');
        debugPrint('- The domain is authorized in Firebase Console Authentication settings');
        debugPrint('- The Firebase project is properly configured for web');
        debugPrint('- CORS is properly configured if applicable');
        debugPrint('- Popup blockers are disabled for this site');
        
        // Check for specific web errors
        String errorStr = e.toString().toLowerCase();
        if (errorStr.contains('popup_closed') || errorStr.contains('popup') && errorStr.contains('closed')) {
          throw Exception('Google Sign-In popup was closed. Please try again and complete the sign-in process.');
        } else if (errorStr.contains('popup_blocked')) {
          throw Exception('Google Sign-In popup was blocked. Please allow popups for this site and try again.');
        }
      }
      throw Exception('Google Sign-In failed. Please check your internet connection and try again.');
    }
  }

  // Desktop-specific Google Sign-In using google_sign_in package
  static Future<firebase_auth.UserCredential?> _signInWithGoogleDesktop() async {
    debugPrint('Firebase Auth Service: Using Google Sign-In package for Windows desktop...');
    try {
      final userCredential = await GoogleSignInDesktopService.signInWithGoogleDesktop();
      debugPrint('Firebase Auth Service: Desktop Google Sign-In successful');
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Firebase Auth Service: Desktop Sign-In Firebase Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Firebase Auth Service: Desktop Sign-In Error: $e');
      throw Exception('Google Sign-In failed. Please check your internet connection and try again.');
    }
  }

  // Map exceptions to user-friendly messages
  static Exception _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    debugPrint('Auth Exception - Code: ${e.code}, Message: ${e.message}');
    
    switch (e.code) {
      // Email validation errors
      case 'invalid-email':
        return Exception('The email address is invalid. Please check and try again.');
      
      // Login/password errors
      case 'wrong-password':
        return Exception('Incorrect password. Please try again.');
      case 'user-not-found':
        return Exception('No user found with this email address. Please check and try again.');
      
      // Registration errors
      case 'email-already-in-use':
        return Exception('An account already exists with this email address. Please use a different email or try logging in.');
      case 'weak-password':
        return Exception('The password is too weak. Please use at least 6 characters.');
      
      // Account status errors
      case 'user-disabled':
        return Exception('This account has been disabled. Please contact support.');
      
      // Rate limiting and security
      case 'too-many-requests':
        return Exception('Too many failed login attempts. Please try again later or reset your password.');
      
      // Network errors
      case 'network-request-failed':
        return Exception('Network connection error. Please check your internet connection and try again.');
      
      // Configuration errors
      case 'operation-not-allowed':
        return Exception('This sign-in method is not enabled. Please try another way.');
      
      // Multi-provider errors
      case 'account-exists-with-different-credential':
        return Exception('An account already exists with a different sign-in method.');
      
      // Additional error codes
      case 'invalid-credential':
        return Exception('Incorrect email or password. Please try again.');
      case 'requires-recent-login':
        return Exception('Please sign in again to perform this action.');
      case 'unknown-error':
        // Check for network related issues first in unknown errors
        final message = (e.message ?? '').toLowerCase();
        if (message.contains('network') || 
            message.contains('connection') || 
            message.contains('socket') || 
            message.contains('host') || 
            message.contains('timeout') ||
            message.contains('offline')) {
          return Exception('Network connection error. Please check your internet connection and try again.');
        }

        if (message.contains('password') || message.contains('credential') || message.contains('invalid')) {
          return Exception('Incorrect password. Please try again.');
        }
        return Exception('An error occurred. Please try again.');
      
      // Fallback for unmapped error codes
      default:
        final message = e.message ?? 'An authentication error occurred.';
        // Clean up message if it contains "Firebase"
        String cleanMessage = message.replaceAll('Firebase', 'Authentication').replaceAll('firebase', 'authentication');
        if (cleanMessage.toLowerCase().contains('network') || cleanMessage.toLowerCase().contains('socket')) {
          return Exception('Network connection error. Please check your internet connection and try again.');
        }
        return Exception(cleanMessage);
    }
  }
}
