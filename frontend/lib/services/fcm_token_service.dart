import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/push_notification_service.dart';

class FCMTokenService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  static final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Update FCM token on backend and Firestore
  static Future<bool> updateFCMToken(String token) async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        print('No authenticated user, skipping FCM token update');
        return false;
      }

      // 1. Professional way: Save token to Firestore for high availability and easy access by Functions
      await _firestore.collection('users').doc(user.uid).set({
        'fcmToken': token,
        'lastTokenUpdate': FieldValue.serverTimestamp(),
        'platform': _getPlatformName(),
      }, SetOptions(merge: true));
      
      print('FCM token updated successfully in Firestore');
      return true;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }

  static String _getPlatformName() {
    if (kIsWeb) return 'web';
    switch (defaultTargetPlatform) {
      case TargetPlatform.android: return 'android';
      case TargetPlatform.iOS: return 'ios';
      case TargetPlatform.macOS: return 'macos';
      case TargetPlatform.windows: return 'windows';
      case TargetPlatform.linux: return 'linux';
      default: return 'unknown';
    }
  }
  
  // Initialize and sync FCM token
  static Future<void> initializeAndSyncToken() async {
    try {
      // Listen for token refreshes
      PushNotificationService.onTokenRefresh((token) {
        updateFCMToken(token);
      });

      // Get current FCM token
      final token = await PushNotificationService.getFCMToken();
      
      if (token != null) {
        print('Current FCM Token: $token');
        await updateFCMToken(token);
        await _subscribeToTopics();
      }
    } catch (e) {
      print('Error initializing FCM token sync: $e');
    }
  }
  
  // Subscribe to relevant topics
  static Future<void> _subscribeToTopics() async {
    try {
      // Subscribe to general notifications
      await PushNotificationService.subscribeToTopic('general');
      
      // Subscribe to course-related notifications
      await PushNotificationService.subscribeToTopic('courses');
      
      // Subscribe to exam notifications
      await PushNotificationService.subscribeToTopic('exams');
      
      // Subscribe to payment notifications
      await PushNotificationService.subscribeToTopic('payments');
      
      print('Subscribed to notification topics');
    } catch (e) {
      print('Error subscribing to topics: $e');
    }
  }
  
  // Unsubscribe from topics
  static Future<void> unsubscribeFromTopics() async {
    try {
      await PushNotificationService.unsubscribeFromTopic('general');
      await PushNotificationService.unsubscribeFromTopic('courses');
      await PushNotificationService.unsubscribeFromTopic('exams');
      await PushNotificationService.unsubscribeFromTopic('payments');
      
      print('Unsubscribed from notification topics');
    } catch (e) {
      print('Error unsubscribing from topics: $e');
    }
  }
}