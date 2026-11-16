// ignore_for_file: use_super_parameters

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';

/// LEB128-encoded integer, zig-zag encoded when [validator] is signed.
class LEBIntegerLayout extends Layout<int> {
  /// [validator] supplies the width/signedness used to validate values.
  LEBIntegerLayout(this.validator, {super.property}) : super(-1);

  final IntegerLayout validator;

  /// Reads a LEB128-encoded integer from the reader starting at [offset].
  static (int, int) _readVarint(LayoutByteReader bytes, {int offset = 0}) {
    int result = 0;
    int shift = 0;
    int pos = offset;
    while (true) {
      final int byte = bytes.at(pos++);
      result |= (byte & 0x7F) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        break;
      }
    }
    return (result, pos - offset);
  }

  /// Encodes [value] as LEB128 bytes.
  static List<int> writeVarint(int value) {
    final List<int> dest = [];
    while (value >= 0x80) {
      dest.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    dest.add(value & 0x7F);
    return dest;
  }

  /// Reverses zig-zag encoding.
  static int zigZagDecode(int n) {
    int value = n ~/ 2;
    if (n % 2 != 0) {
      value = -value - 1;
    }
    return value;
  }

  /// Maps a signed integer to zig-zag-encoded unsigned form.
  static int zigZagEncode(int n) {
    return n >= 0 ? n * 2 : (-n * 2) - 1;
  }

  @override
  int getSpan() {
    return -1;
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _readVarint(bytes, offset: offset);
    int value = decode.$1;
    if (validator.sign) {
      value = zigZagDecode(value);
    }
    return LayoutDecodeResult(consumed: decode.$2, value: value);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    validator.validate(source);
    if (validator.sign) {
      source = zigZagEncode(source);
    }
    final encode = writeVarint(source);
    writer.setAll(offset, encode);
    return encode.length;
  }

  @override
  LEBIntegerLayout clone({String? newProperty}) {
    return LEBIntegerLayout(validator, property: newProperty);
  }
}

/// LEB128-encoded [BigInt], zig-zag encoded when [validator] is signed.
class LEBBigIntegerLayout extends Layout<BigInt> {
  /// Maps a signed [n] (of [bitlen] bits) to zig-zag-encoded unsigned form.
  static BigInt zigZagEncode(BigInt n, int bitlen) {
    return (n << 1) ^ (n >> bitlen);
  }

  /// Reverses zig-zag encoding.
  static BigInt zigZagDecode(BigInt n) {
    return (n >> 1) ^ (-(n & BigInt.one));
  }

  static BigInt zigZagDecode32(BigInt n) {
    BigInt value = n ~/ BigInt.two;
    if (n % BigInt.two != BigInt.zero) {
      value = -value - BigInt.one;
    }
    return value;
  }

  LEBBigIntegerLayout._({required this.validator, String? property})
    : super(-1, property: property);

  /// [validator] supplies the width/signedness used to validate values.
  factory LEBBigIntegerLayout(BigIntLayout validator, {String? property}) {
    if (validator.span.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        "LEBBigIntegerLayout",
        reason: "Invalid validator layout.",
      );
    }
    return LEBBigIntegerLayout._(validator: validator, property: property);
  }

  final BigIntLayout validator;

  /// Reads a LEB128-encoded big integer from the reader starting at [offset].
  static (BigInt, int) _readVarint({
    required LayoutByteReader bytes,
    int offset = 0,
  }) {
    BigInt result = BigInt.zero;
    int shift = 0;
    int index = offset;

    for (; index < bytes.length;) {
      final int byte = bytes.at(index++);
      result |= (BigInt.from(byte & 0x7F)) << shift;
      if ((byte & 0x80) == 0) break;
      shift += 7;
    }
    return (result, index - offset);
  }

  /// Encodes [value] as LEB128 bytes.
  static List<int> writeVarint(BigInt value) {
    final List<int> dest = [];
    final mask = BigInt.from(0x80);
    final mask2 = BigInt.from(0x7F);
    while (value >= mask) {
      dest.add(((value & mask2) | mask).toU8);
      value >>= 7;
    }
    dest.add((value & mask2).toU8);
    return dest;
  }

  @override
  int getSpan() {
    return -1;
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _readVarint(bytes: bytes, offset: offset);
    BigInt value = decode.$1;
    if (validator.sign) {
      value = zigZagDecode(value);
    }
    return LayoutDecodeResult(consumed: decode.$2, value: value);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    validator.validate(source);
    if (validator.sign) {
      source = zigZagEncode(source, validator.bitlen);
    }
    final encode = writeVarint(source);
    writer.setAll(offset, encode);
    return encode.length;
  }

  @override
  LEBBigIntegerLayout clone({String? newProperty}) {
    return LEBBigIntegerLayout(validator, property: newProperty);
  }
}
