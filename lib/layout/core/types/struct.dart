import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// Represent a contiguous sequence of arbitrary layout elements as an Object.
///
/// **NOTE** The [span] of the structure is variable if any layout in [fields] has a variable span.
///  When [encode] we must have a value for all variable-length fields, or we wouldn't be able to
///  figure out how much space to use for storage. We can only identify the value for a field when it has a [property].
///
///  As such, although a structure may contain both unnamed fields and variable-length fields,
///  it cannot contain an unnamed variable-length field.
///
/// - [fields] : Initializer for [fields]. An error is raised if this contains a variable-length field for which a [property] is not defined.
/// - [property] (optional): Initializer for [property].
/// - [decodePrefixes] (optional): Initializer for [decodePrefixes].
///
/// Throws [MessageException] if [fields] contains an unnamed variable-length layout.
///
class StructLayout extends Layout<Map<String, dynamic>> {
  final List<Layout> fields;
  final bool decodePrefixes;
  factory StructLayout(List<Layout> fields,
      {String? property, bool decodePrefixes = false}) {
    for (var fd in fields) {
      if (fd.property == null) {
        throw LayoutException("fields cannot contain unnamed layout", details: {
          "property": property,
          "fields":
              fields.map((e) => "${e.runtimeType}: ${e.property}").join(", ")
        });
      }
    }
    int span = 0;

    try {
      span = fields.fold<int>(0, (span, fd) {
        return span + fd.getSpan(null);
      });
    } catch (e) {
      span = -1;
    }
    return StructLayout._(
        fields: fields,
        span: span,
        decodePrefixes: decodePrefixes,
        property: property);
  }

  StructLayout._({
    required List<Layout> fields,
    required int span,
    required this.decodePrefixes,
    String? property,
  })  : fields = List<Layout>.unmodifiable(fields),
        super(span, property: property);

  @override
  StructLayout clone({String? newProperty}) {
    return StructLayout._(
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
      span = fields.fold(0, (span, fd) {
        final fsp = fd.getSpan(bytes, offset: offset);
        offset += fsp;

        return span + fsp;
      });
    } catch (e, s) {
      throw LayoutException("indeterminate span",
          details: {"property": property}, trace: s);
    }

    return span;
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(LayoutByteReader bytes,
      {int offset = 0}) {
    final Map<String, dynamic> result = {};
    int consumed = 0;
    for (var fd in fields) {
      if (fd.property != null) {
        final decode = fd.decode(bytes, offset: offset);
        consumed += decode.consumed;
        result[fd.property!] = decode.value;
      }
      offset += fd.getSpan(bytes, offset: offset);
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
      int span = field.span;
      lastWrote = (span > 0) ? span : 0;
      if (source.containsKey(field.property)) {
        final value = source[field.property];
        lastWrote = field.encode(value, writer, offset: offset);
        if (span < 0) {
          span = field.getSpan(writer.reader, offset: offset);
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
