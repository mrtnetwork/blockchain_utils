import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

/// Layout for a single key/value pair, used to build map layouts.
class MapEntryLayout extends Layout<MapEntry> {
  final Layout keyLayout;
  final Layout valueLayout;

  MapEntryLayout({
    required this.keyLayout,
    required this.valueLayout,
    super.property,
  }) : super(
         (keyLayout.span >= 0 && valueLayout.span >= 0)
             ? keyLayout.span + valueLayout.span
             : -1,
       );

  @override
  LayoutDecodeResult<MapEntry> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final key = keyLayout.decode(bytes, offset: offset);
    final value = valueLayout.decode(bytes, offset: offset + key.consumed);
    return LayoutDecodeResult(
      consumed: key.consumed + value.consumed,
      value: MapEntry(key.value, value.value),
    );
  }

  @override
  int encode(MapEntry source, LayoutByteWriter writer, {int offset = 0}) {
    final keyBytes = keyLayout.encode(source.key, writer, offset: offset);
    final valueBytes = valueLayout.encode(
      source.value,
      writer,
      offset: offset + keyBytes,
    );
    return keyBytes + valueBytes;
  }

  @override
  int getSpan() {
    final keySpan = keyLayout.getSpan();
    if (keySpan < 0) return keySpan;
    final valSpan = valueLayout.getSpan();
    if (valSpan < 0) return valSpan;
    return keySpan + valSpan;
  }

  @override
  Layout clone({String? newProperty}) {
    return MapEntryLayout(
      keyLayout: keyLayout,
      valueLayout: valueLayout,
      property: newProperty,
    );
  }
}
