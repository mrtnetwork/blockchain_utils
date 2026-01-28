import 'package:blockchain_utils/layout/byte/byte_handler.dart';
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
      pos += decode.consumed;
    }
    return LayoutDecodeResult(consumed: pos - offset, value: encoded);
  }

  @override
  int encode(List source, LayoutByteWriter writer, {int offset = 0}) {
    if (source.length != layouts.length) {
      throw LayoutException(
        "Source length must match layout length.",
        details: {"property": property},
      );
    }
    int pos = offset;
    for (int i = 0; i < source.length; i++) {
      pos += layouts[i].encode(source[i], writer, offset: pos);
    }
    return pos - offset;
  }

  @override
  int getSpan() {
    int span = 0;
    for (int i = 0; i < layouts.length; i++) {
      final layout = layouts[i];
      final lSpan = layout.getSpan();
      if (lSpan < 0) return -1;
      span += lSpan;
    }
    return span;
  }

  @override
  TupleLayout clone({String? newProperty}) {
    return TupleLayout(layouts, property: newProperty);
  }
}
