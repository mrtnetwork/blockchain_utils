import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

class _BigRationalConst {
  static const int maxScale = 20;
}

/// Represents a rational number with arbitrary precision using BigInt for the numerator and denominator.
class BigRational {
  static final BigRational zero = BigRational.from(0);
  static final BigRational one = BigRational.from(1);
  static final BigRational ten = BigRational.from(10);
  final BigInt numerator;
  final BigInt denominator;
  String? _inDecimal;
  static final _one = BigInt.one;
  static final _zero = BigInt.zero;
  static final _ten = BigInt.from(10);
  List<int> encodeRational() {
    // Convert numerator and denominator to bytes
    final numeratorBytes = BigintUtils.toBytes(numerator, length: 2);
    final denominatorBytes = BigintUtils.toBytes(denominator, length: 2);

    // Concatenate numerator and denominator bytes
    final bytes = List<int>.from(numeratorBytes)..addAll(denominatorBytes);

    // Specify the endianness when converting to List<int>
    return bytes;
  }

  BigRational._(this.numerator, this.denominator);

  /// Constructs a BigRational instance from the given numerator and optional denominator.
  factory BigRational(BigInt numerator, {BigInt? denominator}) {
    if (denominator == null) {
      return BigRational._(numerator, _one);
    }
    if (denominator == _zero) {
      throw const ArgumentException("Denominator cannot be 0.");
    }
    if (numerator == _zero) {
      return BigRational._(_zero, _one);
    }
    return _reduce(numerator, denominator);
  }

