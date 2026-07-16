import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u256.dart';
import 'package:blockchain_utils/numbers/src/u32.dart';

import 'i32.dart';
import 'u64.dart';

const int _signBit64 = 0x80000000; // sign bit, within the hi 32-bit limb

class Int64 implements Comparable<Int64> {
  /// Two's-complement bit pattern, reusing Uint64's hi/lo-limb storage.
  final Uint64 _bits;

  const Int64._(this._bits);

  static const Int64 zero = Int64._(Uint64.zero);
  static const Int64 one = Int64._(Uint64.one);
  static const Int64 mask8 = Int64._(Uint64.mask8);
  static const Int64 two = Int64._(Uint64.two);
  static const Int64 minusOne = Int64._(Uint64.max);
  static const Int64 max = Int64._(Uint64.unsafe(0x7FFFFFFF, 0xFFFFFFFF));
  static const Int64 min = Int64._(Uint64.unsafe(_signBit64, 0));

  /// Raw bit-pattern constructor for an already-computed two's-complement
  /// [Uint64] pattern. Prefer [Int64.new] otherwise.
  const Int64.unsafe(Uint64 bits) : _bits = bits;

  /// Builds from a plain Dart [int] (positive or negative). [value] must
  /// itself be a normal, double-safe Dart int (true for any literal or
  /// value that didn't already come from a wider fixed-width type) —
  /// i.e. |value| <= 2^53, so splitting it into hi/lo limbs with plain
  /// arithmetic operators never forms an intermediate exceeding the
  /// JS double-precision safe integer boundary.
  ///
  /// No BigInt involved: non-negative values are split directly into
  /// limbs; negative values split the magnitude into limbs first, then
  /// two's-complement-negate using Uint64's existing web-safe `~` / `+`.
  factory Int64(int value) {
    if (value >= 0) {
      final hi = value ~/ 0x100000000;
      final lo = value % 0x100000000;
      return Int64._(Uint64.unsafe(hi, lo));
    }
    final mag = -value; // safe: |value| <= 2^53, so negation can't overflow
    final hi = mag ~/ 0x100000000;
    final lo = mag % 0x100000000;
    final magBits = Uint64.unsafe(hi, lo);
    return Int64._((~magBits) + Uint64.one);
  }

  static Int64 parseHex(String s) => Int64._(Uint64.parseHex(s));

  /// Builds from an arbitrary signed [BigInt], truncating to 64 bits like
  /// a `wrapping` cast — mirrors [Int32.fromBigInt] / [Int128.fromBigInt].
  /// `BigInt.toUnsigned` gives the exact two's-complement bit pattern
  /// directly, so this is correct for any magnitude/sign.
  factory Int64.fromBigInt(BigInt value) =>
      Int64._(Uint64.fromBigInt(value.toUnsigned(64)));

  /// Strict decimal parse: throws [IntegerError] on overflow/underflow,
  /// unlike the wrapping constructor.
  static Int64 parseDecimal(String s) {
    if (s.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    final negative = s.startsWith('-');
    final digits = negative ? s.substring(1) : s;
    if (digits.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    final mag = Uint64.parseDecimal(
      digits,
    ); // throws on bad chars or u64 overflow
    const minMag = Uint64.unsafe(_signBit64, 0); // 2^63
    if (negative) {
      if (mag > minMag) throw IntegerError.overflow;
      if (mag == minMag) return Int64.min;
      return Int64._((~mag) + Uint64.one); // negate
    } else {
      if (mag > Int64.max._bits) throw IntegerError.overflow;
      return Int64._(mag);
    }
  }

  // ---- conversions ----

  /// Signed value as a [BigInt] — the general-purpose conversion, unlike
  /// [toInt] which throws when the magnitude doesn't fit a double-safe
  /// int. Mirrors [Int32.toBigInt] / [Int128.toBigInt].
  BigInt toBigInt() => _bits.toBigInt().toSigned(64);

  /// Safe only if the magnitude fits in 53 bits — delegates to
  /// `Uint64.toInt()`'s own guard, so it throws [IntegerError] otherwise.
  int toInt() {
    final negative = isNegative;
    final magnitudeBits = negative ? ((~_bits) + Uint64.one) : _bits;
    final mag =
        magnitudeBits.toInt(); // throws if too large for a double-safe int
    return negative ? -mag : mag;
  }

  String toHexString({bool padded = true}) => _bits.toHexString(padded: padded);

  @override
  String toString() {
    if (isZero) return '0';
    if (isNegative) {
      final mag =
          (~_bits) +
          Uint64.one; // correct even at Int64.min: wraps to itself, i.e. 2^63
      return '-${mag.toString()}';
    }
    return _bits.toString();
  }

  /// Fixed 8-byte two's-complement encoding — identical bit-for-bit to
  /// `Uint64.toBytes`, so this just delegates.
  List<int> toBytes([Endian endian = Endian.big]) => _bits.toBytes(endian);

  static Int64 fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
    int offset = 0,
  }) => Int64._(Uint64.fromBytes(bytes, endian: endian, offset: offset));

