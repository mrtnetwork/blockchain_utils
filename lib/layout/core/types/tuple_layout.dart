import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// Represents a layout for tuples.
class TupleLayout extends Layout<List> {
  /// Constructs a [TupleLayout] with the specified list of layouts.
  ///
  /// - [layouts] : The list of layouts representing the tuple elements.
  /// - [property] (optional): The property identifier.
  TupleLayout(List<Layout> layouts, {String? property})
      : layouts = List<Layout>.unmodifiable(layouts),
        super(-1, property: property);
  final List<Layout> layouts;

  @override
  LayoutDecodeResult<List> decode(LayoutByteReader bytes, {int offset = 0}) {
    final List encoded = [];
    int pos = offset;
    for (final i in layouts) {
      final decode = i.decode(bytes, offset: pos);
      encoded.add(decode.value);
      final lSpan = i.getSpan(bytes, offset: pos, source: decode.value);
      assert(lSpan >= 0, "span cannot be negative.");
      pos += lSpan;
    }
    return LayoutDecodeResult(consumed: pos - offset, value: encoded);
  }

  @override
  int encode(List source, LayoutByteWriter writer, {int offset = 0}) {
    if (source.length != layouts.length) {
      throw LayoutException("Source length must match layout length.",
          details: {"property": property});
    }
    int pos = offset;
    for (int i = 0; i < source.length; i++) {
      pos += layouts[i].encode(source[i], writer, offset: pos);
    }
    return pos - offset;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, List? source}) {
    int span = 0;
    for (int i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      final lSpan =
          layout.getSpan(bytes, offset: offset + span, source: source?[i]);
      assert(lSpan >= 0, "span cannot be negative.");
      span += lSpan;
    }
    return span;
  }

  @override
  TupleLayout clone({String? newProperty}) {
    return TupleLayout(layouts, property: newProperty);
  }
}

class TupleCompactLayout extends Layout<List> {
  /// Constructs a [TupleLayout] with the specified list of layouts.
  ///
  /// - [layouts] : The list of layouts representing the tuple elements.
  /// - [property] (optional): The property identifier.
  TupleCompactLayout(List<Layout> layouts, {String? property})
      : layouts = List<Layout>.unmodifiable(layouts),
        super(-1, property: property);
  static final _lengthCodec = LayoutConst.compactOffset();
  final List<Layout> layouts;

  @override
  LayoutDecodeResult<List> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decodeLength = bytes.getCompactLengthInfos(offset);
    if (decodeLength.item2 != layouts.length) {
      throw LayoutException("Source length must match layout length.",
          details: {"property": property});
    }
    final List encoded = [];
    int pos = decodeLength.item1 + offset;
    for (int i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      final decode = layout.decode(bytes, offset: pos);
      encoded.add(decode);
      final lSpan = layout.getSpan(bytes, offset: pos, source: decode);
      assert(lSpan >= 0, "span cannot be negative.");
      pos += lSpan;
    }
    return LayoutDecodeResult(consumed: pos - offset, value: encoded);
  }

  @override
  int encode(List source, LayoutByteWriter writer, {int offset = 0}) {
    if (source.length != layouts.length) {
      throw LayoutException("Source length must match layout length.",
          details: {"property": property});
    }
    final int length =
        _lengthCodec.encode(source.length, writer, offset: offset);
    int pos = offset + length;
    for (int i = 0; i < source.length; i++) {
      pos += layouts[i].encode(source[i], writer, offset: pos);
    }
    return pos - offset;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, List? source}) {
    final decodeLength = bytes!.getCompactLengthInfos(offset);
    int span = decodeLength.item1;
    for (int i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      final lSpan =
          layout.getSpan(bytes, offset: offset + span, source: source?[i]);
      assert(lSpan >= 0, "span cannot be negative.");
      span += lSpan;
    }
    return span;
  }

  @override
  TupleLayout clone({String? newProperty}) {
    return TupleLayout(layouts, property: newProperty);
  }
}
