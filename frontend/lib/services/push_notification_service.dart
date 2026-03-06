import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class PushNotificationService {
  static FirebaseMessaging get _firebaseMessaging => FirebaseMessaging.instance;
  static final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static BuildContext? _context;

  // Set context for navigation
  static void setContext(BuildContext context) {
    _context = context;
  }
  
  // Initialize push notifications
  static Future<void> initialize() async {
    // Only initialize if not on Windows
    if (defaultTargetPlatform == TargetPlatform.windows) {
      debugPrint('Push notifications not supported on Windows');
      return;
    }
    
    try {
      // 1. Request Permission
      NotificationSettings settings = await _firebaseMessaging.requestPermission(
        alert: true,
        badge: true,
        provisional: false,
        sound: true,
      );
      
      print('User granted permission: ${settings.authorizationStatus}');
      
      // 2. Create Android Notification Channel (Professional requirement)
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'high_importance_channel', // id
        'High Importance Notifications', // title
        description: 'This channel is used for important notifications.', // description
        importance: Importance.max,
      );

      await _localNotifications
          .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Initialize local notifications
      await _initializeLocalNotifications(channel);
      
      // 4. Handle background messages
      FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);
      
      // 5. Handle foreground messages
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        print('Got a message in foreground: ${message.notification?.title}');
        _showLocalNotification(message, channel);
      });
      
      // 6. Handle when app is opened from terminated state
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        print('App opened from terminated state: ${message.notification?.title}');
        _handleNotificationTap(message);
      });
      
      // 7. Handle initial message when app is opened from notification
      RemoteMessage? initialMessage = await FirebaseMessaging.instance.getInitialMessage();
      if (initialMessage != null) {
        print('App opened from notification: ${initialMessage.notification?.title}');
        _handleNotificationTap(initialMessage);
      }
      
      // 8. Schedule daily reminder
      await scheduleDailyReminder();
      
    } catch (e) {
      print('Error initializing push notifications: $e');
    }
  }
  
  // Initialize local notifications
  static Future<void> _initializeLocalNotifications(AndroidNotificationChannel channel) async {
    const AndroidInitializationSettings initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    
    final DarwinInitializationSettings initializationSettingsIOS =
        DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    final InitializationSettings initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
      iOS: initializationSettingsIOS,
    );
    
    await _localNotifications.initialize(
      initializationSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // Handle local notification tap
        if (response.payload != null && response.payload!.isNotEmpty) {
          _handleRouteNavigation(response.payload!);
        }
      },
    );
  }
  
  // Background message handler
  @pragma('vm:entry-point')
  static Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
    print('Handling a background message: ${message.messageId}');
  }
  
  // Show local notification
  static Future<void> _showLocalNotification(RemoteMessage message, AndroidNotificationChannel channel) async {
    RemoteNotification? notification = message.notification;
    AndroidNotification? android = message.notification?.android;

    if (notification != null && !kIsWeb) {
      await _localNotifications.show(
        notification.hashCode,
        notification.title,
        notification.body,
        NotificationDetails(
          android: AndroidNotificationDetails(
            channel.id,
            channel.name,
            channelDescription: channel.description,
            icon: android?.smallIcon ?? '@mipmap/ic_launcher',
            importance: Importance.max,
            priority: Priority.high,
          ),
          iOS: const DarwinNotificationDetails(
            presentAlert: true,
            presentBadge: true,
            presentSound: true,
          ),
        ),
        payload: message.data['route'] ?? '',
      );
    }
  }
  
  // Handle notification tap from FCM
  static void _handleNotificationTap(RemoteMessage message) {
    final route = message.data['route'];
    if (route != null) {
      _handleRouteNavigation(route, data: message.data);
    }
  }

  // Handle route navigation
  static void _handleRouteNavigation(String route, {Map<String, dynamic>? data}) {
    if (_context == null) {
      print('Cannot navigate: Context is null');
      return;
    }

    print('Navigating to route: $route with data: $data');

    try {
      if (route.startsWith('/learning/') && data?['courseId'] != null) {
        _context!.push('/learning/${data!['courseId']}');
      } else if (route == '/notifications') {
        _context!.push('/notifications');
      } else if (route == '/my-courses') {
        _context!.push('/my-courses');
      } else if (route.startsWith('/course/') && data?['id'] != null) {
        _context!.push('/course/${data!['id']}');
      } else {
        // Fallback to direct route if possible
        _context!.push(route);
      }
    } catch (e) {
      print('Error during notification navigation: $e');
      // If push fails, try go
      _context!.go(route);
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

  // Listen for token refresh
  static void onTokenRefresh(Function(String) onRefresh) {
    _firebaseMessaging.onTokenRefresh.listen(onRefresh);
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

  // Schedule daily reminder (Duolingo style)
  static Future<void> scheduleDailyReminder() async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;

    final reminder = _getRandomReminder();
    
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'daily_reminder_channel',
      'Daily Reminders',
      channelDescription: 'Notifications to remind you to keep learning',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
      badgeNumber: 1,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    // Using periodicallyShow as a simple way to schedule daily without timezone package
    // In a real app, you'd use tz.TZDateTime for specific time of day
    await _localNotifications.periodicallyShow(
      999, // Unique ID for daily reminder
      reminder['title'],
      reminder['body'],
      RepeatInterval.daily,
      platformDetails,
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      payload: '/dashboard',
    );
    
    print('Daily reminder scheduled: ${reminder['title']}');
  }

  // Clear all notifications and badges
  static Future<void> clearNotifications() async {
    if (defaultTargetPlatform == TargetPlatform.windows) return;
    
    await _localNotifications.cancelAll();
    // For iOS/Android badges, FCM usually handles it or you need a plugin
    // But clearing notifications helps
    print('Notifications cleared');
  }

  // Get a random Duolingo-style reminder
  static Map<String, String> _getRandomReminder() {
    final reminders = [
      {'title': 'Don\'t break your streak! 🔥', 'body': 'Your brain misses learning. Just 5 minutes today?'},
      {'title': 'Excellence Hub misses you 🥺', 'body': 'Ready to master that next lesson? Come on back!'},
      {'title': 'Your goal is waiting! 🎯', 'body': 'Success doesn\'t happen by itself. Let\'s learn something new.'},
      {'title': 'Quick reminder... ⏰', 'body': 'Consistency is the key to mastery. See you in the app!'},
      {'title': 'Psst... 🎓', 'body': 'A little bird told me you haven\'t learned anything today.'},
      {'title': 'Keep the momentum! 🚀', 'body': 'You were doing so well! Don\'t stop now.'},
    ];
    
    return reminders[DateTime.now().millisecond % reminders.length];
  }
}
