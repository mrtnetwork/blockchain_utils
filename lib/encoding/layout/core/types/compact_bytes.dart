import 'package:blockchain_utils/encoding/layout/buffer/buffer.dart';
import 'package:blockchain_utils/encoding/layout/constant/constant.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';

/// Base for `[compact length][payload]`-encoded values. Subclasses only
/// need to convert between raw payload bytes and [T], plus how the wire
/// length value maps to a payload byte count (see [BitSequenceLayout]).
abstract class CompactLengthPrefixedLayout<T> extends Layout<T> {
  CompactLengthPrefixedLayout({super.property}) : super(-1);
  static final _lengthCodec = LayoutConst.compactIntU48();

  /// Number of payload bytes for a decoded wire length of [value].
  int lengthToByteCount(int value) => value;

  /// Wire length value to encode for [byteCount] payload bytes.
  int byteCountToLength(int byteCount) => byteCount;

  /// Converts raw payload bytes into [T].
  T fromBytes(List<int> bytes);

  /// Converts [source] into raw payload bytes.
  List<int> toBytes(T source);

  @override
  int getSpan() => -1;

  @override
  LayoutDecodeResult<T> decode(LayoutByteReader bytes, {int offset = 0}) {
    final decode = bytes.decodeScaleAsInteger(offset);
    bytes.requireAvailable(
      offset + decode.consumed,
      lengthToByteCount(decode.value),
    );
    final total = decode.consumed + lengthToByteCount(decode.value);
    final result = bytes.sublist(offset + decode.consumed, offset + total);
    return LayoutDecodeResult(consumed: total, value: fromBytes(result));
  }

  @override
  int encode(T source, LayoutByteWriter writer, {int offset = 0}) {
    final payload = toBytes(source);
    final int length = _lengthCodec.encode(
      byteCountToLength(payload.length),
      writer,
      offset: offset,
    );
    writer.setAll(offset + length, payload);
    return payload.length + length;
  }
}

/// Compact-length-prefixed raw byte blob.
class CompactBytes extends CompactLengthPrefixedLayout<List<int>> {
  CompactBytes({super.property});

  @override
  List<int> fromBytes(List<int> bytes) => bytes;

  @override
  List<int> toBytes(List<int> source) => source;

  @override
  CompactBytes clone({String? newProperty}) {
    return CompactBytes(property: newProperty);
  }
}
