import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

class COptionLayout<T> extends Layout<T?> {
  COptionLayout(this.layout, {String? property})
      : super(-1, property: property);
  final Layout<T> layout;
  final IntegerLayout discriminator = IntegerLayout(1);

  static void _validateOption({int? value, String? property}) {
    if (value != 0 && value != 1) {
      throw LayoutException("Invalid option bytes.",
          details: {"property": property, "value": value});
    }
  }

  @override
  LayoutDecodeResult<T?> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = discriminator.decode(bytes, offset: offset);
    if (decode.value == 0) {
      return LayoutDecodeResult(consumed: decode.consumed, value: null);
    }
    _validateOption(property: property, value: decode.value);
    final result = layout.decode(bytes, offset: offset + 1);
    return LayoutDecodeResult(
        consumed: result.consumed + decode.consumed, value: result.value as T?);
  }

  @override
  int encode(T? source, LayoutByteWriter writer, {int offset = 0}) {
    if (source == null) {
      return discriminator.encode(0, writer, offset: offset);
    }
    discriminator.encode(1, writer, offset: offset);
    final encode = layout.encode(source, writer, offset: offset + 1);
    return encode + 1;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, T? source}) {
    if (bytes == null) return layout.span + 1;
    final decode = discriminator.decode(bytes, offset: offset);
    if (decode.value == 0) return 1;
    _validateOption(property: property, value: decode.value);
    return layout.span + 1;
  }

  @override
  COptionLayout clone({String? newProperty}) {
    return COptionLayout<T>(layout, property: newProperty);
  }
}
