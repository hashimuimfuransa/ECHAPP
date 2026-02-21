import 'package:http/http.dart' as http;
import 'dart:convert';
import '../config/api_config.dart';
import '../services/push_notification_service.dart';
import '../services/infrastructure/token_manager.dart';

class FCMTokenService {
  
  // Update FCM token on backend
  static Future<bool> updateFCMToken(String token) async {
    try {
      final url = Uri.parse('${ApiConfig.baseUrl}/notifications/fcm-token');
      
      // Get authentication token
      final authToken = await TokenManager().getIdToken();
      
      if (authToken == null) {
        print('No auth token available, skipping FCM token update');
        return false;
      }
      
      final response = await http.put(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $authToken',
        },
        body: json.encode({
          'fcmToken': token,
        }),
      );
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true) {
          print('FCM token updated successfully on backend');
          return true;
        }
      }
      
      // Don't log 401 errors as failures since they're expected when not logged in
      if (response.statusCode != 401) {
        print('Failed to update FCM token: ${response.statusCode}');
      }
      return false;
    } catch (e) {
      print('Error updating FCM token: $e');
      return false;
    }
  }
  
  // Initialize and sync FCM token
  static Future<void> initializeAndSyncToken() async {
    try {
      // Get current FCM token
      final token = await PushNotificationService.getFCMToken();
      
      if (token != null) {
        print('Current FCM Token: $token');
        
        // Update token on backend
        await updateFCMToken(token);
        
        // Subscribe to relevant topics
        await _subscribeToTopics();
      } else {
        print('Failed to get FCM token');
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