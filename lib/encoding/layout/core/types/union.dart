import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/encoding/layout/core/types/numeric.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A tagged union: [discriminator] selects which registered [VariantLayout]
/// decodes/encodes the rest of the data.
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
        throw CoreErrors.invalidOperationArguments(
          "Union",
          name: "discr",
          reason: "discriminator must be an unsigned integer layout",
        );
      }
      discriminator = OffsetLayout(PaddingLayout(discr));
    } else if (discr is ExternalLayout) {
      discriminator = discr;
    } else {
      throw CoreErrors.invalidOperationArguments(
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

  /// Infers which registered variant [source] belongs to.
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
    throw BuError(DefaultErrorType.badLayout,
      "Unable to infer source variant",
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
      throw BuError(DefaultErrorType.invalidArgument,
        "Unknown union variant.",
        details: {
          "property": property,
          "variant": discr.value.toString(),
          "variants": _registry.keys.join(", "),
        },
      );
    }
    final decode = clo.decode(bytes, offset: offset);
    result = decode.value;
    consumed += decode.consumed;

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

  /// Registers a [layout] to decode/encode when the discriminator is [variant].
  VariantLayout addVariant({
    required int variant,
    required Layout layout,
    String? property,
  }) {
    final resolved = property ?? layout.property;
    if (resolved == null) {
      throw CoreErrors.invalidOperationArguments(
        "Union",
        name: "property",
        reason: "Variant layout must have a property.",
      );
    }
    final rv = VariantLayout(
      union: this,
      variant: variant,
      layout: layout,
      property: resolved,
    );
    _registry[variant] = rv;
    return rv;
  }

  @override
  Union clone({String? newProperty}) {
    final layout = Union(discriminator, property: newProperty);
    layout._registry.addAll(Map.from(_registry));
    return layout;
  }
}

/// A single variant within a containing [union], tagged by [variant].
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
    if (!source.containsKey(property)) {
      throw BuError(DefaultErrorType.invalidArgument,
        "variant data missing.",
        details: {"property": property},
      );
    }

    int contentOffset = union.discriminator.span;
    if (contentOffset.isNegative) {
      contentOffset = union.discriminator.encode(
        variant,
        writer,
        offset: offset,
      );
    } else {
      union.discriminator.encode(variant, writer, offset: offset);
    }

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

/// One tag/layout pair in a [TaggedUnionLayout].
class UnionCase<T> {
  final int tag;
  final Layout<dynamic> layout;
  const UnionCase(this.tag, this.layout);
}

/// A tagged union of [cases], where [tagLayout] reads/writes the tag and
/// [tagFor] picks the case to encode a given [T] value with.
class TaggedUnionLayout<T> extends Layout<T> {
  final Layout<int> tagLayout;
  final List<UnionCase<T>> cases;
  final int Function(T value) tagFor;

  const TaggedUnionLayout({
    required this.tagLayout,
    required this.cases,
    required this.tagFor,
    super.property,
  }) : super(-1);

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    final tagRes = tagLayout.decode(bytes, offset: offset);
    final match = cases.firstWhere(
      (c) => c.tag == tagRes.value,
      orElse:
          () =>
              throw BuError(DefaultErrorType.invalidArgument,
                'Unknown union tag',
                details: {'tag': tagRes.value.toString(), 'property': property},
              ),
    );
    final bodyRes = match.layout.decode(
      bytes,
      offset: offset + tagRes.consumed,
    );
    return LayoutDecodeResult(
      consumed: tagRes.consumed + bodyRes.consumed,
      value: bodyRes.value as T,
    );
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    final tag = tagFor(source);
    final match = cases.firstWhere(
      (c) => c.tag == tag,
      orElse:
          () =>
              throw BuError(DefaultErrorType.invalidArgument,
                'Unknown union tag for encode',
                details: {'tag': tag.toString(), 'property': property},
              ),
    );
    int span = tagLayout.encode(tag, writer, offset: offset);
    span += match.layout.encode(source, writer, offset: offset + span);
    return span;
  }

  @override
  TaggedUnionLayout<T> clone({String? newProperty}) => TaggedUnionLayout(
    tagLayout: tagLayout,
    cases: cases,
    tagFor: tagFor,
    property: newProperty,
  );
}
