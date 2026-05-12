import 'dart:io';

class PhoneValidator {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters except + for validation
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanPhone.length < 10) {
      return 'Please enter a valid phone number (at least 10 digits)';
    }
    
    // Basic international phone format validation
    if (!cleanPhone.startsWith('+') && !cleanPhone.startsWith('0')) {
      return 'Please enter a valid phone number with country code (e.g., +1234567890)';
    }
    
    // Additional validation for specific patterns
    if (cleanPhone.startsWith('+')) {
      // International format: +[country_code][number]
      final countryCode = cleanPhone.substring(1, cleanPhone.length - 9);
      final phoneNumber = cleanPhone.substring(cleanPhone.length - 9);
      
      if (countryCode.isEmpty || phoneNumber.length != 9) {
        return 'Please enter a valid international phone number';
      }
    } else if (cleanPhone.startsWith('0')) {
      // Local format: 0[number]
      if (cleanPhone.length < 10) {
        return 'Please enter a valid local phone number';
      }
    }
    
    return null;
  }
  
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it doesn't have a country code and starts with 0, keep as is
    if (cleanPhone.startsWith('0')) {
      return cleanPhone;
    }
    
    // If it has a country code, ensure it starts with +
    if (!cleanPhone.startsWith('+') && cleanPhone.length >= 10) {
      // Assume it's a local number, add common country code if needed
      // This can be customized based on the target region
      return cleanPhone;
    }
    
    return cleanPhone;
  }
  
  static bool isValidPhoneNumber(String phone) {
    return validatePhone(phone) == null;
  }
}
