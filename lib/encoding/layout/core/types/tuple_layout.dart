import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Fixed-order list of heterogeneous layouts, concatenated end to end.
class TupleLayout extends Layout<List> {
  TupleLayout(List<Layout> layouts, {super.property})
    : layouts = List<Layout>.unmodifiable(layouts),
      super(-1);
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
      throw BuError(DefaultErrorType.invalidLength,
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
