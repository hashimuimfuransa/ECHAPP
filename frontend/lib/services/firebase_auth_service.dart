import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/firebase_options.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseAuthService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  // Initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  // Email/Password Registration
  static Future<firebase_auth.UserCredential?> registerWithEmailAndPassword({
    required String email,
    required String password,
    required String fullName,
  }) async {
    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
      
      // Update user profile
      if (userCredential.user != null) {
        await userCredential.user!.updateDisplayName(fullName);
        await userCredential.user!.reload();
      }
      
      return userCredential;
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Registration Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Registration Error: $e');
      throw Exception('Registration failed. Please try again.');
    }
  }

  // Email/Password Login
  static Future<firebase_auth.UserCredential?> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Login Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Login Error: $e');
      throw Exception('Login failed. Please try again.');
    }
  }

  // Password Reset
  static Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      debugPrint('Password Reset Error: ${e.code} - ${e.message}');
      throw _mapFirebaseAuthException(e);
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      throw Exception('Failed to send password reset email. Please try again.');
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

  // Google Sign-In
  static Future<firebase_auth.UserCredential?> signInWithGoogle() async {
    debugPrint('Starting Google Sign-In process...');
    try {
      GoogleSignIn googleSignIn;
      
      // Configure GoogleSignIn differently for web vs mobile
      if (kIsWeb) {
        // For web, we need to specify the client ID explicitly
        googleSignIn = GoogleSignIn(
          clientId: '216678536759-0ac2284f1b0657b32b91b2.apps.googleusercontent.com',
          scopes: [
            'email',
            'profile',
          ],
        );
      } else {
        // For mobile platforms, use the default configuration
        googleSignIn = GoogleSignIn(
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
        }
      }
      throw Exception('Google Sign-In failed. Please try again. Error: $e');
    }
  }

  // Map Firebase Auth exceptions to user-friendly messages
  static Exception _mapFirebaseAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return Exception('The email address is invalid.');
      case 'user-disabled':
        return Exception('This user account has been disabled.');
      case 'user-not-found':
        return Exception('No user found with this email address.');
      case 'wrong-password':
        return Exception('Incorrect password.');
      case 'email-already-in-use':
        return Exception('An account already exists with this email address.');
      case 'operation-not-allowed':
        return Exception('Email/password accounts are not enabled.');
      case 'weak-password':
        return Exception('The password is too weak.');
      case 'too-many-requests':
        return Exception('Too many requests. Please try again later.');
      case 'network-request-failed':
        return Exception('Network error. Please check your connection.');
      default:
        return Exception(e.message ?? 'Authentication failed.');
    }
  }
}
