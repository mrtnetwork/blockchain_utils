import 'dart:typed_data' show Endian, Uint8List;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/i32.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

const int _mask32 = 0xFFFFFFFF;
const int _mask16 = 0xFFFF;

class Uint32 implements Comparable<Uint32> {
  /// Canonical bit pattern, always `< 2^32` and therefore exact as a
  /// double on every backend.
  final int _value;

  const Uint32._(this._value);

  static const Uint32 zero = Uint32._(0);
  static const Uint32 one = Uint32._(1);
  static const Uint32 two = Uint32._(2);
  static const Uint32 max = Uint32._(_mask32);

  /// Raw bit-pattern constructor — [value] must already be in
  /// `[0, 0xFFFFFFFF]`. Prefer [Uint32.new] for arbitrary Dart ints.
  const Uint32.unsafe(this._value);

  factory Uint32(int value) {
    if (value < 0) {
      throw ArgumentException.invalidOperationArguments(
        "Uint32",
        reason: 'value must be non-negative',
      );
    }
    return Uint32._(value & _mask32);
  }

  /// Builds from a plain Dart [int], accepting negative values by taking
  /// their two's-complement bit pattern (masked to 32 bits) instead of
  /// throwing like [Uint32.new] does — e.g. `Uint32.from(-1) == Uint32.max`.
  /// Mirrors the masking `Int32.new` already does for negative input.
  factory Uint32.from(int value) => Uint32._(value % 0x100000000);

