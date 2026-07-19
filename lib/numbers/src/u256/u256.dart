import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/i32.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u32.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

import 'u256_mul/u256_math.dart';

import 'u256_div/u256_div.dart';

class Uint256 implements Comparable<Uint256> {
  final Uint64 _d3; // most significant 64 bits (bits 192..255)
  final Uint64 _d2; // bits 128..191
  final Uint64 _d1; // bits 64..127
  final Uint64 _d0; // least significant 64 bits (bits 0..63)

  const Uint256._(this._d3, this._d2, this._d1, this._d0);

  static const Uint256 zero = Uint256._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  );
  static const Uint256 one = Uint256._(Uint64.zero, Uint64.zero, Uint64.zero, Uint64.one);
  static const Uint256 max = Uint256._(Uint64.max, Uint64.max, Uint64.max, Uint64.max);
  static const Uint256 two = Uint256._(Uint64.zero, Uint64.zero, Uint64.zero, Uint64.two);

  /// Raw limb constructor (most-significant limb first) — prefer
  /// [Uint256.new] / [Uint256.fromBigInt] for arbitrary values.
  const Uint256.unsafe(this._d3, this._d2, this._d1, this._d0);

  /// Builds from a plain Dart [int]. Must be non-negative (same
  /// constraint as `Uint64.new`).
  factory Uint256(int value) =>
      Uint256._(Uint64.zero, Uint64.zero, Uint64.zero, Uint64(value));

  @pragma('vm:prefer-inline')
  factory Uint256.fromUint64(Uint64 value) =>
      Uint256._(Uint64.zero, Uint64.zero, Uint64.zero, value);

  /// Builds from a plain Dart [int], accepting negative values by taking
  /// their two's-complement bit pattern (masked to 256 bits) instead of
  /// throwing like [Uint256.new] does — e.g. `Uint256.from(-1) ==
  /// Uint256.max`. [value] must itself be a normal double-safe Dart int
  /// (`|value| <= 2^53`); BigInt-free, same limb-splitting negation trick
  /// as `Uint64.from`, sign-extended into the three high limbs.
  factory Uint256.from(int value) {
    final isNeg = value < 0;
    final mag = isNeg ? -value : value; // safe: |value| <= 2^53
    final magBits = Uint64.unsafe(mag ~/ 0x100000000, mag % 0x100000000);
    final loBits = isNeg ? (~magBits) + Uint64.one : magBits;
    final ext = isNeg ? Uint64.max : Uint64.zero;
    return Uint256._(ext, ext, ext, loBits);
  }

  factory Uint256.fromBigInt(BigInt value) {
    if (value.isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "fromBigInt",
        reason: 'value must be non-negative',
      );
    }
    final v = value.toUnsigned(256);
    final d3 = Uint64.fromBigInt((v >> 192).toUnsigned(64));
    final d2 = Uint64.fromBigInt((v >> 128).toUnsigned(64));
    final d1 = Uint64.fromBigInt((v >> 64).toUnsigned(64));
    final d0 = Uint64.fromBigInt(v.toUnsigned(64));
    return Uint256._(d3, d2, d1, d0);
  }

  static Uint256 parseHex(String s) {
    var hex = (s.startsWith('0x') || s.startsWith('0X')) ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 64) {
      throw ArgumentException.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    hex = hex.padLeft(64, '0');
    final d3 = Uint64.parseHex('0x${hex.substring(0, 16)}');
    final d2 = Uint64.parseHex('0x${hex.substring(16, 32)}');
    final d1 = Uint64.parseHex('0x${hex.substring(32, 48)}');
    final d0 = Uint64.parseHex('0x${hex.substring(48, 64)}');
    return Uint256._(d3, d2, d1, d0);
  }

  /// Strict decimal parse: throws [IntegerError] on overflow, unlike
  /// the wrapping operators.
  static Uint256 parseDecimal(String s) {
    if (s.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    var acc = Uint256.zero;
    final ten = Uint256(10);
    for (final rune in s.codeUnits) {
      final digit = Uint256(rune - 0x30);
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

  BigInt toBigInt() =>
      (_d3.toBigInt() << 192) |
      (_d2.toBigInt() << 128) |
      (_d1.toBigInt() << 64) |
      _d0.toBigInt();

  /// Only safe if the top three limbs are zero and the low limb is
  /// double-safe — delegates to `Uint64.toInt()`'s own guard, throwing
  /// [IntegerError] otherwise (use [toBigInt] for the general case).
  int toInt() {
    if (!_d3.isZero || !_d2.isZero || !_d1.isZero) {
      throw IntegerError.toIntConvertionError;
    }
    return _d0.toInt();
  }

  String toHexString({bool padded = true}) {
    final hex =
        '${_d3.toHexString()}${_d2.toHexString()}${_d1.toHexString()}${_d0.toHexString()}';
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() {
    if (isZero) return '0';
    final digits = <String>[];
    var rem = this;
    final ten = Uint256(10);
    while (!rem.isZero) {
      final qr = divModImpl(rem, ten);
      digits.add(qr.remainder._d0.toString()); // remainder < 10: a single digit
      rem = qr.quotient;
    }
    return digits.reversed.join();
  }

  /// Fixed 32-byte encoding, delegating to each Uint64 limb's own
  /// (already web-safe) 8-byte encoding.
  List<int> toBytes([Endian endian = Endian.big]) {
    final out = List<int>.filled(32, 0);
    if (endian == Endian.big) {
      out.setRange(0, 8, _d3.toBytes(Endian.big));
      out.setRange(8, 16, _d2.toBytes(Endian.big));
      out.setRange(16, 24, _d1.toBytes(Endian.big));
      out.setRange(24, 32, _d0.toBytes(Endian.big));
    } else {
      out.setRange(0, 8, _d0.toBytes(Endian.little));
      out.setRange(8, 16, _d1.toBytes(Endian.little));
      out.setRange(16, 24, _d2.toBytes(Endian.little));
      out.setRange(24, 32, _d3.toBytes(Endian.little));
    }
    return out;
  }

  static Uint256 fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
    int offset = 0,
  }) {
    if (offset < 0 || bytes.length - offset < 32) {
      throw ArgumentException.invalidOperationArguments(
        "Uint256.fromBytes",
        reason: 'Need at least 32 bytes from offset.',
        details: {"offset": offset.toString(), "length": bytes.length.toString()},
      );
    }
    if (endian == Endian.big) {
      final d3 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset);
      final d2 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 8);
      final d1 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 16);
      final d0 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 24);
      return Uint256._(d3, d2, d1, d0);
    } else {
      final d0 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset);
      final d1 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 8);
      final d2 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 16);
      final d3 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 24);
      return Uint256._(d3, d2, d1, d0);
    }
  }

  // ---- properties ----

  @pragma('vm:prefer-inline')
  bool get isZero => _d3.isZero && _d2.isZero && _d1.isZero && _d0.isZero;
  bool get isEven => _d0.isEven;
  bool get isOdd => _d0.isOdd;
  Uint64 get d3 => _d3;
  Uint64 get d2 => _d2;
  Uint64 get d1 => _d1;
  Uint64 get d0 => _d0;

  // ---- wrapping arithmetic operators ----

  /// Flattened ripple-carry add: works directly on the raw 32-bit
  /// `hi`/`lo` ints instead of routing every limb through
  /// `Uint64.adc` (which itself allocates two intermediate `Uint64`s
  /// and a tuple per call). Every intermediate here (`lo+lo+carry`,
  /// max `2*(2^32-1)+1`) stays under 2^33 — comfortably native- *and*
  /// double-safe — only one `Uint64` is built per output limb.
  ///
  /// Carry is extracted via comparison (`lo > 0xFFFFFFFF`), not via
  /// `>>> 32` — an earlier version used the shift and was broken on
  /// dart2js: a value up to 33 bits wide gets truncated to 32 bits
  /// *before* dart2js applies `>>>`, so shifting right by exactly 32
  /// always yielded 0, silently dropping the carry bit itself and
  /// breaking wraparound on any add that needed to carry out of a
  /// limb (e.g. `1 + Uint256.max` no longer wrapped to `0`). This
  /// comparison-based approach is the same technique `Uint64.operator+`
  /// already uses safely — no truncate-then-shift step to lose the bit.
  Uint256 operator +(Uint256 other) {
    var carry = 0;

    var lo = _d0.lo + other._d0.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    var hi = _d0.hi + other._d0.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d0 = Uint64.fromParts(hi, lo);

    lo = _d1.lo + other._d1.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d1.hi + other._d1.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d1 = Uint64.fromParts(hi, lo);

    lo = _d2.lo + other._d2.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d2.hi + other._d2.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d2 = Uint64.fromParts(hi, lo);

    lo = _d3.lo + other._d3.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d3.hi + other._d3.hi + carry; // top carry discarded: wrapping
    final d3 = Uint64.fromParts(hi, lo);

    return Uint256._(d3, d2, d1, d0);
  }

  /// Flattened borrow-chain subtract — same rationale as `operator+`
  /// above. Note this uses a plain 0/1 borrow flag (not `sbb`'s
  /// all-ones-mask convention); the fast path here doesn't need a
  /// maskable borrow for constant-time blending, just wrapping
  /// subtraction, so the simpler flag keeps every step branch-light.
  Uint256 operator -(Uint256 other) {
    var borrow = 0;

    var lo = _d0.lo - other._d0.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    var hi = _d0.hi - other._d0.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d0 = Uint64.fromParts(hi, lo);

    lo = _d1.lo - other._d1.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d1.hi - other._d1.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d1 = Uint64.fromParts(hi, lo);

    lo = _d2.lo - other._d2.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d2.hi - other._d2.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d2 = Uint64.fromParts(hi, lo);

    lo = _d3.lo - other._d3.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d3.hi - other._d3.hi - borrow; // top borrow discarded: wrapping
    if (hi < 0) hi += 0x100000000;
    final d3 = Uint64.fromParts(hi, lo);

    return Uint256._(d3, d2, d1, d0);
  }

  /// Multiply, keeping only the low 256 bits (wrapping). The actual
  /// row-scanning implementation lives in `u256_math/` and is
  /// platform-split the same way `word_math` is: a fully-flattened
  /// raw-int version on native (`u256_math_native.dart`, no `Uint64`
  /// allocation at all until the final unpack) and a `Uint64.mac`-based
  /// portable version on web (`u256_math_web.dart`). Both files
  /// document the row-scanning-vs-Comba rationale and must stay
  /// algorithmically identical to each other.
  Uint256 operator *(Uint256 other) => mulImpl(this, other);

  /// The actual division implementation lives in `u256_div/` and is
  /// platform-split like `u256_math`/`word_math`: Knuth Algorithm D on
  /// 32-bit digits, native-only (`u256_div_native.dart` — a handful
  /// of word-level steps instead of 256 bit-level ones), with the
  /// original 256-bit-serial algorithm kept as the web-safe fallback
  /// (`u256_div_web.dart`, unchanged in substance from before this
  /// split, just relocated).
  Uint256 operator ~/(Uint256 other) => divModImpl(this, other).quotient;

  Uint256 operator %(Uint256 other) => divModImpl(this, other).remainder;

  // ---- overflow-checked arithmetic ----

  Uint256 addChecked(Uint256 other) {
    final r = this + other;
    if (r < this) throw IntegerError.overflow;
    return r;
  }

  Uint256 subChecked(Uint256 other) {
    if (other > this) throw IntegerError.overflow;
    return this - other;
  }

  Uint256 mulChecked(Uint256 other) {
    if (isZero || other.isZero) return Uint256.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  // ---- bitwise operators ----

  Uint256 operator &(Uint256 other) =>
      Uint256._(_d3 & other._d3, _d2 & other._d2, _d1 & other._d1, _d0 & other._d0);

  Uint256 operator |(Uint256 other) =>
      Uint256._(_d3 | other._d3, _d2 | other._d2, _d1 | other._d1, _d0 | other._d0);

  Uint256 operator ^(Uint256 other) =>
      Uint256._(_d3 ^ other._d3, _d2 ^ other._d2, _d1 ^ other._d1, _d0 ^ other._d0);

  Uint256 operator ~() => Uint256._(~_d3, ~_d2, ~_d1, ~_d0);

  /// Logical left shift, generalized across limb boundaries. Every step
  /// is a plain `Uint64` shift/bitwise op — already proven web-safe in
  /// `Uint64` itself — so no additional safety trick is needed at this
  /// width.
  Uint256 operator <<(int n) {
    final shift = n & 255;
    if (shift == 0) return this;
    final limbShift = shift ~/ 64;
    final bitShift = shift % 64;
    final src = [_d0, _d1, _d2, _d3];
    final out = List<Uint64>.filled(4, Uint64.zero);
    for (var i = 3; i >= 0; i--) {
      final srcIndex = i - limbShift;
      if (srcIndex < 0) continue;
      var value = src[srcIndex] << bitShift;
      if (bitShift > 0 && srcIndex - 1 >= 0) {
        value = value | (src[srcIndex - 1] >> (64 - bitShift));
      }
      out[i] = value;
    }
    return Uint256._(out[3], out[2], out[1], out[0]);
  }

  /// Logical (unsigned) right shift, generalized across limb boundaries.
  Uint256 operator >>(int n) {
    final shift = n & 255;
    if (shift == 0) return this;
    final limbShift = shift ~/ 64;
    final bitShift = shift % 64;
    final src = [_d0, _d1, _d2, _d3];
    final out = List<Uint64>.filled(4, Uint64.zero);
    for (var i = 0; i < 4; i++) {
      final srcIndex = i + limbShift;
      if (srcIndex > 3) continue;
      var value = src[srcIndex] >> bitShift;
      if (bitShift > 0 && srcIndex + 1 <= 3) {
        value = value | (src[srcIndex + 1] << (64 - bitShift));
      }
      out[i] = value;
    }
    return Uint256._(out[3], out[2], out[1], out[0]);
  }

  // ---- comparisons ----

  @override
  @pragma('vm:prefer-inline')
  int compareTo(Uint256 other) {
    var cmp = _d3.compareTo(other._d3);
    if (cmp != 0) return cmp;
    cmp = _d2.compareTo(other._d2);
    if (cmp != 0) return cmp;
    cmp = _d1.compareTo(other._d1);
    if (cmp != 0) return cmp;
    return _d0.compareTo(other._d0);
  }

  bool operator <(Uint256 other) => compareTo(other) < 0;
  bool operator <=(Uint256 other) => compareTo(other) <= 0;
  bool operator >(Uint256 other) => compareTo(other) > 0;
  bool operator >=(Uint256 other) => compareTo(other) >= 0;
  Uint256 operator -() => zero - this;
  @override
  bool operator ==(Object other) =>
      other is Uint256 &&
      _d3 == other._d3 &&
      _d2 == other._d2 &&
      _d1 == other._d1 &&
      _d0 == other._d0;

  @override
  int get hashCode => Object.hash(_d3, _d2, _d1, _d0);

  // ---- cross-type converters ----

  /// Truncating narrow: keeps only the low 32 bits (wrapping, like a
  /// Rust `as u32` cast).
  Uint32 toUint32() => Uint32.unsafe(_d0.lo);

  /// Truncating narrow: keeps only the low 64 bits (wrapping, like a
  /// Rust `as u64` cast).
  Uint64 toUint64() => _d0;

  /// Truncating narrow: keeps only the low 128 bits (wrapping, like a
  /// Rust `as u128` cast).
  Uint128 toUint128() => Uint128.unsafe(_d1, _d0);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i32`
  /// cast).
  Int32 toInt32() => Int32.unsafe(_d0.lo);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i64`
  /// cast).
  Int64 toInt64() => Int64.unsafe(_d0);

  /// Truncating narrow, then reinterpret (wrapping, like a Rust `as i128`
  /// cast).
  Int128 toInt128() => Int128.unsafe(Uint128.unsafe(_d1, _d0));
}
