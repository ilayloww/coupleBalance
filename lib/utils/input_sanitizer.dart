/// Centralized input sanitization utilities.
///
/// Use these helpers before writing any user-supplied strings to Firestore
/// to prevent injection, excessive storage costs, and UI rendering issues.
class InputSanitizer {
  InputSanitizer._();

  /// Strips control characters (except newline/tab) from [input].
  /// This prevents invisible Unicode control chars from being stored.
  static String stripControlChars(String input) {
    // Remove C0/C1 control characters except \n (0x0A) and \t (0x09)
    return input.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F\x7F]'), '');
  }

  /// Trims whitespace and strips control characters.
  static String sanitize(String input) {
    return stripControlChars(input.trim());
  }

  /// Sanitizes and truncates to [maxLength].
  static String sanitizeAndTruncate(String input, int maxLength) {
    final cleaned = sanitize(input);
    return cleaned.length > maxLength
        ? cleaned.substring(0, maxLength)
        : cleaned;
  }

  /// Validates that [amount] is within acceptable bounds.
  /// Returns null if valid, or an error message string.
  static String? validateAmount(double amount) {
    if (amount <= 0) return 'Amount must be greater than zero.';
    if (amount >= 1000000) return 'Amount must be less than 1,000,000.';
    return null;
  }

  /// Validates that [note] is within the max length.
  /// Returns null if valid, or an error message string.
  static String? validateNote(String note, {int maxLength = 500}) {
    if (note.length > maxLength) {
      return 'Text is too long (max $maxLength characters).';
    }
    return null;
  }

  /// Validates that [displayName] is acceptable.
  /// Returns null if valid, or an error message string.
  static String? validateDisplayName(String displayName) {
    if (displayName.isEmpty) return 'Display name cannot be empty.';
    if (displayName.length > 100) {
      return 'Display name is too long (max 100 characters).';
    }
    return null;
  }
}
