import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/utils/numbers/fixed/src/u64/word_math/word_math.dart';

const int _mask32 = 0xFFFFFFFF;
const int _mask16 = 0xFFFF;

class Uint64 implements Comparable<Uint64> {
  final int _hi; // 0..0xFFFFFFFF
  final int _lo; // 0..0xFFFFFFFF

  const Uint64._(this._hi, this._lo);
  static const Uint64 maxInt = Uint64.unsafe(0x7FFFFFFF, 0xFFFFFFFF);
  const Uint64.uncheckedU32(int n) : _lo = n, _hi = 0;
  static const Uint64 zero = Uint64._(0, 0);
  static const Uint64 one = Uint64._(0, 1);
  static const Uint64 two = Uint64._(0, 2);
  static const Uint64 max = Uint64._(_mask32, _mask32);
  static const Uint64 maxU32 = Uint64._(0, _mask32);
  static const Uint64 mask8 = Uint64._(0, 0xFF);

  /// Builds from a plain Dart [int]. Must be non-negative and representable
  /// exactly as a double (i.e. `<= 2^53`, which covers every case where the
  /// value didn't already come from hi/lo limbs). For values above 2^53 use
  /// [fromBigInt] or [parseHex]/[parseDecimal].
  factory Uint64(int value) {
    if (value < 0) {
      throw CoreErrors.invalidOperationArguments(
        "Uint64",
        reason: 'value must be non-negative',
      );
    }
    final hi = (value ~/ 0x100000000) & _mask32;
    final lo = value & _mask32;
    return Uint64._(hi, lo);
  }
  const Uint64.unsafe(this._hi, this._lo)
    : assert(
        _hi >= 0 && _hi <= 0xFFFFFFFF && _lo >= 0 && _lo <= 0xFFFFFFFF,
        'Uint64.unsafe called with out-of-range limb',
      );

  @pragma('vm:prefer-inline')
  factory Uint64.fromParts(int hi, int lo) =>
      Uint64._(hi & _mask32, lo & _mask32);

  /// Builds from a plain Dart [int], accepting negative values by taking
  /// their two's-complement bit pattern (masked to 64 bits) instead of
  /// throwing like [Uint64.new] does — e.g. `Uint64.from(-1) == Uint64.max`.
  /// [value] must itself be a normal double-safe Dart int (`|value| <=
  /// 2^53`); mirrors the negation trick `Int64.new` already uses.
  factory Uint64.from(int value) {
    final isNeg = value < 0;
    final mag = isNeg ? -value : value; // safe: |value| <= 2^53
    final magBits = Uint64.unsafe(mag ~/ 0x100000000, mag % 0x100000000);
    return isNeg ? (~magBits) + Uint64.one : magBits;
  }

