/// Input validation utilities for forms and user input
///
/// Provides reusable validation functions for:
/// - Email addresses
/// - Passwords
/// - Prices
/// - Barcodes
/// - General text fields
library validators;

import '../constants/app_constants.dart';

/// Validates email addresses
class EmailValidator {
  /// Validates an email address
  ///
  /// Returns null if valid, error message string if invalid
  static String? validate(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your email';
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Please enter your email';
    }

    // RFC 5322 simplified regex
    final emailRegex = RegExp(ValidationConstants.emailPattern);

    if (!emailRegex.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }

    // Check for common typos
    if (trimmed.contains('..')) {
      return 'Email address cannot contain consecutive dots';
    }

    if (trimmed.startsWith('.') || trimmed.endsWith('.')) {
      return 'Email address cannot start or end with a dot';
    }

    return null;
  }

  /// Checks if an email is valid without returning error message
  static bool isValid(String? value) {
    return validate(value) == null;
  }
}

/// Validates passwords
class PasswordValidator {
  /// Validates a password
  ///
  /// Returns null if valid, error message string if invalid
  static String? validate(String? value, {bool requireStrong = false}) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }

    if (value.length < ValidationConstants.minPasswordLength) {
      return 'Password must be at least ${ValidationConstants.minPasswordLength} characters';
    }

    if (value.length > ValidationConstants.maxPasswordLength) {
      return 'Password must be less than ${ValidationConstants.maxPasswordLength} characters';
    }

    // Strong password requirements (optional)
    if (requireStrong) {
      if (!RegExp(r'[A-Z]').hasMatch(value)) {
        return 'Password must contain at least one uppercase letter';
      }

      if (!RegExp(r'[a-z]').hasMatch(value)) {
        return 'Password must contain at least one lowercase letter';
      }

      if (!RegExp(r'[0-9]').hasMatch(value)) {
        return 'Password must contain at least one number';
      }

      if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) {
        return 'Password must contain at least one special character';
      }
    }

    return null;
  }

  /// Validates password confirmation matches original
  static String? validateConfirmation(String? password, String? confirmation) {
    if (confirmation == null || confirmation.isEmpty) {
      return 'Please confirm your password';
    }

    if (password != confirmation) {
      return 'Passwords do not match';
    }

    return null;
  }

  /// Checks if a password is valid without returning error message
  static bool isValid(String? value, {bool requireStrong = false}) {
    return validate(value, requireStrong: requireStrong) == null;
  }

  /// Calculates password strength (0-100)
  static int calculateStrength(String? value) {
    if (value == null || value.isEmpty) return 0;

    int strength = 0;

    // Length score (max 30 points)
    strength += (value.length * 3).clamp(0, 30);

    // Character variety scores
    if (RegExp(r'[a-z]').hasMatch(value)) strength += 10; // Lowercase
    if (RegExp(r'[A-Z]').hasMatch(value)) strength += 15; // Uppercase
    if (RegExp(r'[0-9]').hasMatch(value)) strength += 15; // Numbers
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(value)) strength += 20; // Special chars

    // Bonus for no repeating characters
    if (!RegExp(r'(.)\1{2,}').hasMatch(value)) strength += 10;

    return strength.clamp(0, 100);
  }
}

/// Validates prices
class PriceValidator {
  /// Validates a price input
  ///
  /// Returns null if valid, error message string if invalid
  static String? validate(String? value, {
    double? min,
    double? max,
    bool allowZero = false,
  }) {
    if (value == null || value.isEmpty) {
      return 'Please enter a price';
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return 'Please enter a price';
    }

    // Try to parse as double
    final price = double.tryParse(trimmed);

    if (price == null) {
      return 'Please enter a valid number';
    }

    // Check if it's a valid price format (max 2 decimal places)
    if (trimmed.contains('.')) {
      final parts = trimmed.split('.');
      if (parts.length > 2 || (parts.length == 2 && parts[1].length > 2)) {
        return 'Maximum 2 decimal places allowed';
      }
    }

    // Check minimum value
    final minValue = min ?? (allowZero ? 0.0 : ValidationConstants.minPrice);
    if (price < minValue) {
      if (allowZero && price == 0) {
        return null; // Allow zero if explicitly enabled
      }
      return 'Price must be at least \$${minValue.toStringAsFixed(2)}';
    }

    // Check maximum value
    final maxValue = max ?? ValidationConstants.maxPrice;
    if (price > maxValue) {
      return 'Price cannot exceed \$${maxValue.toStringAsFixed(2)}';
    }

    // Warn about unusually high values (but don't fail validation)
    if (price > 1000 && max == null) {
      return 'Price seems unusually high. Please verify.';
    }

    return null;
  }

