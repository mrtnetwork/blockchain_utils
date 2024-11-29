import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/utils/utils.dart';

class CompactLayout<T> extends Layout<T> {
  CompactLayout(this.layout, {String? property})
      : super(-1, property: property);
  final Layout<T> layout;

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.getCompactTotalLenght(offset);
    final result = layout
        .decode(bytes.getReader(offset + decode.item1, offset + decode.item2));
    return LayoutDecodeResult(consumed: decode.item2, value: result.value);
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    final encode = layout.serialize(source);
    final lengthBytes = LayoutSerializationUtils.encodeLength(encode);
    writer.setAll(offset, lengthBytes);
    writer.setAll(offset + lengthBytes.length, encode);
    return encode.length + lengthBytes.length;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, T? source}) {
    return bytes!.getCompactTotalLenght(offset).item2;
  }

  @override
  CompactLayout<T> clone({String? newProperty}) {
    return CompactLayout<T>(layout, property: newProperty);
  }
}
