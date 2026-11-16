import 'package:blockchain_utils/encoding/layout/buffer/src/reader.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A utility class for writing layout bytes dynamically.
class LayoutByteWriter {
  /// Whether the buffer grows on demand (span was unknown/negative).
  final bool growable;

  /// Creates a writer. A negative [span] starts an empty, growable buffer.
  LayoutByteWriter(int span)
    : _buffer = LayoutByteReader.write(
        span >= 0 ? BuBytes.fill(span, 0) : BuBytes.empty(),
      ),
      growable = span < 0;
  final LayoutByteReader _buffer;

  /// The last byte in the tracked buffer.
  int get last => _buffer.last;

  /// Read-only view of the buffer written so far.
  LayoutByteReader get reader => _buffer;

  /// Returns the full buffer contents.
  BuBytes toBytes() {
    return _buffer.bytes;
  }

  /// Returns the byte range `[start, end)`.
  BuBytes sublist(int start, int end) {
    return _buffer.sublist(start, end);
  }

  /// Number of bytes currently in the buffer.
  int get length => _buffer.length;

  /// Grows the buffer with zero bytes so it can hold at least [length] bytes.
  void _ensureLength(int length) {
    if (growable && length > _buffer.length) {
      _buffer.bytes.addAll(List<int>.filled(length - _buffer.length, 0));
    }
  }

  /// Writes an unsigned 8-bit integer at [offset].
  int set(int offset, int value) {
    _ensureLength(offset + 1);
    _buffer.bytes[offset] = value & BinaryOps.mask8;
    return 1;
  }

  /// Writes a big-endian unsigned 16-bit integer at [offset].
  int setU16Be(int offset, int value) {
    return setAll(offset, value.toU16BeBytes());
  }

  int setI16Be(int offset, int value) {
    return setAll(offset, value.toI16BeBytes());
  }

  /// Writes a big-endian unsigned 32-bit integer at [offset].
  int setU32Be(int offset, int value) {
    return setAll(offset, value.toU32BeBytes());
  }

  int setI32Be(int offset, int value) {
    return setAll(offset, value.toI32BeBytes());
  }

  /// Writes a big-endian unsigned 64-bit integer at [offset].
  int setU64Be(int offset, BigInt value) {
    return setAll(offset, value.toU64BeBytes());
  }

  int setI64Be(int offset, BigInt value) {
    return setAll(offset, value.toI64BeBytes());
  }

  /// Writes [bytes] starting at [index]; grows the buffer if needed.
  int setAll(int index, List<int> bytes) {
    _ensureLength(index + bytes.length);
    _buffer.bytes.setAll(index, bytes);
    return bytes.length;
  }

  /// Returns the byte at [pos].
  int at(int pos) => _buffer.bytes[pos];
}
