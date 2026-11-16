import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

typedef CbWrappedLayoutDecoder<T, D> = D Function(T value);
typedef CbWrappedLayoutEncoder<T, D> = T Function(D source);

/// Wraps [layout] with an [encoder]/[decoder] pair to expose it as a
/// different domain type [D].
class CustomLayout<T, D> extends Layout<D> {
  CustomLayout({
    required this.layout,
    required this.decoder,
    required this.encoder,
    super.property,
  }) : super(layout.span);
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

/// Bidirectional mapping between a wire shape [B] and a domain type [A].
class ConvLayout<A, B> extends Layout<A> {
  final Layout<B> inner;
  final B Function(A) toWire;
  final A Function(B) fromWire;

  ConvLayout(
    this.inner, {
    required this.toWire,
    required this.fromWire,
    super.property,
  }) : super(inner.span);

  @override
  LayoutDecodeResult<A> decode(LayoutByteReader bytes, {int offset = 0}) {
    final r = inner.decode(bytes, offset: offset);
    return LayoutDecodeResult(consumed: r.consumed, value: fromWire(r.value));
  }

  @override
  int encode(A source, LayoutByteWriter writer, {int offset = 0}) =>
      inner.encode(toWire(source), writer, offset: offset);

  @override
  ConvLayout<A, B> clone({String? newProperty}) => ConvLayout(
    inner,
    toWire: toWire,
    fromWire: fromWire,
    property: newProperty,
  );
}

class EmptyLayout<R> extends Layout<R> {
  final R value;

  const EmptyLayout(this.value, {super.property}) : super(0);

  @override
  LayoutDecodeResult<R> decode(LayoutByteReader bytes, {int offset = 0}) {
    return LayoutDecodeResult(consumed: 0, value: value);
  }

  @override
  int encode(R source, LayoutByteWriter writer, {int offset = 0}) {
    return span;
  }

  @override
  EmptyLayout<R> clone({String? newProperty}) =>
      EmptyLayout(value, property: newProperty);
}
