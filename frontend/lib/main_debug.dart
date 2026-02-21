import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/app_router.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:firebase_core/firebase_core.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  try {
    debugPrint('Starting app initialization...');
    
    // Initialize Firebase with detailed error handling
    debugPrint('Initializing Firebase...');
    await FirebaseAuthService.initializeFirebase();
    debugPrint('Firebase initialized successfully');
    
    // Initialize push notifications
    debugPrint('Initializing push notifications...');
    await PushNotificationService.initialize();
    debugPrint('Push notifications initialized successfully');
    
    // Start non-critical initialization in background
    debugPrint('Starting background services...');
    _initializeBackgroundServices();
    
    debugPrint('Launching app...');
    runApp(
      const ProviderScope(
        child: ExcellenceCoachingHubApp(),
      ),
    );
  } catch (e, stack) {
    debugPrint('FATAL ERROR during app startup: $e');
    debugPrint('Stack trace: $stack');
    
    // Show error dialog
    runApp(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.error,
                    color: Colors.red,
                    size: 64,
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'App Failed to Start',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Error: $e',
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 16),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: () {
                      // Try to restart the app
                      main();
                    },
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
}

// Background initialization that doesn't block app startup
Future<void> _initializeBackgroundServices() async {
  try {
    debugPrint('Initializing FCM token service...');
    await FCMTokenService.initializeAndSyncToken();
    debugPrint('FCM token service initialized');
    
    debugPrint('Initializing download service...');
    final downloadService = DownloadService();
    await downloadService.init();
    debugPrint('Download service initialized');
    
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
    debugPrint('Building ExcellenceCoachingHubApp');
    
    final themeMode = ref.watch(themeModeProvider);
    
    // Initialize categories
    ref.listen(categoriesProvider, (_, __) {});
    
    // Load initial categories
    WidgetsBinding.instance.addPostFrameCallback((_) {
      debugPrint('Loading initial categories...');
      final categories = CategoriesService.getAllCategories();
      ref.read(categoriesProvider.notifier).state = categories;
      debugPrint('Categories loaded: ${categories.length} items');
    });
    
    debugPrint('App built successfully');
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