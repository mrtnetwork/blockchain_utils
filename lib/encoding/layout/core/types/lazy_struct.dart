import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/core/types/padding_layout.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Like [StructLayout], but each field's layout is resolved lazily via
/// [LazyStructLayoutBuilder], so later fields can depend on earlier results.
class LazyStructLayout<R extends LayoutRepository>
    extends Layout<Map<String, dynamic>> {
  final List<LazyStructLayoutBuilder<Object?, R>> fields;
  final bool decodePrefixes;
  final R? repository;

  factory LazyStructLayout(
    List<LazyStructLayoutBuilder<Object?, R>> fields, {
    R? repository,
    String? property,
    bool decodePrefixes = false,
  }) {
    for (final field in fields) {
      if (field.property == null) {
        throw CoreErrors.invalidOperationArguments(
          "LazyStructLayout",
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
    required List<LazyStructLayoutBuilder<Object?, R>> fields,
    required this.decodePrefixes,
    this.repository,
    super.property,
  }) : fields = fields.immutable,
       super(-1);

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
      if (layout == null) {
        throw BuError(
          DefaultErrorType.invalidArgument,
          "Missing ${field.property} layout.",
        );
      }
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
    int lastOffset = firstOffset;
    int lastWrote = 0;
    for (final field in fields) {
      final layout = field.layout(
        action: LayoutAction.encode,
        sourceOrResult: source,
        remainBytes: 0,
        repository: repository,
        value: source[field.property],
      );
      if (layout == null) continue;
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
        if (span < 0 || layout is! PaddingLayout) {
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
    final encodeLen = (lastOffset + lastWrote) - firstOffset;
    return encodeLen;
  }
}
