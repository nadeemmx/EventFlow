import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    group('email', () {
      test('returns error for empty email', () {
        expect(Validators.email(''), isNotNull);
      });

      test('returns error for invalid email', () {
        expect(Validators.email('invalid'), isNotNull);
      });

      test('returns null for valid email', () {
        expect(Validators.email('test@example.com'), isNull);
      });
    });

    group('password', () {
      test('returns error for empty password', () {
        expect(Validators.password(''), isNotNull);
      });

      test('returns error for short password', () {
        expect(Validators.password('12345'), isNotNull);
      });

      test('returns null for valid password', () {
        expect(Validators.password('123456'), isNull);
      });
    });

    group('confirmPassword', () {
      test('returns error for empty confirmation', () {
        expect(Validators.confirmPassword('', 'pass'), isNotNull);
      });

      test('returns error when passwords do not match', () {
        expect(Validators.confirmPassword('pass1', 'pass2'), isNotNull);
      });

      test('returns null when passwords match', () {
        expect(Validators.confirmPassword('password', 'password'), isNull);
      });
    });

    group('mobile', () {
      test('returns error for empty mobile', () {
        expect(Validators.mobile(''), isNotNull);
      });

      test('returns error for short mobile', () {
        expect(Validators.mobile('12345'), isNotNull);
      });

      test('returns null for valid mobile', () {
        expect(Validators.mobile('9876543210'), isNull);
      });
    });

    group('required', () {
      test('returns error for empty value', () {
        expect(Validators.required(''), isNotNull);
      });

      test('returns null for non-empty value', () {
        expect(Validators.required('test'), isNull);
      });
    });

    group('positiveNumber', () {
      test('returns error for empty value', () {
        expect(Validators.positiveNumber(''), isNotNull);
      });

      test('returns error for zero', () {
        expect(Validators.positiveNumber('0'), isNotNull);
      });

      test('returns null for positive number', () {
        expect(Validators.positiveNumber('100'), isNull);
      });
    });
  });
}
