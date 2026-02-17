import 'package:device_info_plus/device_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

/// Utility class for managing device IDs
class DeviceIdUtils {
  /// Generates or retrieves a unique device ID that persists across app reinstalls
  static Future<String> getOrCreateAppDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    String? savedId = prefs.getString("app_device_id");

    if (savedId != null) return savedId;

    String newId = const Uuid().v4();
    await prefs.setString("app_device_id", newId);
    return newId;
  }

  /// Gets the actual device hardware ID (less reliable but more secure for device binding)
  static Future<String> getHardwareDeviceId() async {
    final deviceInfo = DeviceInfoPlugin();

    if (Platform.isAndroid) {
      final androidInfo = await deviceInfo.androidInfo;
      return androidInfo.id; 
    } else if (Platform.isIOS) {
      final iosInfo = await deviceInfo.iosInfo;
      return iosInfo.identifierForVendor ?? "";
    }
    return "";
  }

  /// Gets the app-specific persistent device ID (recommended for security)
  static Future<String> getAppDeviceId() async {
    return await getOrCreateAppDeviceId();
  }
}