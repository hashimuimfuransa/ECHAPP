import 'dart:convert';
import './infrastructure/api_client.dart';
import '../config/api_config.dart';
import '../models/platform_settings.dart';
import '../models/api_response.dart';

class PlatformSettingsService {
  final ApiClient _apiClient;

  PlatformSettingsService({ApiClient? apiClient}) : _apiClient = apiClient ?? ApiClient();

  /// Get platform settings
  Future<PlatformSettings> getSettings() async {
    try {
      final response = await _apiClient.get(ApiConfig.platformSettings);
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return PlatformSettings.fromJson(data);
    } catch (e) {
      // Return default settings on failure
      return PlatformSettings(
        id: '',
        key: 'general',
        paymentInfo: PaymentInfo(
          mtnMomo: MobilePaymentInfo(accountName: '', accountNumber: '', merchantCode: '', enabled: true),
          airtelMoney: MobilePaymentInfo(accountName: '', accountNumber: '', merchantCode: '', enabled: true),
          bankTransfer: BankTransferInfo(bankName: '', accountName: '', accountNumber: '', swiftCode: '', enabled: true),
          contactSupport: ContactSupport(phone: '', email: '', whatsapp: ''),
        ),
        platformInfo: PlatformInfo(name: 'Excellence Coaching Hub', description: '', contactEmail: '', contactPhone: ''),
      );
    }
  }

  /// Update platform settings (Admin only)
  Future<PlatformSettings> updateSettings(Map<String, dynamic> settingsData) async {
    try {
      final response = await _apiClient.put(
        ApiConfig.platformSettings,
        body: settingsData,
      );
      response.validateStatus();
      
      final jsonBody = jsonDecode(response.body) as Map<String, dynamic>;
      final data = jsonBody['data'] as Map<String, dynamic>;
      
      return PlatformSettings.fromJson(data);
    } catch (e) {
      if (e is ApiException) rethrow;
      throw ApiException('Failed to update platform settings: $e');
    }
  }
}
