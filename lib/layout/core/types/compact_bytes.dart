import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';

class CompactBytes extends Layout<List<int>> {
  CompactBytes({String? property}) : super(-1, property: property);
  final _lengthCodec = LayoutConst.compactIntU48();

  @override
  CompactBytes clone({String? newProperty}) {
    return CompactBytes(property: property);
  }

  @override
  int getSpan() {
    return -1;
  }

  @override
  LayoutDecodeResult<List<int>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final decode = bytes.decodeScaleAsInteger(offset);
    final total = decode.consumed + decode.value;
    final result = bytes.sublist(offset + decode.consumed, offset + total);
    return LayoutDecodeResult(consumed: total, value: result);
  }

  @override
  int encode(List<int> source, LayoutByteWriter writer, {int offset = 0}) {
    final int length = _lengthCodec.encode(
      source.length,
      writer,
      offset: offset,
    );
    writer.setAll(offset + length, source);
    return source.length + length;
  }
}
