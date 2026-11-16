import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

/// A layout with no data: always decodes to `null`, writes nothing.
class NoneLayout<T> extends Layout<T?> {
  const NoneLayout({super.property}) : super(0);

  @override
  Layout clone({String? newProperty}) {
    return NoneLayout(property: newProperty);
  }

  @override
  decode(LayoutByteReader bytes, {int offset = 0}) {
    return const LayoutDecodeResult(consumed: 0, value: null);
  }

  @override
  int encode(source, LayoutByteWriter writer, {int offset = 0}) {
    return 0;
  }

  @override
  int getSpan() {
    return 0;
  }
}
