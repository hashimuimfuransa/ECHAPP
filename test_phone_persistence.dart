import 'package:flutter_test/flutter_test.dart';
import 'package:excellencecoachinghub/config/storage_manager.dart';
import 'package:excellencecoachinghub/models/user.dart';

void main() {
  group('Phone Number Persistence Tests', () {
    late StorageManager storageManager;

    setUp(() {
      storageManager = StorageManager();
    });

    test('should save and retrieve phone number from storage', () async {
      const testPhone = '+1234567890';
      
      // Save phone number
      await storageManager.saveUserPhone(testPhone);
      
      // Retrieve phone number
      final retrievedPhone = await storageManager.getUserPhone();
      
      expect(retrievedPhone, equals(testPhone));
    });

    test('should handle null phone number', () async {
      // Save null phone number
      await storageManager.saveUserPhone(null);
      
      // Retrieve phone number
      final retrievedPhone = await storageManager.getUserPhone();
      
      expect(retrievedPhone, isNull);
    });

    test('should clear phone number when clearing all data', () async {
      const testPhone = '+1234567890';
      
      // Save phone number
      await storageManager.saveUserPhone(testPhone);
      
      // Verify it's saved
      expect(await storageManager.getUserPhone(), equals(testPhone));
      
      // Clear all data
      await storageManager.clearAll();
      
      // Verify phone number is cleared
      expect(await storageManager.getUserPhone(), isNull);
    });

    test('should create User object with phone from storage', () async {
      const testPhone = '+1234567890';
      const testRole = 'student';
      
      // Save test data
      await storageManager.saveUserPhone(testPhone);
      await storageManager.saveUserRole(testRole);
      
      // Create user object (simulating checkAuthStatus)
      final storedPhone = await storageManager.getUserPhone();
      final storedRole = await storageManager.getUserRole();
      
      final user = User(
        id: 'test-id',
        fullName: 'Test User',
        email: 'test@example.com',
        phone: storedPhone,
        role: storedRole ?? 'student',
        createdAt: DateTime.now(),
      );
      
      expect(user.phone, equals(testPhone));
      expect(user.role, equals(testRole));
    });
  });
}
