import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// - [fields] : Initializer for [fields]. An error is raised if this contains a variable-length field for which a [property] is not defined.
/// - [property] (optional): Initializer for [property].
/// - [decodePrefixes] (optional): Initializer for [decodePrefixes].
///
/// Throws [LayoutException] if [fields] contains an unnamed variable-length layout.
///
class LazyStructLayout extends Layout<Map<String, dynamic>> {
  final List<LazyLayout> fields;
  final bool decodePrefixes;
  factory LazyStructLayout(List<LazyLayout> fields,
      {String? property, bool decodePrefixes = false}) {
    for (final field in fields) {
      if (field.property == null) {
        throw LayoutException("fields cannot contain unnamed layout", details: {
          "property": property,
          "fields":
              fields.map((e) => "${e.runtimeType}: ${e.property}").join(", ")
        });
      }
    }
    return LazyStructLayout._(
        fields: fields,
        span: -1,
        decodePrefixes: decodePrefixes,
        property: property);
  }

  LazyStructLayout._({
    required List<LazyLayout> fields,
    required int span,
    required this.decodePrefixes,
    String? property,
  })  : fields = List<LazyLayout>.unmodifiable(fields),
        super(span, property: property);

  @override
  LazyStructLayout clone({String? newProperty}) {
    return LazyStructLayout._(
        span: span,
        fields: fields,
        property: newProperty,
        decodePrefixes: decodePrefixes);
  }

  @override
  int getSpan(LayoutByteReader? bytes, {int offset = 0}) {
    if (this.span >= 0) {
      return this.span;
    }

    int span = 0;

    try {
      span = fields.fold(0, (span, field) {
        final layout = field.layout(property: field.property);
        final fsp = layout.getSpan(bytes, offset: offset);
        offset += fsp;

        return span + fsp;
      });
    } catch (_, s) {
      throw LayoutException("indeterminate span",
          details: {"property": property, "stack": s});
    }

    return span;
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    final Map<String, dynamic> result = {};
    int consumed = 0;
    for (final field in fields) {
      final layout = field.layout(property: field.property);
      if (field.property != null) {
        final decode = layout.decode(bytes, offset: offset);
        consumed += decode.consumed;
        result[field.property!] = decode.value;
      }
      offset += layout.getSpan(bytes, offset: offset);
      if (decodePrefixes && bytes.length == offset) {
        break;
      }
    }

    return LayoutDecodeResult(consumed: consumed, value: result);
  }

  @override
  int encode(Map<String, dynamic> source, LayoutByteWriter writer,
      {int offset = 0}) {
    final firstOffset = offset;
    int lastOffset = 0;
    int lastWrote = 0;

    for (final field in fields) {
      final layout = field.layout(property: field.property);
      int span = layout.span;
      lastWrote = (span > 0) ? span : 0;
      if (source.containsKey(field.property)) {
        final value = source[field.property];
        lastWrote = layout.encode(value, writer, offset: offset);
        if (span < 0) {
          span = layout.getSpan(writer.reader, offset: offset);
        }
      } else {
        if (span < 0 || field is! PaddingLayout) {
          throw LayoutException("Struct Source not found.", details: {
            "key": field.property,
            "source": source,
            "property": property
          });
        }
      }
      lastOffset = offset;
      offset += span;
    }

    return (lastOffset + lastWrote) - firstOffset;
  }
}
