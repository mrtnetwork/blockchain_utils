import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A [discriminator]-flagged value: [noneFlag] means absent, [someFlag]
/// means [layout] follows.
class OptionalLayout<T> extends Layout<T?> {
  final int noneFlag;
  final int someFlag;
  OptionalLayout._(
    this.layout, {
    required this.discriminator,
    required this.noneFlag,
    required this.someFlag,
    super.property,
    this.size,
  }) : super(-1);

  /// [keepLayoutSize] pads the encoding to a fixed size (requires [layout]
  /// to have a fixed span).
  factory OptionalLayout(
    Layout<T> layout, {
    BaseInteger? discriminator,
    String? property,
    bool keepLayoutSize = false,
    int noneFlag = 0,
    int someFlag = 1,
  }) {
    final BaseInteger disc = discriminator ??= IntegerLayout(1);
    if (keepLayoutSize && layout.span.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        "OptionalLayout",
        name: "discriminator",
        reason: "keepLayoutSize works only with layouts that have a fixed size",
      );
    }
    late final int? size = keepLayoutSize ? layout.span + disc.span : null;
    return OptionalLayout._(
      layout,
      discriminator: disc,
      size: size,
      property: property,
      noneFlag: noneFlag,
      someFlag: someFlag,
    );
  }

  final Layout<T> layout;
  final BaseInteger discriminator;
  final int? size;

  void _validateOption({int? value, String? property}) {
    if (value != someFlag && value != noneFlag) {
      throw BuError(DefaultErrorType.invalidArgument,
        "Failed to decode data as option flag.",
        details: {"property": property, "value": value.toString()},
      );
    }
  }

  @override
  LayoutDecodeResult<T?> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = discriminator.decode(bytes, offset: offset);
    _validateOption(property: property, value: decode.value);
    if (decode.value == noneFlag) {
      return LayoutDecodeResult(consumed: size ?? decode.consumed, value: null);
    }
    final result = layout.decode(bytes, offset: offset + decode.consumed);
    return LayoutDecodeResult(
      consumed: size ?? (decode.consumed + result.consumed),
      value: result.value as T?,
    );
  }

  @override
  int encode(T? source, LayoutByteWriter writer, {int offset = 0}) {
    // Public final fields don't promote; copy to locals for null checks.
    final fixedSize = size;
    if (source == null) {
      if (fixedSize != null) {
        discriminator.encode(noneFlag, writer, offset: offset);
        writer.setAll(
          offset + discriminator.span,
          List<int>.filled(fixedSize - discriminator.span, 0),
        );
        return fixedSize;
      }
      return discriminator.encode(noneFlag, writer, offset: offset);
    }
    final discSpan = discriminator.encode(someFlag, writer, offset: offset);
    final encode = layout.encode(source, writer, offset: offset + discSpan);
    return fixedSize ?? encode + discSpan;
  }

  @override
  int getSpan() {
    if (size != null) return size!;
    return span;
  }

  @override
  OptionalLayout<T> clone({String? newProperty}) {
    return OptionalLayout<T>._(
      layout,
      property: newProperty,
      discriminator: discriminator,
      size: size,
      noneFlag: noneFlag,
      someFlag: someFlag,
    );
  }
}
