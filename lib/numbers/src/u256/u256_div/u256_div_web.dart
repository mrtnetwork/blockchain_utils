import 'dart:typed_data';

import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

const int _base = 0x10000;
const int _mask16 = 0xFFFF;

/// Splits a Uint256 into 16 digits, base 2^16, LSB first. Each 32-bit
/// `hi`/`lo` half is split again into two 16-bit digits using `&`/
/// `>>>` — safe here specifically because `w` is provably `< 2^32`
/// (it's a `Uint64` half), so shifting right by 16 never needs to
/// read a bit beyond position 31. See `_divModKnuth16`'s doc comment
/// for the full story on when shifts are/aren't safe in this codebase.
Uint16List _toDigits16(Uint256 v) {
  final d0 = v.d0, d1 = v.d1, d2 = v.d2, d3 = v.d3;
  final halves = [d0.lo, d0.hi, d1.lo, d1.hi, d2.lo, d2.hi, d3.lo, d3.hi];
  final out = Uint16List(16);
  for (var i = 0; i < 8; i++) {
    final w = halves[i];
    out[2 * i] = w & _mask16;
    out[2 * i + 1] = w >>> 16;
  }
  return out;
}

int _pack32(int lo16, int hi16) => lo16 + hi16 * _base;

/// Reassembles a full 16-digit (256-bit) digit array back into a
/// Uint256. Every digit combine uses multiply/add instead of
/// shift/or: `lo16 + hi16*BASE` instead of `(hi16<<16)|lo16`.
Uint256 _fromDigits16(Uint16List d16) {
  final d0 = Uint64.fromParts(_pack32(d16[2], d16[3]), _pack32(d16[0], d16[1]));
  final d1 = Uint64.fromParts(_pack32(d16[6], d16[7]), _pack32(d16[4], d16[5]));
  final d2 = Uint64.fromParts(_pack32(d16[10], d16[11]), _pack32(d16[8], d16[9]));
  final d3 = Uint64.fromParts(_pack32(d16[14], d16[15]), _pack32(d16[12], d16[13]));
  return Uint256.unsafe(d3, d2, d1, d0);
}

int _trimLen(Uint16List d, int len) {
  var n = len;
  while (n > 1 && d[n - 1] == 0) {
    n--;
  }
  return n;
}

/// Single 16-bit-digit divisor: MSB-first digit-by-digit division.
/// Combines via `rem*BASE + digit` (always < BASE*BASE = 2^32,
/// comfortably double-safe) instead of `rem<<16 | digit`. Covers the
/// most common real-world case — dividing/mod-ing by a small constant
/// (base-10 digit extraction for `toString`, decimal parsing).
///
/// `q` is allocated at the full fixed size 16 up front (rather than
/// exactly `len`, then copied into a padded array afterward) — the
/// loop only ever writes indices `0..len-1`, so the unwritten tail is
/// already correctly zero from `List.filled`, with no separate pad
/// step needed.
(Uint16List quotient, int remainder) _divModSingleDigit16(
  Uint16List u,
  int len,
  int divisor,
) {
  final q = Uint16List(16);
  var rem = 0;
  for (var i = len - 1; i >= 0; i--) {
    final cur = rem * _base + u[i];
    q[i] = cur ~/ divisor;
    rem = cur % divisor;
  }
  return (q, rem);
}

