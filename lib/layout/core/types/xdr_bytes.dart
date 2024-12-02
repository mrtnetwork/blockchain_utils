import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// A class representing a blob layout within a buffer.
class XDRBytesLayout extends Layout<List<int>> {
  XDRBytesLayout._(this.layout, {String? property})
      : super(layout.span, property: property);

  final RawBytesLayout layout;

  /// Constructs a [XDRBytesLayout] with the given [length] and [property].
  ///
  /// The [length] can be a positive integer or an unsigned integer [ExternalLayout].
  factory XDRBytesLayout(dynamic length, {String? property}) {
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
    return XDRBytesLayout._(RawBytesLayout(length), property: property);
  }
  static int _reminder(int dividend) {
    final int remainder = dividend % 4;
    return remainder == 0 ? 0 : 4 - remainder;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, List<int>? source}) {
    int span = layout.getSpan(bytes, offset: offset, source: source);
    assert(span >= 0, "span cannot be negative.");
    span += _reminder(span);
    return span;
  }

  @override
  LayoutDecodeResult<List<int>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
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
