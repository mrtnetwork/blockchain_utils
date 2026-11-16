import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Raw byte blob of a fixed size or a size resolved via an [ExternalLayout].
class RawBytesLayout extends Layout<List<int>> {
  final dynamic length;

  const RawBytesLayout._(this.length, {super.property})
    : super(length is ExternalLayout ? -1 : length);

  factory RawBytesLayout(dynamic length, {String? property}) {
    if (length is int) {
      if (length.isNegative) {
        throw CoreErrors.invalidOperationArguments(
          "RawBytesLayout",
          name: "length",
          reason: "The length must be a positive integer.",
        );
      }
    } else if (length is! ExternalLayout) {
      throw CoreErrors.invalidOperationArguments(
        "RawBytesLayout",
        name: "length",
        reason: "The length must be a positive integer or an external layout.",
      );
    }
    return RawBytesLayout._(length, property: property);
  }

  @override
  int getSpan() {
    return span;
  }

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    int span = this.span;
    if (span.isNegative) {
      span = (length as ExternalLayout).decode(bytes, offset: offset).value;
    }
    bytes.requireAvailable(offset, span);
    final result = bytes.sublist(offset, offset + span);
    return LayoutDecodeResult(consumed: span, value: result);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    int span = this.span;
    if (length is ExternalLayout) {
      span = source.length;
    }
    if (span != source.length) {
      throw BuError(DefaultErrorType.invalidLength,"Invalid source length.");
    }
    writer.setAll(offset, source.sublist(0, span));
    if (length is ExternalLayout) {
      (length as ExternalLayout).encode(span, writer, offset: offset);
    }

    return span;
  }

  @override
  RawBytesLayout clone({String? newProperty}) {
    return RawBytesLayout(length, property: newProperty);
  }
}

/// Consumes/writes every remaining byte in the buffer.
class RawTailLayout extends Layout<List<int>> {
  const RawTailLayout({super.property}) : super(-1);

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final tail = bytes.sublist(offset, bytes.length);
    return LayoutDecodeResult(consumed: tail.length, value: tail);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    writer.setAll(offset, source);
    return source.length;
  }

  @override
  RawTailLayout clone({String? newProperty}) =>
      RawTailLayout(property: newProperty);
}

/// Self-delimiting bytes: [discriminator]-encoded length prefix + payload.
/// Not every variable-length field uses this — a trailing field can just
/// run to the end of the buffer (see [RemainderListLayout] in array.dart) —
/// so check the actual field's encoding before assuming a length prefix.
class DynamicBytesLayout extends Layout<List<int>> {
  final IntegerLayout discriminator;

  const DynamicBytesLayout({
    super.property,
    this.discriminator = const IntegerLayout.u32Be(),
  }) : super(-1);

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final decode = discriminator.decode(bytes, offset: offset);
    bytes.requireAvailable(offset + decode.consumed, decode.value);
    final data = bytes.sublist(
      offset + decode.consumed,
      offset + decode.consumed + decode.value,
    );
    return LayoutDecodeResult(
      consumed: decode.consumed + decode.value,
      value: data,
    );
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final encode = discriminator.encode(source.length, writer, offset: offset);
    writer.setAll(offset + encode, source);
    return encode + source.length;
  }

  @override
  DynamicBytesLayout clone({String? newProperty}) =>
      DynamicBytesLayout(property: newProperty);
}
