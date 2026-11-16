import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

/// Layout that resolves lazily, letting self-referential layouts be built.
class LazyLayout<T> extends Layout<T> {
  final Layout<T> Function() resolve;
  const LazyLayout(this.resolve) : super(-1);

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) =>
      resolve().decode(bytes, offset: offset);

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) =>
      resolve().encode(source, writer, offset: offset);

  @override
  Layout<T> clone({String? newProperty}) => this;
}