  factory Uint64.fromBigInt(BigInt value) {
    if (value.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        "fromBigInt",
        reason: 'value must be non-negative',
      );
    }
    final v = value & BigInt.parse('FFFFFFFFFFFFFFFF', radix: 16);
    final hi = (v >> 32).toUnsigned(32).toInt();
    final lo = v.toUnsigned(32).toInt();
    return Uint64._(hi, lo);
  }

  static Uint64 parseHex(String s) {
    var hex = s.startsWith('0x') || s.startsWith('0X') ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 16) {
      throw CoreErrors.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    hex = hex.padLeft(16, '0');
    try {
      final hi = int.parse(hex.substring(0, 8), radix: 16);
      final lo = int.parse(hex.substring(8, 16), radix: 16);
      return Uint64._(hi, lo);
    } on FormatException {
      throw CoreErrors.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
  }

  /// Strict decimal parse: throws [IntegerError] on overflow, unlike the
  /// wrapping `*`/`+` operators.
  static Uint64 parseDecimal(String s) {
    if (s.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      throw CoreErrors.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    var acc = Uint64.zero;
    final ten = Uint64(10);
    for (var i = 0; i < s.length; i++) {
      final rune = s.codeUnitAt(i);
      final digit = Uint64(rune - 0x30);
      final scaled = acc.mulChecked(ten); // throws on overflow
      final next = scaled + digit;
      if (next < scaled) {
        throw CoreErrors.integerOverflow;
      }
      acc = next;
    }
    return acc;
  }

  // ---- conversions ----

  BigInt toBigInt() => (BigInt.from(_hi) << 32) | BigInt.from(_lo);

  /// Only safe if the value fits in 53 bits (i.e. `hi <= 0x1FFFFF`).
  /// Throws otherwise — use [toBigInt] for the general case.
  int toInt() {
    if (_hi > 0x1FFFFF) {
      throw CoreErrors.integerToIntConversionError;
    }
    return _hi * 0x100000000 + _lo;
  }

  String toHexString({bool padded = true}) {
    final hex =
        '${_hi.toRadixString(16).padLeft(8, '0')}'
        '${_lo.toRadixString(16).padLeft(8, '0')}';
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() {
    if (isZero) return '0';
    final digits = <String>[];
    var rem = this;
    final ten = Uint64(10);
    while (!rem.isZero) {
      final qr = rem._divMod(ten);
      digits.add(qr.remainder._lo.toString());
      rem = qr.quotient;
    }
    return digits.reversed.join();
  }

  /// Fixed 8-byte encoding, straight from the hi/lo limbs — no BigInt
  /// involved at any point.
  BuBytes toBytes([Endian endian = Endian.big]) {
    final out = BuBytes.zero(8);
    if (endian == Endian.big) {
      out[0] = (_hi >>> 24) & 0xFF;
      out[1] = (_hi >>> 16) & 0xFF;
      out[2] = (_hi >>> 8) & 0xFF;
      out[3] = _hi & 0xFF;
      out[4] = (_lo >>> 24) & 0xFF;
      out[5] = (_lo >>> 16) & 0xFF;
      out[6] = (_lo >>> 8) & 0xFF;
      out[7] = _lo & 0xFF;
    } else {
      out[0] = _lo & 0xFF;
      out[1] = (_lo >>> 8) & 0xFF;
      out[2] = (_lo >>> 16) & 0xFF;
      out[3] = (_lo >>> 24) & 0xFF;
      out[4] = _hi & 0xFF;
      out[5] = (_hi >>> 8) & 0xFF;
      out[6] = (_hi >>> 16) & 0xFF;
      out[7] = (_hi >>> 24) & 0xFF;
    }
    return out;
  }

  /// Parses an 8-byte unsigned integer directly into hi/lo limbs
  ///
  /// Throws [BuError] if there are fewer than 8 bytes available starting
  /// at [offset].
  static Uint64 fromBytes(
    List<int> bytes, {
    int offset = 0,
    Endian endian = Endian.big,
  }) {
    if (offset < 0 || bytes.length - offset < 8) {
      throw CoreErrors.invalidOperationArguments(
        "Uint64.fromBytes",
        reason: 'Need at least 8 bytes from offset.',
        details: {
          "offset": offset.toString(),
          "length": bytes.length.toString(),
        },
      );
    }

    int hi, lo;
    if (endian == Endian.big) {
      hi =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
      lo =
          (bytes[offset + 4] << 24) |
          (bytes[offset + 5] << 16) |
          (bytes[offset + 6] << 8) |
          bytes[offset + 7];
    } else {
      lo =
          (bytes[offset + 3] << 24) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 1] << 8) |
          bytes[offset];
      hi =
          (bytes[offset + 7] << 24) |
          (bytes[offset + 6] << 16) |
          (bytes[offset + 5] << 8) |
          bytes[offset + 4];
    }

    return Uint64._(hi & _mask32, lo & _mask32);
  }

  // ---- properties ----

  @pragma('vm:prefer-inline')
  bool get isZero => _hi == 0 && _lo == 0;
  bool get isEven => (_lo & 1) == 0;
  bool get isOdd => (_lo & 1) != 0;
  @pragma('vm:prefer-inline')
  int get hi => _hi;
  @pragma('vm:prefer-inline')
  int get lo => _lo;

  // ---- wrapping arithmetic operators ----

  Uint64 operator +(Uint64 other) {
    final lo = _lo + other._lo;
    final carry = lo > _mask32 ? 1 : 0;
    final hi = (_hi + other._hi + carry) & _mask32;
    return Uint64._(hi, lo & _mask32);
  }

  Uint64 operator -(Uint64 other) {
    var lo = _lo - other._lo;
    var borrow = 0;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    }
    var hi = _hi - other._hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
    }
    return Uint64._(hi, lo);
  }

  Uint64 operator *(Uint64 other) {
    final (hi, lo) = widenMul(this, other);
    return lo;
  }

  Uint64 operator ~/(Uint64 other) => _divMod(other).quotient;

  Uint64 operator %(Uint64 other) => _divMod(other).remainder;

  ({Uint64 quotient, Uint64 remainder}) _divMod(Uint64 other) {
    final result = divModImpl(this, other);

    return result;
  }

  // ---- overflow-checked arithmetic ----

  /// Throws [IntegerError] instead of wrapping on overflow.
  Uint64 addChecked(Uint64 other) {
    final r = this + other;
    if (r < this) throw CoreErrors.integerOverflow;
    return r;
  }

  /// Throws [IntegerError] instead of wrapping on underflow.
  Uint64 subChecked(Uint64 other) {
    if (other > this) throw CoreErrors.integerOverflow;
    return this - other;
  }

  /// Throws [IntegerError] instead of wrapping on overflow.
  Uint64 mulChecked(Uint64 other) {
    if (isZero || other.isZero) return Uint64.zero;
    final r = this * other;
    if (r ~/ other != this) throw CoreErrors.integerOverflow;
    return r;
  }

  // ---- bitwise operators ----

  Uint64 operator &(Uint64 other) => Uint64._(_hi & other._hi, _lo & other._lo);

  Uint64 operator |(Uint64 other) => Uint64._(_hi | other._hi, _lo | other._lo);

  Uint64 operator ^(Uint64 other) =>
      Uint64._((_hi ^ other._hi) & _mask32, (_lo ^ other._lo) & _mask32);

  Uint64 operator ~() => Uint64._(_mask32 - _hi, _mask32 - _lo);

  /// Shifts a 32-bit-range value left by 0..31 bits, computing `(value <<
  /// shift) & 0xFFFFFFFF` without ever forming an intermediate above 2^53.
  /// A plain `value << shift` here would be mathematically correct but,
  /// for large [value] and [shift], the *unmasked* intermediate can reach
  /// ~2^63 — silently imprecise as a double on dart2js/dart2wasm even
  /// though it's exact on the VM's native 64-bit int. Every step below
  /// stays under 2^32, comfortably inside the 53-bit safe-integer range on
  /// every platform.
  static int _safeShl32(int value, int shift) {
    if (shift == 0) return value;
    final lo16 = value & _mask16;
    final hi16 = (value >>> 16) & _mask16;
    if (shift < 16) {
      final newLo = (lo16 << shift) & _mask16;
      final carry = lo16 >>> (16 - shift);
      final newHi = ((hi16 << shift) & _mask16) | carry;
      return (newHi << 16) | newLo;
    }
    final s = shift - 16;
    final newHi = (lo16 << s) & _mask16;
    return newHi << 16;
  }

  /// Logical (unsigned) left shift. There's no arithmetic-shift distinction
  /// for an unsigned type.
  Uint64 operator <<(int n) {
    final shift = n & 63;
    if (shift == 0) return this;
    if (shift < 32) {
      final hiShifted = _safeShl32(_hi, shift);
      final carryFromLo = _lo >>> (32 - shift); // right shift: always safe
      final newHi = (hiShifted | carryFromLo) & _mask32;
      final newLo = _safeShl32(_lo, shift) & _mask32;
      return Uint64._(newHi, newLo);
    }
    final newHi = _safeShl32(_lo, shift - 32) & _mask32;
    return Uint64._(newHi, 0);
  }

  /// Logical (unsigned) right shift.
  Uint64 operator >>(int n) {
    final shift = n & 63;
    if (shift == 0) return this;
    if (shift < 32) {
      final loPart = _lo >>> shift; // right shift: always safe
      final carryFromHi = _safeShl32(_hi, 32 - shift);
      final newLo = (loPart | carryFromHi) & _mask32;
      final newHi = (_hi >>> shift) & _mask32; // right shift: always safe
      return Uint64._(newHi, newLo);
    }
    final newLo = (_hi >>> (shift - 32)) & _mask32; // right shift: always safe
    return Uint64._(0, newLo);
  }

  // ---- widening multiply / carry-chain primitives ----
  //
  // These are the building blocks Comba multiplication and Montgomery
  // reduction are built from (mirrors Rust's `mac`/`adc`/`sbb` used in
  // ff/pairing-style field implementations). Verified against a BigInt
  // oracle: 200k random cases each for mac/adc/sbb plus boundary values
  // (0, 1, u64::MAX, u64::MAX-1).

  /// Full 128-bit product of [a] * [b], returned as (high, low) Uint64.
  static (Uint64 hi, Uint64 lo) widenMul(Uint64 a, Uint64 b) {
    final (hi, lo) = widenMulImpl(a, b);

    // Debug-only cross-check against the portable implementation.
    assert(() {
      final (hiP, loP) = widenMulPortable(a, b);
      if (hi == hiP && lo == loP) {
        return true;
      }
      return false;
    }(), "failed");
    return (hi, lo);
  }

  Uint64 operator >>>(int n) => this >> n;

  /// Full 128-bit product of [a] * [b], returned as (high, low) Uint64.
  /// Web-safe: works entirely in 16-bit digits, never forms an
  /// intermediate above 2^53.
  static (Uint64 hi, Uint64 lo) widenMulPortable(Uint64 a, Uint64 b) {
    final aw0 = a._lo & _mask16, aw1 = (a._lo >>> 16) & _mask16;
    final aw2 = a._hi & _mask16, aw3 = (a._hi >>> 16) & _mask16;
    final bw0 = b._lo & _mask16, bw1 = (b._lo >>> 16) & _mask16;
    final bw2 = b._hi & _mask16, bw3 = (b._hi >>> 16) & _mask16;

    final acc0 = aw0 * bw0;
    final acc1 = aw0 * bw1 + aw1 * bw0;
    final acc2 = aw0 * bw2 + aw1 * bw1 + aw2 * bw0;
    final acc3 = aw0 * bw3 + aw1 * bw2 + aw2 * bw1 + aw3 * bw0;
    final acc4 = aw1 * bw3 + aw2 * bw2 + aw3 * bw1;
    final acc5 = aw2 * bw3 + aw3 * bw2;
    final acc6 = aw3 * bw3;

    var carry = 0;
    var v = acc0 + carry;
    final r0 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc1 + carry;
    final r1 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc2 + carry;
    final r2 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc3 + carry;
    final r3 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc4 + carry;
    final r4 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc5 + carry;
    final r5 = v & _mask16;
    carry = v ~/ 0x10000;
    v = acc6 + carry;
    final r6 = v & _mask16;
    carry = v ~/ 0x10000;
    final r7 = carry & _mask16;

    final lo = Uint64.fromParts((r3 << 16) | r2, (r1 << 16) | r0);
    final hi = Uint64.fromParts((r7 << 16) | r6, (r5 << 16) | r4);
    return (hi, lo);
  }

  /// Carry out of s = a + b (wrapping). Returns 0 or 1.
  static Uint64 _carry(Uint64 a, Uint64 b, Uint64 s) =>
      ((a & b) | ((a | b) & ~s)) >>> 63;

  /// Borrow out of d = a - b (wrapping). Returns 0 or 1.
  static Uint64 _borrow(Uint64 a, Uint64 b, Uint64 d) =>
      ((~a & b) | (~(a ^ b) & d)) >>> 63;

  /// Any nonzero value -> 1, zero -> 0.
  static Uint64 _nonzeroBit(Uint64 x) => (x | (Uint64.zero - x)) >>> 63;

  static (Uint64, Uint64) mac(Uint64 a, Uint64 b, Uint64 c, Uint64 carry) {
    final (hi0, lo0) = widenMul(b, c);
    final lo1 = lo0 + a;
    final c1 = _carry(lo0, a, lo1);
    final lo2 = lo1 + carry;
    final c2 = _carry(lo1, carry, lo2);
    return (lo2, hi0 + c1 + c2);
  }

  static (Uint64, Uint64) adc(Uint64 a, Uint64 b, Uint64 carry) {
    final s1 = a + b;
    final c1 = _carry(a, b, s1);
    final s2 = s1 + carry;
    final c2 = _carry(s1, carry, s2);
    return (s2, c1 + c2);
  }

  static (Uint64, Uint64) sbb(Uint64 a, Uint64 b, Uint64 borrowIn) {
    final bit = _nonzeroBit(borrowIn);
    final s1 = a - b;
    final bw1 = _borrow(a, b, s1);
    final s2 = s1 - bit;
    final bw2 = _borrow(s1, bit, s2);
    // bw1 and bw2 can never both be 1, so | is the same as +.
    final mask = Uint64.zero - (bw1 | bw2);
    return (s2, mask);
  }

  // /// Multiply-accumulate: `a + b*c + carry` as a full 128-bit value.
  // /// Returns (result, carryOut) — the standard building block of Comba
  // /// multiplication / Montgomery reduction inner loops.
  // static (Uint64 result, Uint64 carryOut) mac(
  //   Uint64 a,
  //   Uint64 b,
  //   Uint64 c,
  //   Uint64 carry,
  // ) {
  //   final (hi0, lo0) = widenMul(b, c);
  //   final lo1 = lo0 + a;
  //   final c1 = lo1 < lo0 ? Uint64.one : Uint64.zero;
  //   final lo2 = lo1 + carry;
  //   final c2 = lo2 < lo1 ? Uint64.one : Uint64.zero;
  //   return (lo2, hi0 + c1 + c2);
  // }

  // /// Add-with-carry: `a + b + carry`. Returns (result, carryOut) where
  // /// carryOut is the numeric carry (0, 1, or 2 — matches Rust's `adc`,
  // /// which accepts a full-width carry-in from a preceding `mac`).
  // static (Uint64 result, Uint64 carryOut) adc(
  //   Uint64 a,
  //   Uint64 b,
  //   Uint64 carry,
  // ) {
  //   final s1 = a + b;
  //   final c1 = s1 < a ? Uint64.one : Uint64.zero;
  //   final s2 = s1 + carry;
  //   final c2 = s2 < s1 ? Uint64.one : Uint64.zero;
  //   return (s2, c1 + c2);
  // }

  // /// Subtract-with-borrow: `a - b - borrowBit`, where the borrow bit is
  // /// derived from [borrowIn] (zero = no borrow; any nonzero = borrow —
  // /// matches the all-ones-mask convention constant-time field code uses).
  // /// Returns (result, borrowOutMask), where borrowOutMask is
  // /// [Uint64.zero] or [Uint64.max] — ready to `&` directly against a
  // /// modulus limb for a conditional add-back.
  // static (Uint64 result, Uint64 borrowOutMask) sbb(
  //   Uint64 a,
  //   Uint64 b,
  //   Uint64 borrowIn,
  // ) {
  //   final bit = borrowIn.isZero ? Uint64.zero : Uint64.one;
  //   final s1 = a - b;
  //   final bw1 = a < b ? Uint64.one : Uint64.zero;
  //   final s2 = s1 - bit;
  //   final bw2 = s1 < bit ? Uint64.one : Uint64.zero;
  //   final totalBorrow = bw1 + bw2;
  //   final outMask = totalBorrow.isZero ? Uint64.zero : Uint64.max;
  //   return (s2, outMask);
  // }

  /// Branchless select: returns [b] if [choice] else [a]. Built from a
  /// bitmask blend, matching the shape of typical constant-time field code
  /// (this is a helper, not a hardened constant-time guarantee — Dart's
  /// runtime doesn't guarantee branchless codegen).
  static Uint64 ctSelect(Uint64 a, Uint64 b, bool choice) {
    final mask = choice ? Uint64.max : Uint64.zero;
    return (b & mask) | (a & ~mask);
  }

  /// XOR-accumulate equality check across two same-length limb lists —
  /// avoids short-circuiting on the first differing limb, matching the
  /// intent of typical constant-time field-element comparisons.
  static bool ctEquals(List<Uint64> a, List<Uint64> b) {
    if (a.length != b.length) return false;
    var diff = Uint64.zero;
    for (var i = 0; i < a.length; i++) {
      diff = diff | (a[i] ^ b[i]);
    }
    return diff.isZero;
  }

  /// All-ones iff [x] is zero, else zero. Branch-free mask builder for
  /// code-level constant-time selects (no `?:`/`if` on the value).
  static Uint64 isZeroMask(Uint64 x) =>
      Uint64.zero - (Uint64.one - _nonzeroBit(x));

  /// Mask form of [ctEquals]: all-ones iff the limb lists are equal.
  /// Fixed iteration count; no early exit.
  static Uint64 ctEqualsMask(List<Uint64> a, List<Uint64> b) {
    assert(a.length == b.length);
    var diff = Uint64.zero;
    for (var i = 0; i < a.length; i++) {
      diff = diff | (a[i] ^ b[i]);
    }
    return isZeroMask(diff);
  }

  /// Branch-free select on a 0/1 [bit]: returns [b] iff bit == 1, else [a].
  /// The bit must already be a 0/1 [Uint64] (never a `bool`), so no
  /// bool-to-mask conversion — which would itself be a branch — is needed.
  static Uint64 selectBit(Uint64 a, Uint64 b, Uint64 bit) {
    final m = Uint64.zero - bit;
    return (a & ~m) | (b & m);
  }

  // ---- comparisons ----

  @override
  @pragma('vm:prefer-inline')
  int compareTo(Uint64 other) {
    if (_hi != other._hi) return _hi < other._hi ? -1 : 1;
    if (_lo != other._lo) return _lo < other._lo ? -1 : 1;
    return 0;
  }

  bool operator <(Uint64 other) => compareTo(other) < 0;
  bool operator <=(Uint64 other) => compareTo(other) <= 0;
  bool operator >(Uint64 other) => compareTo(other) > 0;
  bool operator >=(Uint64 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Uint64 && _hi == other._hi && _lo == other._lo;

  @override
  int get hashCode => Object.hash(_hi, _lo);

  Uint64 operator -() => Uint64.zero - this;

  int toUint8() => _lo & 0xFF;
}
