import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

class BitSequenceLayout extends Layout<List<int>> {
  const BitSequenceLayout({String? property}) : super(-1, property: property);
  static final _lengthCodec = LayoutConst.compactIntU48();

  @override
  BitSequenceLayout clone({String? newProperty}) {
    return BitSequenceLayout(property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    return bytes!.getCompactTotalLenght(offset).item2 ~/ 8;
  }

  @override
  LayoutDecodeResult<List<int>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    final decode = bytes.getCompactLengthInfos(offset);
    final totalLength = decode.item1 + (decode.item2 ~/ 8);
    final result = bytes.sublist(offset + decode.item1, offset + totalLength);
    return LayoutDecodeResult(consumed: totalLength, value: result);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final int length =
        _lengthCodec.encode(source.length * 8, writer, offset: offset);

    writer.setAll(offset + length, source);
    return source.length + length;
  }
}
