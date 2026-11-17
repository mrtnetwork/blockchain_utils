import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/encoding/double/double_codec.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/encoding/layout/utils/utils.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Base type for layouts whose span/position is resolved externally.
abstract class ExternalLayout extends Layout<int> {
  const ExternalLayout(super.span, {super.property});
}

/// An [ExternalLayout] with a size that is only known once decoded.
abstract class ExternalOffsetLayout extends ExternalLayout {
  const ExternalOffsetLayout({super.property}) : super(-1);
}

/// Consumes every remaining byte as `elementSpan`-sized elements.
class GreedyCount extends ExternalLayout {
  int elementSpan;

  /// [elementSpan] is the byte size of a single element.
  GreedyCount([this.elementSpan = 1, String? property])
    : super(-1, property: property) {
    if (elementSpan.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        "GreedyCount",
        name: "elementSpan",
        reason: "elementSpan must not be negative",
      );
    }
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

/// Shared contract for fixed-width integer layouts ([IntegerLayout], [BigIntLayout]).
abstract class BaseInteger<T> extends Layout<T> {
  const BaseInteger(super.span, {super.property});

  /// Throws if [value] does not fit this layout's width/signedness.
  void validate(T value);
  bool get sign;
  Endian get order;
}

/// Deprecated alias kept for compatibility; use [BaseInteger] instead.
@Deprecated('Use BaseInteger instead.')
typedef BaseIntiger<T> = BaseInteger<T>;

/// Fixed-width floating point layout (32 or 64 bit).
class DoubleLayout extends Layout<double> {
  final Endian order;

  /// 32-bit (single precision) float layout.
  DoubleLayout.f32({super.property, this.order = Endian.little}) : super(4);

  /// 64-bit (double precision) float layout.
  DoubleLayout.f64({super.property, this.order = Endian.little}) : super(8);

  @override
  LayoutDecodeResult<double> decode(LayoutByteReader bytes, {int offset = 0}) {
    bytes.requireAvailable(offset, span);
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

/// Fixed-width integer layout, up to 7 bytes wide.
class IntegerLayout extends BaseInteger<int> {
  @override
  final bool sign;
  @override
  final Endian order;
  final int bitlength;

  @override
  void validate(int value) {
    if (!sign) {
      if (value.isNegative || value.bitLength > bitlength) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Invalid ${value.bitLength}-bit unsigned integer.",
          details: {"property": property, "value": value.toString()},
        );
      }
      return;
    }
    if (bitlength <= 0) {
      if (value != 0) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Invalid 0-bit signed integer.",
          details: {"property": property, "value": value.toString()},
        );
      }
      return;
    }
    // NOTE: bounds use BigInt — `(1 << (bitlength - 1))` overflows the
    // 32-bit JS shift (and 2^55 exceeds the 53-bit safe-int range) on
    // dart2js, wrongly rejecting valid 5..7-byte signed values on web.
    final max = (BigInt.one << (bitlength - 1)) - BigInt.one;
    final v = BigInt.from(value);
    if (v > max || v < -max - BigInt.one) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid ${value.bitLength}-bit signed integer.",
        details: {"property": property, "value": value.toString()},
      );
    }
  }

  /// Big-endian unsigned 32-bit integer layout.
  const IntegerLayout.u32Be({super.property})
    : sign = false,
      order = Endian.big,
      bitlength = 32,
      super(4);

  /// Creates an integer layout spanning [span] bytes.
  IntegerLayout(
    int span, {
    this.sign = false,
    this.order = Endian.little,
    super.property,
    int? bitlength,
  }) : bitlength = bitlength ?? span * 8,
       super(span) {
    if (this.span > 7 || (bitlength != null && bitlength > span * 8)) {
      throw CoreErrors.invalidOperationArguments(
        "IntegerLayout",
        name: "span",
        reason: "Integer layout span must be between 0 and 7 bytes.",
      );
    }
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    bytes.requireAvailable(offset, span);
    if (span > 4) {
      final decode = BigintUtils.fromBytes(
        bytes.bytes,
        offset: offset,
        length: span,
        sign: sign,
        byteOrder: order,
      );
      return LayoutDecodeResult(consumed: span, value: decode.toInt());
    }
    final decode = IntUtils.fromBytes(
      bytes.bytes,
      offset: offset,
      length: span,
      sign: sign,
      byteOrder: order,
    );
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

/// Fixed-width [BigInt] layout, for widths beyond what a Dart [int] holds.
class BigIntLayout extends BaseInteger<BigInt> {
  final int bitlen;
  @override
  final bool sign;
  @override
  final Endian order;

  /// Creates a big-integer layout spanning [span] bytes.
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
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Invalid ${value.bitLength}-bit ${sign ? 'signed' : 'unsigned'} integer.",
        details: {"property": property, "value": value.toString()},
      );
    }
  }

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    bytes.requireAvailable(offset, span);
    final result = BigintUtils.fromBytes(
      bytes.bytes,
      offset: offset,
      length: span,
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

/// Delegates to [layout] at a fixed byte [offset] from wherever it's decoded.
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

/// Base for offset layouts that just delegate int decode/encode/span to a
/// wrapped [layout] (see [CompactOffsetLayout], [VarintOffsetLayout]).
abstract class WrappedIntOffsetLayout<L extends Layout<int>>
    extends ExternalOffsetLayout {
  WrappedIntOffsetLayout(this.layout, {super.property});
  final L layout;

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    return layout.decode(bytes, offset: offset);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(source, writer, offset: offset);
  }

  @override
  int getSpan() => layout.getSpan();
}

