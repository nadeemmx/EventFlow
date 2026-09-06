class Validators {
  static String? email(String? value) {
    if (value == null || value.isEmpty) return 'Email is required';
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) return 'Enter a valid email';
    return null;
  }

  static String? password(String? value) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < 8) return 'Password must be at least 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(value)) return 'Password must contain an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(value)) return 'Password must contain a lowercase letter';
    if (!RegExp(r'[0-9]').hasMatch(value)) return 'Password must contain a number';
    if (!RegExp(r'[^a-zA-Z0-9]').hasMatch(value)) {
      return 'Password must contain a special character';
    }
    return null;
  }

  static String? confirmPassword(String? value, String password) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != password) return 'Passwords do not match';
    return null;
  }

  static String? mobile(String? value) {
    if (value == null || value.isEmpty) return 'Mobile number is required';
    if (value.length < 10) return 'Enter a valid mobile number';
    return null;
  }

  static String? required(String? value, [String field = 'This field']) {
    if (value == null || value.trim().isEmpty) return '$field is required';
    return null;
  }

  static String? positiveNumber(String? value, [String field = 'Value']) {
    if (value == null || value.isEmpty) return '$field is required';
    final num = double.tryParse(value);
    if (num == null || num <= 0) return '$field must be a positive number';
    return null;
  }
}
