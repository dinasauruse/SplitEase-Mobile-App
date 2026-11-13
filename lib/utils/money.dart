/// Result of parsing a text field into an integer value.
class ParseResult {
  const ParseResult.ok(this.value) : error = null;
  const ParseResult.fail(this.error) : value = null;

  final int? value;
  final String? error;

  bool get isValid => error == null;
}

/// Money and percentage helpers.
///
/// All money is stored as an integer number of "cents" (1/100 rupiah) and all
/// percentages as integer "hundredths of a percent" (10% == 1000). No `double`
/// is ever used for financial arithmetic, so there are no floating-point errors.
class Money {
  Money._();

  static final RegExp _decimalPattern = RegExp(r'^\d+(\.\d+)?$');
  static final RegExp _integerPattern = RegExp(r'^\d+$');

  /// Parses a non-negative amount with up to 2 decimals ("25000", "19.99")
  /// into cents. The decimal separator is a dot.
  static ParseResult parseMoney(
    String raw,
    String label, {
    int maxWholeDigits = 10,
  }) {
    return _parseScaled(raw, label, maxWholeDigits: maxWholeDigits);
  }

  /// Parses a percentage between 0 and 100 (up to 2 decimals) into hundredths
  /// of a percent.
  static ParseResult parsePercent(String raw, String label) {
    final tooLarge = '$label cannot be greater than 100.';
    final result = _parseScaled(
      raw,
      label,
      maxWholeDigits: 6,
      tooLargeMessage: tooLarge,
    );
    if (!result.isValid) return result;
    if (result.value! > 10000) return ParseResult.fail(tooLarge);
    return result;
  }

  /// Parses a quantity: a whole number from 1 to 999.
  static ParseResult parseQuantity(String raw) {
    final text = raw.trim();
    if (text.isEmpty) return const ParseResult.fail('Quantity is required.');
    if (text.startsWith('-')) {
      final rest = text.substring(1);
      if (_decimalPattern.hasMatch(rest)) {
        return const ParseResult.fail('Quantity cannot be negative.');
      }
      return const ParseResult.fail('Quantity must be a whole number.');
    }
    if (!_integerPattern.hasMatch(text)) {
      return const ParseResult.fail('Quantity must be a whole number.');
    }
    if (text.length > 6) {
      return const ParseResult.fail('Quantity cannot be greater than 999.');
    }
    final value = int.parse(text);
    if (value == 0) {
      return const ParseResult.fail('Quantity must be at least 1.');
    }
    if (value > 999) {
      return const ParseResult.fail('Quantity cannot be greater than 999.');
    }
    return ParseResult.ok(value);
  }

  static ParseResult _parseScaled(
    String raw,
    String label, {
    required int maxWholeDigits,
    String? tooLargeMessage,
  }) {
    final text = raw.trim();
    if (text.isEmpty) return ParseResult.fail('$label is required.');
    if (text.startsWith('-')) {
      final rest = text.substring(1);
      if (_decimalPattern.hasMatch(rest)) {
        return ParseResult.fail('$label cannot be negative.');
      }
      return ParseResult.fail('$label must be a number.');
    }
    if (!_decimalPattern.hasMatch(text)) {
      return ParseResult.fail('$label must be a number.');
    }
    final parts = text.split('.');
    final whole = parts[0];
    final fraction = parts.length > 1 ? parts[1] : '';
    if (fraction.length > 2) {
      return ParseResult.fail('$label allows at most 2 decimal places.');
    }
    if (whole.length > maxWholeDigits) {
      return ParseResult.fail(tooLargeMessage ?? '$label is too large.');
    }
    return ParseResult.ok(
      int.parse(whole) * 100 + int.parse(fraction.padRight(2, '0')),
    );
  }

  /// `amountCents * hundredths / 10000`, rounded half up to the nearest cent.
  static int percentOf(int amountCents, int percentHundredths) {
    return (amountCents * percentHundredths + 5000) ~/ 10000;
  }

  /// Indonesian Rupiah formatting: `Rp31.250`, `Rp1.250,50`.
  /// Decimals (2 digits) are only shown when the amount has a fraction.
  static String formatRupiah(int cents) {
    final negative = cents < 0;
    final abs = cents.abs();
    final whole = abs ~/ 100;
    final fraction = abs % 100;
    final digits = whole.toString();
    final buffer = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
      buffer.write(digits[i]);
    }
    final fractionText =
        fraction == 0 ? '' : ',${fraction.toString().padLeft(2, '0')}';
    return '${negative ? '-' : ''}Rp$buffer$fractionText';
  }

  /// Percentage formatting with a decimal comma: `10%`, `7,5%`.
  static String formatPercent(int hundredths) {
    final whole = hundredths ~/ 100;
    final fraction = hundredths % 100;
    if (fraction == 0) return '$whole%';
    final fractionText = fraction % 10 == 0
        ? (fraction ~/ 10).toString()
        : fraction.toString().padLeft(2, '0');
    return '$whole,$fractionText%';
  }
}
