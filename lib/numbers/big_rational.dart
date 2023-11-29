import 'package:blockchain_utils/exception/exception.dart';

class BigRational {
  final BigInt numerator;
  final BigInt denominator;
  static final _one = BigInt.one;
  static final _zero = BigInt.zero;
  static final _ten = BigInt.from(10);
  BigRational._(this.numerator, this.denominator);

  factory BigRational(BigInt numerator, [BigInt? denominator]) {
    if (denominator == null) {
      return BigRational._(numerator, _one);
    }
    if (denominator == _zero) {
      throw ArgumentException("Denominator cannot be 0.");
    }
    if (numerator == _zero) {
      return BigRational._(_zero, _one);
    }
    return _reduce(numerator, denominator);
  }
  factory BigRational.from(int numerator, [int? denominator]) {
    return BigRational(BigInt.from(numerator), BigInt.from(denominator ?? 1));
  }
  static BigInt _gcd(BigInt a, BigInt b) {
    BigInt t;
    while (b != _zero) {
      t = b;
      b = a % b;
      a = t;
    }
    return a;
  }

  static BigInt _lcm(BigInt a, BigInt b) {
    return (a * b) ~/ _gcd(a, b);
  }

  factory BigRational.parseDecimal(String n) {
    List<String> parts = n.split(RegExp(r'e', caseSensitive: false));
    if (parts.length > 2) {
      throw ArgumentException("Invalid input: too many 'e' tokens");
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

    parts = n.trim().split(".");
    if (parts.length > 2) {
      throw ArgumentException("Invalid input: too many '.' tokens");
    }
    if (parts.length > 1) {
      bool isNegative = parts[0][0] == '-';
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

    return BigRational._(BigInt.parse(n), _one);
  }
  factory BigRational.parse(String v) {
    List<String> texts = v.split("/");
    if (texts.length > 2) {
      throw ArgumentException("Invalid input: too many '/' tokens");
    }

    if (texts.length > 1) {
      final List<String> parts = texts[0].split("_");
      if (parts.length > 2) {
        throw ArgumentException("Invalid input: too many '_' tokens");
      }

      if (parts.length > 1) {
        final bool isPositive = parts[0][0] != "-";
        BigInt numerator = BigInt.parse(parts[0]) * BigInt.parse(texts[1]);
        if (isPositive) {
          numerator += BigInt.parse(parts[1]);
        } else {
          numerator -= BigInt.parse(parts[1]);
        }
        return _reduce(numerator, BigInt.parse(texts[1]));
      }

      return _reduce(BigInt.parse(texts[0]), BigInt.parse(texts[1]));
    }

    return BigRational.parseDecimal(v);
  }
  BigInt toBigInt() {
    return _truncate;
  }

  double toDouble() {
    return numerator / denominator;
  }

  BigRational operator +(BigRational other) {
    final BigInt multiple = _lcm(denominator, other.denominator);
    BigInt a = multiple ~/ denominator;
    BigInt b = multiple ~/ other.denominator;

    a = numerator * a;
    b = other.numerator * b;

    return _reduce(a + b, multiple);
  }

  BigRational operator *(BigRational other) {
    final BigInt resultNumerator = numerator * other.numerator;
    final BigInt resultDenominator = denominator * other.denominator;

    return _reduce(resultNumerator, resultDenominator);
  }

  BigRational operator /(BigRational other) {
    final BigInt resultNumerator = numerator * other.denominator;
    final BigInt resultDenominator = denominator * other.numerator;

    return _reduce(resultNumerator, resultDenominator);
  }

  BigRational operator -() {
    return BigRational._(-numerator, denominator);
  }

  BigRational operator -(BigRational other) {
    return this + ~other;
  }

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

  BigRational operator ~/(BigRational other) {
    BigInt divmod = _truncate;
    BigInt rminder = _remainder;
    BigInt floor;

    if (rminder == _zero || !divmod.isNegative) {
      floor = divmod;
    } else {
      floor = divmod - _one;
    }
    return BigRational._(floor, _one);
  }

  BigRational operator ~() {
    if (denominator.isNegative) {
      return BigRational._(numerator, -denominator);
    }
    return BigRational._(-numerator, denominator);
  }

  BigRational pow(int n) {
    final BigInt num = numerator.pow(n);
    final BigInt denom = denominator.pow(n);
    return _reduce(num, denom);
  }

  BigRational ceil(toBigInt) {
    BigInt divmod = _truncate;
    BigInt remind = _remainder;
    BigInt ceil;

    if (remind == _zero || divmod.isNegative) {
      ceil = divmod;
    } else {
      ceil = divmod + _one;
    }

    return BigRational._(ceil, _one);
  }

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

  BigRational remainder(BigRational other) {
    return this - (this ~/ other) * other;
  }

  BigInt get _remainder {
    return numerator.remainder(denominator);
  }

  BigInt get _truncate {
    return numerator ~/ denominator;
  }

  String toDecimal({int digits = 10}) {
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

  @override
  bool operator ==(other) {
    return other is BigRational &&
        other.denominator == denominator &&
        other.numerator == numerator;
  }

  @override
  int get hashCode => Object.hash(numerator, denominator);
  @override
  String toString() {
    if (denominator == _one) {
      return toDecimal();
    }
    return '$numerator/$denominator';
  }
}
