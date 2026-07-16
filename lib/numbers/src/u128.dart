import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exception/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';

import 'i128.dart';
import 'i32.dart';
import 'i64.dart';
import 'u256.dart';
import 'u32.dart';
import 'u64.dart';

class Uint128 implements Comparable<Uint128> {
  final Uint64 _hi;
  final Uint64 _lo;

  const Uint128._(this._hi, this._lo);

  static const Uint128 zero = Uint128._(Uint64.zero, Uint64.zero);
  static const Uint128 one = Uint128._(Uint64.zero, Uint64.one);
  static const Uint128 max = Uint128._(Uint64.max, Uint64.max);

  /// Raw limb constructor — prefer [Uint128.new] / [Uint128.fromBigInt]
  /// for arbitrary values.
  const Uint128.unsafe(this._hi, this._lo);

  /// Builds from a plain Dart [int]. Must be non-negative (same
  /// constraint as `Uint64.new`).
  factory Uint128(int value) => Uint128._(Uint64.zero, Uint64(value));

  factory Uint128.fromUint64(Uint64 value) => Uint128._(Uint64.zero, value);

  /// Builds from a plain Dart [int], accepting negative values by taking
  /// their two's-complement bit pattern (masked to 128 bits) instead of
  /// throwing like [Uint128.new] does — e.g. `Uint128.from(-1) ==
  /// Uint128.max`. [value] must itself be a normal double-safe Dart int
  /// (`|value| <= 2^53`); BigInt-free, same limb-splitting negation trick
  /// as `Uint64.from`, sign-extended into the high limb.
  factory Uint128.from(int value) {
    final isNeg = value < 0;
    final mag = isNeg ? -value : value; // safe: |value| <= 2^53
    final magBits = Uint64.unsafe(mag ~/ 0x100000000, mag % 0x100000000);
    final loBits = isNeg ? (~magBits) + Uint64.one : magBits;
    final ext = isNeg ? Uint64.max : Uint64.zero;
    return Uint128._(ext, loBits);
  }

