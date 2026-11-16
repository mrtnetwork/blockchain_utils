import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Rust `COption<T>`: a 1-byte discriminator (0 = none, 1 = some) followed
/// by [layout] when present.
class COptionLayout<T> extends Layout<T?> {
  COptionLayout(this.layout, {super.property}) : super(-1);
  final Layout<T> layout;
  final IntegerLayout discriminator = IntegerLayout(1);

  static void _validateOption({int? value, String? property}) {
    if (value != 0 && value != 1) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Failed to decode data as COption flag.",
        details: {"property": property, "value": value.toString()},
      );
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
      consumed: result.consumed + decode.consumed,
      value: result.value as T?,
    );
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
  int getSpan() {
    if (layout.span > 0) return layout.span + 1;
    return -1;
  }

  @override
  COptionLayout clone({String? newProperty}) {
    return COptionLayout<T>(layout, property: newProperty);
  }
}
