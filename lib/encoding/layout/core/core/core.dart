import 'package:blockchain_utils/encoding/layout/buffer/src/reader.dart';
import 'package:blockchain_utils/encoding/layout/buffer/src/writer.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

typedef CbLayoutFunc<T> = Layout<T> Function({String? property});
typedef CbOnFinalizeDecode<T, R extends LayoutRepository> =
    dynamic Function(
      T layoutResult,
      Map<String, dynamic> structResult,
      R? repository,
    );
typedef CbOnFinalizeEncode<T, R extends LayoutRepository> =
    void Function(T source, Map<String, dynamic> structSource, R? repository);

/// Whether a lazy layout builder is being asked to decode or encode.
enum LayoutAction {
  encode,
  decode;

  bool get isEncode => this == encode;
  bool get isDecode => this == decode;
}

/// Context passed to a lazy layout builder when it's asked to resolve its
/// layout. [encodeValue] is only ever set (and required) when encoding.
class RequestLayoutParams<T, SOURCE, R extends LayoutRepository> {
  final LayoutAction action;
  final SOURCE sourceOrResult;
  final int remainBytes;
  final R? repository;
  final T? encodeValue;
  const RequestLayoutParams({
    required this.action,
    required this.sourceOrResult,
    required this.remainBytes,
    required this.repository,
    required this.encodeValue,
  });
}

typedef CbLazyStructLayoutFunc<T, R extends LayoutRepository> =
    Layout<T>? Function(
      String? property,
      RequestLayoutParams<T, Map<String, dynamic>, R> params,
    );
typedef CbMsgPackLayoutFunc<K, V, R extends LayoutRepository> =
    Layout<V>? Function(
      String? property,
      RequestLayoutParams<V, Map<K, V>, R> params,
    );

/// Marker base for the user-supplied context object threaded through lazy
/// layout builders (see [LazyStructLayoutBuilder], [LazyMsgPackMapLayoutBuilder]).
abstract class LayoutRepository {}

/// Shared contract for a field whose layout is resolved lazily.
abstract class BaseLazyStructLayoutBuilder<
  T,
  SOURCE,
  R extends LayoutRepository
> {
  abstract final String? property;
  Layout<T>? layout({
    required LayoutAction action,
    required SOURCE sourceOrResult,
    required int remainBytes,
    R? repository,
    T? value,
  });
}

/// A field of a [LazyStructLayout], with its layout resolved lazily and
/// optional decode/encode finalization hooks.
class LazyStructLayoutBuilder<T, R extends LayoutRepository>
    extends BaseLazyStructLayoutBuilder<T, Map<String, dynamic>, R> {
  final CbLazyStructLayoutFunc<T, R> _layout;
  final CbOnFinalizeDecode<T, R>? finalizeDecode;
  final CbOnFinalizeEncode<T, R>? finalizeEncode;
  @override
  final String? property;
  LazyStructLayoutBuilder({
    required CbLazyStructLayoutFunc<T, R> layout,
    this.finalizeDecode,
    this.finalizeEncode,
    required this.property,
  }) : _layout = layout;

  @override
  Layout<T>? layout({
    required LayoutAction action,
    required Map<String, dynamic> sourceOrResult,
    required int remainBytes,
    R? repository,
    T? value,
  }) {
    return _layout(
      property,
      RequestLayoutParams(
        action: action,
        sourceOrResult: sourceOrResult,
        repository: repository,
        remainBytes: remainBytes,
        encodeValue: value,
      ),
    );
  }

  /// Post-processes a decoded value, if [finalizeDecode] was supplied.
  dynamic onFinalizeDecode(
    T layoutResult,
    Map<String, dynamic> structResult,
    R? repository,
  ) {
    if (finalizeDecode == null) return layoutResult;
    return finalizeDecode!(layoutResult, structResult, repository);
  }

  /// Runs [finalizeEncode] after a value has been encoded, if supplied.
  void onFinalizeEncode(
    T source,
    Map<String, dynamic> structSource,
    R? repository,
  ) {
    finalizeEncode?.call(source, structSource, repository);
  }
}

/// Base contract every layout implements: byte span plus decode/encode.
abstract class Layout<T> {
  final int span;
  final String? property;
  const Layout(this.span, {this.property});

  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0});
  int encode(T source, LayoutByteWriter writer, {int offset = 0});
  int getSpan() => span;

  Layout clone({String? newProperty});

  /// Encodes [source] to a standalone byte buffer.
  BuBytes serialize(T source) {
    final LayoutByteWriter data = LayoutByteWriter(span);
    final enc = encode(source, data);
    final encodeBytes = span > 0 ? data.toBytes() : data.sublist(0, enc);
    return encodeBytes;
  }

  /// Encodes [source] and returns it as a hex string.
  String serializeHex(T source, {String? prefix}) {
    return BytesUtils.toHexString(serialize(source), prefix: prefix);
  }

  /// Decodes a value out of [bytes] starting at [offset].
  LayoutDecodeResult<T> deserialize(List<int> bytes, {int offset = 0}) {
    final reader = LayoutByteReader(bytes);
    try {
      final decodeBytes = decode(reader, offset: offset);
      return decodeBytes;
    } on RangeError catch (e) {
      throw BuError(DefaultErrorType.invalidLength,
        "Truncated layout bytes.",
        details: {"property": property, "reason": e.toString()},
      );
    }
  }
}

typedef CbGetLayoutSpan = List<int> Function(int);

/// Result of a decode: the value plus how many bytes it consumed.
class LayoutDecodeResult<T> {
  final int consumed;
  final T value;
  const LayoutDecodeResult({required this.consumed, required this.value});
}

/// A map value field whose layout is resolved lazily, keyed by [K].
class LazyMsgPackMapLayoutBuilder<K, V, R extends LayoutRepository>
    extends BaseLazyStructLayoutBuilder<V, Map<K, V>, R> {
  final CbMsgPackLayoutFunc<K, V, R> _layout;
  @override
  final String? property;
  LazyMsgPackMapLayoutBuilder({
    required CbMsgPackLayoutFunc<K, V, R> layout,
    this.property,
  }) : _layout = layout;

  @override
  Layout<V>? layout({
    required LayoutAction action,
    required Map<K, V> sourceOrResult,
    required int remainBytes,
    R? repository,
    V? value,
  }) {
    return _layout(
      property,
      RequestLayoutParams(
        action: action,
        sourceOrResult: sourceOrResult,
        repository: repository,
        remainBytes: remainBytes,
        encodeValue: value,
      ),
    );
  }
}
