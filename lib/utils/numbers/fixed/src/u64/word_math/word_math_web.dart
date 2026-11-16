import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/word_math/word_math_native.dart' as native;

/// Opts into real 64-bit-int math on the VM instead of the portable
/// (web-safe) algorithms in this file.
const bool useNativeWordMath = bool.fromEnvironment(
  "BLOCKCHAIN_UTILS_NATIVE_MATH",
  defaultValue: false,
);

/// `a * b` as a 128-bit result split into (high, low) 64-bit halves.
(Uint64 hi, Uint64 lo) widenMulImpl(Uint64 a, Uint64 b) {
  if (useNativeWordMath) return native.widenMulImpl(a, b);
  return Uint64.widenMulPortable(a, b);
}

const int _base = 0x10000;
const int _mask16 = 0xFFFF;

/// Splits a Uint64 into 4 base-2^16 digits, LSB first.
List<int> _toDigits16(Uint64 v) {
  final out = List<int>.filled(4, 0);
  out[0] = v.lo & _mask16;
  out[1] = v.lo >>> 16;
  out[2] = v.hi & _mask16;
  out[3] = v.hi >>> 16;
  return out;
}

int _pack32(int lo16, int hi16) => lo16 + hi16 * _base;

Uint64 _fromDigits16(List<int> d) =>
    Uint64.fromParts(_pack32(d[2], d[3]), _pack32(d[0], d[1]));

int _trimLen(List<int> d, int len) {
  var n = len;
  while (n > 1 && d[n - 1] == 0) {
    n--;
  }
  return n;
}

/// Single-digit divisor: MSB-first long division, base 2^16.
(List<int> quotient, int remainder) _divModSingleDigit16(
  List<int> u,
  int len,
  int divisor,
) {
  final q = List<int>.filled(4, 0);
  var rem = 0;
  for (var i = len - 1; i >= 0; i--) {
    final cur = rem * _base + u[i];
    q[i] = cur ~/ divisor;
    rem = cur % divisor;
  }
  return (q, rem);
}

/// Knuth Algorithm D long division on base-2^16 digits. Divisions by
/// the constant `_base` use shifts/masks instead of `~/`/`%` (faster on
/// dart2js); the variable divisor `vn[n-1]` has no shift equivalent and
/// stays real division.
(List<int> quotient, List<int> remainder) _divModKnuth16(
  List<int> u,
  int uLen,
  List<int> v,
  int n,
) {
  final m = uLen - n;

  var dShift = 0;
  var top = v[n - 1];
  while (top < 0x8000) {
    top *= 2;
    dShift++;
  }
  var shiftMul = 1;
  for (var i = 0; i < dShift; i++) {
    shiftMul *= 2;
  }
  final topDiv = _base >>> dShift;

  List<int> shl(List<int> digits, int len, int extra) {
    final out = List<int>.filled(len + extra, 0);
    if (dShift == 0) {
      for (var i = 0; i < len; i++) {
        out[i] = digits[i];
      }
      return out;
    }
    var carry = 0;
    for (var i = 0; i < len; i++) {
      final combined = digits[i] * shiftMul + carry;
      out[i] = combined & _mask16;
      carry = combined >>> 16;
    }
    if (extra > 0) {
      out[len] = carry;
    }
    return out;
  }

  final vn = shl(v, n, 0);
  final un = shl(u, uLen, 1);

  final q = List<int>.filled(4, 0); // fixed size; only 0..m are ever written

  for (var j = m; j >= 0; j--) {
    final num = un[j + n] * _base + un[j + n - 1];
    var qhat = num ~/ vn[n - 1]; // variable divisor: real division
    var rhat = num % vn[n - 1]; // variable divisor: real division
    if (qhat > _mask16) {
      qhat = _mask16;
      rhat = num - qhat * vn[n - 1];
    }

    while (rhat <= _mask16) {
      final lhs = qhat * vn[n - 2];
      final rhs = rhat * _base + un[j + n - 2];
      if (lhs <= rhs) break;
      qhat -= 1;
      rhat += vn[n - 1];
    }

    var borrow = 0;
    var carryMul = 0;
    for (var i = 0; i < n; i++) {
      final p = qhat * vn[i] + carryMul;
      carryMul = p >>> 16;
      final pLo = p & _mask16;
      var t = un[j + i] - pLo - borrow;
      if (t < 0) {
        t += _base;
        borrow = 1;
      } else {
        borrow = 0;
      }
      un[j + i] = t;
    }
    var t = un[j + n] - carryMul - borrow;
    if (t < 0) {
      t += _base;
      borrow = 1;
    } else {
      borrow = 0;
    }
    un[j + n] = t;

    if (borrow != 0) {
      qhat -= 1;
      var carryAdd = 0;
      for (var i = 0; i < n; i++) {
        final s = un[j + i] + vn[i] + carryAdd;
        un[j + i] = s & _mask16;
        carryAdd = s >>> 16;
      }
      un[j + n] = (un[j + n] + carryAdd) & _mask16;
    }

    q[j] = qhat;
  }

  final rem = List<int>.filled(4, 0);
  if (dShift == 0) {
    for (var i = 0; i < n; i++) {
      rem[i] = un[i];
    }
  } else {
    for (var i = 0; i < n; i++) {
      var w = un[i] >>> dShift;
      if (i + 1 < n) {
        w += (un[i + 1] * topDiv) & _mask16;
      }
      rem[i] = w & _mask16;
    }
  }

  return (q, rem);
}

/// Unsigned 64-bit division: `a ~/ b` and `a % b`.
({Uint64 quotient, Uint64 remainder}) divModImpl(Uint64 a, Uint64 b) {
  if (useNativeWordMath) return native.divModImpl(a, b);
  if (b.isZero) throw CoreErrors.integerDivisionByZero;
  if (a.compareTo(b) < 0) return (quotient: Uint64.zero, remainder: a);

  final uFull = _toDigits16(a);
  final vFull = _toDigits16(b);
  final uLen = _trimLen(uFull, 4);
  final n = _trimLen(vFull, 4);

  if (n == 1) {
    final (q, r) = _divModSingleDigit16(uFull, uLen, vFull[0]);
    return (quotient: _fromDigits16(q), remainder: Uint64.from(r));
  }

  final (qDigits, rDigits) = _divModKnuth16(uFull, uLen, vFull, n);
  return (quotient: _fromDigits16(qDigits), remainder: _fromDigits16(rDigits));
}
