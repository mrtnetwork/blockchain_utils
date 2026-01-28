import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

/// A class representing a constant layout within a buffer.
class ConstantLayout<T> extends Layout<T> {
  final T value;

  /// Constructs a [ConstantLayout] layout with the given [value] and [property].
  const ConstantLayout(this.value, {String? property})
    : super(0, property: property);

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
