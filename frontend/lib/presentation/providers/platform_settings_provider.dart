import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/platform_settings.dart';
import '../../services/platform_settings_service.dart';

final platformSettingsServiceProvider = Provider<PlatformSettingsService>((ref) {
  return PlatformSettingsService();
});

final platformSettingsProvider = StateNotifierProvider<PlatformSettingsNotifier, AsyncValue<PlatformSettings>>((ref) {
  final service = ref.watch(platformSettingsServiceProvider);
  return PlatformSettingsNotifier(service);
});

class PlatformSettingsNotifier extends StateNotifier<AsyncValue<PlatformSettings>> {
  final PlatformSettingsService _service;

  PlatformSettingsNotifier(this._service) : super(const AsyncValue.loading()) {
    loadSettings();
  }

  Future<void> loadSettings() async {
    state = const AsyncValue.loading();
    try {
      final settings = await _service.getSettings();
      state = AsyncValue.data(settings);
    } catch (e, stack) {
      state = AsyncValue.error(e, stack);
    }
  }

  Future<bool> updateSettings(PlatformSettings settings) async {
    try {
      final updatedSettings = await _service.updateSettings(settings.toJson());
      state = AsyncValue.data(updatedSettings);
      return true;
    } catch (e) {
      return false;
    }
  }
  
  Future<bool> updatePaymentInfo(PaymentInfo paymentInfo) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(paymentInfo: paymentInfo);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updatePlatformInfo(PlatformInfo platformInfo) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(platformInfo: platformInfo);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updateUserManagementSettings(UserManagementSettings userManagement) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(userManagement: userManagement);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updateContentModerationSettings(ContentModerationSettings contentModeration) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(contentModeration: contentModeration);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updateNotificationSettings(NotificationSettings notifications) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(notifications: notifications);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updateAppearanceSettings(AppearanceSettings appearance) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(appearance: appearance);
    
    return await updateSettings(newSettings);
  }

  Future<bool> updateDataManagementSettings(DataManagementSettings dataManagement) async {
    final currentSettings = state.value;
    if (currentSettings == null) return false;
    
    final newSettings = currentSettings.copyWith(dataManagement: dataManagement);
    
    return await updateSettings(newSettings);
  }
}
