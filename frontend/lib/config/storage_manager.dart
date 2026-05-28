import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:convert';

class StorageManager {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );


  static const String _userRoleKey = 'user_role';
  static const String _userIdKey = 'user_id';
  static const String _accessTokenKey = 'access_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const String _userPhoneKey = 'user_phone';
  static const String _userNameKey = 'user_name';
  static const String _userAvatarKey = 'user_avatar';
  static const String _userInterestsKey = 'user_interests';
  static const String _userShortTermGoalKey = 'user_short_term_goal';
  static const String _userMidTermGoalKey = 'user_mid_term_goal';
  static const String _userLongTermGoalKey = 'user_long_term_goal';
  static const String _hasCompletedOnboardingKey = 'has_completed_onboarding';

  // Firebase handles authentication tokens internally

  Future<void> saveUserRole(String role) async {
    await _storage.write(key: _userRoleKey, value: role);
  }

  Future<String?> getUserRole() async {
    return await _storage.read(key: _userRoleKey);
  }

  Future<void> saveUserId(String userId) async {
    await _storage.write(key: _userIdKey, value: userId);
  }

  Future<String?> getUserId() async {
    return await _storage.read(key: _userIdKey);
  }

  Future<void> saveAccessToken(String token) async {
    await _storage.write(key: _accessTokenKey, value: token);
  }

  Future<String?> getAccessToken() async {
    return await _storage.read(key: _accessTokenKey);
  }

  Future<void> saveRefreshToken(String token) async {
    await _storage.write(key: _refreshTokenKey, value: token);
  }

  Future<String?> getRefreshToken() async {
    return await _storage.read(key: _refreshTokenKey);
  }

  Future<void> saveUserPhone(String? phone) async {
    if (phone != null) {
      await _storage.write(key: _userPhoneKey, value: phone);
    }
  }

  Future<String?> getUserPhone() async {
    return await _storage.read(key: _userPhoneKey);
  }

  Future<void> saveUserName(String? name) async {
    if (name != null) {
      await _storage.write(key: _userNameKey, value: name);
    }
  }

  Future<String?> getUserName() async {
    return await _storage.read(key: _userNameKey);
  }

  Future<void> saveUserAvatar(String? avatar) async {
    if (avatar != null) {
      await _storage.write(key: _userAvatarKey, value: avatar);
    }
  }

  Future<String?> getUserAvatar() async {
    return await _storage.read(key: _userAvatarKey);
  }

  Future<void> saveUserInterests(List<String>? interests) async {
    if (interests != null) {
      await _storage.write(key: _userInterestsKey, value: jsonEncode(interests));
    }
  }

  Future<List<String>?> getUserInterests() async {
    final value = await _storage.read(key: _userInterestsKey);
    if (value != null) {
      try {
        return List<String>.from(jsonDecode(value));
      } catch (e) {
        return null;
      }
    }
    return null;
  }

  Future<void> saveUserShortTermGoal(String? goal) async {
    if (goal != null) {
      await _storage.write(key: _userShortTermGoalKey, value: goal);
    }
  }

  Future<String?> getUserShortTermGoal() async {
    return await _storage.read(key: _userShortTermGoalKey);
  }

  Future<void> saveUserMidTermGoal(String? goal) async {
    if (goal != null) {
      await _storage.write(key: _userMidTermGoalKey, value: goal);
    }
  }

  Future<String?> getUserMidTermGoal() async {
    return await _storage.read(key: _userMidTermGoalKey);
  }

  Future<void> saveUserLongTermGoal(String? goal) async {
    if (goal != null) {
      await _storage.write(key: _userLongTermGoalKey, value: goal);
    }
  }

  Future<String?> getUserLongTermGoal() async {
    return await _storage.read(key: _userLongTermGoalKey);
  }
Future<void> saveHasCompletedOnboarding(bool completed) async {
    await _storage.write(key: _hasCompletedOnboardingKey, value: completed.toString());
  }

  Future<bool> hasCompletedOnboarding() async {
    final value = await _storage.read(key: _hasCompletedOnboardingKey);
    return value == 'true';
  }

  Future<void> clearOnboarding() async {
    await _storage.delete(key: _hasCompletedOnboardingKey);
  }

  
  // Clear all stored data
  Future<void> clearAll() async {
    await _storage.delete(key: _userRoleKey);
    await _storage.delete(key: _userIdKey);
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _hasCompletedOnboardingKey);
    await _storage.delete(key: _userPhoneKey);
    await _storage.delete(key: _userNameKey);
    await _storage.delete(key: _userAvatarKey);
    await _storage.delete(key: _userInterestsKey);
    await _storage.delete(key: _userShortTermGoalKey);
    await _storage.delete(key: _userMidTermGoalKey);
    await _storage.delete(key: _userLongTermGoalKey);
  }

  // Generic key-value helpers
  Future<String?> getItem(String key) async {
    return await _storage.read(key: key);
  }

  Future<void> saveItem(String key, String value) async {
    await _storage.write(key: key, value: value);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final userId = await getUserId();
    return userId != null && userId.isNotEmpty;
  }
}

// Provider for StorageManager
final storageManagerProvider = Provider<StorageManager>((ref) => StorageManager());
