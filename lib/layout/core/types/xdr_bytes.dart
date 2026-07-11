import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core.dart';

/// A class representing a blob layout within a buffer.
class XDRBytesLayout extends Layout<List<int>> {
  XDRBytesLayout._(this.layout, {String? property})
    : super(layout.span, property: property);

  final RawBytesLayout layout;

  /// Constructs a [XDRBytesLayout] with the given [length] and [property].
  factory XDRBytesLayout(dynamic length, {String? property}) {
    if (length is int) {
      if (length.isNegative) {
        throw ArgumentException.invalidOperationArguments(
          "XDRBytesLayout",
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
    return XDRBytesLayout._(RawBytesLayout(length), property: property);
  }
  static int _reminder(int dividend) {
    final int remainder = dividend % 4;
    return remainder == 0 ? 0 : 4 - remainder;
  }

  @override
  int getSpan() {
    int span = layout.getSpan();
    if (span.isNegative) return span;
    assert(span >= 0, "span cannot be negative.");
    span += _reminder(span);
    return span;
  }

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final result = layout.decode(bytes, offset: offset);
    final span = result.consumed + _reminder(result.consumed);
    return LayoutDecodeResult(consumed: span, value: result.value);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final span = layout.encode(source, writer, offset: offset);
    return span + _reminder(span);
  }

  @override
  XDRBytesLayout clone({String? newProperty}) {
    return XDRBytesLayout._(layout, property: newProperty);
  }
}
