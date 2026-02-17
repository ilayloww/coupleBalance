enum PasswordValidationError { none, tooShort, missingUppercase, missingNumber }

class Validators {
  static PasswordValidationError validatePassword(String password) {
    if (password.length < 8) {
      return PasswordValidationError.tooShort;
    }
    if (!password.contains(RegExp(r'[A-Z]'))) {
      return PasswordValidationError.missingUppercase;
    }
    if (!password.contains(RegExp(r'[0-9]'))) {
      return PasswordValidationError.missingNumber;
    }
    return PasswordValidationError.none;
  }
}
