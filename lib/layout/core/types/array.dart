import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'constant.dart';
import 'numeric.dart';
import 'padding_layout.dart';

/// Represent a contiguous sequence of a specific layout as an Array.
class SequenceLayout<T> extends Layout<List<T>> {
  final Layout elementLayout;
  final Layout<int>? count;
  factory SequenceLayout({
    required Layout elementLayout,
    Layout<int>? count,
    String? property,
  }) {
    if (count != null) {
      if (!(count is ExternalLayout ||
          (count is ConstantLayout<int> && count.value >= 0) ||
          count is PaddingLayout)) {
        throw ArgumentException.invalidOperationArguments(
          "SequenceLayout",
          name: "count",
          reason: 'Invalid sequence count layout.',
        );
      }
    }
    int span = -1;
    if ((count is ExternalLayout) ||
        (count is ConstantLayout<int> && count.value >= 0)) {
      if (count is! ExternalLayout && (elementLayout.span >= 0)) {
        span = (count as ConstantLayout).value * elementLayout.span;
      }
    }

    return SequenceLayout._(
      elementLayout: elementLayout,
      count: count,
      property: property,
      span: span,
    );
  }

  const SequenceLayout._({
    required this.elementLayout,
    required this.count,
    required int span,
    String? property,
  }) : super(span, property: property);
  // @override
  @override
  int getSpan() {
    if (span >= 0) {
      return span;
    }

    int counter = -1;
    if (count is ConstantLayout) {
      counter = (count as ConstantLayout).value;
    }
    if (counter >= 0 && elementLayout.span >= 0) {
      return counter * elementLayout.span;
    }
    return span;
  }

  @override
  LayoutDecodeResult<List<T>> decode(LayoutByteReader bytes, {int offset = 0}) {
    final List<T> decoded = [];
    final countLayout = this.count;
    int startOffset = offset;
    if (countLayout == null) {
      while (true) {
        final decodeElement = elementLayout.decode(bytes, offset: startOffset);
        decoded.add(decodeElement.value);
        startOffset += decodeElement.consumed;
        if (bytes.isEnd(startOffset)) break;
      }
      return LayoutDecodeResult(consumed: startOffset - offset, value: decoded);
    }
    int i = 0;

    int count;
    if (countLayout is ExternalOffsetLayout) {
      final decode = countLayout.decode(bytes, offset: offset);
      startOffset += decode.consumed;
      count = decode.value;
    } else {
      count = countLayout.decode(bytes, offset: offset).value;
    }
    while (i < count) {
      final decodeElement = elementLayout.decode(bytes, offset: startOffset);
      decoded.add(decodeElement.value);
      startOffset += decodeElement.consumed;
      i += 1;
    }
    return LayoutDecodeResult(consumed: startOffset - offset, value: decoded);
  }

  @override
  int encode(List<T> source, LayoutByteWriter writer, {int offset = 0}) {
    int span = 0;
    final countLayout = count;
    if (countLayout is ExternalOffsetLayout) {
      span = countLayout.encode(source.length, writer, offset: offset);
    } else if (countLayout is ExternalLayout) {
      countLayout.encode(source.length, writer, offset: offset);
    }
    span = source.fold(span, (span, v) {
      final encodeLength = elementLayout.encode(
        v,
        writer,
        offset: offset + span,
      );
      return span + encodeLength;
    });
    return span;
  }

  @override
  SequenceLayout clone({String? newProperty}) {
    return SequenceLayout<T>(
      elementLayout: elementLayout,
      count: count,
      property: newProperty,
    );
  }
}
