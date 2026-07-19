import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u32.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:blockchain_utils/utils/utils.dart';

const int _signBit32 = 0x80000000;

class Int32 implements Comparable<Int32> {
  /// Canonical two's-complement bit pattern, stored as an unsigned value
  /// in `[0, 0xFFFFFFFF]`. Always exact as a double on every backend.
  final int _bits;

  const Int32._(this._bits);

  static const Int32 zero = Int32._(0);
  static const Int32 one = Int32._(1);
  static const Int32 minusOne = Int32._(BinaryOps.mask32);
  static const Int32 max = Int32._(0x7FFFFFFF);
  static const Int32 min = Int32._(_signBit32);
  static const Int32 mask8 = Int32._(0xFF);

  int get bits => _bits;

  /// Raw bit-pattern constructor — [bits] must already be in
  /// `[0, 0xFFFFFFFF]`. Prefer [Int32.new] for arbitrary Dart ints.
  const Int32.unsafe(this._bits) : assert(_bits >= 0 && _bits <= BinaryOps.mask32);

  /// Builds from a plain Dart [int] (positive or negative), truncating to
  /// 32 bits like a `wrapping` cast. [value] must itself be a normal,
  /// double-safe Dart int (true for any literal or value that didn't
  /// already come from a wider fixed-width type).
  factory Int32(int value) {
    if (value >= 0) return Int32._(value & BinaryOps.mask32);
    var v = value % 0x100000000; // Dart's % is non-negative for a positive divisor.
    return Int32._(v & BinaryOps.mask32);
  }

  factory Int32.fromBigInt(BigInt value) => Int32._(value.toUnsigned(32).toInt());

  static Int32 parseHex(String s) {
    final hex = (s.startsWith('0x') || s.startsWith('0X')) ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 8 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw ArgumentException.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    return Int32._(int.parse(hex, radix: 16) & BinaryOps.mask32);
  }

  /// Strict decimal parse: throws [IntegerError] on overflow/underflow,
  /// unlike the wrapping constructor.
  static Int32 parseDecimal(String s) {
    if (s.isEmpty) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    final negative = s.startsWith('-');
    final digits = negative ? s.substring(1) : s;
    // A valid i32 magnitude has at most 10 digits ("2147483648"); rejecting
    // longer strings up front means int.parse below never sees more digits
    // than that, so it stays exact on web.
    if (digits.isEmpty || digits.length > 10 || !RegExp(r'^[0-9]+$').hasMatch(digits)) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    final mag = int.parse(digits);
    if (negative) {
      if (mag > 0x80000000) throw IntegerError.overflow;
      return Int32._((0x100000000 - mag) & BinaryOps.mask32);
    } else {
      if (mag > 0x7FFFFFFF) throw IntegerError.overflow;
      return Int32._(mag);
    }
  }

  // ---- conversions ----

  BigInt toBigInt() => BigInt.from(_bits).toSigned(32);

  /// Always safe: `_bits` is always `< 2^32`, far inside the double-safe
  /// integer range, so this is just a sign-extension, never a precision
  /// concern.
  int toInt() => _bits >= _signBit32 ? _bits - 0x100000000 : _bits;

  double toDouble() => toInt().toDouble();