  factory Uint128.fromBigInt(BigInt value) {
    if (value.isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "fromBigInt",
        reason: 'value must be non-negative',
      );
    }
    final v = value.toUnsigned(128);
    final hi = Uint64.fromBigInt(v >> 64);
    final lo = Uint64.fromBigInt(v.toUnsigned(64));
    return Uint128._(hi, lo);
  }

  static Uint128 parseHex(String s) {
    var hex = (s.startsWith('0x') || s.startsWith('0X')) ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 32) {
      throw ArgumentException.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    hex = hex.padLeft(32, '0');
    final hi = Uint64.parseHex('0x${hex.substring(0, 16)}');
    final lo = Uint64.parseHex('0x${hex.substring(16, 32)}');
    return Uint128._(hi, lo);
  }

  /// Strict decimal parse: throws [IntegerError] on overflow, unlike
  /// the wrapping operators.
  static Uint128 parseDecimal(String s) {
    if (s.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    var acc = Uint128.zero;
    final ten = Uint128(10);
    for (final rune in s.codeUnits) {
      final digit = Uint128(rune - 0x30);
      final scaled = acc.mulChecked(ten); // throws on overflow
      final next = scaled + digit;
      if (next < scaled) {
        throw IntegerError.overflow;
      }
      acc = next;
    }
    return acc;
  }

  // ---- conversions ----

  BigInt toBigInt() => (_hi.toBigInt() << 64) | _lo.toBigInt();

  /// Only safe if the value fits in the hi limb being zero and the lo
  /// limb being double-safe — delegates to `Uint64.toInt()`'s own guard,
  /// throwing [IntegerError] otherwise (use [toBigInt] for the general
  /// case).
  int toInt() {
    if (!_hi.isZero) {
      throw IntegerError.toIntConvertionError;
    }
    return _lo.toInt();
  }

  String toHexString({bool padded = true}) {
    final hex = '${_hi.toHexString()}${_lo.toHexString()}';
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() {
    if (isZero) return '0';
    final digits = <String>[];
    var rem = this;
    final ten = Uint128(10);
    while (!rem.isZero) {
      final qr = rem._divMod(ten);
      digits.add(qr.remainder._lo.toString()); // remainder < 10: a single digit
      rem = qr.quotient;
    }
    return digits.reversed.join();
  }

  /// Fixed 16-byte encoding, delegating to each Uint64 limb's own
  /// (already web-safe) 8-byte encoding.
  List<int> toBytes([Endian endian = Endian.big]) {
    final out = List<int>.filled(16, 0);
    if (endian == Endian.big) {
      out.setRange(0, 8, _hi.toBytes(Endian.big));
      out.setRange(8, 16, _lo.toBytes(Endian.big));
    } else {
      out.setRange(0, 8, _lo.toBytes(Endian.little));
      out.setRange(8, 16, _hi.toBytes(Endian.little));
    }
    return out;
  }

  static Uint128 fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
    int offset = 0,
  }) {
    if (offset < 0 || bytes.length - offset < 16) {
      throw ArgumentException.invalidOperationArguments(
        "Uint128.fromBytes",
        reason: 'Need at least 16 bytes from offset.',
        details: {
          "offset": offset.toString(),
          "length": bytes.length.toString(),
        },
      );
    }

    if (endian == Endian.big) {
      final hi = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset);
      final lo = Uint64.fromBytes(
        bytes,
        endian: Endian.big,
        offset: offset + 8,
      );
      return Uint128._(hi, lo);
    } else {
      final lo = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset);
      final hi = Uint64.fromBytes(
        bytes,
        endian: Endian.little,
        offset: offset + 8,
      );
      return Uint128._(hi, lo);
    }
  }

  // ---- properties ----

  bool get isZero => _hi.isZero && _lo.isZero;
  bool get isEven => _lo.isEven;
  Uint64 get hi => _hi;
  Uint64 get lo => _lo;

  // ---- wrapping arithmetic operators ----

  Uint128 operator +(Uint128 other) {
    final (loSum, carry) = Uint64.adc(_lo, other._lo, Uint64.zero);
    final hiSum = _hi + other._hi + carry;
    return Uint128._(hiSum, loSum);
  }

  Uint128 operator -(Uint128 other) {
    final (loDiff, borrowMask) = Uint64.sbb(_lo, other._lo, Uint64.zero);
    final borrowBit = borrowMask.isZero ? Uint64.zero : Uint64.one;
    final hiDiff = _hi - other._hi - borrowBit;
    return Uint128._(hiDiff, loDiff);
  }

  /// Multiply, keeping only the low 128 bits (wrapping). Built entirely
  /// from `Uint64.widenMul` (the full 64x64->128 product of the low
  /// limbs) plus wrapping 64-bit multiplies for the cross terms — the
  /// same decomposition `Uint64.operator*` itself uses one level down.
  Uint128 operator *(Uint128 other) {
    final (mHi, mLo) = Uint64.widenMul(_lo, other._lo);
    final cross =
        (_hi * other._lo) + (_lo * other._hi); // both already mod 2^64
    final hi = mHi + cross;
    return Uint128._(hi, mLo);
  }

  Uint128 operator ~/(Uint128 other) => _divMod(other).quotient;

  Uint128 operator %(Uint128 other) => _divMod(other).remainder;

  ({Uint128 quotient, Uint128 remainder}) _divMod(Uint128 other) {
    if (other.isZero) throw IntegerError.divisionByZero;
    if (compareTo(other) < 0) return (quotient: Uint128.zero, remainder: this);
    var quotient = Uint128.zero;
    var remainder = Uint128.zero;
    for (var i = 127; i >= 0; i--) {
      remainder = remainder._shl1();
      if (_bit(i) != 0) {
        remainder = Uint128._(remainder._hi, remainder._lo | Uint64.one);
      }
      if (remainder.compareTo(other) >= 0) {
        remainder = remainder - other;
        quotient = quotient._setBit(i);
      }
    }
    return (quotient: quotient, remainder: remainder);
  }

  int _bit(int i) {
    final limb = i < 64 ? _lo : _hi;
    final shift = i < 64 ? i : i - 64;
    return ((limb >> shift) & Uint64.one).isZero ? 0 : 1;
  }

  Uint128 _setBit(int i) {
    final bitVal = Uint64.one << (i < 64 ? i : i - 64);
    return i < 64 ? Uint128._(_hi, _lo | bitVal) : Uint128._(_hi | bitVal, _lo);
  }

  Uint128 _shl1() {
    final newHi = (_hi << 1) | (_lo >> 63);
    final newLo = _lo << 1;
    return Uint128._(newHi, newLo);
  }

  // ---- overflow-checked arithmetic ----

  Uint128 addChecked(Uint128 other) {
    final r = this + other;
    if (r < this) throw IntegerError.overflow;
    return r;
  }

  Uint128 subChecked(Uint128 other) {
    if (other > this) throw IntegerError.overflow;
    return this - other;
  }

  Uint128 mulChecked(Uint128 other) {
    if (isZero || other.isZero) return Uint128.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  // ---- bitwise operators ----

  Uint128 operator &(Uint128 other) =>
      Uint128._(_hi & other._hi, _lo & other._lo);

  Uint128 operator |(Uint128 other) =>
      Uint128._(_hi | other._hi, _lo | other._lo);

  Uint128 operator ^(Uint128 other) =>
      Uint128._(_hi ^ other._hi, _lo ^ other._lo);

  Uint128 operator ~() => Uint128._(~_hi, ~_lo);

  /// Logical left shift. Each step here is a plain `Uint64` shift/bitwise
  /// op — already proven web-safe in `Uint64` itself — so no additional
  /// safety trick is needed at this width.
  Uint128 operator <<(int n) {
    final shift = n & 127;
    if (shift == 0) return this;
    if (shift < 64) {
      final newHi = (_hi << shift) | (_lo >> (64 - shift));
      final newLo = _lo << shift;
      return Uint128._(newHi, newLo);
    }
    final s = shift - 64;
    return Uint128._(_lo << s, Uint64.zero);
  }

  /// Logical (unsigned) right shift.
  Uint128 operator >>(int n) {
    final shift = n & 127;
    if (shift == 0) return this;
    if (shift < 64) {
      final newLo = (_lo >> shift) | (_hi << (64 - shift));
      final newHi = _hi >> shift;
      return Uint128._(newHi, newLo);
    }
    final s = shift - 64;
    return Uint128._(Uint64.zero, _hi >> s);
  }

  // ---- comparisons ----

  @override
  int compareTo(Uint128 other) {
    final hiCmp = _hi.compareTo(other._hi);
    if (hiCmp != 0) return hiCmp;
    return _lo.compareTo(other._lo);
  }

  bool operator <(Uint128 other) => compareTo(other) < 0;
  bool operator <=(Uint128 other) => compareTo(other) <= 0;
  bool operator >(Uint128 other) => compareTo(other) > 0;
  bool operator >=(Uint128 other) => compareTo(other) >= 0;

  @override
  bool operator ==(Object other) =>
      other is Uint128 && _hi == other._hi && _lo == other._lo;

  @override
  int get hashCode => Object.hash(_hi, _lo);

  // ---- cross-type converters ----

  /// Truncating narrow: keeps only the low 32 bits (wrapping, like a
  /// Rust `as u32` cast).
  Uint32 toUint32() => Uint32.unsafe(_lo.lo);

  /// Truncating narrow: keeps only the low 64 bits (wrapping, like a
  /// Rust `as u64` cast).
  Uint64 toUint64() => _lo;

  /// Zero-extending widen. Always exact.
  Uint256 toUint256() => Uint256.unsafe(Uint64.zero, Uint64.zero, _hi, _lo);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i32`
  /// cast).
  Int32 toInt32() => Int32.unsafe(_lo.lo);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i64`
  /// cast).
  Int64 toInt64() => Int64.unsafe(_lo);

  /// Same-width bit reinterpretation (two's complement) — e.g.
  /// `Uint128.max.toInt128() == Int128.minusOne`.
  Int128 toInt128() => Int128.unsafe(this);
}
