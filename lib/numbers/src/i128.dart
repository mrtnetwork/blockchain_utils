import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';

import 'i32.dart';
import 'i64.dart';
import 'u128.dart';
import 'u256/u256.dart';
import 'u32.dart';
import 'u64/u64.dart';

const int _signBit32 = 0x80000000; // top bit of the top 32-bit word

class Int128 implements Comparable<Int128> {
  /// Two's-complement bit pattern, reusing Uint128's hi/lo-limb storage.
  final Uint128 _bits;

  const Int128._(this._bits);

  static const Int128 zero = Int128._(Uint128.zero);
  static const Int128 one = Int128._(Uint128.one);
  static const Int128 minusOne = Int128._(Uint128.max);
  static const Int128 max = Int128._(
    Uint128.unsafe(Uint64.unsafe(0x7FFFFFFF, 0xFFFFFFFF), Uint64.max),
  );
  static const Int128 min = Int128._(
    Uint128.unsafe(Uint64.unsafe(_signBit32, 0), Uint64.zero),
  );

  /// Raw bit-pattern constructor for an already-computed two's-complement
  /// [Uint128] pattern. Prefer [Int128.new] or [Int128.fromBigInt]
  /// otherwise.
  const Int128.unsafe(Uint128 bits) : _bits = bits;

  /// Builds from a plain Dart [int] (positive or negative).
  factory Int128(int value) => Int128.fromBigInt(BigInt.from(value));

  /// Builds from an arbitrary signed [BigInt], truncating to 128 bits
  /// like a `wrapping` cast. `BigInt.toUnsigned` gives the exact
  /// two's-complement bit pattern directly, so this is correct for any
  /// magnitude.
  factory Int128.fromBigInt(BigInt value) =>
      Int128._(Uint128.fromBigInt(value.toUnsigned(128)));

  static Int128 parseHex(String s) => Int128._(Uint128.parseHex(s));

  /// Strict decimal parse: throws [IntegerError] on overflow/underflow,
  /// unlike the wrapping constructor.
  static Int128 parseDecimal(String s) {
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
    final mag = Uint128.parseDecimal(digits); // throws on bad chars or u128 overflow
    const minMag = Uint128.unsafe(Uint64.unsafe(_signBit32, 0), Uint64.zero); // 2^127
    if (negative) {
      if (mag > minMag) throw IntegerError.overflow;
      if (mag == minMag) return Int128.min;
      return Int128._((~mag) + Uint128.one); // negate
    } else {
      if (mag > Int128.max._bits) throw IntegerError.overflow;
      return Int128._(mag);
    }
  }

  // ---- conversions ----

  BigInt toBigInt() => _bits.toBigInt().toSigned(128);

  /// Safe only if the magnitude fits in a double-safe int — delegates to
  /// `Uint128.toInt()`'s own guard, so it throws [IntegerError] otherwise
  /// (use [toBigInt] for the general case).
  int toInt() {
    final negative = isNegative;
    final magnitudeBits = negative ? ((~_bits) + Uint128.one) : _bits;
    final mag = magnitudeBits.toInt();
    return negative ? -mag : mag;
  }

  String toHexString({bool padded = true}) => _bits.toHexString(padded: padded);

  @override
  String toString() {
    if (isZero) return '0';
    if (isNegative) {
      // Correct even at Int128.min: negation wraps back to its own bit
      // pattern, which Uint128 correctly reads as the magnitude 2^127.
      final mag = (~_bits) + Uint128.one;
      return '-${mag.toString()}';
    }
    return _bits.toString();
  }

  /// Fixed 16-byte two's-complement encoding — identical bit-for-bit to
  /// `Uint128.toBytes`, so this just delegates.
  List<int> toBytes([Endian endian = Endian.big]) => _bits.toBytes(endian);

