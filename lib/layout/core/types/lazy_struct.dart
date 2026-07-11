import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/layout/byte/byte_handler.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';

class LazyStructLayout<R extends LayoutRepository>
    extends Layout<Map<String, dynamic>> {
  final List<BaseLazyStructLayoutBuilder<Object?, R>> fields;
  final bool decodePrefixes;
  final R? repository;
  factory LazyStructLayout(
    List<BaseLazyStructLayoutBuilder<Object?, R>> fields, {
    R? repository,
    String? property,
    bool decodePrefixes = false,
  }) {
    for (final field in fields) {
      if (field.property == null) {
        throw ArgumentException.invalidOperationArguments(
          "SequenceLayout",
          name: "fields",
          reason: 'Fields cannot contain unnamed layout.',
        );
      }
    }
    return LazyStructLayout._(
      fields: fields,
      decodePrefixes: decodePrefixes,
      property: property,
      repository: repository,
    );
  }

  LazyStructLayout._({
    required List<BaseLazyStructLayoutBuilder<Object?, R>> fields,
    required this.decodePrefixes,
    this.repository,
    String? property,
  }) : fields = fields.immutable,
       super(-1, property: property);

  @override
  LazyStructLayout<R> clone({String? newProperty}) {
    return LazyStructLayout._(
      fields: fields,
      property: newProperty,
      decodePrefixes: decodePrefixes,
      repository: repository,
    );
  }

  @override
  LayoutDecodeResult<Map<String, dynamic>> decode(
    LayoutByteReader bytes, {
    int offset = 0,
  }) {
    final Map<String, dynamic> result = {};
    int remindBytes = bytes.length - offset;
    int consumed = 0;
    for (final field in fields) {
      final layout = field.layout(
        action: LayoutAction.decode,
        sourceOrResult: result,
        remainBytes: remindBytes,
        repository: repository,
      );
      final decode = layout.decode(bytes, offset: offset);
      consumed += decode.consumed;
      remindBytes -= decode.consumed;
      result[field.property!] = field.onFinalizeDecode(
        decode.value,
        result,
        repository,
      );
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
    int lastOffset = 0;
    int lastWrote = 0;
    for (final field in fields) {
      final layout = field.layout(
        action: LayoutAction.encode,
        sourceOrResult: source,
        remainBytes: 0,
        repository: repository,
      );
      int span = layout.span;
      lastWrote = (span > 0) ? span : 0;
      if (source.containsKey(field.property)) {
        final value = source[field.property];
        lastWrote = layout.encode(value, writer, offset: offset);
        if (span < 0) {
          span = lastWrote;
        }
        field.onFinalizeEncode(value, source, repository);
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
    final encodeLen = (lastOffset + lastWrote) - firstOffset;
    return encodeLen;
  }
}
