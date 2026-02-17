import 'package:flutter_test/flutter_test.dart';
import 'package:couple_balance/utils/validators.dart';

void main() {
  group('Password Validation', () {
    test('returns tooShort when password is less than 8 characters', () {
      expect(
        Validators.validatePassword('Abc1'),
        PasswordValidationError.tooShort,
      );
      expect(
        Validators.validatePassword('Abcdef1'),
        PasswordValidationError.tooShort,
      );
    });

    test('returns missingUppercase when no uppercase letter is present', () {
      expect(
        Validators.validatePassword('abcdefg1'),
        PasswordValidationError.missingUppercase,
      );
    });

    test('returns missingNumber when no number is present', () {
      expect(
        Validators.validatePassword('Abcdefgh'),
        PasswordValidationError.missingNumber,
      );
    });

    test('returns none when password is valid', () {
      expect(
        Validators.validatePassword('Abcdefg1'),
        PasswordValidationError.none,
      );
      expect(
        Validators.validatePassword('StrongP@ssw0rd'),
        PasswordValidationError.none,
      );
    });
  });
}
