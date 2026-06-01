import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/download_service.dart';

final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  // Return the singleton instance and keep it alive to prevent disposal
  ref.keepAlive();
  final service = DownloadService();
  
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
