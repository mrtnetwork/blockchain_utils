import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/utils/utils.dart';
import 'numeric.dart';

class CompactOffsetLayout extends ExternalLayout {
  const CompactOffsetLayout({String? property}) : super(-1, property: property);

  @override
  bool isCount() {
    return true;
  }

  @override
  LayoutDecodeResult<int> decode(LayoutByteReader bytes, {int offset = 0}) {
    throw UnimplementedError();
  }

  @override
  int encode(int source, LayoutByteWriter writer, {int offset = 0}) {
    final encodeLength = LayoutSerializationUtils.compactIntToBytes(source);
    writer.setAll(offset, encodeLength);
    return encodeLength.length;
  }

  @override
  CompactOffsetLayout clone({String? newProperty}) {
    return CompactOffsetLayout(property: newProperty);
  }
}
