import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

/// Represent a contiguous sequence of arbitrary layout elements as an Object.
class StructLayout extends Layout<Map<String, dynamic>> {
  final List<Layout> fields;
  final bool decodePrefixes;
  factory StructLayout(
    List<Layout> fields, {
    String? property,
    bool decodePrefixes = false,
  }) {
    for (final fd in fields) {
      if (fd.property == null) {
        throw ArgumentException.invalidOperationArguments(
          "StructLayout",
          name: "fields",
          reason: "fields cannot contain unnamed layout",
        );
      }
    }
    int span = 0;
    for (final i in fields) {
      final s = i.getSpan();
      if (s.isNegative) {
        span = -1;
        break;
      }
      span += s;
    }
    return StructLayout._(
      fields: fields,
      span: span,
      decodePrefixes: decodePrefixes,
      property: property,
    );
  }

  StructLayout._({
    required List<Layout> fields,
    required int span,
    required this.decodePrefixes,
    String? property,
  }) : fields = List<Layout>.unmodifiable(fields),
       super(span, property: property);

  @override
  StructLayout clone({String? newProperty}) {
    return StructLayout._(
      span: span,
      fields: fields,
      property: newProperty,
      decodePrefixes: decodePrefixes,
    );
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final Map<String, dynamic> result = {};
    int consumed = 0;
    for (final fd in fields) {
      final decode = fd.decode(bytes, offset: offset);
      consumed += decode.consumed;
      result[fd.property!] = decode.value;
      offset += decode.consumed;
    }

    return LayoutDecodeResult(consumed: consumed, value: result);
  }

  @override
  int encode(
    Map<String, dynamic> source,
    LayoutByteWriter writer, {
    int offset = 0,
  }) {
    final firstOffset = offset;
    int lastOffset = firstOffset;
    int lastWrote = 0;

    for (final field in fields) {
      int span = field.span;
      if (source.containsKey(field.property)) {
        final value = source[field.property];
        lastWrote = field.encode(value, writer, offset: offset);
        if (span < 0) {
          span = lastWrote;
        }
      } else {
        if (span < 0 || field is! PaddingLayout) {
          throw LayoutException(
            "Struct Source not found.",
            details: {
              "key": field.property,
              "source": source.toString(),
              "property": property,
            },
          );
        }
      }
      lastOffset = offset;
      offset += span;
    }

    return (lastOffset + lastWrote) - firstOffset;
  }
}