  /// Constructs a BigRational instance from the given numerator and optional denominator as integers.
  factory BigRational.from(int numerator, {int? denominator}) {
    return BigRational(BigInt.from(numerator),
        denominator: BigInt.from(denominator ?? 1));
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

  static BigRational? tryParseDecimaal(String decimal) {
    try {
      return BigRational.parseDecimal(decimal);
    } catch (e) {
      return null;
    }
  }

  /// Parses a decimal string and constructs a BigRational instance from it.
  ///
  /// This method parses the given decimal string and constructs a BigRational representing the decimal value it contains.
  /// It supports parsing decimal strings in scientific, floating point, and integer notation.
  ///
  /// [decimal] The decimal string to be parsed.
  /// returns A BigRational instance representing the parsed decimal value.
  factory BigRational.parseDecimal(String decimal) {
    List<String> parts = decimal.split(RegExp(r'e', caseSensitive: false));
    if (parts.length > 2) {
      throw const ArgumentException("Invalid input: too many 'e' tokens");
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
      final BigRational exponent =
          BigRational._(_ten.pow(int.parse(parts[1])), _one);
      if (isPositive) {
        return significand * exponent;
      } else {
        return significand / exponent;
      }
    }

    parts = decimal.trim().split(".");
    if (parts.length > 2) {
      throw const ArgumentException("Invalid input: too many '.' tokens");
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
          parts[1].isEmpty ? _zero : BigInt.parse(parts[1]), BigInt.parse(exp));
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

  /// Adds the given BigRational to this BigRational and returns the result.
  ///
  /// [other] The BigRational to be added.
  /// returns A new BigRational representing the sum of this BigRational and the given BigRational.
  BigRational operator +(BigRational other) {
    final BigInt multiple = _lcm(denominator, other.denominator);
    BigInt a = multiple ~/ denominator;
    BigInt b = multiple ~/ other.denominator;

    a = numerator * a;
    b = other.numerator * b;

    return _reduce(a + b, multiple);
  }

  /// Multiplies this BigRational by the given BigRational and returns the result.
  ///
  /// [other] The BigRational to be multiplied by.
  /// returns A new BigRational representing the product of this BigRational and the given BigRational.
  BigRational operator *(BigRational other) {
    final BigInt resultNumerator = numerator * other.numerator;
    final BigInt resultDenominator = denominator * other.denominator;

    return _reduce(resultNumerator, resultDenominator);
  }

  /// Divides this BigRational by the given BigRational and returns the result.
  ///
  /// [other] The BigRational to divide by.
  /// returns A new BigRational representing the quotient of this BigRational and the given BigRational.
  BigRational operator /(BigRational other) {
    final BigInt resultNumerator = numerator * other.denominator;
    final BigInt resultDenominator = denominator * other.numerator;

    return _reduce(resultNumerator, resultDenominator);
  }

  /// Negates this BigRational and returns the result.
  BigRational operator -() {
    return BigRational._(-numerator, denominator);
  }

  /// Subtracts the given BigRational from this BigRational and returns the result.
  ///
  /// [other] The BigRational to be subtracted.
  /// returns A new BigRational representing the difference between this BigRational and the given BigRational.
  BigRational operator -(BigRational other) {
    return this + ~other;
  }

  /// Computes the remainder of dividing this BigRational by the given BigRational and returns the result.
  ///
  /// [other] The divisor BigRational.
  /// returns A new BigRational representing the remainder of the division operation.
  BigRational operator %(BigRational other) {
    BigRational re = remainder(other);
    if (isNegative) {
      re += other.abs();
    }
    return re;
  }

  /// Compares this BigRational with the given BigRational and returns true if this BigRational is less than the given BigRational.
  ///
  /// [other] The BigRational to compare with.
  /// returns true if this BigRational is less than the given BigRational; otherwise, false.
  bool operator <(BigRational other) {
    return compareTo(other) < 0;
  }

  /// Checks if this BigRational is less than or equal to the given BigRational.
  ///
  /// [other] The BigRational to compare with.
  /// returns true if this BigRational is less than or equal to the given BigRational; otherwise, false.
  bool operator <=(BigRational other) {
    return compareTo(other) <= 0;
  }

  /// Checks if this BigRational is greater than the given BigRational.
  ///
  /// [other] The BigRational to compare with.
  /// returns true if this BigRational is greater than the given BigRational; otherwise, false.
  bool operator >(BigRational other) {
    return compareTo(other) > 0;
  }

  /// Checks if this BigRational is greater than or equal to the given BigRational.
  ///
  /// [other] The BigRational to compare with.
  /// returns true if this BigRational is greater than or equal to the given BigRational; otherwise, false.
  bool operator >=(BigRational other) {
    return compareTo(other) >= 0;
  }

  /// Performs integer division on this BigRational by the given BigRational and returns the result as a BigRational.
  ///
  /// [other] The divisor BigRational.
  /// Returns a new BigRational representing the integer division of this BigRational by the given BigRational.
  BigRational operator ~/(BigRational other) {
    final BigInt divmod = _truncate;
    final BigInt rminder = _remainder;
    BigInt floor;

    if (rminder == _zero || !divmod.isNegative) {
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

  /// Rounds this BigRational towards zero and returns the result as a BigRational.
  BigRational operator ~() {
    if (denominator.isNegative) {
      return BigRational._(numerator, -denominator);
    }
    return BigRational._(-numerator, denominator);
  }

  /// Raises this BigRational to the power of n and returns the result as a BigRational.
  ///
  /// [n] The exponent.
  /// Returns a new BigRational representing the result of raising this BigRational to the power of n.
  BigRational pow(int n) {
    final BigInt num = numerator.pow(n);
    final BigInt denom = denominator.pow(n);
    return _reduce(num, denom);
  }

  /// Rounds this BigRational towards positive infinity and returns the result as a BigRational.
  ///
  /// Returns a new BigRational representing the ceiling of this BigRational.
  BigRational ceil(toBigInt) {
    final BigInt divmod = _truncate;
    final BigInt remind = _remainder;
    BigInt ceil;

    if (remind == _zero || divmod.isNegative) {
      ceil = divmod;
    } else {
      ceil = divmod + _one;
    }

    return BigRational._(ceil, _one);
  }

  /// Compares this BigRational with the given BigRational and returns an integer representing the result.
  ///
  /// [v] The BigRational to compare with.
  /// Returns 0 if this BigRational is equal to the given BigRational, 1 if this BigRational is greater, and -1 if this BigRational is less.
  int compareTo(BigRational v) {
    if (denominator == v.denominator) {
      return numerator.compareTo(v.numerator);
    }
    final int comparison =
        (denominator.isNegative == v.denominator.isNegative) ? 1 : -1;
    return comparison *
        (numerator * v.denominator).compareTo(v.numerator * denominator);
  }

  BigRational abs() {
    if (isPositive) return this;
    return ~this;
  }

  /// Checks if this BigRational is negative.
  ///
  /// Returns true if this BigRational is negative; otherwise, false.
  bool get isNegative {
    return (numerator.isNegative != denominator.isNegative) &&
        numerator != _zero;
  }

  /// Checks if this BigRational is positive.
  ///
  /// Returns true if this BigRational is positive; otherwise, false.
  bool get isPositive {
    return (numerator.isNegative == denominator.isNegative) &&
        numerator != _zero;
  }

  /// Checks if this BigRational is zero.
  ///
  /// Returns true if this BigRational is zero; otherwise, false.
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

// Returns the remainder of division of this BigRational by the given BigRational.
  ///
  /// [other] The divisor
  /// Returns a new BigRational representing the remainder of the division.
  BigRational remainder(BigRational other) {
    return this - (this ~/ other) * other;
  }

  /// Gets the remainder of the division of the numerator by the denominator.
  ///
  /// Returns the remainder of the division as a BigInt.
  BigInt get _remainder {
    return numerator.remainder(denominator);
  }

  /// Gets the result of truncating the division of the numerator by the denominator.
  ///
  /// Returns the truncated division result as a BigInt.
  BigInt get _truncate {
    return numerator ~/ denominator;
  }

  /// Converts this BigRational to its decimal representation.
  ///
  /// [digits] The number of digits after the decimal point (default is the scale of the BigRational).
  /// Returns a string representing the decimal value, with the specified number of digits after the decimal point.
  String toDecimal({int? digits}) {
    if (digits == null && _inDecimal != null) {
      return _inDecimal!;
    }
    digits ??= scale;
    final BigInt nDive = _truncate;
    final BigInt nReminder = _remainder;
    String intPart = nDive.abs().toString();
    final BigRational remainder = _reduce(nReminder.abs(), denominator);
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

  /// Gets the precision of this BigRational, which is the total number of significant digits.
  ///
  /// Returns an integer representing the precision of this BigRational.
  int get precision {
    final toAbs = abs();
    return toAbs.scale + toAbs.toBigInt().toString().length;
  }

  /// Gets the scale of this BigRational, which is the number of decimal places.
  ///
  /// Returns an integer representing the scale of this BigRational.
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
  bool operator ==(other) {
    return other is BigRational &&
        other.denominator == denominator &&
        other.numerator == numerator;
  }

  @override
  int get hashCode => numerator.hashCode ^ denominator.hashCode;
}
