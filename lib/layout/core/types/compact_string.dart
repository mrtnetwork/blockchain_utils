import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/utils/utils.dart';

class CompactString extends Layout<String> {
  const CompactString({String? property}) : super(-1, property: property);
  static final _lengthCodec = LayoutConst.compactIntU48();

  @override
  CompactString clone({String? newProperty}) {
    return CompactString(property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, String? source}) {
    return bytes!.getCompactTotalLenght(offset).item2;
  }

  @override
  LayoutDecodeResult<String> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.getCompactTotalLenght(offset);
    final result = bytes.sublist(offset + decode.item1, offset + decode.item2);
    return LayoutDecodeResult(
        consumed: decode.item2, value: StringUtils.decode(result));
  }

  @override
  int encode(String source, LayoutByteWriter writer, {int offset = 0}) {
    final sourceBytes = StringUtils.encode(source);
    final int length =
        _lengthCodec.encode(sourceBytes.length, writer, offset: offset);
    writer.setAll(offset + length, sourceBytes);
    return sourceBytes.length + length;
  }
}
