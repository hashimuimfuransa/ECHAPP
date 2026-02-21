import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';

class GoogleSignInDesktopService {
  static final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  
  // Desktop OAuth client ID from Google Cloud Console (Desktop application type)
  static const String _desktopClientId = '192720000772-4gckpvbqm0raq4vl7g8lsphbl0rbi325.apps.googleusercontent.com';
  static const String _redirectUrl = 'http://localhost:8080/callback';
  static const String _firebaseApiKey = 'AIzaSyBjWFgcO6gWOjmk5vqUjxDTcFpGFj_hOd8';

  static Future<firebase_auth.UserCredential?> signInWithGoogleDesktop() async {
    debugPrint('GoogleSignInDesktopService: Starting Google Sign-In for Windows desktop');
    
    try {
      // Open Google's OAuth consent screen in browser
      final authUrl = _buildAuthUrl();
      debugPrint('GoogleSignInDesktopService: Opening browser for OAuth...');
      
      if (!await launchUrl(Uri.parse(authUrl), mode: LaunchMode.externalApplication)) {
        throw Exception('Could not launch Google Sign-In URL');
      }
      
      debugPrint('GoogleSignInDesktopService: Waiting for user to complete sign-in in browser...');
      
      // Start local server to receive the callback
      final authCode = await _waitForOAuthCallback();
      
      if (authCode == null) {
        debugPrint('GoogleSignInDesktopService: OAuth callback timeout');
        throw Exception('Google Sign-In process timed out. Please try again.');
      }
      
      debugPrint('GoogleSignInDesktopService: Received auth code, exchanging for tokens...');
      
      // Exchange authorization code for ID token using Firebase's signInWithIdp
      final userCredential = await _exchangeCodeForToken(authCode);
      
      debugPrint('GoogleSignInDesktopService: Successfully signed in: ${userCredential.user?.email}');
      return userCredential;
    } catch (e) {
      debugPrint('GoogleSignInDesktopService: Error during sign-in: $e');
      rethrow;
    }
  }

  static String _buildAuthUrl() {
    final params = {
      'client_id': _desktopClientId,
      'redirect_uri': _redirectUrl,
      'response_type': 'code',
      'scope': 'openid email profile',
      'access_type': 'offline',
    };

    final queryString = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'https://accounts.google.com/o/oauth2/v2/auth?$queryString';
  }

  static Future<String?> _waitForOAuthCallback() async {
    try {
      final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 8080);
      debugPrint('GoogleSignInDesktopService: OAuth callback server started on port 8080');
      
      String? authCode;
      
      server.listen((request) {
        final uri = request.uri;
        if (uri.path == '/callback') {
          authCode = uri.queryParameters['code'];
          
          if (authCode != null) {
            debugPrint('GoogleSignInDesktopService: Received authorization code');
            request.response.write('Authorization successful! You can close this window.');
          } else {
            final error = uri.queryParameters['error'];
            debugPrint('GoogleSignInDesktopService: OAuth error: $error');
            request.response.write('Authorization failed: $error');
          }
        }
        request.response.close();
      });
      
      // Wait for callback with 2 minute timeout
      int attempts = 0;
      while (attempts < 240) {
        await Future.delayed(const Duration(milliseconds: 500));
        if (authCode != null) {
          await server.close();
          return authCode;
        }
        attempts++;
      }
      
      await server.close();
      return null;
    } catch (e) {
      debugPrint('GoogleSignInDesktopService: Error setting up callback server: $e');
      rethrow;
    }
  }

  static Future<firebase_auth.UserCredential> _exchangeCodeForToken(String authCode) async {
    try {
      // Exchange auth code for ID token using Google's token endpoint
      final tokenResponse = await http.post(
        Uri.parse('https://oauth2.googleapis.com/token'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'code': authCode,
          'client_id': _desktopClientId,
          'redirect_uri': _redirectUrl,
          'grant_type': 'authorization_code',
        },
      );

      if (tokenResponse.statusCode != 200) {
        final error = jsonDecode(tokenResponse.body);
        throw Exception('Token exchange failed: ${error['error_description']}');
      }

      final tokenData = jsonDecode(tokenResponse.body);
      final idToken = tokenData['id_token'];

      if (idToken == null) {
        throw Exception('No ID token received from Google');
      }

      debugPrint('GoogleSignInDesktopService: Received ID token from Google');

      // Sign in to Firebase using the ID token
      final credential = firebase_auth.GoogleAuthProvider.credential(idToken: idToken);
      final userCredential = await _auth.signInWithCredential(credential);

      return userCredential;
    } catch (e) {
      debugPrint('GoogleSignInDesktopService: Token exchange error: $e');
      rethrow;
    }
  }

  static Future<void> signOut() async {
    try {
      await _auth.signOut();
      debugPrint('GoogleSignInDesktopService: Signed out successfully');
    } catch (e) {
      debugPrint('GoogleSignInDesktopService: Error signing out: $e');
      rethrow;
    }
  }
}