  // ---- properties ----

  bool get isZero => _bits.isZero;
  bool get isNegative => (_bits.hi & _signBit64) != 0;
  bool get isEven => _bits.isEven;

  /// Raw two's-complement bit pattern as a [Uint64].
  Uint64 get rawBits => _bits;

  // ---- wrapping arithmetic operators ----
  //
  // Add/sub/mul/bitwise/left-shift are bit-identical between unsigned and
  // two's-complement signed representations, so these delegate straight to
  // Uint64's operators (already proven web-safe there).

  Int64 operator +(Int64 other) => Int64._(_bits + other._bits);
  Int64 operator -(Int64 other) => Int64._(_bits - other._bits);
  Int64 operator *(Int64 other) => Int64._(_bits * other._bits);
  Int64 operator -() => Int64.zero - this; // wraps to itself at Int64.min

  Int64 operator &(Int64 other) => Int64._(_bits & other._bits);
  Int64 operator |(Int64 other) => Int64._(_bits | other._bits);
  Int64 operator ^(Int64 other) => Int64._(_bits ^ other._bits);
  Int64 operator ~() => Int64._(~_bits);

  /// Logical left shift (bits shifted out the top are discarded) —
  /// identical for signed and unsigned, delegates to `Uint64`.
  Int64 operator <<(int n) => Int64._(_bits << n);

  /// Logical (unsigned) right shift — top bits filled with zero regardless
  /// of sign.
  Int64 unsignedShiftRight(int n) => Int64._(_bits >> n);

  /// Arithmetic (sign-propagating) right shift.
  Int64 operator >>(int n) {
    final shift = n & 63;
    final logical = _bits >> shift;
    if (!isNegative || shift == 0) return Int64._(logical);
    // Build a mask of `shift` leading one-bits by logically shifting an
    // all-ones pattern and inverting — every step here is a plain Uint64
    // shift/bitwise op, already web-safe.
    final mask = ~(Uint64.max >> shift);
    return Int64._(logical | mask);
  }

  /// Truncating division (toward zero), like Rust's `/` or C's `/`.
  /// `Int64.min ~/ Int64.minusOne` wraps back to `Int64.min` (the one case
  /// where the mathematical quotient doesn't fit).
  Int64 operator ~/(Int64 other) {
    if (other.isZero) throw IntegerError.divisionByZero;
    if (this == Int64.min && other == Int64.minusOne) return Int64.min;
    final negResult = isNegative != other.isNegative;
    // Negating Int64.min wraps back to its own bit pattern, which Uint64
    // correctly reads as 2^63 — exactly the right magnitude — so no
    // special-casing is needed here beyond the min/-1 guard above.
    final aMag = isNegative ? (-this)._bits : _bits;
    final bMag = other.isNegative ? (-other)._bits : other._bits;
    final q = aMag ~/ bMag;
    final result = Int64._(q);
    return negResult ? -result : result;
  }

