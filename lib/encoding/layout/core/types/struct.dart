import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A contiguous sequence of named [fields], decoded/encoded into a
/// `Map<String, dynamic>` in declaration order.
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
        throw CoreErrors.invalidOperationArguments(
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
          throw BuError(
            DefaultErrorType.notFound,
            "Struct source not found.",
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

/// Sequence of fields concatenated in order, mapped to/from a domain type
/// [R] via [build]/[unbuild] instead of a `Map` — the natural shape for a
/// generated encoding of an annotated class.
class ObjSeqLayout<R> extends Layout<R> {
  final List<Layout<dynamic>> fields;
  final R Function(List<dynamic> values) build;
  final List<dynamic> Function(R value) unbuild;

  ObjSeqLayout(
    this.fields, {
    required this.build,
    required this.unbuild,
    super.property,
  }) : super(_span(fields));

  static int _span(List<Layout<dynamic>> fields) =>
      fields.any((f) => f.span < 0) ? -1 : fields.fold(0, (p, f) => p + f.span);

  @override
  LayoutDecodeResult<R> decode(LayoutByteReader bytes, {int offset = 0}) {
    final values = <dynamic>[];
    int consumed = 0;
    for (final f in fields) {
      final r = f.decode(bytes, offset: offset + consumed);
      values.add(r.value);
      consumed += r.consumed;
    }
    return LayoutDecodeResult(consumed: consumed, value: build(values));
  }

  @override
  int encode(R source, LayoutByteWriter writer, {int offset = 0}) {
    final values = unbuild(source);
    int span = 0;
    for (int i = 0; i < fields.length; i++) {
      span += fields[i].encode(values[i], writer, offset: offset + span);
    }
    return span;
  }

  @override
  ObjSeqLayout<R> clone({String? newProperty}) => ObjSeqLayout(
    fields,
    build: build,
    unbuild: unbuild,
    property: newProperty,
  );
}
