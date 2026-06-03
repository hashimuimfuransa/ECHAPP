import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'package:excellencecoachinghub/config/app_theme.dart';
import 'package:excellencecoachinghub/presentation/router/app_router.dart';
import 'package:excellencecoachinghub/services/firebase_auth_service.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:excellencecoachinghub/l10n/app_localizations.dart';
import 'package:excellencecoachinghub/l10n/kinyarwanda_material_localizations.dart';
import 'package:excellencecoachinghub/presentation/providers/localization_provider.dart';
import 'package:excellencecoachinghub/presentation/providers/notification_provider.dart';
import 'package:excellencecoachinghub/services/download_service.dart';
import 'package:excellencecoachinghub/services/push_notification_service.dart';
import 'package:excellencecoachinghub/services/fcm_token_service.dart';
import 'package:excellencecoachinghub/presentation/screens/settings/settings_screen.dart';
import 'package:media_kit/media_kit.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  MediaKit.ensureInitialized();
  
  // Enable gesture resampling for smoother touch interactions
  GestureBinding.instance.resamplingEnabled = true;
  
  // Set system UI mode to hide navigation buttons for mobile
  if (!kIsWeb) {
    await SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.edgeToEdge,
      overlays: [],
    );
    
    // Set preferred orientations
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
  }
  
  // Use runZonedGuarded to catch any unhandled errors that might crash the app
  await runZonedGuarded(() async {
    try {
      debugPrint('Main: Starting app initialization...');
      
      // Initialize Firebase first (must be ready before plugins that rely on it)
      // Added a timeout and detailed logging to debug the "see nothing" issue
      await FirebaseAuthService.initializeFirebase();
      debugPrint('Main: Firebase initialized successfully');

      // Initialize push notifications only on supported platforms (not Windows)
      if (defaultTargetPlatform != TargetPlatform.windows) {
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
    final locale = ref.watch(localeProvider);

    // Wire static services so local notifications are also saved to the
    // backend and appear on the Notifications page.
    PushNotificationService.onNotificationCreated ??= ({
      required String title,
      required String message,
      required String type,
    }) async {
      try {
        await ref.read(notificationProvider.notifier).createAndSave(
          title: title,
          message: message,
          type: type,
        );
      } catch (_) {}
    };

    // When a backend FCM message arrives in the foreground, reload the
    // notifications list so the new entry immediately appears in the page.
    PushNotificationService.onFcmMessageReceived ??= () async {
      try {
        await ref.read(notificationProvider.notifier).loadNotifications();
      } catch (_) {}
    };
    
    return MaterialApp.router(
      title: 'ExcellenceCoachingHub',
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      routerConfig: AppRouter.routerInstance,
      locale: locale,
      supportedLocales: AppLocalizations.supportedLocales,
      localizationsDelegates: [
        AppLocalizations.delegate,
        const KinyarwandaMaterialLocalizationsDelegate(),
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      debugShowCheckedModeBanner: false,
      builder: (context, child) {
        // Ensure localizations are loaded before showing content
        final localizations = AppLocalizations.of(context);
        if (localizations == null) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(),
            ),
          );
        }
        return child ?? const SizedBox.shrink();
      },
    );
  }
}
