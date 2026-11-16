import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

/// A layout that always decodes/encodes to a fixed [value] and takes no bytes.
class ConstantLayout<T> extends Layout<T> {
  final T value;

  const ConstantLayout(this.value, {super.property}) : super(0);

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    return LayoutDecodeResult(consumed: 0, value: value);
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    return 0;
  }

  @override
  Layout clone({String? newProperty}) {
    return ConstantLayout(value, property: newProperty);
  }

  @override
  int getSpan() {
    return 0;
  }
}
