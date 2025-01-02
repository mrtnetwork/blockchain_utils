import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/double/codec/double_utils.dart';
import 'package:blockchain_utils/double/codec/float_utils.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'package:blockchain_utils/layout/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

/// Represents an external layout.
abstract class ExternalLayout extends Layout<int> {
  const ExternalLayout(super.span, {super.property});
  bool isCount() => false;
}

abstract class ExternalOffsetLayout extends ExternalLayout {
  const ExternalOffsetLayout({String? property})
      : super(-1, property: property);
  LayoutDecodeResult<int> getLenAndSpan(LayoutByteReader bytes,
      {int offset = 0});
}

/// Represents a layout that greedily consumes bytes until the end.
class GreedyCount extends ExternalLayout {
  int elementSpan;

  GreedyCount([this.elementSpan = 1, String? property])
      : assert(!elementSpan.isNegative),
        super(-1, property: property);

  @override
  bool isCount() {
    return true;
  }

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
    final bytes = span > 4
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
  @override
  void validate(int value) {
    if (value.isNegative && !sign) {
      throw LayoutException(
          "Negative value cannot be encoded with unsigned layout.",
          details: {"property": property});
    }
    if (value.bitLength > span * 8) {
      throw LayoutException(
          "Value exceeds the maximum size for encoding with this layout.",
          details: {
            "property": property,
            "layout": runtimeType.toString(),
            "bitLength": span * 8,
            "sign": sign,
            "value": value
          });
    }
  }

  IntegerLayout(int span,
      {this.sign = false, this.order = Endian.little, String? property})
      : super(span, property: property) {
    if (6 < this.span) {
      throw LayoutException("span must not exceed 6 bytes", details: {
        "property": property,
        "layout": runtimeType.toString(),
        "sign": sign,
        "span": span
      });
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
    final bytes = span > 4
        ? BigintUtils.toBytes(BigInt.from(source), length: span, order: order)
        : IntUtils.toBytes(source, length: span, byteOrder: order);
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
  @override
  final bool sign;
  @override
  final Endian order;
  BigIntLayout(super.span,
      {this.sign = false, this.order = Endian.little, super.property});
  @override
  void validate(BigInt value) {
    if (value.isNegative && !sign) {
      throw LayoutException(
          "Negative value cannot be encoded with unsigned layout.",
          details: {"property": property});
    }
    if (value.bitLength > span * 8) {
      throw LayoutException(
          "Value exceeds the maximum size for encoding with this layout.",
          details: {"property": property});
    }
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final result = BigintUtils.fromBytes(bytes.sublist(offset, offset + span),
        byteOrder: order, sign: sign);
    return LayoutDecodeResult(consumed: span, value: result);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    validate(source);
    final toBytes = BigintUtils.toBytes(source, length: span, order: order);
    writer.setAll(offset, toBytes);
    return span;
  }

  @override
  BigIntLayout clone({String? newProperty}) {
    return BigIntLayout(span, sign: sign, order: order, property: newProperty);
  }
}

/// Represents a union discriminator layout.
abstract class UnionDiscriminatorLayout extends Layout<int> {
  UnionDiscriminatorLayout(String property) : super(0, property: property);
}

/// Represents a union layout discriminator.
class UnionLayoutDiscriminatorLayout extends UnionDiscriminatorLayout {
  final ExternalLayout layout;

  UnionLayoutDiscriminatorLayout(this.layout, {String? property})
      : assert(layout.isCount(),
            'layout must be an unsigned integer ExternalLayout'),
        super(property ?? layout.property ?? 'variant');

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    return layout.decode(bytes, offset: offset);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(source, writer, offset: offset);
  }

  @override
  UnionLayoutDiscriminatorLayout clone({String? newProperty}) {
    return UnionLayoutDiscriminatorLayout(layout, property: newProperty);
  }
}

/// Represents an offset layout.
class OffsetLayout extends ExternalLayout {
  final PaddingLayout<int> layout;
  final int offset;

  OffsetLayout(this.layout, {this.offset = 0, String? property})
      : super(layout.span, property: property ?? layout.property);

  @override
  bool isCount() {
    return true;
  }

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
  int getSpan(LayoutByteReader? bytes, {int offset = 0, int? source}) {
    return bytes!.getCompactDataOffset(offset);
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    // final decode = bytes.getCompactIntAtOffset(offset, sign: layout.sign);
    final decode = bytes.getCompactLengthInfos(offset, sign: layout.sign);
    layout.validate(decode.item2);
    return LayoutDecodeResult(consumed: decode.item1, value: decode.item2);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final bytes = LayoutSerializationUtils.compactIntToBytes(source);
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
  int getSpan(LayoutByteReader? bytes, {int offset = 0, BigInt? source}) {
    return bytes!.getCompactDataOffset(offset);
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.getCompactBigintInfos(offset, sign: layout.sign);
    layout.validate(decode.item2);
    return LayoutDecodeResult(consumed: decode.item1, value: decode.item2);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final bytes = LayoutSerializationUtils.compactToBytes(source);
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  CompactBigIntLayout clone({String? newProperty}) {
    return CompactBigIntLayout(layout, property: newProperty);
  }
}
