import 'package:flutter_test/flutter_test.dart';
import 'package:aquacart/core/utils/validators.dart';

void main() {
  group('Validators Unit Tests', () {
    test('validateEmail correctly accepts valid emails and rejects invalid ones', () {
      // Valid emails
      expect(Validators.validateEmail('customer@aquacart.in'), isNull);
      expect(Validators.validateEmail('user.name+tag@example.co.uk'), isNull);
      expect(Validators.validateEmail('dealer123@domain.org'), isNull);

      // Invalid emails
      expect(Validators.validateEmail(''), isNotNull);
      expect(Validators.validateEmail(null), isNotNull);
      expect(Validators.validateEmail('plainaddress'), isNotNull);
      expect(Validators.validateEmail('@missingusername.com'), isNotNull);
      expect(Validators.validateEmail('username@.com'), isNotNull);
    });

    test('validatePassword requires at least 6 characters', () {
      expect(Validators.validatePassword('123456'), isNull);
      expect(Validators.validatePassword('superSecurePass!'), isNull);

      expect(Validators.validatePassword(''), isNotNull);
      expect(Validators.validatePassword(null), isNotNull);
      expect(Validators.validatePassword('12345'), isNotNull);
    });

    test('validatePhone correctly validates Indian 10-digit mobile numbers', () {
      expect(Validators.validatePhone('9876543210'), isNull);
      expect(Validators.validatePhone('+91 98765 43210'), isNull);
      expect(Validators.validatePhone('8877665544'), isNull);

      expect(Validators.validatePhone(''), isNotNull);
      expect(Validators.validatePhone(null), isNotNull);
      expect(Validators.validatePhone('12345'), isNotNull);
      expect(Validators.validatePhone('5555555555'), isNotNull); // Doesn't start with 6-9
    });

    test('validateGstNumber validates 15-character GSTIN format', () {
      // Valid GSTINs
      expect(Validators.validateGstNumber('29AABCU9603R1ZM'), isNull);
      expect(Validators.validateGstNumber('33AAACB1234F1ZQ'), isNull);

      // Invalid GSTINs
      expect(Validators.validateGstNumber(''), isNotNull);
      expect(Validators.validateGstNumber(null), isNotNull);
      expect(Validators.validateGstNumber('SHORTGST'), isNotNull);
      expect(Validators.validateGstNumber('INVALID_GSTIN_123'), isNotNull);
    });

    test('validateName enforces non-empty names', () {
      expect(Validators.validateName('Rahul Sharma'), isNull);
      expect(Validators.validateName('A'), isNotNull);
      expect(Validators.validateName(''), isNotNull);
      expect(Validators.validateName(null), isNotNull);
    });
  });
}
