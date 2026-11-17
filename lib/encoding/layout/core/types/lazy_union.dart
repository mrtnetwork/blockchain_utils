import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

typedef CbGetEnumIndex = int Function(Map<String, dynamic> source);
typedef CbNormalizeLayoutResult =
    Map<String, dynamic> Function(Map<String, dynamic> result, int variant);

/// Describes one variant of a [LazyUnion]: its lazily-resolved [layout] and
/// how its discriminator index is determined.
class LazyVariantModel<T> {
  final CbLayoutFunc<T> layout;
  final String? property;
  final int? index;
  final CbGetEnumIndex? onRequestIndex;
  final CbNormalizeLayoutResult? onNormalizeDecodeResult;

  const LazyVariantModel({
    required this.layout,
    required this.property,
    required this.index,
    this.onNormalizeDecodeResult,
    this.onRequestIndex,
  });

  /// Resolves this variant's discriminator index for [source].
  int getIndex(Map<String, dynamic> source) {
    final index = this.index ?? onRequestIndex?.call(source);
    if (index == null) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Failed to determine layout index.",
        details: {"property": property},
      );
    }
    return index;
  }
}

/// Like [Union], but variant layouts are resolved lazily via [LazyVariantModel].
class LazyUnion extends Layout<Map<String, dynamic>> {
  final Layout discriminator;
  final Map<int, LazyVariantLayout> _registry = {};
  LazyVariantLayout? _defaultLayout;

  LazyUnion._({
    required this.discriminator,
    required int span,
    required String? property,
  }) : super(span, property: property);

  factory LazyUnion({
    required IntegerLayout discr,
    required List<LazyVariantModel> variants,
    String? property,
  }) {
    return LazyUnion._(
      discriminator: OffsetLayout(PaddingLayout(discr)),
      span: -1,
      property: property,
    ).._addVariant(variants);
  }

  factory LazyUnion.offset({
    required ExternalOffsetLayout discr,
    required List<LazyVariantModel> variants,
    String? property,
  }) {
    return LazyUnion._(discriminator: discr, span: -1, property: property)
      .._addVariant(variants);
  }

  @override
  int getSpan() {
    return span;
  }

  /// Infers which registered variant [source] belongs to.
  LazyVariantLayout? _defaultGetSourceVariant(Map<String, dynamic> source) {
    for (final tag in _registry.keys) {
      final vlo = _registry[tag];
      if (source.containsKey(vlo?.property)) {
        return vlo;
      }
    }
    if (_defaultLayout != null) {
      return _defaultLayout!;
    }
    throw BuError(
      DefaultErrorType.invalidArgument,
      "Failed to determine variant layout.",
      details: {
        "property": property,
        "discriminator": discriminator.property,
        "sources": source.keys.map((e) => e.toString()).join(", "),
      },
    );
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final discr = discriminator.decode(bytes, offset: offset);
    final clo = _registry[discr.value] ?? _defaultLayout;
    if (clo == null) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Failed to determine variant layout.",
        details: {
          "property": property,
          "layout": discr.value.toString(),
          "layouts": _registry.keys.join(", "),
        },
      );
    }
    int consumed = discr.consumed;
    final decode = clo.decode(bytes, offset: offset);
    consumed += decode.consumed;
    final callBack = clo.layout.onNormalizeDecodeResult;
    Map<String, dynamic> result = decode.value;
    if (callBack != null) {
      result = callBack(result, discr.value);
    }
    return LayoutDecodeResult(consumed: consumed, value: result);
  }

  @override
  int encode(
    Map<String, dynamic> source,
    LayoutByteWriter writer, {
    int offset = 0,
  }) {
    final vlo = _defaultGetSourceVariant(source);
    if (vlo == null) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Failed to determine variant layout.",
        details: {"property": property, "source": source.toString()},
      );
    }

    return vlo.encode(source, writer, offset: offset);
  }

  void _addVariant(List<LazyVariantModel> variants) {
    final dup = variants.map((e) => e.index).toSet();
    if (dup.length != variants.length) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "Duplicate variant layout detected.",
      );
    }
    final defaultVariant = variants.firstWhereNullable((e) => e.index == null);
    if (defaultVariant != null) {
      _defaultLayout = LazyVariantLayout(union: this, layout: defaultVariant);
    }
    for (final i in variants) {
      final index = i.index;
      if (index == null) continue;
      _registry[index] = LazyVariantLayout(union: this, layout: i);
    }
  }

  /// Looks up the variant layout for the discriminator at [offset].
  LazyVariantLayout? getVariant(
    LayoutByteReader variantBytes, {
    int offset = 0,
  }) {
    final int variant =
        discriminator.decode(variantBytes, offset: offset).value;

    return _registry[variant] ?? _defaultLayout;
  }

  @override
  LazyUnion clone({String? newProperty}) {
    return LazyUnion._(
        discriminator: discriminator,
        property: newProperty,
        span: span,
      )
      .._registry.addAll(_registry.clone())
      .._defaultLayout = _defaultLayout;
  }
}

/// A single variant within a containing [LazyUnion].
class LazyVariantLayout extends Layout<Map<String, dynamic>> {
  final LazyUnion union;
  final LazyVariantModel layout;

  const LazyVariantLayout._({
    required this.union,
    required this.layout,
    required int span,
    String? property,
  }) : super(span, property: property);

  factory LazyVariantLayout({
    required LazyUnion union,
    required LazyVariantModel layout,
  }) {
    return LazyVariantLayout._(
      union: union,
      span: union.span,
      layout: layout,
      property: layout.property,
    );
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    int contentOffset = union.discriminator.span;
    if (contentOffset.isNegative) {
      contentOffset =
          union.discriminator.decode(bytes, offset: offset).consumed;
    }
    assert(contentOffset >= 0, "span cannot be negative.");

    final Map<String, dynamic> dest = {};
    int consumed = 0;
    final result = layout
        .layout(property: layout.property)
        .decode(bytes, offset: offset + contentOffset);
    dest[property!] = result.value;
    consumed += result.consumed;

    return LayoutDecodeResult(consumed: consumed, value: dest);
  }

  @override
  int encode(
    Map<String, dynamic> source,
    LayoutByteWriter writer, {
    int offset = 0,
  }) {
    final index = this.layout.getIndex(source);
    int contentOffset = union.discriminator.encode(
      index,
      writer,
      offset: offset,
    );
    assert(contentOffset >= 0, "span cannot be negative.");
    if (!source.containsKey(property)) {
      throw BuError(
        DefaultErrorType.invalidArgument,
        "variant data missing.",
        details: {"property": property},
      );
    }
    int span = contentOffset;

    final layout = this.layout.layout(property: this.layout.property);
    final encode = layout.encode(
      source[property],
      writer,
      offset: offset + contentOffset,
    );
    span += encode;

    return span;
  }

  @override
  LazyVariantLayout clone({String? newProperty}) {
    return LazyVariantLayout._(
      union: union,
      layout: layout,
      property: newProperty,
      span: span,
    );
  }
}