  static Int128 fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
    int offset = 0,
  }) => Int128._(Uint128.fromBytes(bytes, endian: endian, offset: offset));

  bool get isZero => _bits.isZero;
  bool get isNegative => (_bits.hi.hi & _signBit32) != 0;
  bool get isEven => _bits.isEven;

  /// Raw two's-complement bit pattern as a [Uint128].
  Uint128 get rawBits => _bits;

  // ---- wrapping arithmetic operators ----

  Int128 operator +(Int128 other) => Int128._(_bits + other._bits);
  Int128 operator -(Int128 other) => Int128._(_bits - other._bits);
  Int128 operator *(Int128 other) => Int128._(_bits * other._bits);
  Int128 operator -() => Int128.zero - this; // wraps to itself at Int128.min

  Int128 operator &(Int128 other) => Int128._(_bits & other._bits);
  Int128 operator |(Int128 other) => Int128._(_bits | other._bits);
  Int128 operator ^(Int128 other) => Int128._(_bits ^ other._bits);
  Int128 operator ~() => Int128._(~_bits);

  /// Logical left shift — identical for signed and unsigned, delegates
  /// to `Uint128`.
  Int128 operator <<(int n) => Int128._(_bits << n);

  /// Logical (unsigned) right shift — top bits filled with zero
  /// regardless of sign.
  Int128 unsignedShiftRight(int n) => Int128._(_bits >> n);

  /// Arithmetic (sign-propagating) right shift.
  Int128 operator >>(int n) {
    final shift = n & 127;
    final logical = _bits >> shift;
    if (!isNegative || shift == 0) return Int128._(logical);
    final mask = ~(Uint128.max >> shift);
    return Int128._(logical | mask);
  }

  /// Truncating division (toward zero). `Int128.min ~/ Int128.minusOne`
  /// wraps back to `Int128.min` (the one case where the mathematical
  /// quotient doesn't fit).
  Int128 operator ~/(Int128 other) {
    if (other.isZero) throw IntegerError.divisionByZero;
    if (this == Int128.min && other == Int128.minusOne) return Int128.min;
    final negResult = isNegative != other.isNegative;
    final aMag = isNegative ? (-this)._bits : _bits;
    final bMag = other.isNegative ? (-other)._bits : other._bits;
    final q = aMag ~/ bMag;
    final result = Int128._(q);
    return negResult ? -result : result;
  }

  /// Truncating remainder (same sign as the dividend), consistent with
  /// `operator ~/` above.
  Int128 operator %(Int128 other) => this - (this ~/ other) * other;

  // ---- overflow-checked arithmetic ----

  Int128 addChecked(Int128 other) {
    final overflow =
        isNegative == other.isNegative && (this + other).isNegative != isNegative;
    final r = this + other;
    if (overflow) throw IntegerError.overflow;
    return r;
  }

  /// `-other` wraps back to `Int128.min` itself when `other == Int128.min`
  /// (no positive counterpart in two's complement), so that case can't go
  /// through `addChecked(-other)` like every other value can. `this -
  /// Int128.min` only fits the signed range when `this` is negative, in
  /// which case the plain wrapping subtract is already exact.
  Int128 subChecked(Int128 other) {
    if (other == Int128.min) {
      if (!isNegative) throw IntegerError.overflow;
      return this - other;
    }
    return addChecked(-other);
  }

  /// Detects overflow via round-trip: wrap-multiply then divide back out.
  /// Detects overflow via round-trip: wrap-multiply then divide back out.
  ///
  /// `Int128.min * Int128.minusOne` needs an explicit guard — see the
  /// matching comment on `Int32.mulChecked` for why.
  Int128 mulChecked(Int128 other) {
    if ((this == Int128.min && other == Int128.minusOne) ||
        (this == Int128.minusOne && other == Int128.min)) {
      throw IntegerError.overflow;
    }
    if (isZero || other.isZero) return Int128.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  Int128 abs() => isNegative ? -this : this; // wraps to itself at Int128.min

  // ---- comparisons ----

  static const Uint128 _signMask = Uint128.unsafe(
    Uint64.unsafe(_signBit32, 0),
    Uint64.zero,
  );

  /// Flips the top bit on both operands, which turns two's-complement
  /// ordering into plain unsigned ordering — then delegates to
  /// `Uint128.compareTo`.
  @override
  int compareTo(Int128 other) {
    final a = _bits ^ _signMask;
    final b = other._bits ^ _signMask;
    return a.compareTo(b);
  }

  bool operator <(Int128 other) => compareTo(other) < 0;
  bool operator <=(Int128 other) => compareTo(other) <= 0;
  bool operator >(Int128 other) => compareTo(other) > 0;
  bool operator >=(Int128 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Int128 && _bits == other._bits;

  @override
  int get hashCode => _bits.hashCode;

  // ---- cross-type converters ----

  /// Truncating cast, keeps the low 32 bits.
  ///
  /// Equivalent to Rust:
  /// `self as u32`
  Uint32 toUint32() => _bits.toUint32();

  /// Truncating cast, keeps the low 64 bits.
  ///
  /// Equivalent to Rust:
  /// `self as u64`
  Uint64 toUint64() => _bits.toUint64();

  /// Same-width bit reinterpretation.
  ///
  /// Examples:
  /// Int128(-1).toUint128() == Uint128.max
  /// Int128.min.toUint128() == 1 << 127
  Uint128 toUint128() => _bits;

  /// Zero/sign extending cast to 256 bits.
  ///
  /// Negative numbers are sign extended:
  /// -1 -> 0xffff...ffff
  ///
  /// Positive numbers are zero extended.
  Uint256 toUint256() {
    final ext = isNegative ? Uint64.max : Uint64.zero;
    return Uint256.unsafe(ext, ext, _bits.hi, _bits.lo);
  }

  /// Same-width reinterpretation.
  ///
  /// Int128(-1).toInt128() == this
  Int128 toInt128() => this;

  /// Signed narrowing to Int32.
  ///
  /// Keeps low 32 bits.
  Int32 toInt32() => Int32.unsafe(_bits.lo.lo);

  /// Signed narrowing to Int64.
  ///
  /// Keeps low 64 bits.
  Int64 toInt64() => Int64.unsafe(_bits.lo);
}
