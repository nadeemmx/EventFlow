import 'package:flutter_test/flutter_test.dart';
import 'package:eventflow_app/core/utils/validators.dart';

void main() {
  group('Validators.email', () {
    test('returns null for valid email', () {
      expect(Validators.email('user@example.com'), null);
    });

    test('returns error for invalid email', () {
      expect(Validators.email('invalid-email'), 'Enter a valid email');
    });

    test('returns error for empty email', () {
      expect(Validators.email(''), 'Email is required');
    });

    test('returns error for null email', () {
      expect(Validators.email(null), 'Email is required');
    });
  });

  group('Validators.password', () {
    test('returns null for valid password', () {
      expect(Validators.password('Passw0rd!'), null);
    });

    test('returns error for too short password', () {
      expect(Validators.password('12345'), 'Password must be at least 8 characters');
    });

    test('returns error for empty password', () {
      expect(Validators.password(''), 'Password is required');
    });

    test('returns error for null password', () {
      expect(Validators.password(null), 'Password is required');
    });
  });

  group('Validators.confirmPassword', () {
    test('returns null when passwords match', () {
      expect(Validators.confirmPassword('password123', 'password123'), null);
    });

    test('returns error when passwords do not match', () {
      expect(Validators.confirmPassword('different', 'password123'), 'Passwords do not match');
    });

    test('returns error for empty confirm password', () {
      expect(Validators.confirmPassword('', 'password123'), 'Please confirm your password');
    });

    test('returns error for null confirm password', () {
      expect(Validators.confirmPassword(null, 'password123'), 'Please confirm your password');
    });
  });

  group('Validators.mobile', () {
    test('returns null for valid mobile', () {
      expect(Validators.mobile('9876543210'), null);
    });

    test('returns error for too short mobile', () {
      expect(Validators.mobile('12345'), 'Enter a valid mobile number');
    });

    test('returns error for empty mobile', () {
      expect(Validators.mobile(''), 'Mobile number is required');
    });

    test('returns error for null mobile', () {
      expect(Validators.mobile(null), 'Mobile number is required');
    });
  });

  group('Validators.required', () {
    test('returns null for non-empty value', () {
      expect(Validators.required('hello'), null);
    });

    test('returns error for empty value', () {
      expect(Validators.required(''), 'This field is required');
    });

    test('returns error for null value', () {
      expect(Validators.required(null), 'This field is required');
    });

    test('returns error for whitespace-only value', () {
      expect(Validators.required('   '), 'This field is required');
    });

    test('uses custom field name', () {
      expect(Validators.required(null, 'Name'), 'Name is required');
    });
  });
}
