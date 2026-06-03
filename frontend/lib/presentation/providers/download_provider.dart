import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/download_service.dart';
import 'notification_provider.dart';

final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  // Return the singleton instance and keep it alive to prevent disposal
  ref.keepAlive();
  final service = DownloadService();

  // Bridge download complete/failed events into the notification system so they
  // appear in the Notifications page AND the device notification panel.
  service.onNotificationCreated = ({
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
  
  // Initialize the service when provider is first accessed
  // Use Future.microtask to not block the provider creation
  Future.microtask(() async {
    try {
      await service.init();
    } catch (e) {
      print('Error initializing download service in provider: $e');
    }
  });
  
  return service;
});
