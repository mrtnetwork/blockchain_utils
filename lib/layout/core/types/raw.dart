import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// A class representing a blob layout within a buffer.
class RawBytesLayout extends Layout<List<int>> {
  /// The number of bytes in the blob.
  final dynamic length;

  const RawBytesLayout._(this.length, {String? property})
    : super(length is ExternalLayout ? -1 : length, property: property);

  factory RawBytesLayout(dynamic length, {String? property}) {
    if (length is int) {
      if (length.isNegative) {
        throw ArgumentException.invalidOperationArguments(
          "RawBytesLayout",
          name: "length",
          reason: "The length must be a positive integer.",
        );
      }
    } else if (length is! ExternalLayout) {
      throw ArgumentException.invalidOperationArguments(
        "RawBytesLayout",
        name: "length",
        reason: "The length layout.",
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
    // final int span = getSpan(bytes, offset: offset);
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
      throw LayoutException("Invalid source length.");
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