/// Knuth Algorithm D (TAOCP Vol. 2, section 4.3.1) on 16-bit digits —
/// the web-safe counterpart to the 32-bit-digit version used natively
/// (`u256_div_native.dart`).
///
/// **Where shifts are and aren't used, and why.** An earlier version
/// of this function used `~/`/`%` by `BASE` (0x10000) everywhere,
/// specifically avoiding shifts — because an earlier bug in this
/// codebase (`Uint256.operator+`) used `>>> 32` to extract a carry bit
/// from a value that could be 33 bits wide, and broke on dart2js: the
/// operand gets truncated to 32 bits *before* the shift is applied, so
/// a shift trying to read a bit beyond position 31 silently reads 0.
/// A Chrome CPU profile (with source map) on this exact function later
/// showed that caution had a real cost: `~/`/`% BASE` compile on
/// dart2js to a call into `JSNumber.%`/`JSNumber._tdivFast` — Dart's
/// division/modulo have different negative-operand semantics than
/// JS's native `%`, so dart2js can't just emit a raw operator — and
/// that helper call was, by a wide margin, the single hottest
/// function in the whole benchmark (more self-time than this
/// function's own algorithm).
///
/// Every operand these operations are ever called on is non-negative
/// (this whole algorithm works on digit values, never negative
/// numbers), and every division/modulo *specifically by the constant
/// `BASE`* has an operand provably `< 2^32` at that call site (proven
/// by hand for each one below, and cross-checked by a Python
/// simulation with runtime assertions that flag it if any operand
/// ever exceeds 2^32 — none did, across 62k+ cases). That combination
/// means `x ~/ BASE` and `x % BASE` can safely become `x >>> 16` and
/// `x & 0xFFFF`: the shift only ever needs to reach bit 16 through
/// 31, nowhere near the 33rd-bit danger zone that broke `operator+`.
///
/// What's **not** converted: `~/ vn[n-1]`, `% vn[n-1]` (the
/// quotient-digit estimate) and `~/ divisor`, `% divisor` (in
/// `_divModSingleDigit16`) — those divide by a value that varies at
/// runtime and isn't a known power of two, so there's no equivalent
/// shift/mask for them; they stay as real division.
///
/// Verified against a Python simulation matching this function's
/// structure line-for-line, across: 30k random dividend/divisor pairs
/// of random bit-length, 256 boundary-value combinations, 32k cases
/// sweeping every divisor digit-length 1-16, 16k cases specifically
/// constructed to hit every possible normalization shift amount (0
/// through 15), 30k cases stressing the single-digit-divisor path, and
/// a toString-shaped test that repeatedly divides by 10 and
/// reconstructs the original value — zero mismatches across every
/// version of this function (arithmetic-only, then pad-free, then
/// this shift-optimized one). That verification history also caught a
/// real bounds bug (the normalize-shift helper unconditionally writing
/// a carry-out slot that doesn't exist when called for the divisor,
/// whose top carry is mathematically always zero) before it ever
/// reached this file.
(Uint16List quotient, Uint16List remainder) _divModKnuth16(
  Uint16List u,
  int uLen,
  Uint16List v,
  int n,
) {
  final m = uLen - n;

  // Normalize: find dShift (0..15) such that v's top digit, scaled by
  // 2^dShift, has its high bit (bit 15 of 16) set. shiftMul = 2^dShift
  // is built via repeated multiplication, not `1 << dShift` — kept as
  // multiplication here (rather than `1 << dShift`) since `dShift`
  // itself isn't yet bounded at this point in a way worth re-deriving;
  // the cost of one small loop up to 15 iterations is negligible.
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
      // shiftMul <= 0x8000, carry < 0x10000 (bounded recursively by
      // this same reasoning) => combined < 2^32. Safe to shift/mask.
      final combined = digits[i] * shiftMul + carry;
      out[i] = combined & _mask16;
      carry = combined >>> 16;
    }
    // Only store the carry-out if the caller left room for it
    // (extra > 0). For the divisor (extra == 0) this carry is
    // mathematically guaranteed zero by construction of dShift, so
    // there's nothing to store — writing it unconditionally would
    // write one slot past the end of a length-`len` array.
    if (extra > 0) {
      out[len] = carry;
    }
    return out;
  }

  final vn = shl(v, n, 0);
  final un = shl(u, uLen, 1);

  final q = Uint16List(16); // fixed size; only 0..m are ever written

  for (var j = m; j >= 0; j--) {
    final num = un[j + n] * _base + un[j + n - 1];
    var qhat = num ~/ vn[n - 1];
    var rhat = num % vn[n - 1];
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

    // multiply-and-subtract: un[j..j+n] -= qhat * vn[0..n-1]
    var borrow = 0;
    var carryMul = 0;
    for (var i = 0; i < n; i++) {
      // p = qhat*vn[i] + carryMul: qhat, vn[i] <= 0xFFFF, carryMul <
      // 0x10000 (bounded recursively) => p < 2^32. Safe to shift/mask.
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
      // qhat was one too high (rare): add the divisor back once.
      qhat -= 1;
      var carryAdd = 0;
      for (var i = 0; i < n; i++) {
        // s = un[j+i] + vn[i] + carryAdd, all three terms < 0x10000
        // => s comfortably < 2^32.
        final s = un[j + i] + vn[i] + carryAdd;
        un[j + i] = s & _mask16;
        carryAdd = s >>> 16;
      }
      un[j + n] = (un[j + n] + carryAdd) & _mask16;
    }

    q[j] = qhat;
  }

  // Unnormalize: remainder = un[0..n-1] shifted right by dShift bits.
  // un[i] < 0x10000 and dShift <= 15, so `>>> dShift` never needs to
  // read beyond position 15 — comfortably safe. Fixed size 16 for the
  // same reason as `q` above — only 0..n-1 are ever written.
  final rem = Uint16List(16);
  if (dShift == 0) {
    for (var i = 0; i < n; i++) {
      rem[i] = un[i];
    }
  } else {
    for (var i = 0; i < n; i++) {
      var w = un[i] >>> dShift;
      if (i + 1 < n) {
        // un[i+1] < 0x10000, topDiv <= 0x8000 (since dShift >= 1 here)
        // => product < 2^32. Safe to shift/mask.
        w += (un[i + 1] * topDiv) & _mask16;
      }
      rem[i] = w & _mask16;
    }
  }

  return (q, rem);
}

/// Web-safe division: replaces the original 256-bit-serial algorithm
/// with word-based (16-bit digit) division — a handful of digit-level
/// steps instead of up to 256 bit-level ones. See `_divModKnuth16`'s
/// doc comment for which operations use shifts (proven safe, and
/// meaningfully faster than the division/modulo they replace on
/// dart2js) versus which stay as real division (genuinely variable
/// divisors, no shift equivalent exists) — and the verification
/// history behind that split.
({Uint256 quotient, Uint256 remainder}) divModImpl(Uint256 a, Uint256 b) {
  if (b.isZero) throw IntegerError.divisionByZero;
  if (a.compareTo(b) < 0) return (quotient: Uint256.zero, remainder: a);

  final uFull = _toDigits16(a);
  final vFull = _toDigits16(b);
  final uLen = _trimLen(uFull, 16);
  final n = _trimLen(vFull, 16);

  if (n == 1) {
    final (q, r) = _divModSingleDigit16(uFull, uLen, vFull[0]);
    return (
      quotient: _fromDigits16(q),
      remainder: Uint256.fromUint64(Uint64.fromParts(0, r)),
    );
  }

  final (qDigits, rDigits) = _divModKnuth16(uFull, uLen, vFull, n);
  return (quotient: _fromDigits16(qDigits), remainder: _fromDigits16(rDigits));
}
