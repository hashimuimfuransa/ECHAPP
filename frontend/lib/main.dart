import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/app_router.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:excellencecoachinghub/services/categories_service.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Start critical initialization in parallel
  await Future.wait([
    FirebaseAuthService.initializeFirebase(),
    PushNotificationService.initialize(),
  ]);
  
  // Start non-critical initialization in background
  _initializeBackgroundServices();
  
  runApp(
    const ProviderScope(
      child: ExcellenceCoachingHubApp(),
    ),
  );
}

// Background initialization that doesn't block app startup
Future<void> _initializeBackgroundServices() async {
  try {
    // Initialize FCM token sync (non-blocking)
    await FCMTokenService.initializeAndSyncToken();
    
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
