import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/numbers/src/exception/exception.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u256/u256.dart';
import 'package:blockchain_utils/numbers/src/u32.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'div/u512_div.dart';
import 'math/u512_math.dart';

class Uint512 implements Comparable<Uint512> {
  final Uint64 _d7; // most significant 64 bits (bits 448..511)
  final Uint64 _d6; // bits 384..447
  final Uint64 _d5; // bits 320..383
  final Uint64 _d4; // bits 256..319
  final Uint64 _d3; // bits 192..255
  final Uint64 _d2; // bits 128..191
  final Uint64 _d1; // bits 64..127
  final Uint64 _d0; // least significant 64 bits (bits 0..63)

  const Uint512._(
    this._d7,
    this._d6,
    this._d5,
    this._d4,
    this._d3,
    this._d2,
    this._d1,
    this._d0,
  );

  static const Uint512 zero = Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  );
  static const Uint512 one = Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.one,
  );
  static const Uint512 max = Uint512._(
    Uint64.max,
    Uint64.max,
    Uint64.max,
    Uint64.max,
    Uint64.max,
    Uint64.max,
    Uint64.max,
    Uint64.max,
  );
  static const Uint512 two = Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.two,
  );

  /// Raw limb constructor (most-significant limb first) — prefer
  /// [Uint512.new] / [Uint512.fromBigInt] for arbitrary values.
  const Uint512.unsafe(
    this._d7,
    this._d6,
    this._d5,
    this._d4,
    this._d3,
    this._d2,
    this._d1,
    this._d0,
  );

  /// Builds from a plain Dart [int]. Must be non-negative (same
  /// constraint as `Uint64.new`).
  factory Uint512(int value) => Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64(value),
  );

  @pragma('vm:prefer-inline')
  factory Uint512.fromUint64(Uint64 value) => Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    value,
  );

  /// Widens a [Uint256] into the low 256 bits of a [Uint512], zero
  /// extended — the common case for e.g. holding a 256x256->512-bit
  /// product's operands, or a double-width Montgomery intermediate.
  @pragma('vm:prefer-inline')
  factory Uint512.fromUint256(Uint256 value) => Uint512._(
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    value.d3,
    value.d2,
    value.d1,
    value.d0,
  );

  /// Builds from a plain Dart [int], accepting negative values by taking
  /// their two's-complement bit pattern (masked to 512 bits) instead of
  /// throwing like [Uint512.new] does — e.g. `Uint512.from(-1) ==
  /// Uint512.max`. [value] must itself be a normal double-safe Dart int
  /// (`|value| <= 2^53`); BigInt-free, same limb-splitting negation trick
  /// as `Uint64.from`, sign-extended into the seven high limbs.
  factory Uint512.from(int value) {
    final isNeg = value < 0;
    final mag = isNeg ? -value : value; // safe: |value| <= 2^53
    final magBits = Uint64.unsafe(mag ~/ 0x100000000, mag % 0x100000000);
    final loBits = isNeg ? (~magBits) + Uint64.one : magBits;
    final ext = isNeg ? Uint64.max : Uint64.zero;
    return Uint512._(ext, ext, ext, ext, ext, ext, ext, loBits);
  }

  factory Uint512.fromBigInt(BigInt value) {
    if (value.isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "fromBigInt",
        reason: 'value must be non-negative',
      );
    }
    final v = value.toUnsigned(512);
    final d7 = Uint64.fromBigInt((v >> 448).toUnsigned(64));
    final d6 = Uint64.fromBigInt((v >> 384).toUnsigned(64));
    final d5 = Uint64.fromBigInt((v >> 320).toUnsigned(64));
    final d4 = Uint64.fromBigInt((v >> 256).toUnsigned(64));
    final d3 = Uint64.fromBigInt((v >> 192).toUnsigned(64));
    final d2 = Uint64.fromBigInt((v >> 128).toUnsigned(64));
    final d1 = Uint64.fromBigInt((v >> 64).toUnsigned(64));
    final d0 = Uint64.fromBigInt(v.toUnsigned(64));
    return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
  }

  static Uint512 parseHex(String s) {
    var hex = (s.startsWith('0x') || s.startsWith('0X')) ? s.substring(2) : s;
    if (hex.isEmpty || hex.length > 128) {
      throw ArgumentException.invalidOperationArguments(
        "parseHex",
        reason: 'invalid hex literal.',
        details: {"value": s},
      );
    }
    hex = hex.padLeft(128, '0');
    final d7 = Uint64.parseHex('0x${hex.substring(0, 16)}');
    final d6 = Uint64.parseHex('0x${hex.substring(16, 32)}');
    final d5 = Uint64.parseHex('0x${hex.substring(32, 48)}');
    final d4 = Uint64.parseHex('0x${hex.substring(48, 64)}');
    final d3 = Uint64.parseHex('0x${hex.substring(64, 80)}');
    final d2 = Uint64.parseHex('0x${hex.substring(80, 96)}');
    final d1 = Uint64.parseHex('0x${hex.substring(96, 112)}');
    final d0 = Uint64.parseHex('0x${hex.substring(112, 128)}');
    return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
  }

  /// Strict decimal parse: throws [IntegerError] on overflow, unlike
  /// the wrapping operators.
  static Uint512 parseDecimal(String s) {
    if (s.isEmpty || !RegExp(r'^[0-9]+$').hasMatch(s)) {
      throw ArgumentException.invalidOperationArguments(
        "parseDecimal",
        reason: 'Invalid decimal literal.',
        details: {"value": s},
      );
    }
    var acc = Uint512.zero;
    final ten = Uint512(10);
    for (final rune in s.codeUnits) {
      final digit = Uint512(rune - 0x30);
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
      (_d7.toBigInt() << 448) |
      (_d6.toBigInt() << 384) |
      (_d5.toBigInt() << 320) |
      (_d4.toBigInt() << 256) |
      (_d3.toBigInt() << 192) |
      (_d2.toBigInt() << 128) |
      (_d1.toBigInt() << 64) |
      _d0.toBigInt();

  /// Only safe if the top seven limbs are zero and the low limb is
  /// double-safe — delegates to `Uint64.toInt()`'s own guard, throwing
  /// [IntegerError] otherwise (use [toBigInt] for the general case).
  int toInt() {
    if (!_d7.isZero ||
        !_d6.isZero ||
        !_d5.isZero ||
        !_d4.isZero ||
        !_d3.isZero ||
        !_d2.isZero ||
        !_d1.isZero) {
      throw IntegerError.toIntConvertionError;
    }
    return _d0.toInt();
  }

  String toHexString({bool padded = true}) {
    final hex =
        '${_d7.toHexString()}${_d6.toHexString()}${_d5.toHexString()}'
        '${_d4.toHexString()}${_d3.toHexString()}${_d2.toHexString()}'
        '${_d1.toHexString()}${_d0.toHexString()}';
    return padded ? hex : hex.replaceFirst(RegExp(r'^0+(?=.)'), '');
  }

  @override
  String toString() {
    if (isZero) return '0';
    final digits = <String>[];
    var rem = this;
    final ten = Uint512(10);
    while (!rem.isZero) {
      final qr = divModImpl(rem, ten);
      digits.add(qr.remainder._d0.toString()); // remainder < 10: a single digit
      rem = qr.quotient;
    }
    return digits.reversed.join();
  }

  /// Fixed 64-byte encoding, delegating to each Uint64 limb's own
  /// (already web-safe) 8-byte encoding.
  List<int> toBytes([Endian endian = Endian.big]) {
    final out = List<int>.filled(64, 0);
    if (endian == Endian.big) {
      out.setRange(0, 8, _d7.toBytes(Endian.big));
      out.setRange(8, 16, _d6.toBytes(Endian.big));
      out.setRange(16, 24, _d5.toBytes(Endian.big));
      out.setRange(24, 32, _d4.toBytes(Endian.big));
      out.setRange(32, 40, _d3.toBytes(Endian.big));
      out.setRange(40, 48, _d2.toBytes(Endian.big));
      out.setRange(48, 56, _d1.toBytes(Endian.big));
      out.setRange(56, 64, _d0.toBytes(Endian.big));
    } else {
      out.setRange(0, 8, _d0.toBytes(Endian.little));
      out.setRange(8, 16, _d1.toBytes(Endian.little));
      out.setRange(16, 24, _d2.toBytes(Endian.little));
      out.setRange(24, 32, _d3.toBytes(Endian.little));
      out.setRange(32, 40, _d4.toBytes(Endian.little));
      out.setRange(40, 48, _d5.toBytes(Endian.little));
      out.setRange(48, 56, _d6.toBytes(Endian.little));
      out.setRange(56, 64, _d7.toBytes(Endian.little));
    }
    return out;
  }

  static Uint512 fromBytes(
    List<int> bytes, {
    Endian endian = Endian.big,
    int offset = 0,
  }) {
    if (offset < 0 || bytes.length - offset < 64) {
      throw ArgumentException.invalidOperationArguments(
        "Uint512.fromBytes",
        reason: 'Need at least 64 bytes from offset.',
        details: {"offset": offset.toString(), "length": bytes.length.toString()},
      );
    }
    if (endian == Endian.big) {
      final d7 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset);
      final d6 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 8);
      final d5 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 16);
      final d4 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 24);
      final d3 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 32);
      final d2 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 40);
      final d1 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 48);
      final d0 = Uint64.fromBytes(bytes, endian: Endian.big, offset: offset + 56);
      return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
    } else {
      final d0 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset);
      final d1 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 8);
      final d2 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 16);
      final d3 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 24);
      final d4 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 32);
      final d5 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 40);
      final d6 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 48);
      final d7 = Uint64.fromBytes(bytes, endian: Endian.little, offset: offset + 56);
      return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
    }
  }

  // ---- properties ----

  @pragma('vm:prefer-inline')
  bool get isZero =>
      _d7.isZero &&
      _d6.isZero &&
      _d5.isZero &&
      _d4.isZero &&
      _d3.isZero &&
      _d2.isZero &&
      _d1.isZero &&
      _d0.isZero;
  bool get isEven => _d0.isEven;
  bool get isOdd => _d0.isOdd;
  Uint64 get d7 => _d7;
  Uint64 get d6 => _d6;
  Uint64 get d5 => _d5;
  Uint64 get d4 => _d4;
  Uint64 get d3 => _d3;
  Uint64 get d2 => _d2;
  Uint64 get d1 => _d1;
  Uint64 get d0 => _d0;

  // ---- wrapping arithmetic operators ----

  /// Flattened ripple-carry add: works directly on the raw 32-bit
  /// `hi`/`lo` ints instead of routing every limb through
  /// `Uint64.adc` — same technique as `Uint256.operator+`, generalized
  /// to 8 limbs. Carry is extracted via comparison (`lo > 0xFFFFFFFF`),
  /// never via `>>> 32` — see `Uint256.operator+`'s history for why
  /// that shift specifically breaks on dart2js (a 33-bit-wide value
  /// gets truncated to 32 bits *before* the shift, silently dropping
  /// the carry bit) even though the overall magnitude stays
  /// double-safe. Comparison has no such truncation step.
  Uint512 operator +(Uint512 other) {
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
    hi = _d3.hi + other._d3.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d3 = Uint64.fromParts(hi, lo);

    lo = _d4.lo + other._d4.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d4.hi + other._d4.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d4 = Uint64.fromParts(hi, lo);

    lo = _d5.lo + other._d5.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d5.hi + other._d5.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d5 = Uint64.fromParts(hi, lo);

    lo = _d6.lo + other._d6.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d6.hi + other._d6.hi + carry;
    carry = hi > 0xFFFFFFFF ? 1 : 0;
    final d6 = Uint64.fromParts(hi, lo);

    lo = _d7.lo + other._d7.lo + carry;
    carry = lo > 0xFFFFFFFF ? 1 : 0;
    hi = _d7.hi + other._d7.hi + carry; // top carry discarded: wrapping
    final d7 = Uint64.fromParts(hi, lo);

    return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
  }

  /// Flattened borrow-chain subtract — same rationale as `operator+`
  /// above, generalized to 8 limbs. Plain 0/1 borrow flag (not `sbb`'s
  /// all-ones-mask convention) — this fast path doesn't need a
  /// maskable borrow for constant-time blending, just wrapping
  /// subtraction.
  Uint512 operator -(Uint512 other) {
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
    hi = _d3.hi - other._d3.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d3 = Uint64.fromParts(hi, lo);

    lo = _d4.lo - other._d4.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d4.hi - other._d4.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d4 = Uint64.fromParts(hi, lo);

    lo = _d5.lo - other._d5.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d5.hi - other._d5.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d5 = Uint64.fromParts(hi, lo);

    lo = _d6.lo - other._d6.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d6.hi - other._d6.hi - borrow;
    if (hi < 0) {
      hi += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    final d6 = Uint64.fromParts(hi, lo);

    lo = _d7.lo - other._d7.lo - borrow;
    if (lo < 0) {
      lo += 0x100000000;
      borrow = 1;
    } else {
      borrow = 0;
    }
    hi = _d7.hi - other._d7.hi - borrow; // top borrow discarded: wrapping
    if (hi < 0) hi += 0x100000000;
    final d7 = Uint64.fromParts(hi, lo);

    return Uint512._(d7, d6, d5, d4, d3, d2, d1, d0);
  }

  /// Multiply, keeping only the low 512 bits (wrapping). The actual
  /// implementation lives in `u512_math/`, platform-split like
  /// `u256_math`/`word_math`: a raw-int native version
  /// (`u512_math_native.dart`) and a 16-bit-digit web-safe version
  /// (`u512_math_web.dart`).
  Uint512 operator *(Uint512 other) => mulImpl(this, other);

  /// The actual division implementation lives in `u512_div/`,
  /// platform-split like `u512_math`/`word_math`: Knuth Algorithm D,
  /// 32-bit digits native (`u512_div_native.dart`), 16-bit digits web
  /// (`u512_div_web.dart`).
  Uint512 operator ~/(Uint512 other) => divModImpl(this, other).quotient;

  Uint512 operator %(Uint512 other) => divModImpl(this, other).remainder;

  // ---- overflow-checked arithmetic ----

  Uint512 addChecked(Uint512 other) {
    final r = this + other;
    if (r < this) throw IntegerError.overflow;
    return r;
  }

  Uint512 subChecked(Uint512 other) {
    if (other > this) throw IntegerError.overflow;
    return this - other;
  }

  Uint512 mulChecked(Uint512 other) {
    if (isZero || other.isZero) return Uint512.zero;
    final r = this * other;
    if (r ~/ other != this) throw IntegerError.overflow;
    return r;
  }

  // ---- bitwise operators ----

  Uint512 operator &(Uint512 other) => Uint512._(
    _d7 & other._d7,
    _d6 & other._d6,
    _d5 & other._d5,
    _d4 & other._d4,
    _d3 & other._d3,
    _d2 & other._d2,
    _d1 & other._d1,
    _d0 & other._d0,
  );

  Uint512 operator |(Uint512 other) => Uint512._(
    _d7 | other._d7,
    _d6 | other._d6,
    _d5 | other._d5,
    _d4 | other._d4,
    _d3 | other._d3,
    _d2 | other._d2,
    _d1 | other._d1,
    _d0 | other._d0,
  );

  Uint512 operator ^(Uint512 other) => Uint512._(
    _d7 ^ other._d7,
    _d6 ^ other._d6,
    _d5 ^ other._d5,
    _d4 ^ other._d4,
    _d3 ^ other._d3,
    _d2 ^ other._d2,
    _d1 ^ other._d1,
    _d0 ^ other._d0,
  );

  Uint512 operator ~() => Uint512._(~_d7, ~_d6, ~_d5, ~_d4, ~_d3, ~_d2, ~_d1, ~_d0);

  /// Logical left shift, generalized across limb boundaries. Every step
  /// is a plain `Uint64` shift/bitwise op — already proven web-safe in
  /// `Uint64` itself — so no additional safety trick is needed at this
  /// width.
  Uint512 operator <<(int n) {
    final shift = n & 511;
    if (shift == 0) return this;
    final limbShift = shift ~/ 64;
    final bitShift = shift % 64;
    final src = [_d0, _d1, _d2, _d3, _d4, _d5, _d6, _d7];
    final out = List<Uint64>.filled(8, Uint64.zero);
    for (var i = 7; i >= 0; i--) {
      final srcIndex = i - limbShift;
      if (srcIndex < 0) continue;
      var value = src[srcIndex] << bitShift;
      if (bitShift > 0 && srcIndex - 1 >= 0) {
        value = value | (src[srcIndex - 1] >> (64 - bitShift));
      }
      out[i] = value;
    }
    return Uint512._(out[7], out[6], out[5], out[4], out[3], out[2], out[1], out[0]);
  }

  /// Logical (unsigned) right shift, generalized across limb boundaries.
  Uint512 operator >>(int n) {
    final shift = n & 511;
    if (shift == 0) return this;
    final limbShift = shift ~/ 64;
    final bitShift = shift % 64;
    final src = [_d0, _d1, _d2, _d3, _d4, _d5, _d6, _d7];
    final out = List<Uint64>.filled(8, Uint64.zero);
    for (var i = 0; i < 8; i++) {
      final srcIndex = i + limbShift;
      if (srcIndex > 7) continue;
      var value = src[srcIndex] >> bitShift;
      if (bitShift > 0 && srcIndex + 1 <= 7) {
        value = value | (src[srcIndex + 1] << (64 - bitShift));
      }
      out[i] = value;
    }
    return Uint512._(out[7], out[6], out[5], out[4], out[3], out[2], out[1], out[0]);
  }

  // ---- comparisons ----

  @override
  @pragma('vm:prefer-inline')
  int compareTo(Uint512 other) {
    var cmp = _d7.compareTo(other._d7);
    if (cmp != 0) return cmp;
    cmp = _d6.compareTo(other._d6);
    if (cmp != 0) return cmp;
    cmp = _d5.compareTo(other._d5);
    if (cmp != 0) return cmp;
    cmp = _d4.compareTo(other._d4);
    if (cmp != 0) return cmp;
    cmp = _d3.compareTo(other._d3);
    if (cmp != 0) return cmp;
    cmp = _d2.compareTo(other._d2);
    if (cmp != 0) return cmp;
    cmp = _d1.compareTo(other._d1);
    if (cmp != 0) return cmp;
    return _d0.compareTo(other._d0);
  }

  bool operator <(Uint512 other) => compareTo(other) < 0;
  bool operator <=(Uint512 other) => compareTo(other) <= 0;
  bool operator >(Uint512 other) => compareTo(other) > 0;
  bool operator >=(Uint512 other) => compareTo(other) >= 0;
  Uint512 operator -() => zero - this;
  @override
  bool operator ==(Object other) =>
      other is Uint512 &&
      _d7 == other._d7 &&
      _d6 == other._d6 &&
      _d5 == other._d5 &&
      _d4 == other._d4 &&
      _d3 == other._d3 &&
      _d2 == other._d2 &&
      _d1 == other._d1 &&
      _d0 == other._d0;

  @override
  int get hashCode => Object.hash(_d7, _d6, _d5, _d4, _d3, _d2, _d1, _d0);

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

  /// Truncating narrow: keeps only the low 256 bits (wrapping, like a
  /// Rust `as u256` cast).
  Uint256 toUint256() => Uint256.unsafe(_d3, _d2, _d1, _d0);
}