  /// Validates a price as a double value
  static String? validateValue(double? value, {
    double? min,
    double? max,
    bool allowZero = false,
  }) {
    if (value == null) {
      return 'Please enter a price';
    }

    return validate(value.toString(), min: min, max: max, allowZero: allowZero);
  }

  /// Checks if a price is valid without returning error message
  static bool isValid(String? value, {double? min, double? max}) {
    return validate(value, min: min, max: max) == null;
  }

  /// Formats a price string to standard currency format
  static String format(double value) {
    return '\$${value.toStringAsFixed(2)}';
  }
}

/// Validates barcodes
class BarcodeValidator {
  /// Validates a barcode
  ///
  /// Returns null if valid, error message string if invalid
  static String? validate(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a barcode' : null;
    }

    final trimmed = value.trim();

    if (trimmed.isEmpty) {
      return required ? 'Please enter a barcode' : null;
    }

    // Remove any spaces or dashes
    final cleaned = trimmed.replaceAll(RegExp(r'[\s-]'), '');

    // Check length (EAN-8, UPC-12, EAN-13, ISBN-13 are most common)
    if (cleaned.length < ValidationConstants.minBarcodeLength) {
      return 'Barcode must be at least ${ValidationConstants.minBarcodeLength} digits';
    }

    if (cleaned.length > ValidationConstants.maxBarcodeLength) {
      return 'Barcode must be less than ${ValidationConstants.maxBarcodeLength} digits';
    }

    // Check if all characters are digits
    if (!RegExp(r'^\d+$').hasMatch(cleaned)) {
      return 'Barcode must contain only numbers';
    }

    // Common barcode formats: UPC (12), EAN (8 or 13), ISBN (10 or 13)
    final validLengths = [8, 10, 12, 13];
    if (!validLengths.contains(cleaned.length)) {
      return 'Invalid barcode length. Expected 8, 10, 12, or 13 digits';
    }

    return null;
  }

  /// Checks if a barcode is valid without returning error message
  static bool isValid(String? value) {
    return validate(value, required: false) == null;
  }

  /// Cleans a barcode by removing spaces and dashes
  static String clean(String value) {
    return value.replaceAll(RegExp(r'[\s-]'), '');
  }

  /// Formats a barcode with dashes for readability
  static String format(String value) {
    final cleaned = clean(value);
    if (cleaned.length == 12) {
      // UPC-A format: XXX-XXX-XXX-XXX
      return '${cleaned.substring(0, 3)}-${cleaned.substring(3, 6)}-${cleaned.substring(6, 9)}-${cleaned.substring(9)}';
    } else if (cleaned.length == 13) {
      // EAN-13 format: XX-XXXXX-XXXXX-X
      return '${cleaned.substring(0, 2)}-${cleaned.substring(2, 7)}-${cleaned.substring(7, 12)}-${cleaned.substring(12)}';
    }
    return cleaned;
  }
}

/// Validates general text input
class TextValidator {
  /// Validates required text field
  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }

  /// Validates text length
  static String? length(
    String? value, {
    int? min,
    int? max,
    String fieldName = 'This field',
  }) {
    if (value == null || value.isEmpty) {
      if (min != null && min > 0) {
        return '$fieldName is required';
      }
      return null;
    }

    if (min != null && value.length < min) {
      return '$fieldName must be at least $min characters';
    }

    if (max != null && value.length > max) {
      return '$fieldName must be less than $max characters';
    }

    return null;
  }

  /// Validates alphanumeric text
  static String? alphanumeric(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.isEmpty) {
      return null;
    }

    if (!RegExp(r'^[a-zA-Z0-9\s]+$').hasMatch(value)) {
      return '$fieldName must contain only letters and numbers';
    }

    return null;
  }

  /// Validates URL format
  static String? url(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a URL' : null;
    }

    try {
      final uri = Uri.parse(value);
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return 'Please enter a valid URL starting with http:// or https://';
      }
      if (!uri.hasAuthority) {
        return 'Please enter a valid URL with a domain name';
      }
    } catch (e) {
      return 'Please enter a valid URL';
    }

    return null;
  }

  /// Validates phone number (basic)
  static String? phone(String? value, {bool required = false}) {
    if (value == null || value.isEmpty) {
      return required ? 'Please enter a phone number' : null;
    }

    // Remove common formatting characters
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]+'), '');

    // Check if it's all digits (optionally with + prefix)
    if (!RegExp(r'^\+?\d{10,15}$').hasMatch(cleaned)) {
      return 'Please enter a valid phone number';
    }

    return null;
  }
}

/// Composite validator for combining multiple validations
class CompositeValidator {
  /// Runs multiple validators and returns the first error found
  static String? validate(String? value, List<String? Function(String?)> validators) {
    for (final validator in validators) {
      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }
}
