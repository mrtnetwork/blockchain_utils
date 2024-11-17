import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// Represents a layout for optional values.
class OptionalLayout<T> extends Layout<T?> {
  OptionalLayout._(this.layout,
      {required this.discriminator, String? property, this.size})
      : super(-1, property: property);

  /// Constructs an [OptionalLayout] with the specified layout and optional discriminator.
  ///
  /// - [layout] : The layout for the optional value.
  /// - [property] (optional): The property identifier.
  /// - [keepLayoutSize] (optional): Whether to keep the layout size.
  /// - [discriminator] (optional): The discriminator layout.
  factory OptionalLayout(Layout<T> layout,
      {BaseIntiger? discriminator,
      String? property,
      bool keepLayoutSize = false}) {
    final BaseIntiger disc = discriminator ??= IntegerLayout(1);
    if (keepLayoutSize && layout.span.isNegative) {
      throw const LayoutException(
          "keepLayoutSize works only with layouts that have a fixed size.");
    }
    late final int? size = keepLayoutSize ? layout.span + disc.span : null;
    return OptionalLayout._(layout,
        discriminator: disc, size: size, property: property);
  }

  final Layout<T> layout;
  final BaseIntiger discriminator;
  // final bool keepLayoutSize;
  final int? size;
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
    final result = layout.decode(bytes, offset: offset + decode.consumed);
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
    final encode =
        layout.encode(source, writer, offset: offset + discriminator.span);
    return size ?? encode + discriminator.span;
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0, T? source}) {
    if (size != null) return size!;

    final decode = discriminator.decode(bytes!, offset: offset);
    if (decode.value == 0) return discriminator.span;
    _validateOption(property: property, value: decode.value);
    final lSpan = layout.getSpan(bytes,
        offset: offset + discriminator.span, source: source);
    assert(lSpan >= 0, "span cannot be negative.");
    return lSpan + discriminator.span;
  }

  @override
  OptionalLayout<T> clone({String? newProperty}) {
    return OptionalLayout<T>._(
      layout,
      property: newProperty,
      discriminator: discriminator,
      size: size,
    );
  }
}