/// SCALE compact-encoded integer, validated against [layout]'s width.
class CompactIntLayout extends Layout<int> {
  final IntegerLayout layout;
  const CompactIntLayout(this.layout, {super.property}) : super(-1);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeScaleAsInteger(offset);
    layout.validate(decode.value);
    return LayoutDecodeResult(consumed: decode.consumed, value: decode.value);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final bytes = LayoutSerializationUtils.encodeLength(source.toString());
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  CompactIntLayout clone({String? newProperty}) {
    return CompactIntLayout(layout, property: newProperty);
  }
}

/// SCALE compact-encoded big integer, validated against [layout]'s width.
class CompactBigIntLayout extends Layout<BigInt> {
  CompactBigIntLayout(this.layout, {super.property}) : super(-1);
  final BaseInteger<BigInt> layout;

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

/// Varint-encoded integer, validated against [layout]'s width.
class VarintIntLayout extends Layout<int> {
  final IntegerLayout layout;
  const VarintIntLayout(this.layout, {super.property}) : super(-1);

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeVarintAsInteger(offset);
    layout.validate(decode.value);
    return LayoutDecodeResult(consumed: decode.consumed, value: decode.value);
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validate(source);
    final bytes = LayoutSerializationUtils.encodeVarint(source);
    writer.setAll(offset, bytes);
    return bytes.length;
  }

  @override
  VarintIntLayout clone({String? newProperty}) {
    return VarintIntLayout(layout, property: newProperty);
  }
}

/// LEB128-style unsigned natural number (no upper bound).
class NatLayout extends Layout<BigInt> {
  const NatLayout({super.property}) : super(-1);

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    BigInt value = BigInt.zero;
    int shift = 0;
    int consumed = 0;
    while (true) {
      final b = bytes.at(offset + consumed);
      value |= BigInt.from(b & 0x7f) << shift;
      consumed++;
      if (b & 0x80 == 0) break;
      shift += 7;
    }
    return LayoutDecodeResult(consumed: consumed, value: value);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    if (source < BigInt.zero) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        'Nat cannot be negative',
        details: {'value': source.toString()},
      );
    }
    BigInt v = source;
    int span = 0;
    do {
      int b = (v & BigInt.from(0x7f)).toInt();
      v >>= 7;
      if (v > BigInt.zero) b |= 0x80;
      writer.set(offset + span, b);
      span++;
    } while (v > BigInt.zero);
    return span;
  }

  @override
  NatLayout clone({String? newProperty}) => NatLayout(property: newProperty);
}

/// Zarith signed integer ("Z"): first byte carries a sign bit (0x40) and
/// 6 magnitude bits, subsequent bytes carry 7 magnitude bits each, all
/// but the last byte have the continuation bit (0x80) set.
class ZarithIntLayout extends Layout<BigInt> {
  const ZarithIntLayout({super.property}) : super(-1);

  @override
  LayoutDecodeResult<BigInt> decode(LayoutByteReader bytes, {int offset = 0}) {
    final first = bytes.at(offset);
    final neg = (first & 0x40) != 0;
    BigInt value = BigInt.from(first & 0x3f);
    int shift = 6;
    int consumed = 1;
    bool cont = (first & 0x80) != 0;
    while (cont) {
      final b = bytes.at(offset + consumed);
      value |= BigInt.from(b & 0x7f) << shift;
      cont = (b & 0x80) != 0;
      shift += 7;
      consumed++;
    }
    return LayoutDecodeResult(consumed: consumed, value: neg ? -value : value);
  }

  @override
  int encode(BigInt source, LayoutByteWriter writer, {int offset = 0}) {
    final neg = source.isNegative;
    BigInt abs = neg ? -source : source;
    int firstByte = (abs & BigInt.from(0x3f)).toInt();
    abs >>= 6;
    if (neg) firstByte |= 0x40;
    if (abs > BigInt.zero) firstByte |= 0x80;
    writer.set(offset, firstByte);
    int span = 1;
    while (abs > BigInt.zero) {
      int b = (abs & BigInt.from(0x7f)).toInt();
      abs >>= 7;
      if (abs > BigInt.zero) b |= 0x80;
      writer.set(offset + span, b);
      span++;
    }
    return span;
  }

  @override
  ZarithIntLayout clone({String? newProperty}) =>
      ZarithIntLayout(property: newProperty);
}
