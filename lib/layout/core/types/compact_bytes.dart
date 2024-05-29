import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

class CompactBytes extends Layout<List<int>> {
  const CompactBytes({String? property}) : super(-1, property: property);
  static final _lengthCodec = LayoutConst.compactIntU48();

  @override
  CompactBytes clone({String? newProperty}) {
    return CompactBytes(property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    return bytes!.getCompactTotalLenght(offset).item2;
  }

  @override
  LayoutDecodeResult<List<int>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    final decode = bytes.getCompactTotalLenght(offset);
    final result = bytes.sublist(offset + decode.item1, offset + decode.item2);
    return LayoutDecodeResult(consumed: decode.item2, value: result);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final int length =
        _lengthCodec.encode(source.length, writer, offset: offset);
    writer.setAll(offset + length, source);
    return source.length + length;
  }
}
