import 'package:flutter_test/flutter_test.dart';
import 'package:found404/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('rejects empty input', () {
      expect(Validators.email(''), isNotNull);
    });

    test('rejects malformed address', () {
      expect(Validators.email('not-an-email'), isNotNull);
    });

    test('accepts a well-formed address', () {
      expect(Validators.email('student@university.edu'), isNull);
    });
  });

  group('Validators.password', () {
    test('rejects short passwords', () {
      expect(Validators.password('123'), isNotNull);
    });

    test('accepts passwords meeting the minimum length', () {
      expect(Validators.password('longenoughpassword'), isNull);
    });
  });

  group('Validators.confirmPassword', () {
    test('rejects mismatched confirmation', () {
      expect(Validators.confirmPassword('abc', 'xyz'), isNotNull);
    });

    test('accepts matching confirmation', () {
      expect(Validators.confirmPassword('abc', 'abc'), isNull);
    });
  });
}
