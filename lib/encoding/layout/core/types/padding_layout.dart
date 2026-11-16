import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Transparent wrapper that reports [layout]'s span as its own, used to
/// mark a field whose absence is tolerated (e.g. trailing struct padding).
class PaddingLayout<T> extends Layout<T> {
  final BaseInteger<T> layout;
  PaddingLayout(this.layout, {super.property}) : super(layout.span);

  @override
  int getSpan() {
    return layout.getSpan();
  }

  @override
  PaddingLayout clone({String? newProperty}) {
    return PaddingLayout(layout, property: newProperty);
  }

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    return layout.decode(bytes, offset: offset);
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    return layout.encode(source, writer, offset: offset);
  }
}

/// Length-prefixed payload: a [discriminator]-encoded byte count followed
/// by exactly that many bytes decoded through [inner]. The inner layout is
/// bounded to just that byte range, so remainder-based inner layouts stop
/// at the right place instead of reading into whatever follows.
class DynamicSizeLayout<T> extends Layout<T> {
  final Layout<T> inner;
  final IntegerLayout discriminator;

  const DynamicSizeLayout(
    this.inner, {
    this.discriminator = const IntegerLayout.u32Be(),
    super.property,
  }) : super(-1);

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = discriminator.decode(bytes, offset: offset);
    final slice = bytes.sublist(
      offset + decode.consumed,
      offset + decode.consumed + decode.value,
    );
    final subReader = LayoutByteReader(slice);
    final r = inner.decode(subReader, offset: 0);
    if (r.consumed != decode.value) {
      throw BuError(DefaultErrorType.badLayout,
        'dynamic_size payload was not fully consumed',
        details: {
          'declared': decode.value.toString(),
          'consumed': r.consumed.toString(),
          'property': property,
        },
      );
    }
    return LayoutDecodeResult(
      consumed: decode.consumed + decode.value,
      value: r.value,
    );
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    // Encoded to a scratch buffer first: the length prefix must be written
    // before the encoded length of `inner` is known.
    final scratch = LayoutByteWriter(-1);
    final written = inner.encode(source, scratch, offset: 0);
    final encode = discriminator.encode(written, writer, offset: offset);
    writer.setAll(offset + encode, scratch.toBytes());
    return encode + written;
  }

  @override
  DynamicSizeLayout<T> clone({String? newProperty}) => DynamicSizeLayout(
    inner,
    discriminator: discriminator,
    property: newProperty,
  );
}
