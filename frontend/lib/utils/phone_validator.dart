import 'dart:io';

class PhoneValidator {
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove any non-digit characters except + for validation
    final cleanPhone = value.replaceAll(RegExp(r'[^\d+]'), '');
    
    // Allow numbers with or without country code (validates as local number)
    final digitsOnly = cleanPhone.replaceAll(RegExp(r'[^\d]'), '');
    
    // Check for specific country code requirements
    if (cleanPhone.startsWith('+7')) {
      // Kazakhstan and Russia require exactly 10 digits after +7
      final digitsAfterCountry = cleanPhone.substring(2);
      if (digitsAfterCountry.length != 10) {
        return 'Phone number must have exactly 10 digits for Kazakhstan/Russia (+7).';
      }
    } else if (cleanPhone.startsWith('+')) {
      // Other countries: generally 9-12 digits after country code
      final digitsAfterCountry = cleanPhone.substring(1);
      if (digitsAfterCountry.length < 9) {
        return 'Phone number is too short. Most countries require 9-12 digits after the country code.';
      }
      if (digitsAfterCountry.length > 12) {
        return 'Phone number is too long. Maximum 12 digits after country code.';
      }
    } else {
      // Local format (no country code): 7-12 digits
      if (digitsOnly.length < 7) {
        return 'Phone number is too short. Please enter a valid phone number.';
      }
      if (digitsOnly.length > 12) {
        return 'Phone number is too long. Maximum 12 digits allowed.';
      }
    }
    
    return null;
  }
  
  static String formatPhoneNumber(String phone) {
    // Remove any non-digit characters except +
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    // If it has a country code (+)
    if (cleanPhone.startsWith('+')) {
      // Strip leading zeros after the country code (common user mistake)
      // E.g., +0793... becomes +793...
      String afterPlus = cleanPhone.substring(1);
      afterPlus = afterPlus.replaceFirst(RegExp(r'^0+'), '');
      return '+$afterPlus';
    }
    
    // If it starts with 0, keep as local format
    if (cleanPhone.startsWith('0')) {
      return cleanPhone;
    }
    
    return cleanPhone;
  }
  
  static bool isValidPhoneNumber(String phone) {
    return validatePhone(phone) == null;
  }
  
  static String? getPhoneFormatError(String phone) {
    final cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    
    if (cleanPhone.startsWith('+')) {
      final digitsAfterPlus = cleanPhone.substring(1);
      final digitsWithoutLeadingZero = digitsAfterPlus.replaceFirst(RegExp(r'^0+'), '');
      
      if (digitsWithoutLeadingZero.length < 8) {
        return 'Phone number is too short. Most countries require 9-12 digits after the country code.';
      }
      if (digitsWithoutLeadingZero.length > 15) {
        return 'Phone number is too long. E.164 format requires max 15 digits.';
      }
    }
    
    return null;
  }
}
