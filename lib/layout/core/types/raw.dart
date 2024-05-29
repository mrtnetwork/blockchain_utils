import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// A class representing a blob layout within a buffer.
class RawBytesLayout extends Layout<List<int>> {
  /// The number of bytes in the blob.
  ///
  /// This may be a non-negative integer or an instance of [ExternalLayout] that satisfies [ExternalLayout.isCount].
  final dynamic length;

  const RawBytesLayout._(this.length, {String? property})
      : super(length is ExternalLayout ? -1 : length, property: property);

  /// Constructs a [RawBytesLayout] with the given [length] and [property].
  ///
  /// The [length] can be a positive integer or an unsigned integer [ExternalLayout].
  factory RawBytesLayout(dynamic length, {String? property}) {
    if (length is int) {
      if (length.isNegative) {
        throw LayoutException("The length must be a positive integer.",
            details: {"property": property, "length": length});
      }
    } else if (length is! ExternalLayout) {
      throw LayoutException(
          "The length can be a positive integer or an unsigned integer ExternalLayout",
          details: {"property": property, "length": length});
    }
    return RawBytesLayout._(length, property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    int span = this.span;
    if (span < 0) {
      span = (length as ExternalLayout).decode(bytes!, offset: offset).value;
    }
    return span;
  }

  @override
  LayoutDecodeResult<List<int>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    int span = getSpan(bytes, offset: offset);
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
      throw LayoutException("encode requires a source with length $span.",
          details: {
            "property": property,
            "length": span,
            "sourceLength": source.length
          });
    }
    if (offset + span > writer.length) {
      if (!writer.growable) {
        throw LayoutException("Encoding overruns bytes", details: {
          "property": property,
        });
      }
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
