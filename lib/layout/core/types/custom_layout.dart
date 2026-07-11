import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

/// Represents a custom layout with customized encoding and decoding functions.
typedef CbWrappedLayoutDecoder<T, D> = D Function(T value);

typedef CbWrappedLayoutEncoder<T, D> = T Function(D source);

class CustomLayout<T, D> extends Layout<D> {
  /// Constructs a [CustomLayout] with the specified layout, encoder, and decoder functions.
  CustomLayout({
    required this.layout,
    required this.decoder,
    required this.encoder,
    String? property,
  }) : super(layout.span, property: property);
  final Layout<T> layout;
  final CbWrappedLayoutEncoder<T, D> encoder;
  final CbWrappedLayoutDecoder<T, D> decoder;

  @override
  LayoutDecodeResult<D> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decodeBytes = layout.decode(bytes, offset: offset);
    final decode = decoder(decodeBytes.value);
    return LayoutDecodeResult(consumed: decodeBytes.consumed, value: decode);
  }

  @override
  int encode(D source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(encoder(source), writer, offset: offset);
  }

  @override
  int getSpan() {
    return layout.getSpan();
  }

  @override
  CustomLayout<T, D> clone({String? newProperty}) {
    return CustomLayout<T, D>(
      layout: layout,
      decoder: decoder,
      encoder: encoder,
      property: newProperty,
    );
  }
}
