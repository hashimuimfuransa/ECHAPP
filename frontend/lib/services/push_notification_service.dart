import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

class PushNotificationService {
  static final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  
  // Initialize push notifications
  static Future<void> initialize() async {
    try {
      // Request permission for iOS
      if (!kIsWeb) {
        NotificationSettings settings = await _firebaseMessaging.requestPermission(
          alert: true,
          badge: true,
          provisional: false,
          sound: true,
        );
        
        if (settings.authorizationStatus == AuthorizationStatus.authorized) {
          print('User granted permission for notifications');
        } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
          print('User granted provisional permission');
        } else {
          print('User declined or has not accepted permission');
        }
      }
      
      // Initialize local notifications
      await _initializeLocalNotifications();
      
      // Get the token
      final fcmToken = await _firebaseMessaging.getToken();
      print('FCM Token: $fcmToken');
      
      // Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message in foreground: ${message.notification?.title}');
        _showLocalNotification(message);
      });
      
      // Handle when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from terminated state: ${message.notification?.title}');
        _handleNotificationTap(message);
      });
      
      // Handle initial message when app is opened from notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.notification?.title}');
        _handleNotificationTap(initialMessage);
      }
      
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }
  
  // Initialize local notifications
  static Future<void> _initializeLocalNotifications() async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
      onDidReceiveLocalNotification: (id, title, body, payload) async {
        // Handle iOS notification tap
        print('Local notification tapped: $title');
      },
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle notification tap
        print('Local notification tapped: ${response.payload}');
      },
    );
  }
  
  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
    // Show local notification
    _showLocalNotification(message);
  }
  
  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message) async {
    const AndroidNotificationDetails androidPlatformChannelSpecifics =
        AndroidNotificationDetails(
      'excellence_hub_channel', 
      'Excellence Hub Notifications',
      channelDescription: 'Notifications for Excellence Coaching Hub',
      importance: Importance.max,
      priority: Priority.high,
      ticker: 'ticker',
      icon: '@mipmap/ic_launcher',
    );
    
    const NotificationDetails platformChannelSpecifics =
        NotificationDetails(android: androidPlatformChannelSpecifics);
    
    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      message.notification?.title ?? 'Notification',
      message.notification?.body ?? 'You have a new notification',
      platformChannelSpecifics,
      payload: message.data['route'] ?? '',
    );
  }
  
  // Handle notification tap
  static void _handleNotificationTap(RemoteMessage message) {
    // Navigate to specific screen based on notification data
    final route = message.data['route'];
    final courseId = message.data['courseId'];
    final examId = message.data['examId'];
    
    print('Handling notification tap - Route: $route, Course: $courseId, Exam: $examId');
    
    // This would integrate with your app's navigation system
    // For now, we just log the action
    if (route != null) {
      // Example navigation logic:
      // - If route is '/learning' and courseId is provided, navigate to course
      // - If route is '/exams' and examId is provided, navigate to exam
      // - etc.
    }
  }
  
  // Get FCM token
  static Future<String?> getFCMToken() async {
    try {
      return await _firebaseMessaging.getToken();
    } catch (e) {
      print('Error getting FCM token: $e');
      return null;
    }
  }
  
  // Subscribe to topic
  static Future<void> subscribeToTopic(String topic) async {
    try {
      await _firebaseMessaging.subscribeToTopic(topic);
      print('Subscribed to topic: $topic');
    } catch (e) {
      print('Error subscribing to topic: $e');
    }
  }
  
  // Unsubscribe from topic
  static Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _firebaseMessaging.unsubscribeFromTopic(topic);
      print('Unsubscribed from topic: $topic');
    } catch (e) {
      print('Error unsubscribing from topic: $e');
    }
  }
}