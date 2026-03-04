import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/download_service.dart';

final downloadServiceProvider = ChangeNotifierProvider<DownloadService>((ref) {
  final service = DownloadService();
  return service;
});
