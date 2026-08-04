/// Form-field validators shared across features (register/login, create
/// post, claim forms, etc). Each returns a user-facing error string, or
/// `null` when the value is valid — matching Flutter's `FormField.validator`
/// signature so these can be passed straight through.
class Validators {
  Validators._();

  static final RegExp _emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

  static String? required(String? value, {String fieldName = 'This field'}) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  /// Only Sunway student mail is accepted, so every account belongs to a real
  /// member of the campus community (NFR04/NFR05). This is only the first of
  /// two checks — Firestore security rules reject non-campus accounts on the
  /// server as well, because a client-side check alone can be bypassed.
  static const String campusEmailDomain = '@imail.sunway.edu.my';

  static String? email(String? value) {
    if (value == null || value.trim().isEmpty) return 'Email is required';
    final email = value.trim().toLowerCase();
    if (!_emailPattern.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    if (!email.endsWith(campusEmailDomain)) {
      return 'Use your Sunway email ($campusEmailDomain)';
    }
    return null;
  }

  static String? password(String? value, {int minLength = 8}) {
    if (value == null || value.isEmpty) return 'Password is required';
    if (value.length < minLength) {
      return 'Password must be at least $minLength characters';
    }
    return null;
  }

  static String? confirmPassword(String? value, String originalPassword) {
    if (value == null || value.isEmpty) return 'Please confirm your password';
    if (value != originalPassword) return 'Passwords do not match';
    return null;
  }

  static String? minLength(
    String? value,
    int min, {
    String fieldName = 'This field',
  }) {
    if (value == null || value.trim().length < min) {
      return '$fieldName must be at least $min characters';
    }
    return null;
  }

  static String? maxLength(
    String? value,
    int max, {
    String fieldName = 'This field',
  }) {
    if (value != null && value.trim().length > max) {
      return '$fieldName must be at most $max characters';
    }
    return null;
  }
}
