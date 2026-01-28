import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'numeric.dart';

class CompactOffsetLayout extends ExternalOffsetLayout {
  CompactOffsetLayout(this.layout, {super.property});

  final CompactIntLayout layout;

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = layout.decode(bytes, offset: offset);
    return decode;
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final encodeLength = layout.encode(source, writer, offset: offset);
    return encodeLength;
  }

  @override
  CompactOffsetLayout clone({String? newProperty}) {
    return CompactOffsetLayout(layout, property: newProperty);
  }

  @override
  int getSpan() {
    return layout.getSpan();
  }
}
