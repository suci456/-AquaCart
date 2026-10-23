class Validators {
  static final RegExp _emailRegExp = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  static final RegExp _phoneRegExp = RegExp(r'^[6-9]\d{9}$');

  // Indian 15-character GSTIN format:
  // 2 digits state code + 5 chars PAN + 4 digits PAN + 1 char entity + 1 char Z + 1 check digit
  static final RegExp _gstRegExp = RegExp(
    r'^[0-9]{2}[A-Z]{5}[0-9]{4}[A-Z]{1}[1-9A-Z]{1}Z[0-9A-Z]{1}$',
  );

  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email address is required';
    }
    final trimmed = value.trim();
    if (!_emailRegExp.hasMatch(trimmed)) {
      return 'Please enter a valid email address';
    }
    return null;
  }

  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required';
    }
    // Strip common prefixes like +91, 0, or spaces
    final cleaned = value.replaceAll(RegExp(r'[\s+()-]'), '').replaceFirst(RegExp(r'^91'), '');
    if (!_phoneRegExp.hasMatch(cleaned)) {
      return 'Please enter a valid 10-digit mobile number';
    }
    return null;
  }

  static String? validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Name is required';
    }
    if (value.trim().length < 2) {
      return 'Name must be at least 2 characters';
    }
    return null;
  }

  static String? validateGstNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'GSTIN is required for wholesale dealer verification';
    }
    final upper = value.trim().toUpperCase();
    if (upper.length != 15) {
      return 'GSTIN must be exactly 15 characters';
    }
    if (!_gstRegExp.hasMatch(upper)) {
      return 'Invalid GSTIN format (e.g. 29AABCU9603R1ZM)';
    }
    return null;
  }

  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName is required';
    }
    return null;
  }
}
