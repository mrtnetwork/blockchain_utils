import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

import 'compact.dart';
import 'constant.dart';
import 'numeric.dart';
import 'padding_layout.dart';

/// Represent a contiguous sequence of a specific layout as an Array.
///
/// Factory: [SequenceLayout]
///
/// - [elementLayout] : Initializer for [elementLayout].
/// - [count] : Initializer for [count]. The parameter must be either a positive [ConstantLayout] integer layout or an instance of
///  [ExternalLayout].
/// - [property] (optional): Initializer for [property].
///
class SequenceLayout<T> extends Layout<List<T>> {
  final Layout elementLayout;
  final Layout count; // Type can be ExternalLayout or int
  factory SequenceLayout(
      {required Layout elementLayout,
      required Layout count,
      String? property}) {
    if (!((count is ExternalLayout && count.isCount()) ||
        (count is ConstantLayout && count.value is int && count.value >= 0) ||
        count is PaddingLayout)) {
      throw LayoutException(
          'count must be non-negative integer or an unsigned integer ExternalLayout',
          details: {"property": property, "count": count});
    }
    int span = -1;
    if ((count is ExternalLayout && count.isCount()) ||
        (count is ConstantLayout && count.value >= 0)) {
      if (count is! ExternalLayout && (elementLayout.span >= 0)) {
        span = (count as ConstantLayout).value * elementLayout.span;
      }
    }

    return SequenceLayout._(
        elementLayout: elementLayout,
        count: count,
        property: property,
        span: span);
  }

  const SequenceLayout._({
    required this.elementLayout,
    required this.count,
    required int span,
    String? property,
  }) : super(span, property: property);

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    if (this.span >= 0) {
      return this.span;
    }

    int span = 0;
    int counter = 0;
    if (count is CompactOffsetLayout) {
      final decodeLength = bytes!.getCompactLengthInfos(offset);
      span = decodeLength.item1;
      counter = decodeLength.item2;
    } else if (count is ExternalLayout) {
      counter = count.decode(bytes!, offset: offset).value;
    }

    if (this.elementLayout.span > 0) {
      span += (counter * this.elementLayout.span);
    } else {
      int idx = 0;
      while (idx < counter) {
        span += this.elementLayout.getSpan(bytes, offset: offset + span);
        ++idx;
      }
    }
    return span;
  }

  @override
  LayoutDecodeResult<List<T>> decode(LayoutByteReader bytes, {int offset = 0}) {
    List<T> decoded = [];
    int i = 0;
    int startOffset = offset;
    int count;
    if (this.count is CompactOffsetLayout) {
      final decodeLength = bytes.getCompactLengthInfos(offset);
      startOffset += decodeLength.item1;
      count = decodeLength.item2;
    } else {
      count = this.count.decode(bytes, offset: offset).value;
    }
    while (i < count) {
      final decodeElement =
          this.elementLayout.decode(bytes, offset: startOffset);
      decoded.add(decodeElement.value);
      startOffset += this.elementLayout.getSpan(bytes, offset: startOffset);
      i += 1;
    }
    return LayoutDecodeResult(consumed: startOffset - offset, value: decoded);
  }

  @override
  int encode(List<T> source, LayoutByteWriter writer, {int offset = 0}) {
    int span = 0;
    if (count is CompactOffsetLayout) {
      span = (count as CompactOffsetLayout)
          .encode(source.length, writer, offset: offset);
    } else if (this.count is ExternalLayout) {
      this.count.encode(source.length, writer, offset: offset);
    }
    span = source.fold(span, (span, v) {
      final encodeLength =
          elementLayout.encode(v, writer, offset: offset + span);
      return span + encodeLength;
    });

    return span;
  }

  @override
  SequenceLayout clone({String? newProperty}) {
    return SequenceLayout<T>(
        elementLayout: elementLayout, count: count, property: newProperty);
  }
}
