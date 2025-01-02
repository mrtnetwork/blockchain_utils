import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

class LazyVariantModel<T> {
  final LayoutFunc<T> layout;
  final String? property;
  final int index;
  const LazyVariantModel(
      {required this.layout, required this.property, required this.index});
}

class LazyUnion extends Layout<Map<String, dynamic>> {
  final UnionLayoutDiscriminatorLayout discriminator;
  final Map<int, LazyVariantLayout> _registry = {};
  LazyUnion._(
      {required this.discriminator,
      required int span,
      required String? property})
      : super(span, property: property);
  factory LazyUnion(IntegerLayout discr, {String? property}) {
    return LazyUnion._(
        discriminator:
            UnionLayoutDiscriminatorLayout(OffsetLayout(PaddingLayout(discr))),
        span: -1,
        property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes,
      {int offset = 0, Map<String, dynamic>? source}) {
    if (span >= 0) {
      return span;
    }

    final vlo = getVariant(bytes!, offset: offset);
    if (vlo == null) {
      throw LayoutException("unable to determine span for unrecognized variant",
          details: {"property": property});
    }

    return vlo.getSpan(bytes, offset: offset, source: source);
  }

  LazyVariantLayout? defaultGetSourceVariant(Map<String, dynamic> source) {
    if (source.containsKey(discriminator.property)) {
      final vlo = _registry[source[discriminator.property]];
      if (vlo != null && (source.containsKey(vlo.property))) {
        return vlo;
      }
    } else {
      for (final tag in _registry.keys) {
        final vlo = _registry[tag];
        if (source.containsKey(vlo?.property)) {
          return vlo;
        }
      }
    }
    throw LayoutException("unable to infer source variant", details: {
      "property": property,
      "discriminator": discriminator.property,
      "sources": source.keys.map((e) => e.toString()).join(", ")
    });
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    final discr = discriminator.decode(bytes, offset: offset);
    final clo = _registry[discr.value];
    if (clo == null) {
      throw LayoutException("unable to determine layout.",
          details: {"property": property, "layout": discr.value});
    }
    Map<String, dynamic> result = {};
    int consumed = discr.consumed;
    final decode = clo.decode(bytes, offset: offset);
    result = decode.value;
    consumed += decode.consumed;
    return LayoutDecodeResult(consumed: consumed, value: result);
  }

  @override
  int encode(Map<String, dynamic> source, LayoutByteWriter writer,
      {int offset = 0}) {
    final vlo = defaultGetSourceVariant(source);
    if (vlo == null) {
      throw LayoutException("unable to determine source layout.",
          details: {"property": property, "source": source});
    }

    return vlo.encode(source, writer, offset: offset);
  }

  LazyVariantLayout addVariant(LazyVariantModel layout) {
    final rv = LazyVariantLayout(union: this, layout: layout);
    _registry[layout.index] = rv;
    return rv;
  }

  LazyVariantLayout? getVariant(LayoutByteReader variantBytes,
      {int offset = 0}) {
    final int variant =
        discriminator.decode(variantBytes, offset: offset).value;
    return _registry[variant];
  }

  @override
  LazyUnion clone({String? newProperty}) {
    final layout = LazyUnion._(
        discriminator: discriminator, property: newProperty, span: span);
    layout._registry.addAll(Map.from(_registry));
    return layout;
  }
}

class LazyVariantLayout extends Layout<Map<String, dynamic>> {
  final LazyUnion union;
  final LazyVariantModel layout;
  const LazyVariantLayout._(
      {required this.union,
      required this.layout,
      required int span,
      String? property})
      : super(span, property: property);

  factory LazyVariantLayout(
      {required LazyUnion union, required LazyVariantModel layout}) {
    return LazyVariantLayout._(
        union: union,
        span: union.span,
        layout: layout,
        property: layout.property);
  }

  @override
  int getSpan(LayoutByteReader? bytes,
      {int offset = 0, Map<String, dynamic>? source}) {
    if (!this.span.isNegative) {
      return this.span;
    }
    final int contentOffset = union.discriminator.layout.span;

    int span = 0;
    span = layout.layout(property: layout.property).getSpan(bytes,
        offset: offset + contentOffset, source: source?[property]);
    assert(span >= 0, "span cannot be negative.");
    return contentOffset + span;
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    if (this != union.getVariant(bytes, offset: offset)) {
      throw LayoutException("variant mismatch",
          details: {"property": property});
    }

    final int contentOffset = union.discriminator.layout.span;

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
  int encode(Map<String, dynamic> source, LayoutByteWriter writer,
      {int offset = 0}) {
    final int contentOffset = union.discriminator.layout.span;
    if (!source.containsKey(property)) {
      throw LayoutException("variant lacks property",
          details: {"property": property});
    }
    union.discriminator.encode(this.layout.index, writer, offset: offset);
    int span = contentOffset;

    final layout = this.layout.layout(property: this.layout.property);
    layout.encode(source[property], writer, offset: offset + contentOffset);
    final lSpan = layout.getSpan(writer.reader,
        offset: offset + contentOffset, source: source[property]);
    assert(lSpan >= 0, "span cannot be negative.");
    span += lSpan;

    if (union.span >= 0 && span > union.span) {
      throw LayoutException("encoded variant overruns containing union",
          details: {"property": property});
    }

    return span;
  }

  @override
  LazyVariantLayout clone({String? newProperty}) {
    return LazyVariantLayout._(
        union: union, layout: layout, property: newProperty, span: span);
  }
}