  /// Truncating remainder (same sign as the dividend), consistent with
  /// `operator ~/` above — this is `remainder()` semantics, not Dart's
  /// Euclidean `%`.
  Int64 operator %(Int64 other) => this - (this ~/ other) * other;

  // ---- overflow-checked arithmetic ----

  Int64 addChecked(Int64 other) {
    final overflow =
        isNegative == other.isNegative &&
        (this + other).isNegative != isNegative;
    final r = this + other;
    if (overflow) throw IntegerError.overflow;
    return r;
  }

  /// `-other` wraps back to `Int64.min` itself when `other == Int64.min`
  /// (no positive counterpart in two's complement), so that case can't go
  /// through `addChecked(-other)` like every other value can. `this -
  /// Int64.min` only fits the signed range when `this` is negative, in
  /// which case the plain wrapping subtract is already exact.
  Int64 subChecked(Int64 other) {
    if (other == Int64.min) {
      if (!isNegative) throw IntegerError.overflow;
      return this - other;
    }
    return addChecked(-other);
  }

  /// Detects overflow via round-trip: wrap-multiply then divide back out.
  /// Avoids ever forming a >64-bit intermediate.
  /// Detects overflow via round-trip: wrap-multiply then divide back out.
  /// Avoids ever forming a >64-bit intermediate.
  ///
  /// `Int64.min * Int64.minusOne` needs an explicit guard — see the
  /// matching comment on `Int32.mulChecked` for why.
  Int64 mulChecked(Int64 other) {
    if ((this == Int64.min && other == Int64.minusOne) ||
        (this == Int64.minusOne && other == Int64.min)) {
      throw IntegerError.overflow;
    }
    if (isZero || other.isZero) return Int64.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  Int64 abs() => isNegative ? -this : this; // wraps to itself at Int64.min

  // ---- comparisons ----

  static const Uint64 _signMask = Uint64.unsafe(_signBit64, 0);

  /// Flips the sign bit on both operands, which turns two's-complement
  /// ordering into plain unsigned ordering — then delegates to
  /// `Uint64.compareTo`.
  @override
  int compareTo(Int64 other) {
    final a = _bits ^ _signMask;
    final b = other._bits ^ _signMask;
    return a.compareTo(b);
  }

  bool operator <(Int64 other) => compareTo(other) < 0;
  bool operator <=(Int64 other) => compareTo(other) <= 0;
  bool operator >(Int64 other) => compareTo(other) > 0;
  bool operator >=(Int64 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Int64 && _bits == other._bits;

  @override
  int get hashCode => _bits.hashCode;

  Int32 get toI32 => Int32.unsafe(_bits.lo);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i32`
  /// cast). Same value as the [toI32] getter, kept for naming consistency
  /// with the other `toIntNN`/`toUintNN` converters.
  Int32 toInt32() => Int32.unsafe(_bits.lo);

  int toUint8() => _bits.lo & 0xFF;

  // ---- cross-type converters ----

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as u32`
  /// cast).
  Uint32 toUint32() => _bits.toUint32();

  /// Same-width bit reinterpretation (two's complement) — e.g.
  /// `Int64.minusOne.toUint64() == Uint64.max`.
  Uint64 toUint64() => _bits;

  /// Sign-extending widen, then reinterpret.
  Uint128 toUint128() {
    final ext = isNegative ? Uint64.max : Uint64.zero;
    return Uint128.unsafe(ext, _bits);
  }

  /// Sign-extending widen, then reinterpret.
  Uint256 toUint256() {
    final ext = isNegative ? Uint64.max : Uint64.zero;
    return Uint256.unsafe(ext, ext, ext, _bits);
  }

  /// Sign-extending widen — same bit pattern as [toUint128], just
  /// relabelled signed.
  Int128 toInt128() {
    final ext = isNegative ? Uint64.max : Uint64.zero;
    return Int128.unsafe(Uint128.unsafe(ext, _bits));
  }
}