  String toHexString({bool padded = true}) {
    final hex = _bits.toRadixString(16).padLeft(8, '0');
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() => toInt().toString();

  List<int> toBytes([Endian endian = Endian.big]) {
    final out = List<int>.filled(4, 0);
    if (endian == Endian.big) {
      out[0] = (_bits >>> 24) & 0xFF;
      out[1] = (_bits >>> 16) & 0xFF;
      out[2] = (_bits >>> 8) & 0xFF;
      out[3] = _bits & 0xFF;
    } else {
      out[0] = _bits & 0xFF;
      out[1] = (_bits >>> 8) & 0xFF;
      out[2] = (_bits >>> 16) & 0xFF;
      out[3] = (_bits >>> 24) & 0xFF;
    }
    return out;
  }

  static Int32 fromBytes(List<int> bytes, {Endian endian = Endian.big, int offset = 0}) {
    if (offset < 0 || bytes.length - offset < 4) {
      throw ArgumentException.invalidOperationArguments(
        "Int32.fromBytes",
        reason: 'Need at least 4 bytes from offset.',
        details: {"offset": offset.toString(), "length": bytes.length.toString()},
      );
    }
    int v;
    if (endian == Endian.big) {
      v =
          (bytes[offset] << 24) |
          (bytes[offset + 1] << 16) |
          (bytes[offset + 2] << 8) |
          bytes[offset + 3];
    } else {
      v =
          (bytes[offset + 3] << 24) |
          (bytes[offset + 2] << 16) |
          (bytes[offset + 1] << 8) |
          bytes[offset];
    }
    return Int32._(v & BinaryOps.mask32);
  }

  // ---- properties ----

  bool get isZero => _bits == 0;
  bool get isNegative => _bits >= _signBit32;
  bool get isEven => (_bits & 1) == 0;

  /// Raw two's-complement bit pattern as an unsigned `int` (`0..0xFFFFFFFF`).
  int get rawBits => _bits;

  // ---- wrapping arithmetic operators ----

  Int32 operator +(Int32 other) => Int32._((_bits + other._bits) & BinaryOps.mask32);

  Int32 operator -(Int32 other) {
    var v = _bits - other._bits;
    if (v < 0) v += 0x100000000;
    return Int32._(v);
  }

  Int32 operator -() => Int32.zero - this; // wraps to itself at Int32.min

  /// Multiply, keeping only the low 32 bits (wrapping). Two 32-bit
  /// magnitudes multiplied directly can reach ~2^64 — unsafe as a double
  /// on web — so this decomposes into 16-bit limbs first, the same way
  /// `Uint64.operator*` does.
  Int32 operator *(Int32 other) {
    final a = _bits, b = other._bits;
    final aLo = a & BinaryOps.mask16, aHi = (a >>> 16) & BinaryOps.mask16;
    final bLo = b & BinaryOps.mask16, bHi = (b >>> 16) & BinaryOps.mask16;
    final lo = aLo * bLo; // < 2^32, safe
    final cross =
        (aLo * bHi + aHi * bLo) & BinaryOps.mask16; // terms < 2^32, sum < 2^33, safe
    final result = (lo + (cross << 16)) & BinaryOps.mask32; // both terms < 2^32, safe
    return Int32._(result);
  }

  /// Truncating division (toward zero), like Rust's `/` or C's `/`.
  /// `Int32.min ~/ Int32.minusOne` wraps back to `Int32.min` (the one
  /// case where the mathematical quotient doesn't fit).
  Int32 operator ~/(Int32 other) {
    if (other.isZero) throw IntegerError.overflow;
    if (this == Int32.min && other == Int32.minusOne) return Int32.min;
    return Int32(toInt() ~/ other.toInt()); // magnitudes <= 2^31, safe
  }

  /// Truncating remainder (same sign as the dividend), consistent with
  /// `operator ~/` above — this is `remainder()` semantics, not Dart's
  /// Euclidean `%`.
  Int32 operator %(Int32 other) => this - (this ~/ other) * other;

  // ---- overflow-checked arithmetic ----

  Int32 addChecked(Int32 other) {
    final r = toInt() + other.toInt(); // both safe magnitudes, sum safe too
    if (r < -0x80000000 || r > 0x7FFFFFFF) throw IntegerError.overflow;
    return Int32(r);
  }

  /// `-other` wraps back to `Int32.min` itself when `other == Int32.min`
  /// (there's no positive counterpart in two's complement), so that case
  /// can't go through `addChecked(-other)` like every other value can.
  /// `this - Int32.min` only fits the signed range when `this` is
  /// negative, in which case the plain wrapping subtract is already
  /// exact (never actually wraps).
  Int32 subChecked(Int32 other) {
    if (other == Int32.min) {
      if (!isNegative) throw IntegerError.overflow;
      return this - other;
    }
    return addChecked(-other);
  }

  /// Detects overflow via round-trip: wrap-multiply then divide back out —
  /// same technique every sibling `mulChecked` uses, BigInt-free.
  ///
  /// `Int32.min * Int32.minusOne` needs an explicit guard: `~/` itself
  /// special-cases `min ~/ minusOne` to wrap back to `min` (matching real
  /// hardware behavior), which would otherwise make the round-trip check
  /// below look "clean" even though the true product (`2^31`) overflows.
  Int32 mulChecked(Int32 other) {
    if ((this == Int32.min && other == Int32.minusOne) ||
        (this == Int32.minusOne && other == Int32.min)) {
      throw IntegerError.overflow;
    }
    if (isZero || other.isZero) return Int32.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  Int32 abs() => isNegative ? -this : this; // wraps to itself at Int32.min

  // ---- bitwise operators ----

  Int32 operator &(Int32 other) => Int32._(_bits & other._bits);

  Int32 operator |(Int32 other) => Int32._(_bits | other._bits);

  Int32 operator ^(Int32 other) => Int32._((_bits ^ other._bits) & BinaryOps.mask32);

  Int32 operator ~() => Int32._(BinaryOps.mask32 - _bits);

  /// Shifts a 32-bit-range value left by 0..15 or 16..31 bits, computing
  /// `(value << shift) & 0xFFFFFFFF` without ever forming an intermediate
  /// above 2^53. A plain `value << shift` here would be mathematically
  /// correct but, for a large [value] and [shift], the *unmasked*
  /// intermediate can reach ~2^63 — silently imprecise as a double on
  /// dart2js/dart2wasm. Every step below stays under 2^32.
  static int _safeShl32(int value, int shift) {
    if (shift == 0) return value;
    final lo16 = value & BinaryOps.mask16;
    final hi16 = (value >>> 16) & BinaryOps.mask16;
    if (shift < 16) {
      final newLo = (lo16 << shift) & BinaryOps.mask16;
      final carry = lo16 >>> (16 - shift);
      final newHi = ((hi16 << shift) & BinaryOps.mask16) | carry;
      return (newHi << 16) | newLo;
    }
    final s = shift - 16;
    final newHi = (lo16 << s) & BinaryOps.mask16;
    return newHi << 16;
  }

  /// Logical left shift (bits shifted out the top are discarded).
  Int32 operator <<(int n) {
    final shift = n & 31;
    return Int32._(_safeShl32(_bits, shift) & BinaryOps.mask32);
  }

  /// Arithmetic (sign-propagating) right shift.
  Int32 operator >>(int n) {
    final shift = n & 31;
    if (shift == 0) return this;
    // toInt() is always safe (magnitude <= 2^31), and a right shift only
    // shrinks magnitude, so the plain core `>>` is safe here too.
    return Int32._((toInt() >> shift) & BinaryOps.mask32);
  }

  /// Logical (unsigned) right shift — top bits filled with zero regardless
  /// of sign.
  Int32 operator >>>(int n) {
    final shift = n & 31;
    if (shift == 0) return this;
    return Int32._(
      (_bits >>> shift) & BinaryOps.mask32,
    ); // right shift only shrinks magnitude: safe
  }

  // ---- comparisons ----

  @override
  int compareTo(Int32 other) {
    final a = toInt();
    final b = other.toInt();
    return a < b
        ? -1
        : a > b
        ? 1
        : 0;
  }

  bool operator <(Int32 other) => compareTo(other) < 0;
  bool operator <=(Int32 other) => compareTo(other) <= 0;
  bool operator >(Int32 other) => compareTo(other) > 0;
  bool operator >=(Int32 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Int32 && _bits == other._bits;

  @override
  int get hashCode => _bits.hashCode;
  int toUint8() {
    return (this & Int32.mask8).toInt();
  }

  // ---- cross-type converters ----

  /// Same-width bit reinterpretation (two's complement) — e.g.
  /// `Int32.minusOne.toUint32() == Uint32.max`.
  Uint32 toUint32() => Uint32.unsafe(_bits);

  /// Sign-extending widen, then reinterpret — e.g. `Int32.minusOne`
  /// widens to all-ones, so `toUint64()` is `Uint64.max`, not `Uint32.max`.
  Int64 toInt64() => Int64.unsafe(
    Uint64.unsafe((_bits & _signBit32) != 0 ? BinaryOps.mask32 : 0, _bits),
  );

  /// Sign-extending widen (via [toInt64]'s bit pattern), then reinterpret.
  Uint64 toUint64() => toInt64().rawBits;

  /// Sign-extending widen (via [toInt64]), then reinterpret.
  Uint128 toUint128() => toInt64().toUint128();

  /// Sign-extending widen (via [toInt64]), then reinterpret.
  Uint256 toUint256() => toInt64().toUint256();

  /// Sign-extending widen (via [toInt64]).
  Int128 toInt128() => toInt64().toInt128();
}
