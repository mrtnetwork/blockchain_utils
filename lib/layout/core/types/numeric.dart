import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'package:blockchain_utils/layout/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

/// Represents an external layout.
abstract class ExternalLayout extends Layout<int> {
  const ExternalLayout(super.span, {super.property});
}

abstract class ExternalOffsetLayout extends ExternalLayout {
  const ExternalOffsetLayout({String? property})
    : super(-1, property: property);
}

/// Represents a layout that greedily consumes bytes until the end.
class GreedyCount extends ExternalLayout {
  int elementSpan;

  GreedyCount([this.elementSpan = 1, String? property])
    : assert(!elementSpan.isNegative),
      super(-1, property: property);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final rem = bytes.length - offset;
    final count = rem ~/ elementSpan;
    return LayoutDecodeResult(consumed: 0, value: count);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    return 0;
  }

  @override
  GreedyCount clone({String? newProperty}) {
    return GreedyCount(elementSpan, newProperty);
  }
}

abstract class BaseIntiger<T> extends Layout<T> {
  const BaseIntiger(super.span, {super.property});
  void validate(T value);
  bool get sign;
  Endian get order;
}

/// Represents a layout for double-precision floating point numbers.
class DoubleLayout extends Layout<double> {
  final Endian order;
  DoubleLayout.f32({String? property, this.order = Endian.little})
    : super(4, property: property);
  DoubleLayout.f64({String? property, this.order = Endian.little})
    : super(8, property: property);

  @override
  LayoutDecodeResult<double> decode(LayoutByteReader bytes, {int offset = 0}) {
    final data = bytes.sublist(offset, offset + span);
    double? result;
    if (span > 4) {
      result = DoubleCoder.fromBytes(data, byteOrder: order);
    }
    result ??= FloatCoder.fromBytes(data, byteOrder: order);
    return LayoutDecodeResult(consumed: span, value: result);
  }

  @override
  int encode(double source, LayoutByteWriter writer, {int offset = 0}) {
    final bytes =
        span > 4
            ? DoubleCoder.toBytes(source, byteOrder: order)
            : FloatCoder.toBytes(source, byteOrder: order);
    writer.setAll(offset, bytes);
    return span;
  }

  @override
  DoubleLayout clone({String? newProperty}) {
    if (span > 4) {
      return DoubleLayout.f64(property: newProperty, order: order);
    }
    return DoubleLayout.f32(property: newProperty, order: order);
  }
}

/// Represents a layout for integers.
class IntegerLayout extends BaseIntiger<int> {
  @override
  final bool sign;
  @override
  final Endian order;
  final int bitlength;
  @override
  void validate(int value) {
    if ((value.isNegative && !sign) || value.bitLength > bitlength) {
      throw LayoutException(
        "Invalid ${value.bitLength}-bit ${sign ? 'signed' : 'unsigned'} integer.",
        details: {"property": property, "value": value.toString()},
      );
    }
  }

  IntegerLayout(
    int span, {
    this.sign = false,
    this.order = Endian.little,
    String? property,
    int? bitlength,
  }) : bitlength = bitlength ?? span * 8,
       super(span, property: property) {
    assert(!span.isNegative, "Invalid integer layout span");
    if (this.span > 7 || (bitlength != null && bitlength > span * 8)) {
      throw ArgumentException.invalidOperationArguments(
        "IntegerLayout",
        name: "span",
        reason: "Invalid layout span",
      );
    }
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final data = bytes.sublist(offset, offset + span);
    if (span > 4) {
      final decode = BigintUtils.fromBytes(data, sign: sign, byteOrder: order);
      return LayoutDecodeResult(consumed: span, value: decode.toInt());
    }

    final decode = IntUtils.fromBytes(data, sign: sign, byteOrder: order);
    return LayoutDecodeResult(consumed: span, value: decode);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    validate(source);
    final bytes = source.toBytes(length: span, byteOrder: order, sign: sign);
    writer.setAll(offset, bytes);
    return span;
  }

  @override
  IntegerLayout clone({String? newProperty}) {
    return IntegerLayout(span, sign: sign, order: order, property: newProperty);
  }
}

/// Represents a layout for big integers.
class BigIntLayout extends BaseIntiger<BigInt> {
  final int bitlen;
  @override
  final bool sign;
  @override
  final Endian order;
  BigIntLayout(
    super.span, {
    this.sign = false,
    this.order = Endian.little,
    super.property,
  }) : bitlen = (() {
         final bitlen = span * 8;
         if (sign) return bitlen - 1;
         return bitlen;
       }());
  @override
  void validate(BigInt value) {
    if ((value.isNegative && !sign) || value.bitLength > bitlen) {
      throw LayoutException(
        "Invalid ${value.bitLength}-bit ${sign ? 'signed' : 'unsigned'} integer.",
        details: {"property": property, "value": value.toString()},
      );
    }
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final result = BigintUtils.fromBytes(
      bytes.sublist(offset, offset + span),
      byteOrder: order,
      sign: sign,
    );
    return LayoutDecodeResult(consumed: span, value: result);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    validate(source);
    final toBytes = source.toBytes(length: span, byteOrder: order, sign: sign);
    writer.setAll(offset, toBytes);
    return span;
  }

  @override
  BigIntLayout clone({String? newProperty}) {
    return BigIntLayout(span, sign: sign, order: order, property: newProperty);
  }
}

/// Represents an offset layout.
class OffsetLayout extends ExternalLayout {
  final PaddingLayout<int> layout;
  final int offset;
  OffsetLayout(this.layout, {this.offset = 0, String? property})
    : super(layout.span, property: property ?? layout.property);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final result = layout.decode(bytes, offset: offset + this.offset);
    return result;
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(source, writer, offset: offset + this.offset);
  }

  @override
  OffsetLayout clone({String? newProperty}) {
    return OffsetLayout(layout, offset: offset, property: newProperty);
  }
}

class CompactIntLayout extends Layout<int> {
  final IntegerLayout layout;
  const CompactIntLayout(this.layout, {String? property})
    : super(-1, property: property);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeScaleAsInteger(offset);
    layout.validate(decode.value);
    return LayoutDecodeResult(consumed: decode.consumed, value: decode.value);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final bytes = LayoutSerializationUtils.encodeLength(source.toString());
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  CompactIntLayout clone({String? newProperty}) {
    return CompactIntLayout(layout, property: newProperty);
  }
}

class CompactBigIntLayout extends Layout<BigInt> {
  CompactBigIntLayout(this.layout, {String? property})
    : super(-1, property: property);
  final BaseIntiger layout;

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeScale(offset);
    layout.validate(decode.value);
    return decode;
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final bytes = LayoutSerializationUtils.encodeLength(source.toString());
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  CompactBigIntLayout clone({String? newProperty}) {
    return CompactBigIntLayout(layout, property: newProperty);
  }
}

class VarintIntLayout extends Layout<int> {
  final IntegerLayout layout;
  const VarintIntLayout(this.layout, {String? property})
    : super(-1, property: property);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeVarintAsInteger(offset);
    layout.validate(decode.value);
    return LayoutDecodeResult(consumed: decode.consumed, value: decode.value);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final bytes = LayoutSerializationUtils.encodeVarint(source);
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  CompactIntLayout clone({String? newProperty}) {
    return CompactIntLayout(layout, property: newProperty);
  }
}
