import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/rational/big_rational.dart';

import 'exception.dart';

class _AmountConverterConstants {
  static final BigRational bigR9 = BigRational(BigInt.from(10).pow(9));
  static final BigRational bigR8 = BigRational(BigInt.from(10).pow(8));
  static final BigRational bigR18 = BigRational(BigInt.from(10).pow(18));
  static final BigRational bigR6 = BigRational(BigInt.from(10).pow(6));
  static final BigRational bigR12 = BigRational(BigInt.from(10).pow(12));
  static final BigRational bigR10 = BigRational(BigInt.from(10).pow(10));
  static BigRational fromDecimalNumber(int decimal) {
    switch (decimal) {
      case 9:
        return bigR9;
      case 8:
        return bigR8;
      case 18:
        return bigR18;
      case 6:
        return bigR6;
      case 12:
        return bigR12;
      case 10:
        return bigR10;
      default:
        return BigRational(BigInt.from(10).pow(decimal));
    }
  }
}

/// Utility class for converting amounts between decimal and base units.
class AmountConverterUtils {
  /// Multiplies two decimal amounts and converts the result to base units.
  static BigInt converAmount({
    required String baseAmount,
    required String amount,
    required int decimals,
  }) {
    final BigRational? bPrice = BigRational.tryParseDecimaal(baseAmount);
    final BigRational? aPrice = BigRational.tryParseDecimaal(amount);
    if (bPrice == null || aPrice == null) {
      throw AmountConverterException(
          'Invalid amount format: cannot parse the input string.');
    }
    return toUnit(
        amount: (bPrice * aPrice).toDecimal(),
        decimals: decimals,
        enforceMaxDecimals: false);
  }

  /// Converts a decimal string to a base unit (BigInt) value.
  static BigInt toUnit({
    required String amount,
    required int decimals,
    bool enforceMaxDecimals = true,
  }) {
    BigRational? dec = BigRational.tryParseDecimaal(amount);
    if (dec == null) {
      throw AmountConverterException(
          'Invalid amount format: cannot parse the input string.',
          details: {"amount": amount});
    }
    if (enforceMaxDecimals && dec.scale > decimals) {
      throw AmountConverterException(
          'Invalid amount format: too many decimal places.');
    }
    dec = dec * _AmountConverterConstants.fromDecimalNumber(decimals);

    return dec.toBigInt();
  }

  /// Converts a base unit (BigInt) to a decimal string.
  static String toAmount({
    required BigInt unit,
    required int decimals,
    int? showDecimals = 8,
  }) {
    final BigRational dec = BigRational(unit) /
        _AmountConverterConstants.fromDecimalNumber(decimals);
    return dec.toDecimal(digits: showDecimals);
  }

  /// Converts a native asset amount to the chain’s decimal format.
  static BigInt convertDecimals({
    required BigInt amount,
    required int from,
    required int to,
  }) {
    final diff = to - from;
    if (diff == 0) return amount;
    final bigR = BigRational(amount);
    final diffR = BigRational(BigInt.from(10).pow((to - from).abs()));

    if (diff > 0) {
      // Scale up (e.g., 6 → 10)
      return (bigR * diffR).toBigInt();
    } else {
      // Scale down (e.g., 10 → 6)
      return (bigR / diffR).toBigInt();
    }
  }
}

/// Handles conversions between human-readable amounts and base units.
class AmountConverter {
  /// Number of decimal places used by the base unit (e.g., 8 for BTC).
  final int decimals;

  /// Maximum number of decimals to show when formatting display values.
  final int? displayPrecision;
  const AmountConverter._({required this.decimals, this.displayPrecision = 8});

  static const AmountConverter btc =
      AmountConverter._(decimals: 8, displayPrecision: 8);

  static const AmountConverter eth =
      AmountConverter._(decimals: 18, displayPrecision: 18);

  static const AmountConverter tron =
      AmountConverter._(decimals: 6, displayPrecision: 6);

  static const AmountConverter polkadot =
      AmountConverter._(decimals: 10, displayPrecision: 10);
  static const AmountConverter kusama =
      AmountConverter._(decimals: 12, displayPrecision: 12);

  static const AmountConverter sol =
      AmountConverter._(decimals: 9, displayPrecision: 9);

  static const AmountConverter xrp =
      AmountConverter._(decimals: 6, displayPrecision: 6);

  static const AmountConverter ada =
      AmountConverter._(decimals: 6, displayPrecision: 6);

  /// Creates a converter with the specified [decimals] and [displayPrecision].
  ///
  /// Throws [AmountConverterException] if:
  /// - [decimals] is negative or exceeds [mask8].
  /// - [displayPrecision] is negative.
  factory AmountConverter({required int decimals, int? displayPrecision = 8}) {
    if (decimals.isNegative || decimals > mask8) {
      throw AmountConverterException(
        'Invalid decimals value: must be between 0 and $mask8.',
      );
    }
    if (displayPrecision != null && displayPrecision.isNegative) {
      throw AmountConverterException(
          "Invalid displayPrecision value: must be non-negative.");
    }
    return AmountConverter._(
        decimals: decimals, displayPrecision: displayPrecision);
  }

  /// Converts a human-readable amount string to its base unit representation.
  ///
  /// Example: `"1.23"` → `123000000n` (with 8 decimals).
  ///
  /// [enforceMaxDecimals] If true, throws an exception when the input amount has more fractional
  /// digits than the allowed number of decimals.
  ///
  /// Example: For decimals = 2, "1.234" would trigger an exception.
  BigInt toUnit(String amount, {bool enforceMaxDecimals = true}) {
    return AmountConverterUtils.toUnit(
        amount: amount,
        decimals: decimals,
        enforceMaxDecimals: enforceMaxDecimals);
  }

  /// Converts a base unit value to a human-readable decimal string.
  ///
  /// Example: `123000000n` → `"1.23"` (with [displayPrecision]).
  String toAmount(BigInt unit) {
    return AmountConverterUtils.toAmount(
        unit: unit, decimals: decimals, showDecimals: displayPrecision);
  }
}