  factory Uint32.fromBigInt(BigInt value) {
    if (value.isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "fromBigInt",
        reason: 'value must be non-negative',
      );
    }
    return Uint32._(value.toUnsigned(32).toInt());
  }

  static Uint32 parseHex(String s) {
    final hex = (s.startsWith('0x') || s.startsWith('0X')) ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 8 || !RegExp(r'^[0-9a-fA-F]+$').hasMatch(hex)) {
      throw ArgumentException.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    return Uint32._(int.parse(hex, radix: 16) & _mask32);
  }

  /// Strict decimal parse: throws [IntegerError] on overflow, unlike
  /// the wrapping constructor.
  static Uint32 parseDecimal(String s) {
    // A valid u32 has at most 10 digits ("4294967295"); rejecting longer
    // strings up front means int.parse below never sees more digits than
    // that, so it stays exact on web.
    if (s.isEmpty || s.length > 10 || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    final v = int.parse(s);
    if (v > _mask32) throw IntegerError.overflow;
    return Uint32._(v);
  }

  // ---- conversions ----

  BigInt toBigInt() => BigInt.from(_value);

  /// Always safe: `_value` is always `< 2^32`, far inside the
  /// double-safe integer range.
  int toInt() => _value;

  double toDouble() => _value.toDouble();

  String toHexString({bool padded = true}) {
    final hex = _value.toRadixString(16).padLeft(8, '0');
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() => _value.toString();

  Uint8List toBytes([Endian endian = Endian.big]) {
    final out = Uint8List(4);
    if (endian == Endian.big) {
      out[0] = (_value >>> 24) & 0xFF;
      out[1] = (_value >>> 16) & 0xFF;
      out[2] = (_value >>> 8) & 0xFF;
      out[3] = _value & 0xFF;
    } else {
      out[0] = _value & 0xFF;
      out[1] = (_value >>> 8) & 0xFF;
      out[2] = (_value >>> 16) & 0xFF;
      out[3] = (_value >>> 24) & 0xFF;
    }
    return out;
  }

  static Uint32 fromBytes(List<int> bytes, {Endian endian = Endian.big, int offset = 0}) {
    if (offset < 0 || bytes.length - offset < 4) {
      throw ArgumentException.invalidOperationArguments(
        "Uint32.fromBytes",
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
    return Uint32._(v & _mask32);
  }

  // ---- properties ----

  bool get isZero => _value == 0;
  bool get isEven => (_value & 1) == 0;

  /// Raw bit pattern as an unsigned `int` (`0..0xFFFFFFFF`).
  int get rawBits => _value;

  // ---- wrapping arithmetic operators ----

  Uint32 operator +(Uint32 other) => Uint32._((_value + other._value) & _mask32);

  Uint32 operator -(Uint32 other) {
    var v = _value - other._value;
    if (v < 0) v += 0x100000000;
    return Uint32._(v);
  }

  /// Multiply, keeping only the low 32 bits (wrapping). Two 32-bit
  /// magnitudes multiplied directly can reach ~2^64 — unsafe as a double
  /// on web — so this decomposes into 16-bit limbs first, the same way
  /// `Uint64.operator*` and `Int32.operator*` do.
  Uint32 operator *(Uint32 other) {
    final a = _value, b = other._value;
    final aLo = a & _mask16, aHi = (a >>> 16) & _mask16;
    final bLo = b & _mask16, bHi = (b >>> 16) & _mask16;
    final lo = aLo * bLo; // < 2^32, safe
    final cross = (aLo * bHi + aHi * bLo) & _mask16; // terms < 2^32, sum < 2^33, safe
    final result = (lo + (cross << 16)) & _mask32; // both terms < 2^32, safe
    return Uint32._(result);
  }

  /// Both operands are always `< 2^32` (well within the double-safe
  /// range), so plain `int` division/modulo here is exact directly — no
  /// BigInt or limb decomposition needed.
  Uint32 operator ~/(Uint32 other) {
    if (other.isZero) throw IntegerError.divisionByZero;
    return Uint32._(_value ~/ other._value);
  }

  Uint32 operator %(Uint32 other) {
    if (other.isZero) throw IntegerError.divisionByZero;
    return Uint32._(_value % other._value);
  }

  // ---- overflow-checked arithmetic ----

  Uint32 addChecked(Uint32 other) {
    final r = this + other;
    if (r < this) throw IntegerError.overflow;
    return r;
  }

  Uint32 subChecked(Uint32 other) {
    if (other > this) throw IntegerError.overflow;
    return this - other;
  }

  /// The true product of two u32s can reach ~2^64 — still safe as a
  /// double (well under 2^53 is false here, so this uses the same
  /// wrapping `*` plus a division round-trip check rather than forming
  /// the full product directly).
  Uint32 mulChecked(Uint32 other) {
    if (isZero || other.isZero) return Uint32.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  // ---- bitwise operators ----

  Uint32 operator &(Uint32 other) => Uint32._(_value & other._value);

  Uint32 operator |(Uint32 other) => Uint32._(_value | other._value);

  Uint32 operator ^(Uint32 other) => Uint32._((_value ^ other._value) & _mask32);

  Uint32 operator ~() => Uint32._(_mask32 - _value);

  /// Shifts a 32-bit-range value left by 0..31 bits without ever forming
  /// an intermediate above 2^53 — see the doc comment on
  /// `Int32._safeShl32` for why a plain `value << shift` would not be
  /// safe here for large values/shifts.
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

  Uint32 operator <<(int n) {
    final shift = n & 31;
    return Uint32._(_safeShl32(_value, shift) & _mask32);
  }

  /// Logical right shift (the only kind that applies to an unsigned
  /// type). Right shift only shrinks magnitude, so this is always safe
  /// directly.
  Uint32 operator >>(int n) {
    final shift = n & 31;
    if (shift == 0) return this;
    return Uint32._(_value >>> shift);
  }

  @override
  int compareTo(Uint32 other) =>
      _value < other._value
          ? -1
          : _value > other._value
          ? 1
          : 0;

  bool operator <(Uint32 other) => compareTo(other) < 0;
  bool operator <=(Uint32 other) => compareTo(other) <= 0;
  bool operator >(Uint32 other) => compareTo(other) > 0;
  bool operator >=(Uint32 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) => other is Uint32 && _value == other._value;
  Uint32 operator -() => Uint32.zero - this;

  @override
  int get hashCode => _value.hashCode;

  // ---- cross-type converters ----
  //
  // Widening (-> a wider unsigned/signed type) is always exact: this
  // value zero-extends into the extra limbs. Narrowing back down to a
  // same-or-smaller width isn't offered here since Uint32 is already the
  // narrowest unsigned type in this family; same-width reinterpretation
  // (-> Int32) just relabels the existing bit pattern as two's complement.

  /// Zero-extending widen. Always exact.
  Uint64 toUint64() => Uint64.unsafe(0, _value);

  /// Zero-extending widen. Always exact.
  Uint128 toUint128() => Uint128.fromUint64(toUint64());

  /// Zero-extending widen. Always exact.
  Uint256 toUint256() => Uint256.fromUint64(toUint64());

  /// Same-width bit reinterpretation (two's complement) — e.g.
  /// `Uint32.max.toInt32() == Int32.minusOne`.
  Int32 toInt32() => Int32.unsafe(_value);

  /// Zero-extending widen, then reinterpret — always non-negative and
  /// exact, since a 32-bit magnitude always fits in a positive Int64.
  Int64 toInt64() => toUint64().toInt64();

  /// Zero-extending widen, then reinterpret — always non-negative and
  /// exact for the same reason as [toInt64].
  Int128 toInt128() => Int128.unsafe(toUint128());
}
