import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/constant/constant.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/leb128.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';

/// Offset layout for an unsigned 32-bit LEB128-encoded length.
class LEB128U32OffsetLayout extends ExternalOffsetLayout {
  LEB128U32OffsetLayout({super.property});

  final LEBIntegerLayout layout = LEBIntegerLayout(LayoutConst.u32());

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = layout.decode(bytes, offset: offset);
    return decode;
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    layout.validator.validate(source);
    final encodeLength = LEBIntegerLayout.writeVarint(source);
    writer.setAll(offset, encodeLength);
    return encodeLength.length;
  }

  @override
  LEB128U32OffsetLayout clone({String? newProperty}) {
    return LEB128U32OffsetLayout(property: newProperty);
  }

  @override
  int getSpan() {
    return layout.getSpan();
  }
}
