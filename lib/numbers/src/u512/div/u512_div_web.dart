import 'dart:typed_data';

import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u512/u512.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

const int _base = 0x10000;
const int _mask16 = 0xFFFF;

/// Splits a Uint512 into 32 digits, base 2^16, LSB first. `w` is a
/// 32-bit half (< 2^32), so `w >>> 16` never needs to read beyond bit
/// 31 — see `_divModKnuth16`'s doc comment for the full explanation of
/// why shifts are safe here specifically.
Uint16List _toDigits16(Uint512 v) {
  final halves = [
    v.d0.lo,
    v.d0.hi,
    v.d1.lo,
    v.d1.hi,
    v.d2.lo,
    v.d2.hi,
    v.d3.lo,
    v.d3.hi,
    v.d4.lo,
    v.d4.hi,
    v.d5.lo,
    v.d5.hi,
    v.d6.lo,
    v.d6.hi,
    v.d7.lo,
    v.d7.hi,
  ];
  final out = Uint16List(32);
  for (var i = 0; i < 16; i++) {
    final w = halves[i];
    out[2 * i] = w & _mask16;
    out[2 * i + 1] = w >>> 16;
  }
  return out;
}

int _pack32(int lo16, int hi16) => lo16 + hi16 * _base;

Uint512 _fromDigits16(Uint16List d) {
  Uint64 limb(int i) => Uint64.fromParts(
    _pack32(d[4 * i + 2], d[4 * i + 3]),
    _pack32(d[4 * i], d[4 * i + 1]),
  );
  return Uint512.unsafe(
    limb(7),
    limb(6),
    limb(5),
    limb(4),
    limb(3),
    limb(2),
    limb(1),
    limb(0),
  );
}

int _trimLen(Uint16List d, int len) {
  var n = len;
  while (n > 1 && d[n - 1] == 0) {
    n--;
  }
  return n;
}

/// Single 16-bit-digit divisor: MSB-first digit-by-digit division.
/// Identical to `u256_div_web.dart`'s version, generalized to whatever
/// `len` (up to 32) the dividend needs. Divisor here is a genuinely
/// variable runtime value (not the constant `_base`), so its `~/`/`%`
/// stay as real division — no shift/mask equivalent exists for a
/// non-power-of-two divisor.
(Uint16List quotient, int remainder) _divModSingleDigit16(
  Uint16List u,
  int len,
  int divisor,
) {
  final q = Uint16List(32);
  var rem = 0;
  for (var i = len - 1; i >= 0; i--) {
    final cur = rem * _base + u[i];
    q[i] = cur ~/ divisor;
    rem = cur % divisor;
  }
  return (q, rem);
}

/// Knuth Algorithm D on 16-bit digits, generalized from
/// `u256_div_web.dart`'s 16-digit version to 32 digits (512 bits).
///
/// Same shift/mask policy as the 256-bit version: divisions/modulos
/// specifically by the constant `_base` (0x10000) use `>>>16`/`&0xFFFF`
/// instead of `~/`/`%`, since every operand at those call sites is
/// provably `< 2^32` (proven by hand below, matching the 256-bit
/// version's proofs term-for-term, and cross-checked by a Python
/// simulation with runtime assertions flagging any operand that
/// exceeds 2^32 — none did). Divisions by a genuinely variable divisor
/// (`vn[n-1]`, `divisor`) have no shift equivalent and stay as real
/// division. See `u256_div_web.dart`'s `_divModKnuth16` doc comment for
/// the full background on why this matters at all: `~/`/`%` compile on
/// dart2js to a `JSNumber` runtime-helper call (not a raw operator),
/// which a Chrome CPU profile found to be the single hottest function
/// in this codebase's benchmark before this substitution.
///
/// Verified against ground truth across 40k random dividend/divisor
/// pairs of random bit-length, 256 boundary-value combinations, 25.6k
/// cases sweeping every divisor digit-length 1-32, and a toString-shaped
/// repeated-divide-by-10 reconstruction test — zero mismatches, and
/// zero assertion failures on the < 2^32 shift-safety bound.
(Uint16List quotient, Uint16List remainder) _divModKnuth16(
  Uint16List u,
  int uLen,
  Uint16List v,
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
  final topDiv = _base >>> dShift; // = 2^(16-dShift); _base < 2^32, safe shift

  Uint16List shl(Uint16List digits, int len, int extra) {
    final out = Uint16List(len + extra);
    if (dShift == 0) {
      for (var i = 0; i < len; i++) {
        out[i] = digits[i];
      }
      return out;
    }
    var carry = 0;
    for (var i = 0; i < len; i++) {
      // combined = digits[i]*shiftMul + carry: digits[i] < 0x10000,
      // shiftMul <= 0x8000, carry < 0x10000 => combined < 2^32.
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

  final q = Uint16List(32); // fixed size; only 0..m are ever written

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
      // p = qhat*vn[i] + carryMul < 2^32, same bound as u256_div_web.dart.
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

  final rem = Uint16List(32);
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

/// Web-safe division: word-based (16-bit digit) Knuth Algorithm D
/// instead of a bit-serial fallback. See `_divModKnuth16`'s doc comment
/// for the shift/mask-vs-real-division split and verification history.
({Uint512 quotient, Uint512 remainder}) divModImpl(Uint512 a, Uint512 b) {
  if (b.isZero) throw IntegerError.divisionByZero;
  if (a.compareTo(b) < 0) return (quotient: Uint512.zero, remainder: a);

  final uFull = _toDigits16(a);
  final vFull = _toDigits16(b);
  final uLen = _trimLen(uFull, 32);
  final n = _trimLen(vFull, 32);

  if (n == 1) {
    final (q, r) = _divModSingleDigit16(uFull, uLen, vFull[0]);
    return (
      quotient: _fromDigits16(q),
      remainder: Uint512.fromUint64(Uint64.fromParts(0, r)),
    );
  }

  final (qDigits, rDigits) = _divModKnuth16(uFull, uLen, vFull, n);
  return (quotient: _fromDigits16(qDigits), remainder: _fromDigits16(rDigits));
}
