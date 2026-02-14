/// Validation utilities for form inputs and data validation
class ValidationUtils {
  /// Validate that a string is not empty
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validate email format
  static String? validateEmail(String? email) {
    if (email == null || email.trim().isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(email.trim())) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  /// Validate password strength
  static String? validatePassword(String? password) {
    if (password == null || password.trim().isEmpty) {
      return 'Password is required';
    }
    
    if (password.trim().length < 6) {
      return 'Password must be at least 6 characters long';
    }
    
    return null;
  }

  /// Validate numeric value
  static String? validateNumber(String? value, String fieldName, {double? min, double? max}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    
    final number = double.tryParse(value.trim());
    if (number == null) {
      return '$fieldName must be a valid number';
    }
    
    if (min != null && number < min) {
      return '$fieldName must be at least $min';
    }
    
    if (max != null && number > max) {
      return '$fieldName must be no more than $max';
    }
    
    return null;
  }

  /// Validate positive number
  static String? validatePositiveNumber(String? value, String fieldName) {
    return validateNumber(value, fieldName, min: 0);
  }

  /// Validate that a list is not empty
  static String? validateNonEmptyList(List? list, String fieldName) {
    if (list == null || list.isEmpty) {
      return '$fieldName cannot be empty';
    }
    return null;
  }

  /// Validate phone number format
  static String? validatePhone(String? phone) {
    if (phone == null || phone.trim().isEmpty) {
      return null; // Phone is optional
    }
    
    // Simple phone validation - adjust regex as needed
    final phoneRegex = RegExp(r'^[\+]?[1-9][\d]{0,15}$');
    if (!phoneRegex.hasMatch(phone.trim())) {
      return 'Please enter a valid phone number';
    }
    
    return null;
  }

  /// Validate URL format
  static String? validateUrl(String? url) {
    if (url == null || url.trim().isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    if (!urlRegex.hasMatch(url.trim())) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  /// Validate minimum length
  static String? validateMinLength(String? value, String fieldName, int minLength) {
    if (value == null) {
      return '$fieldName is required';
    }
    
    if (value.trim().length < minLength) {
      return '$fieldName must be at least $minLength characters long';
    }
    
    return null;
  }

  /// Validate maximum length
  static String? validateMaxLength(String? value, String fieldName, int maxLength) {
    if (value == null) {
      return null;
    }
    
    if (value.trim().length > maxLength) {
      return '$fieldName must be no more than $maxLength characters long';
    }
    
    return null;
  }

  /// Combine multiple validators
  static String? combineValidators(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final result = validator(value);
      if (result != null) {
        return result;
      }
    }
    return null;
  }
}

/// Form validation result
class ValidationResult {
  final bool isValid;
  final String? errorMessage;
  final Map<String, String?> fieldErrors;

  ValidationResult({
    required this.isValid,
    this.errorMessage,
    this.fieldErrors = const {},
  });

  /// Create success result
  factory ValidationResult.success() {
    return ValidationResult(isValid: true);
  }

  /// Create error result
  factory ValidationResult.error(String errorMessage, [Map<String, String?>? fieldErrors]) {
    return ValidationResult(
      isValid: false,
      errorMessage: errorMessage,
      fieldErrors: fieldErrors ?? {},
    );
  }

  /// Check if a specific field has an error
  bool hasFieldError(String fieldName) {
    return fieldErrors[fieldName] != null;
  }

  /// Get error message for a specific field
  String? getFieldError(String fieldName) {
    return fieldErrors[fieldName];
  }
}
