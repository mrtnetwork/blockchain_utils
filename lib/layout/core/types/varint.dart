import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/numeric.dart';

class VarintOffsetLayout extends ExternalOffsetLayout {
  VarintOffsetLayout(this.layout, {super.property});

  final VarintIntLayout layout;

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
  VarintOffsetLayout clone({String? newProperty}) {
    return VarintOffsetLayout(layout, property: newProperty);
  }

  @override
  int getSpan() {
    return layout.getSpan();
  }
}
