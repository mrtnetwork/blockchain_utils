import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

/// Represents a custom layout with customized encoding and decoding functions.
typedef WrappedLayoutDecoder<T, D> = D Function(T value);

typedef WrappedLayoutEncoder<T, D> = T Function(D source);

class CustomLayout<T, D> extends Layout<D> {
  /// Constructs a [CustomLayout] with the specified layout, encoder, and decoder functions.
  ///
  /// - [layout] : The layout to be customized.
  /// - [encoder] : The encoder function to convert the custom type [D] to [T].
  /// - [decoder] : The decoder function to convert [T] to the custom type [D].
  /// - [property] (optional): The property identifier.
  CustomLayout(
      {required this.layout,
      required this.decoder,
      required this.encoder,
      String? property})
      : super(layout.span, property: property);
  final Layout<T> layout;
  final WrappedLayoutEncoder<T, D> encoder;
  final WrappedLayoutDecoder<T, D> decoder;

  @override
  LayoutDecodeResult<D> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decodeBytes = this.layout.decode(bytes, offset: offset);
    final decode = decoder(decodeBytes.value);
    return LayoutDecodeResult(consumed: decodeBytes.consumed, value: decode);
  }

  @override
  int encode(D source, LayoutByteWriter writer, {int offset = 0}) {
    return this.layout.encode(encoder(source), writer, offset: offset);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    return this.layout.getSpan(bytes, offset: offset);
  }

  @override
  CustomLayout<T, D> clone({String? newProperty}) {
    return CustomLayout<T, D>(
        layout: layout,
        decoder: decoder,
        encoder: encoder,
        property: newProperty);
  }
}
