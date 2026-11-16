import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/equatable/equatable.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Cap on how many decimal places [BigRational.scale] will compute.
class _BigRationalConst {
  static const int maxScale = 20;
}

/// Represents a rational number with arbitrary precision using BigInt for the numerator and denominator.
class BigRational with Equality {
  static final BigRational zero = BigRational.from(0);
  static final BigRational one = BigRational.from(1);
  static final BigRational ten = BigRational.from(10);
  final BigInt numerator;
  final BigInt denominator;
  String? _inDecimal;
  static final _one = BigInt.one;
  static final _zero = BigInt.zero;
  static final _ten = BigInt.from(10);

  /// Encodes numerator and denominator as fixed 2-byte big-endian values.
  /// NOTE: only correct for values that fit in 2 bytes — not suitable for
  /// arbitrary-precision numerators/denominators.
  BuBytes encodeRational() {
    final numeratorBytes = numerator.toBeBytes(length: 2);
    final denominatorBytes = denominator.toBeBytes(length: 2);
    return BuBytes.concat([numeratorBytes, denominatorBytes]);
  }

  BigRational._(this.numerator, this.denominator);

  /// Constructs a BigRational instance from the given numerator and optional denominator.
  factory BigRational(BigInt numerator, {BigInt? denominator}) {
    if (denominator == null) {
      return BigRational._(numerator, _one);
    }
    if (denominator == _zero) {
      throw CoreErrors.invalidOperationArguments(
        "BigRational",
        name: "denominator",
        reason: "Denominator cannot be 0.",
      );
    }
    if (numerator == _zero) {
      return BigRational._(_zero, _one);
    }
    return _reduce(numerator, denominator);
  }

  /// Constructs a BigRational instance from the given numerator and optional denominator as integers.
  factory BigRational.from(int numerator, {int? denominator}) {
    return BigRational(
      BigInt.from(numerator),
      denominator: BigInt.from(denominator ?? 1),
    );
  }

  /// Constructs a BigRational from a [double], exactly.
  ///
  /// Expands the IEEE-754 bit pattern (mantissa × 2^exp) instead of going
  /// through float formatting: `toString`/`toStringAsFixed` render exponents
  /// past 1e21 and `toInt` overflows past 2^63, so neither survives huge
  /// values (e.g. indexer balances in exponent form, which JSON decodes to
  /// double). Fractional values keep their exact binary value as
  /// numerator/denominator.
  ///
  /// Throws [ArgumentException] for NaN and infinities.
  factory BigRational.fromDouble(double value) {
    if (value.isNaN || value.isInfinite) {
      throw CoreErrors.invalidOperationArguments(
        "fromDouble",
        name: "value",
        reason: "NaN and infinities cannot be represented as BigRational.",
      );
    }
    if (value == 0) return BigRational._(_zero, _one);

    // Read as two 32-bit words (getUint64 is unsupported on the web).
    final data = ByteData(8)..setFloat64(0, value, Endian.big);
    final hi = data.getUint32(0, Endian.big);
    final lo = data.getUint32(4, Endian.big);

    final negative = hi >= 0x80000000;
    final biasedExp = (hi & 0x7FFFFFFF) >> 20; // 11 bits
    final mantHi = hi & 0xFFFFF; // top 20 bits of the 52-bit fraction

    var mantissa = (BigInt.from(mantHi) << 32) | BigInt.from(lo);
    if (biasedExp != 0) {
      mantissa |= BigInt.one << 52; // implicit leading bit (normal numbers)
    }
    // Subnormals (biasedExp == 0) use exponent -1074 with no implicit bit.
    final exp = (biasedExp == 0 ? 1 : biasedExp) - 1075;

    final signedMantissa = negative ? -mantissa : mantissa;
    if (exp >= 0) return BigRational(signedMantissa << exp);
    return BigRational(signedMantissa, denominator: _one << (-exp));
  }

