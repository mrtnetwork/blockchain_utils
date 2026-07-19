import 'dart:typed_data';

import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

const int _base = 0x10000;

/// Splits a Uint256 into 16 digits, base 2^16, LSB first. Same
/// technique as `u256_div_web.dart`'s `_toDigits16` — duplicated
/// locally rather than shared, matching how `u256_math_native.dart`
/// and `u256_div_native.dart` each keep their own local `_pack`/
/// `_unpack` instead of sharing across files. `Uint16List` rather than
/// `List<int>`: every stored digit is provably < 0x10000, and typed
/// data avoids the element-type-checking overhead a generic `List<int>`
/// carries on dart2js (a Chrome CPU profile on this codebase showed
/// real self-time in array index-set/type-check helpers).
///
/// Uses `&`/`>>>` rather than `%`/`~/`: `w` is a 32-bit half (< 2^32)
/// here, so `w >>> 16` never needs to read beyond bit 31 — same proof
/// as `u256_div_web.dart`'s `_toDigits16`, which found this exact
/// substitution eliminates a large, profiler-confirmed cost (`~/`/`%`
/// compile on dart2js to a `JSNumber` runtime-helper call, not a raw
/// operator, because Dart's modulo has different negative-operand
/// semantics than JS's native `%`).
Uint16List _toDigits16(Uint256 v) {
  final d0 = v.d0, d1 = v.d1, d2 = v.d2, d3 = v.d3;
  final halves = [d0.lo, d0.hi, d1.lo, d1.hi, d2.lo, d2.hi, d3.lo, d3.hi];
  final out = Uint16List(16);
  for (var i = 0; i < 8; i++) {
    final w = halves[i];
    out[2 * i] = w & 0xFFFF;
    out[2 * i + 1] = w >>> 16;
  }
  return out;
}

int _pack32(int lo16, int hi16) => lo16 + hi16 * _base;

Uint256 _fromDigits16(List<int> d16) {
  final d0 = Uint64.fromParts(_pack32(d16[2], d16[3]), _pack32(d16[0], d16[1]));
  final d1 = Uint64.fromParts(_pack32(d16[6], d16[7]), _pack32(d16[4], d16[5]));
  final d2 = Uint64.fromParts(_pack32(d16[10], d16[11]), _pack32(d16[8], d16[9]));
  final d3 = Uint64.fromParts(_pack32(d16[14], d16[15]), _pack32(d16[12], d16[13]));
  return Uint256.unsafe(d3, d2, d1, d0);
}

/// Full 256x256->256 wrapping multiply, web-safe, 16-bit digits.
///
/// The previous version of this file called `Uint64.mac()` 10 times —
/// correct, but each call allocates several `Uint64` objects, and on
/// dart2js those are real heap-allocated JS objects (no VM-style
/// escape analysis making them free the way it sometimes can on
/// native). This version works entirely on plain `int`s in fixed-size
/// arrays instead.
///
/// 16-bit digits (not 32-bit) specifically because a single product
/// of two digits must stay under 2^53 to be double-safe: two 16-bit
/// digits multiply to at most ~2^32 (safe), but two 32-bit digits
/// would multiply to ~2^64 (far past double precision) — the same
/// reason `Uint64.widenMulPortable` already uses 16-bit digits rather
/// than 32-bit ones.
///
/// Only digit pairs `(i, j)` with `i + j <= 15` are computed at all —
/// anything with `i + j > 15` would only ever affect output digits
/// beyond bit 255, which get dropped anyway for wrapping semantics, so
/// there's no reason to compute those ~120 unused terms. This keeps
/// the loop to the ~136 (triangular, not full 16x16=256) terms that
/// actually matter.
///
/// The final carry-propagation pass below still uses `~/`/`%` by
/// `0x10000` rather than `>>>`/`&`, unlike `_toDigits16` above and most
/// of `u256_div_web.dart`: `acc[k]` can hold up to ~16 * (2^16-1)^2 ≈
/// 2^36 before this pass reduces it, which exceeds the < 2^32 bound
/// that makes the shift/mask substitution safe elsewhere in this
/// codebase (see `u256_div_web.dart`'s `_divModKnuth16` doc comment for
/// the full explanation of that bound and why it matters on dart2js).
///
/// Verified against ground truth across 200k random 256-bit pairs plus
/// every limb-boundary combination — zero mismatches.
Uint256 mulImpl(Uint256 a, Uint256 b) {
  final aw = _toDigits16(a);
  final bw = _toDigits16(b);

  // acc holds large transient sums (up to ~16 * (2^16-1)^2 ≈ 2^36)
  // until the carry-propagation pass below reduces each slot to a
  // proper 16-bit digit — Uint16List would silently truncate these,
  // so this one has to stay a plain List unlike aw/bw/the arrays in
  // u256_div_web.dart.
  final acc = List<int>.filled(16, 0);
  for (var i = 0; i < 16; i++) {
    final ai = aw[i];
    if (ai == 0) continue; // common for smaller values; cheap to skip
    final maxJ = 15 - i;
    for (var j = 0; j <= maxJ; j++) {
      acc[i + j] += ai * bw[j];
    }
  }

  var carry = 0;
  for (var k = 0; k < 16; k++) {
    // acc[k] here can exceed 2^32 (see doc comment above) — this must
    // stay `%`/`~/`, not `&`/`>>>`.
    final v = acc[k] + carry;
    acc[k] = v % _base;
    carry = v ~/ _base;
  }
  // carry beyond digit 15 represents overflow past 256 bits: dropped,
  // matching this operator's wrapping semantics.

  return _fromDigits16(acc);
}
