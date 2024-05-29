import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// Represents a layout for optional values.
class OptionalLayout<T> extends Layout<T?> {
  /// Constructs an [OptionalLayout] with the specified layout and optional discriminator.
  ///
  /// - [layout] : The layout for the optional value.
  /// - [property] (optional): The property identifier.
  /// - [keepLayoutSize] (optional): Whether to keep the layout size.
  /// - [discriminator] (optional): The discriminator layout.
  OptionalLayout(this.layout,
      {Layout? discriminator, String? property, this.keepLayoutSize = false})
      : discriminator = discriminator ?? IntegerLayout(1),
        super(-1, property: property);
  final Layout<T> layout;
  final Layout discriminator;
  final bool keepLayoutSize;
  late final int? size =
      keepLayoutSize ? layout.span + discriminator.span : null;
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
      return LayoutDecodeResult(consumed: size ?? decode.consumed, value: null);
    }
    _validateOption(property: property, value: decode.value);
    final result = layout.decode(bytes, offset: offset + 1);
    return LayoutDecodeResult(
        consumed: size ?? (decode.consumed + result.consumed),
        value: result.value as T?);
  }

  @override
  int encode(T? source, LayoutByteWriter writer, {int offset = 0}) {
    if (source == null) {
      return size ?? discriminator.encode(0, writer, offset: offset);
    }
    discriminator.encode(1, writer, offset: offset);
    final encode = layout.encode(source, writer, offset: offset + 1);
    return size ?? encode + 1;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    if (size != null) return size!;

    final decode = discriminator.decode(bytes!, offset: offset);
    if (decode.value == 0) return 1;
    _validateOption(property: property, value: decode.value);
    return layout.getSpan(bytes, offset: offset + 1) + 1;
  }

  @override
  OptionalLayout<T> clone({String? newProperty}) {
    return OptionalLayout<T>(layout,
        property: newProperty,
        keepLayoutSize: keepLayoutSize,
        discriminator: discriminator);
  }
}
