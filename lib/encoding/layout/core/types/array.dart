import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/constant.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A contiguous sequence of [elementLayout], either a fixed/derived [count]
/// or, when [count] is null, decoded until the buffer is exhausted.
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
        throw CoreErrors.invalidOperationArguments(
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
        if (decodeElement.consumed <= 0) {
          throw const BuError(DefaultErrorType.badLayout,"Sequence element consumed no bytes.");
        }
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

/// Repeats [element] until the buffer is exhausted, with no count/length
/// prefix — e.g. how a Tezos operation list fills the rest of a message.
class RemainderListLayout<T> extends Layout<List<T>> {
  final Layout<T> element;
  const RemainderListLayout(this.element, {super.property}) : super(-1);

  @override
  LayoutDecodeResult<List<T>> decode(LayoutByteReader bytes, {int offset = 0}) {
    final items = <T>[];
    int consumed = 0;
    while (offset + consumed < bytes.length) {
      final r = element.decode(bytes, offset: offset + consumed);
      if (r.consumed <= 0) {
        throw const BuError(DefaultErrorType.badLayout,"Sequence element consumed no bytes.");
      }
      items.add(r.value);
      consumed += r.consumed;
    }
    return LayoutDecodeResult(consumed: consumed, value: items);
  }

  @override
  int encode(List<T> source, LayoutByteWriter writer, {int offset = 0}) {
    int span = 0;
    for (final item in source) {
      span += element.encode(item, writer, offset: offset + span);
    }
    return span;
  }

  @override
  RemainderListLayout<T> clone({String? newProperty}) =>
      RemainderListLayout(element, property: newProperty);
}