  /// Finds the greatest common divisor of two BigInt numbers a and b.
  static BigInt _gcd(BigInt a, BigInt b) {
    BigInt t;
    while (b != _zero) {
      t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  /// Finds the least common multiple of two BigInt numbers a and b.
  static BigInt _lcm(BigInt a, BigInt b) {
    return (a * b) ~/ _gcd(a, b);
  }

  static BigRational? tryParse(String decimal) {
    try {
      return BigRational.parseDecimal(decimal);
    } catch (e) {
      return null;
    }
  }

  /// Parses a decimal string (integer, floating-point, or scientific
  /// notation) into a [BigRational].
  factory BigRational.parseDecimal(String decimal) {
    List<String> parts = decimal.split(RegExp(r'e', caseSensitive: false));
    if (parts.length > 2) {
      throw CoreErrors.invalidOperationArguments(
        "parseDecimal",
        name: "decimal",

        reason: "Invalid decimals.",
      );
    }

    if (parts.length > 1) {
      bool isPositive = true;
      if (parts[1][0] == "-") {
        parts[1] = parts[1].substring(1);
        isPositive = false;
      }
      if (parts[1][0] == "+") {
        parts[1] = parts[1].substring(1);
      }
      final BigRational significand = BigRational.parseDecimal(parts[0]);
      final BigRational exponent = BigRational._(
        _ten.pow(int.parse(parts[1])),
        _one,
      );
      if (isPositive) {
        return significand * exponent;
      } else {
        return significand / exponent;
      }
    }

    parts = decimal.trim().split(".");
    if (parts.length > 2) {
      throw CoreErrors.invalidOperationArguments(
        "parseDecimal",
        name: "decimal",
        reason: "Invalid decimals.",
      );
    }
    if (parts.length > 1) {
      final bool isNegative = parts[0][0] == '-';
      if (isNegative) parts[0] = parts[0].substring(1);
      BigRational intPart = BigRational._(BigInt.parse(parts[0]), _one);
      final int length = parts[1].length;
      while (parts[1].isNotEmpty && parts[1][0] == "0") {
        parts[1] = parts[1].substring(1);
      }

      final String exp = "1${"0" * length}";
      final BigRational decPart = _reduce(
        parts[1].isEmpty ? _zero : BigInt.parse(parts[1]),
        BigInt.parse(exp),
      );
      intPart = intPart + decPart;
      if (isNegative) intPart = ~intPart;
      return intPart;
    }

    return BigRational._(BigInt.parse(decimal), _one);
  }

  /// Converts the BigRational to a BigInt.
  BigInt toBigInt() {
    return _truncate;
  }

  /// Converts the BigRational to a double.
  double toDouble() {
    return numerator / denominator;
  }

  /// Adds [other] to this value.
  BigRational operator +(BigRational other) {
    final BigInt multiple = _lcm(denominator, other.denominator);
    BigInt a = multiple ~/ denominator;
    BigInt b = multiple ~/ other.denominator;

    a = numerator * a;
    b = other.numerator * b;

    return _reduce(a + b, multiple);
  }

  /// Multiplies this value by [other].
  BigRational operator *(BigRational other) {
    final BigInt resultNumerator = numerator * other.numerator;
    final BigInt resultDenominator = denominator * other.denominator;

    return _reduce(resultNumerator, resultDenominator);
  }

  /// Divides this value by [other].
  BigRational operator /(BigRational other) {
    final BigInt resultNumerator = numerator * other.denominator;
    final BigInt resultDenominator = denominator * other.numerator;

    return _reduce(resultNumerator, resultDenominator);
  }

  /// Negates this BigRational and returns the result.
  BigRational operator -() {
    return BigRational._(-numerator, denominator);
  }

  /// Subtracts [other] from this value.
  BigRational operator -(BigRational other) {
    return this + ~other;
  }

  /// Euclidean remainder of dividing this value by [other] (always non-negative).
  BigRational operator %(BigRational other) {
    BigRational re = remainder(other);
    if (isNegative) {
      re += other.abs();
    }
    return re;
  }

  bool operator <(BigRational other) {
    return compareTo(other) < 0;
  }

  bool operator <=(BigRational other) {
    return compareTo(other) <= 0;
  }

  bool operator >(BigRational other) {
    return compareTo(other) > 0;
  }

  bool operator >=(BigRational other) {
    return compareTo(other) >= 0;
  }

  /// Floor division of this value by [other].
  BigRational operator ~/(BigRational other) {
    final BigInt divmod = _truncate;
    final BigInt rem = _remainder;
    BigInt floor;

    if (rem == _zero || !divmod.isNegative) {
      floor = divmod;
    } else {
      floor = divmod - _one;
    }
    return BigRational._(floor, _one);
  }

  /// Returns the floor of the BigRational as a BigRational with denominator 1
  BigRational floor() {
    BigInt flooredNumerator;

    if (numerator.isNegative && denominator.isNegative) {
      // Both numerator and denominator are negative: treat as positive
      flooredNumerator = numerator.abs() ~/ denominator.abs();
    } else if (numerator.isNegative || denominator.isNegative) {
      // One of them is negative: result will be negative
      flooredNumerator =
          (numerator.abs() ~/ denominator.abs()) * BigInt.from(-1) - BigInt.one;
    } else {
      // Both are positive: simple integer division
      flooredNumerator = numerator ~/ denominator;
    }

    // Return the floored value as a BigRational with denominator 1
    return BigRational(flooredNumerator, denominator: BigInt.one);
  }

  /// Negates this BigRational (keeping the denominator non-negative).
  BigRational operator ~() {
    if (denominator.isNegative) {
      return BigRational._(numerator, -denominator);
    }
    return BigRational._(-numerator, denominator);
  }

  /// Raises this value to the power of [n].
  BigRational pow(int n) {
    final BigInt num = numerator.pow(n);
    final BigInt denom = denominator.pow(n);
    return _reduce(num, denom);
  }

  /// Rounds this value towards positive infinity.
  BigRational ceil() {
    final BigInt divmod = _truncate;
    final BigInt rem = _remainder;
    BigInt ceil;

    if (rem == _zero || divmod.isNegative) {
      ceil = divmod;
    } else {
      ceil = divmod + _one;
    }

    return BigRational._(ceil, _one);
  }

  /// Compares this value to [v]: -1, 0, or 1.
  int compareTo(BigRational v) {
    if (denominator == v.denominator) {
      return numerator.compareTo(v.numerator);
    }
    final int comparison =
        (denominator.isNegative == v.denominator.isNegative) ? 1 : -1;
    return comparison *
        (numerator * v.denominator).compareTo(v.numerator * denominator);
  }

  /// Absolute value of this BigRational.
  BigRational abs() {
    if (isPositive) return this;
    return ~this;
  }

  bool get isNegative {
    return (numerator.isNegative != denominator.isNegative) &&
        numerator != _zero;
  }

  bool get isPositive {
    return (numerator.isNegative == denominator.isNegative) &&
        numerator != _zero;
  }

  bool get isZero {
    return numerator == _zero;
  }

  static BigRational _reduce(BigInt n, BigInt d) {
    final BigInt divisor = _gcd(n, d);
    final BigInt num = n ~/ divisor;
    final BigInt denom = d ~/ divisor;
    if (denom.isNegative) {
      return BigRational._(-num, -denom);
    }
    return BigRational._(num, denom);
  }

  /// Remainder of dividing this value by [other] (same sign as the dividend).
  BigRational remainder(BigRational other) {
    return this - (this ~/ other) * other;
  }

  /// Remainder of dividing the numerator by the denominator.
  BigInt get _remainder {
    return numerator.remainder(denominator);
  }

  /// Truncated division of the numerator by the denominator.
  BigInt get _truncate {
    return numerator ~/ denominator;
  }

  /// Converts this value to a decimal string, with [digits] digits after
  /// the decimal point (defaults to [scale]).
  String toDecimal({int? digits}) {
    if (digits == null && _inDecimal != null) {
      return _inDecimal!;
    }
    digits ??= scale;
    final BigInt truncated = _truncate;
    final BigInt remainderPart = _remainder;
    String intPart = truncated.abs().toString();
    final BigRational remainder = _reduce(remainderPart.abs(), denominator);
    final BigRational shiftedRemainder =
        remainder * BigRational._(_ten.pow(digits), _one);
    final BigInt decPart =
        shiftedRemainder.numerator ~/ shiftedRemainder.denominator;
    if (isNegative) {
      intPart = "-$intPart";
    }
    if (decPart == _zero) {
      return intPart;
    }

    String decPartStr = decPart.abs().toString();
    if (decPartStr.length < digits) {
      decPartStr = '0' * (digits - decPartStr.length) + decPartStr;
    }
    if ((shiftedRemainder.numerator % shiftedRemainder.denominator) == _zero) {
      while (decPartStr.endsWith('0')) {
        decPartStr = decPartStr.substring(0, decPartStr.length - 1);
      }
    }

    if (digits < 1) {
      return intPart;
    }

    return '$intPart${decPart < _zero ? '' : '.'}$decPartStr';
  }

  bool get isDecimal => denominator != _one;

  @override
  String toString() {
    _inDecimal ??= toDecimal();
    return _inDecimal!;
  }

  /// Total number of significant digits.
  int get precision {
    final toAbs = abs();
    return toAbs.scale + toAbs.toBigInt().toString().length;
  }

  /// Number of decimal places needed to represent this value exactly
  /// (capped at [_BigRationalConst.maxScale]).
  int get scale {
    int scale = 0;
    BigRational r = this;
    while (r.denominator != BigInt.one) {
      scale++;
      r *= ten;
      if (scale >= _BigRationalConst.maxScale) break;
    }
    return scale;
  }

  @override
  List<dynamic> get variables => [denominator, numerator];
}
