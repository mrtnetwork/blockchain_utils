import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'numeric.dart';

/// Represent any number of span-compatible layouts.
///
class Union extends Layout<Map<String, dynamic>> {
  final Layout discriminator;
  final Map<int, VariantLayout> _registry = {};
  Union._({
    required this.discriminator,
    required int span,
    required String? property,
  }) : super(span, property: property);
  factory Union(Layout discr, {String? property}) {
    final Layout discriminator;
    if (discr is IntegerLayout) {
      if (discr.sign) {
        throw ArgumentException.invalidOperationArguments(
          "Union",
          name: "discr",
          reason: "discriminator must be an unsigned integer layout",
        );
      }
      discriminator = OffsetLayout(PaddingLayout(discr));
    } else if (discr is ExternalLayout) {
      discriminator = discr;
    } else {
      throw ArgumentException.invalidOperationArguments(
        "Union",
        name: "discr",
        reason: "Invalid discriminator layout.",
      );
    }
    return Union._(discriminator: discriminator, span: -1, property: property);
  }

  @override
  int getSpan() {
    return span;
  }

  VariantLayout _defaultGetSourceVariant(Map<String, dynamic> source) {
    if (source.containsKey(discriminator.property)) {
      final vlo = _registry[source[discriminator.property]];
      if (vlo != null && (source.containsKey(vlo.property))) {
        return vlo;
      }
    } else {
      for (final tag in _registry.keys) {
        final vlo = _registry[tag];
        if (source.containsKey(vlo?.property)) {
          return vlo!;
        }
      }
    }
    throw LayoutException(
      "unable to infer source variant",
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
    final clo = _registry[discr.value];
    Map<String, dynamic> result = {};
    int consumed = discr.consumed;
    if (clo == null) {
      result[discriminator.property!] = discr.value;
    } else {
      final decode = clo.decode(bytes, offset: offset);
      result = decode.value;
      consumed += decode.consumed;
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
    return vlo.encode(source, writer, offset: offset);
  }

  VariantLayout addVariant({
    required int variant,
    required Layout layout,
    String? property,
  }) {
    final rv = VariantLayout(
      union: this,
      variant: variant,
      layout: layout,
      property: property,
    );
    _registry[variant] = rv;
    return rv;
  }

  @override
  Union clone({String? newProperty}) {
    final layout = Union(discriminator, property: newProperty);
    layout._registry.addAll(Map.from(_registry));
    return Union(discriminator, property: newProperty);
  }
}

/// Represent a specific variant within a containing union.
class VariantLayout extends Layout<Map<String, dynamic>> {
  final Union union;
  final int variant;
  final Layout layout;
  const VariantLayout._({
    required this.union,
    required this.variant,
    required this.layout,
    required int span,
    String? property,
  }) : super(span, property: property);

  factory VariantLayout({
    required Union union,
    required int variant,
    required Layout layout,
    String? property,
  }) {
    return VariantLayout._(
      union: union,
      variant: variant,
      span: union.span,
      layout: layout,
      property: property,
    );
  }

  @override
  int getSpan() {
    return span;
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    int contentOffset =
        union.discriminator.decode(bytes, offset: offset).consumed;
    assert(contentOffset >= 0, "span cannot be negative.");

    final Map<String, dynamic> dest = {};
    int consumed = 0;
    final result = layout.decode(bytes, offset: offset + contentOffset);
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
    int contentOffset = union.discriminator.span;
    if (contentOffset.isNegative) {
      contentOffset = union.discriminator.encode(
        variant,
        writer,
        offset: offset,
      );
    }

    if (!source.containsKey(property)) {
      throw LayoutException(
        "variant data missing.",
        details: {"property": property},
      );
    }

    union.discriminator.encode(variant, writer, offset: offset);
    int span = contentOffset;

    final encode = layout.encode(
      source[property],
      writer,
      offset: offset + contentOffset,
    );
    span += encode;

    return span;
  }

  @override
  VariantLayout clone({String? newProperty}) {
    return VariantLayout._(
      union: union,
      variant: variant,
      layout: layout,
      property: newProperty,
      span: span,
    );
  }
}
