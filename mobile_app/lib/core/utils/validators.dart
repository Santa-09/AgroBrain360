class V {
  static String? email(String? v) {
    if (v == null || v.trim().isEmpty) return 'Email is required';
    final normalized = v.trim();
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(normalized)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  static String? phone(String? v) {
    if (v == null || v.isEmpty) return 'Phone number required';
    if (!RegExp(r'^[6-9]\d{9}$').hasMatch(v.replaceAll(RegExp(r'\s'), '')))
      return 'Enter valid 10-digit mobile number';
    return null;
  }

  static String? password(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 6) return 'Minimum 6 characters';
    return null;
  }

  static String? strongPassword(String? v) {
    if (v == null || v.isEmpty) return 'Password required';
    if (v.length < 8) return 'Minimum 8 characters';
    if (!RegExp(r'[A-Z]').hasMatch(v)) return 'Add an uppercase letter';
    if (!RegExp(r'[a-z]').hasMatch(v)) return 'Add a lowercase letter';
    if (!RegExp(r'\d').hasMatch(v)) return 'Add a number';
    if (!RegExp(r'[^A-Za-z0-9]').hasMatch(v)) return 'Add a special character';
    return null;
  }

  static String? name(String? v) {
    if (v == null || v.trim().isEmpty) return 'Name required';
    if (v.trim().length < 2) return 'Name too short';
    return null;
  }

  static String? required(String? v, [String f = 'This field']) {
    if (v == null || v.trim().isEmpty) return '$f is required';
    return null;
  }
}
