import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/constant/constant.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class CompactString extends Layout<String> {
  CompactString({String? property}) : super(-1, property: property);
  final _lengthCodec = LayoutConst.compactIntU48();

  @override
  CompactString clone({String? newProperty}) {
    return CompactString(property: property);
  }

  @override
  int getSpan() {
    return -1;
  }

  @override
  LayoutDecodeResult<String> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeScaleAsInteger(offset);
    final total = decode.consumed + decode.value;

    final result = bytes.sublist(offset + decode.consumed, offset + total);
    return LayoutDecodeResult(
      consumed: total,
      value: StringUtils.decode(result),
    );
  }

  @override
  int encode(String source, LayoutByteWriter writer, {int offset = 0}) {
    final sourceBytes = StringUtils.encode(source);
    final int length = _lengthCodec.encode(
      sourceBytes.length,
      writer,
      offset: offset,
    );
    writer.setAll(offset + length, sourceBytes);
    return sourceBytes.length + length;
  }
}
