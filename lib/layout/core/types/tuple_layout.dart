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
    List encoded = [];
    int pos = offset;
    for (final i in layouts) {
      final decode = i.decode(bytes, offset: pos);
      encoded.add(decode.value);
      pos += i.getSpan(bytes, offset: pos);
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
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    int span = 0;
    for (final i in layouts) {
      span += i.getSpan(bytes, offset: offset + span);
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
    List encoded = [];
    int pos = decodeLength.item1 + offset;
    for (final i in layouts) {
      encoded.add(i.decode(bytes, offset: pos));
      pos += i.getSpan(bytes, offset: pos);
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
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    final decodeLength = bytes!.getCompactLengthInfos(offset);
    int span = decodeLength.item1;
    for (final i in layouts) {
      span += i.getSpan(bytes, offset: offset + span);
    }
    return span;
  }

  @override
  TupleLayout clone({String? newProperty}) {
    return TupleLayout(layouts, property: newProperty);
  }
}
