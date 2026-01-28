import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/numeric.dart';

/// A layout class for encoding and decoding integers
class LEBIntegerLayout extends Layout<int> {
  /// Constructor for [LEBIntegerLayout].
  ///
  /// [validator] is the underlying integer layout used for validation.
  /// [property] is an optional key associated with this layout for structured data handling.
  LEBIntegerLayout(this.validator, {String? property})
    : super(-1, property: property);

  /// The integer layout used to validate values before encoding.
  final IntegerLayout validator;

  /// Decodes a LEB128-encoded integer from a byte list starting at [startIndex].
  static int readVarint(List<int> bytes, {int startIndex = 0}) {
    int result = 0;
    int shift = 0;
    for (int i = startIndex; i < bytes.length; i++) {
      final int byte = bytes[i];
      result |= (byte & 0x7F) << shift;
      shift += 7;
      if ((byte & 0x80) == 0) {
        break;
      }
    }

    return result;
  }

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

  /// Encodes an integer [value] using LEB128 format.
  static List<int> writeVarint(int value) {
    final List<int> dest = [];
    while (value >= 0x80) {
      dest.add((value & 0x7F) | 0x80);
      value >>= 7;
    }
    dest.add(value & 0x7F);
    return dest;
  }

  static int zigZagDecode(int n) {
    int value = n ~/ 2;
    if (n % 2 != 0) {
      value = -value - 1;
    }
    return value;
  }

  static int zigZagEncode(int n) {
    return n >= 0 ? n * 2 : (-n * 2) - 1;
  }

  /// Calculates the span (number of bytes) occupied by a LEB128-encoded integer.
  @override
  int getSpan() {
    return -1;
  }

  /// Decodes a LEB128-encoded integer from the byte stream starting at [offset].
  ///
  /// - [bytes]: The byte stream to decode from.
  /// - [offset]: The starting position for decoding.
  ///
  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _readVarint(bytes, offset: offset);
    int value = decode.$1;
    if (validator.sign) {
      value = zigZagDecode(value);
    }
    return LayoutDecodeResult(consumed: decode.$2, value: value);
  }

  /// Encodes an integer [source] using LEB128 and writes it to the byte writer.
  ///
  /// - [source]: The integer value to encode.
  /// - [writer]: The byte writer to output the encoded data.
  /// - [offset]: The position in the writer to start writing.
  ///
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

  /// Creates a copy (clone) of the current layout with an optional new [property].
  @override
  LEBIntegerLayout clone({String? newProperty}) {
    return LEBIntegerLayout(validator, property: newProperty);
  }
}

/// A layout class for encoding and decoding integers
class LEBBigIntegerLayout extends Layout<BigInt> {
  static BigInt zigZagEncode(BigInt n, int bitlen) {
    return (n << 1) ^ (n >> bitlen);
  }

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

  /// Constructor for [LEBIntegerLayout].
  ///
  /// [validator] is the underlying integer layout used for validation.
  /// [property] is an optional key associated with this layout for structured data handling.
  LEBBigIntegerLayout._({required this.validator, String? property})
    : super(-1, property: property);

  factory LEBBigIntegerLayout(BigIntLayout validator, {String? property}) {
    if (validator.span.isNegative) {
      throw ArgumentException.invalidOperationArguments(
        "LEBBigIntegerLayout",
        reason: "Invalid validator layout.",
      );
    }
    return LEBBigIntegerLayout._(validator: validator, property: property);
  }

  /// The integer layout used to validate values before encoding.
  final BigIntLayout validator;

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

  /// Encodes an integer [value] using LEB128 format.
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

  /// Calculates the span (number of bytes) occupied by a LEB128-encoded integer.
  @override
  int getSpan() {
    return -1;
  }

  /// Decodes a LEB128-encoded integer from the byte stream starting at [offset].
  ///
  /// - [bytes]: The byte stream to decode from.
  /// - [offset]: The starting position for decoding.
  ///
  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = _readVarint(bytes: bytes, offset: offset);
    BigInt value = decode.$1;
    if (validator.sign) {
      value = zigZagDecode(value);
    }
    return LayoutDecodeResult(consumed: decode.$2, value: value);
  }

  /// Encodes an integer [source] using LEB128 and writes it to the byte writer.
  ///
  /// - [source]: The integer value to encode.
  /// - [writer]: The byte writer to output the encoded data.
  /// - [offset]: The position in the writer to start writing.
  ///
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

  /// Creates a copy (clone) of the current layout with an optional new [property].
  @override
  LEBBigIntegerLayout clone({String? newProperty}) {
    return LEBBigIntegerLayout(validator, property: newProperty);
  }
}
