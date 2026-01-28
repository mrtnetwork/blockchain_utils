import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

/// Represents the layout for a key-value pair in a map.
class MapEntryLayout extends Layout<MapEntry> {
  final Layout keyLayout;
  final Layout valueLayout;

  /// Constructs a [MapEntryLayout] with the specified key and value layouts.
  ///
  /// - [keyLayout] : The layout for the key.
  /// - [valueLayout] : The layout for the value.
  /// - [property] (optional): The property identifier.
  MapEntryLayout({
    required this.keyLayout,
    required this.valueLayout,
    String? property,
  }) : super(
         (keyLayout.span >= 0 && valueLayout.span >= 0)
             ? keyLayout.span + valueLayout.span
             : -1,
         property: property,
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
