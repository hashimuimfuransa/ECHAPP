import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

/// Manages Firebase authentication tokens and user state
class TokenManager {
  static final TokenManager _instance = TokenManager._internal();
  factory TokenManager() => _instance;
  TokenManager._internal();

  /// Get current Firebase user
  firebase_auth.User? get currentUser => firebase_auth.FirebaseAuth.instance.currentUser;

  /// Check if user is authenticated
  bool get isAuthenticated => currentUser != null;

  /// Get fresh Firebase ID token
  Future<String?> getIdToken({bool forceRefresh = false}) async {
    try {
      final user = currentUser;
      if (user == null) return null;
      
      return await user.getIdToken(forceRefresh);
    } catch (e) {
      print('Error getting ID token: $e');
      return null;
    }
  }

  /// Listen to auth state changes
  Stream<firebase_auth.User?> authStateChanges() {
    return firebase_auth.FirebaseAuth.instance.authStateChanges();
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await firebase_auth.FirebaseAuth.instance.signOut();
    } catch (e) {
      print('Error signing out: $e');
      rethrow;
    }
  }

  /// Get user display name
  String? get displayName => currentUser?.displayName;

  /// Get user email
  String? get email => currentUser?.email;

  /// Get user photo URL
  String? get photoUrl => currentUser?.photoURL;

  /// Get user UID
  String? get uid => currentUser?.uid;
}