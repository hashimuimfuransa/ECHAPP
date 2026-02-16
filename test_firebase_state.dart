import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

void main() async {
  print('=== Testing Firebase Auth State ===');
  
  final auth = firebase_auth.FirebaseAuth.instance;
  final user = auth.currentUser;
  
  print('Current user: ${user?.uid ?? 'null'}');
  print('Current user email: ${user?.email ?? 'null'}');
  print('Current user display name: ${user?.displayName ?? 'null'}');
  
  if (user != null) {
    try {
      print('Attempting to get ID token...');
      final token = await user.getIdToken(true);
      print('Token acquired: ${token != null}');
      if (token != null) {
        print('Token length: ${token.length}');
        print('Token preview: ${token.substring(0, 50)}...');
      }
    } catch (e) {
      print('Error getting token: $e');
    }
  } else {
    print('No current user found');
  }
}