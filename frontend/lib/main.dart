import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/app_router.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';


Future<void> main() async {
  // Use runZonedGuarded to catch any unhandled errors that might crash the app
  await runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    try {
      debugPrint('Main: Starting app initialization...');
      
      // Initialize Firebase first (must be ready before plugins that rely on it)
      // Added a timeout and detailed logging to debug the "see nothing" issue
      await FirebaseAuthService.initializeFirebase();
      debugPrint('Main: Firebase initialized successfully');

      // Initialize push notifications only on supported platforms (not Windows)
      if (defaultTargetPlatform != TargetPlatform.windows && !kIsWeb) {
        await PushNotificationService.initialize();
      }

      // Start non-critical initialization in background
      _initializeBackgroundServices();
      
      runApp(
        const ProviderScope(
          child: ExcellenceCoachingHubApp(),
        ),
      );
    } catch (e, stack) {
      // Handle startup errors gracefully
      debugPrint('FATAL ERROR during app startup: $e');
      debugPrint('Stack trace: $stack');
      
      _showErrorApp(e.toString());
    }
  }, (error, stack) {
    debugPrint('UNHANDLED ERROR: $error');
    debugPrint('Stack trace: $stack');
    // If the app is already running, this won't do much, but it helps with startup crashes
  });
}

void _showErrorApp(String error) {
  runApp(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, color: Colors.red, size: 64),
                const SizedBox(height: 20),
                const Text(
                  'App Failed to Start',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 20),
                Text(
                  'Error: $error',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(height: 20),
                ElevatedButton(
                  onPressed: () => main(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// Background initialization that doesn't block app startup
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize FCM token sync only on supported platforms
    if (defaultTargetPlatform != TargetPlatform.windows) {
      await FCMTokenService.initializeAndSyncToken();
    }
    
    // Initialize download service (non-blocking)
    final downloadService = DownloadService();
    await downloadService.init();
    
    debugPrint('Background services initialized successfully');
  } catch (e) {
    debugPrint('Error initializing background services: $e');
    // Don't crash the app if background services fail
  }
}

class ExcellenceCoachingHubApp extends ConsumerWidget {
  const ExcellenceCoachingHubApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    
    // Initialize categories
    ref.listen(categoriesProvider, (_, __) {});
    
    // Load initial categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final categories = CategoriesService.getAllCategories();
      ref.read(categoriesProvider.notifier).state = categories;
    });
    
    return MaterialApp.router(
      title: 'ExcellenceCoachingHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter().router,
      debugShowCheckedModeBanner: false,
    );
  }
}
