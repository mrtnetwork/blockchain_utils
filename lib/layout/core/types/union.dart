import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// Represent any number of span-compatible layouts.
///
/// If the union has a [defaultLayout] that layout must have a non-negative [span].
/// The span of a fixed-span union includes its [discriminator] if the variant is a prefix
/// of the union, plus the span of its [defaultLayout].
///
/// If the union does not have a default layout then the encoded span of the union depends on
/// the encoded span of its variant (which may be fixed or variable).
///
/// [Variant layout]s are added through [addVariant].
/// If the union has a default layout, the span of the [layout contained by the variant]
/// must not exceed the span of the [defaultLayout] (minus the span of a prefix disriminator, if used).
/// The span of the variant will equal the span of the union itself.
///
/// The variant for a buffer can only be identified from the [discriminator] [property]
/// (in the case of the [defaultLayout]), or by using [getVariant] and examining the resulting
/// [VariantLayout] instance.
///
/// - [discriminator] : How to identify the layout used to interpret the union contents.
/// The parameter must be an instance of [UnionDiscriminatorLayout], an [ExternalLayout] that satisfies [isCount()],
/// or unsigned [IntegerLayout]. When a non-external layout element is passed the layout appears at the start
/// of the union. In all cases the (synthesized) [UnionDiscriminatorLayout] instance is recorded as [discriminator].
/// - [defaultLayout] (optional): Initializer for [defaultLayout]. If absent defaults to `null`. If `null` there
///   is no default layout: the union has data-dependent length and attempts to decode or encode
///   unrecognized variants will throw an exception. A [Layout] instance must have a non-negative [span],
///   and if it lacks a [property] the [defaultLayout] will be a [clone] with property `content`.
/// - [property] (optional): Initializer for [property].
///
class Union extends Layout<Map<String, dynamic>> {
  final UnionLayoutDiscriminatorLayout discriminator;
  final bool usesPrefixDiscriminator;
  final Layout? defaultLayout;
  final Map<int, VariantLayout> _registry = {};
  Union._(
      {required this.discriminator,
      required this.usesPrefixDiscriminator,
      required this.defaultLayout,
      required int span,
      required String? property})
      : super(span, property: property);
  factory Union(Layout discr, {Layout? defaultLayout, String? property}) {
    if (discr is! UnionDiscriminatorLayout &&
        discr is! ExternalLayout &&
        discr is! IntegerLayout) {
      throw LayoutException(
          "discr must be a UnionDiscriminatorLayout or an unsigned integer layout",
          details: {"property": property});
    }
    if (discr is IntegerLayout && discr.sign) {
      throw LayoutException("discr must be an unsigned integer layout",
          details: {"property": property});
    }
    final usesPrefixDiscriminator = (discr is IntegerLayout);
    int span = -1;
    if (defaultLayout != null) {
      if (defaultLayout.span < 0) {
        throw LayoutException("defaultLayout must have constant span.",
            details: {"property": property});
      }
      if (defaultLayout.property == null) {
        defaultLayout = defaultLayout.clone(newProperty: 'content');
      }
      span = defaultLayout.span;
      if (span >= 0 && (discr is IntegerLayout)) {
        span += (discr).span;
      }
    }
    final UnionLayoutDiscriminatorLayout discriminator;
    if (discr is IntegerLayout) {
      discriminator =
          UnionLayoutDiscriminatorLayout(OffsetLayout(PaddingLayout(discr)));
    } else if ((discr is ExternalLayout) && discr.isCount()) {
      discriminator = UnionLayoutDiscriminatorLayout(discr);
    } else if (discr is! UnionDiscriminatorLayout) {
      throw LayoutException(
          "discr must be a UnionDiscriminatorLayout or an unsigned integer layout",
          details: {"property": property});
    } else {
      discriminator = discr as UnionLayoutDiscriminatorLayout;
    }
    return Union._(
        discriminator: discriminator,
        usesPrefixDiscriminator: usesPrefixDiscriminator,
        defaultLayout: defaultLayout,
        span: span,
        property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    if (span >= 0) {
      return span;
    }

    final vlo = getVariant(bytes!, offset: offset);
    if (vlo == null) {
      throw LayoutException("unable to determine span for unrecognized variant",
          details: {"property": property});
    }

    return vlo.getSpan(bytes, offset: offset);
  }

  VariantLayout? defaultGetSourceVariant(Map<String, dynamic> source) {
    if (source.containsKey(discriminator.property)) {
      if (source.containsKey(defaultLayout?.property)) {
        return null;
      }
      final vlo = _registry[source[discriminator.property]];
      if (vlo != null &&
          (vlo.layout == null || source.containsKey(vlo.property))) {
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
    Map<String, dynamic> result = {};
    int consumed = discr.consumed;
    if (clo == null) {
      final defaultLayout = this.defaultLayout;
      int contentOffset = 0;

      if (usesPrefixDiscriminator) {
        contentOffset = discriminator.layout.span;
      }

      result[discriminator.property!] = discr.value;

      if (defaultLayout != null) {
        final decode =
            defaultLayout.decode(bytes, offset: offset + contentOffset);
        consumed += decode.consumed;
        result[defaultLayout.property!] = decode;
      }
    } else {
      final decode = clo.decode(bytes, offset: offset);
      result = decode.value;
      consumed += decode.consumed;
    }

    return LayoutDecodeResult(consumed: consumed, value: result);
  }

  @override
  int encode(Map<String, dynamic> source, LayoutByteWriter writer,
      {int offset = 0}) {
    final vlo = defaultGetSourceVariant(source);

    if (vlo == null) {
      int contentOffset = 0;
      if (usesPrefixDiscriminator) {
        contentOffset = discriminator.layout.span;
      }
      discriminator.encode(source[discriminator.property], writer,
          offset: offset);
      return contentOffset +
          defaultLayout!.encode(source[defaultLayout!.property], writer,
              offset: offset + contentOffset);
    }

    return vlo.encode(source, writer, offset: offset);
  }

  VariantLayout addVariant(
      {required int variant, Layout? layout, String? property}) {
    final rv = VariantLayout(
        union: this, variant: variant, layout: layout, property: property);
    _registry[variant] = rv;
    return rv;
  }

  VariantLayout? getVariant(LayoutByteReader variantBytes, {int offset = 0}) {
    int variant = discriminator.decode(variantBytes, offset: offset).value;
    return _registry[variant];
  }

  @override
  Union clone({String? newProperty}) {
    final layout = Union(discriminator,
        property: newProperty, defaultLayout: defaultLayout);
    layout._registry.addAll(Map.from(_registry));
    return Union(discriminator,
        property: newProperty, defaultLayout: defaultLayout);
  }
}

/// Represent a specific variant within a containing union.
///
/// **NOTE** The [span] of the variant may include the span of the [Union.discriminator] used to identify it,
/// but values read and written using the variant strictly conform to the content of [layout].
///
/// **NOTE** User code should not invoke this constructor directly. Use the union [Union.addVariant] helper method.
///
/// - [union] : Initializer for [union].
/// - [variant] : Initializer for [variant].
/// - [layout] (optional): Initializer for [layout]. If absent the variant carries no data.
/// - [property] (optional): Initializer for [property]. Unlike many other layouts, variant layouts normally
///   include a property name so they can be identified within their containing [Union].
///   The property identifier may be absent only if `layout` is absent.
///
class VariantLayout extends Layout<Map<String, dynamic>> {
  final Union union;
  final int variant;
  final Layout? layout;
  const VariantLayout._(
      {required this.union,
      required this.variant,
      this.layout,
      required int span,
      String? property})
      : super(span, property: property);

  factory VariantLayout({
    required Union union,
    required int variant,
    Layout? layout,
    String? property,
  }) {
    if (layout != null) {
      if ((union.defaultLayout != null) &&
          (0 <= layout.span) &&
          (layout.span > union.defaultLayout!.span)) {
        throw LayoutException("variant span exceeds span of containing union",
            details: {"property": property});
      }
    }
    int span = union.span;
    if (0 > union.span) {
      span = layout != null ? layout.span : 0;
      if ((0 <= span) && union.usesPrefixDiscriminator) {
        span += union.discriminator.layout.span;
      }
    }
    return VariantLayout._(
        union: union,
        variant: variant,
        span: span,
        layout: layout,
        property: property);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    if (!this.span.isNegative) {
      return this.span;
    }
    int contentOffset = 0;
    if (union.usesPrefixDiscriminator) {
      contentOffset = union.discriminator.layout.span;
    }
    int span = 0;
    if (layout != null) {
      span = layout!.getSpan(bytes, offset: offset + contentOffset);
    }
    return contentOffset + span;
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    if (this != union.getVariant(bytes, offset: offset)) {
      throw LayoutException("variant mismatch",
          details: {"property": property});
    }

    int contentOffset = 0;
    if (union.usesPrefixDiscriminator) {
      contentOffset = union.discriminator.layout.span;
    }
    final Map<String, dynamic> dest = {};
    int consumed = 0;
    if (layout != null) {
      final result = layout!.decode(bytes, offset: offset + contentOffset);
      dest[property!] = result.value;
      consumed += result.consumed;
    } else if (property != null) {
      dest[property!] = true;
    } else if (union.usesPrefixDiscriminator) {
      dest[union.discriminator.property!] = variant;
    }

    return LayoutDecodeResult(consumed: consumed, value: dest);
  }

  @override
  int encode(Map<String, dynamic> source, LayoutByteWriter writer,
      {int offset = 0}) {
    int contentOffset = 0;
    if (union.usesPrefixDiscriminator) {
      contentOffset = union.discriminator.layout.span;
    }

    if (layout != null && !source.containsKey(property)) {
      throw LayoutException("variant lacks property",
          details: {"property": property});
    }

    union.discriminator.encode(variant, writer, offset: offset);
    int span = contentOffset;

    if (layout != null) {
      layout!.encode(source[property], writer, offset: offset + contentOffset);
      span += layout!.getSpan(writer.reader, offset: offset + contentOffset);

      if (union.span >= 0 && span > union.span) {
        throw LayoutException("encoded variant overruns containing union",
            details: {"property": property});
      }
    }

    return span;
  }

  @override
  VariantLayout clone({String? newProperty}) {
    return VariantLayout._(
        union: union,
        variant: variant,
        layout: layout,
        property: newProperty,
        span: span);
  }
}
