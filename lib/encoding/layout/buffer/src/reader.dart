import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/encoding/layout/utils/utils.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Read-only cursor over an immutable byte buffer used by layout decoders.
class LayoutByteReader {
  /// Wraps [bytes] as an immutable buffer.
  LayoutByteReader(List<int> bytes) : _bytes = bytes.asImmutableBytes;

  /// Wraps an already-immutable buffer without copying.
  LayoutByteReader.write(this._bytes);
  final BuBytes _bytes;

  /// The underlying immutable byte buffer.
  BuBytes get bytes => _bytes;

  /// Total number of bytes in the buffer.
  int get length => _bytes.length;

  /// Returns the byte range `[start, end)`.
  BuBytes sublist(int start, int end) {
    return _bytes.sublist(start, end);
  }

  /// Throws [LayoutException] unless [length] bytes starting at [offset]
  /// are available. Fixed-span decodes call this first so short reads fail
  /// as [LayoutException] instead of leaking raw range errors from the
  /// byte utilities underneath.
  void requireAvailable(int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > _bytes.length) {
      throw BuError(DefaultErrorType.invalidLength,
        "Truncated layout bytes.",
        details: {
          "offset": offset.toString(),
          "length": length.toString(),
          "available": _bytes.length.toString(),
        },
      );
    }
  }

  /// Decodes a SCALE-encoded compact integer at [offset] as a Dart [int].
  LayoutDecodeResult<int> decodeScaleAsInteger(int offset) {
    final decode = LayoutSerializationUtils.decodeScale(_bytes, offset: offset);
    if (!decode.value.isSafeInt()) {
      throw const BuError(DefaultErrorType.invalidLength,"scale number is too large for int.");
    }
    return LayoutDecodeResult(
      consumed: decode.consumed,
      value: decode.value.toInt(),
    );
  }

  /// Decodes a SCALE-encoded compact integer at [offset] as a [BigInt].
  LayoutDecodeResult<BigInt> decodeScale(int offset) {
    return LayoutSerializationUtils.decodeScale(_bytes, offset: offset);
  }

  /// Number of bytes the SCALE header at [offset] occupies.
  int getScaleLength(int offset) {
    return LayoutSerializationUtils.getScaleRequiredLength(_bytes[offset]);
  }

  /// Number of bytes the varint header at [offset] occupies.
  int getVarintLength(int offset) {
    return LayoutSerializationUtils.getVarintLength(_bytes[offset]);
  }

  /// Decodes a varint at [offset] as a Dart [int].
  LayoutDecodeResult<int> decodeVarintAsInteger(int offset) {
    final decode = LayoutSerializationUtils.decodeVarint(
      _bytes,
      offset: offset,
    );
    if (!decode.value.isSafeInt()) {
      throw const BuError(DefaultErrorType.invalidLength,"varint number is too large for int.");
    }
    return LayoutDecodeResult(
      consumed: decode.consumed,
      value: decode.value.toInt(),
    );
  }

  /// Returns the byte at [index].
  int at(int index) => _bytes[index];

  /// The last byte in the buffer.
  int get last => _bytes.last;

  /// Whether [offset] has reached the end of the buffer.
  bool isEnd(int offset) {
    return offset >= _bytes.length;
  }

  /// Reads an unsigned 8-bit integer at [index].
  int getU8(int index) => _bytes[index];

  /// Reads a big-endian unsigned 16-bit integer starting at [index].
  int getU16Be(int index) {
    return _bytes[index] << 8 | _bytes[index + 1];
  }

  /// Reads a big-endian unsigned 32-bit integer starting at [index].
  int getU32Be(int index) {
    return (_bytes[index] << 24) |
        (_bytes[index + 1] << 16) |
        (_bytes[index + 2] << 8) |
        _bytes[index + 3];
  }

  /// Reads a big-endian unsigned 64-bit integer starting at [i].
  BigInt getU64Be(int i) {
    BigInt v = BigInt.zero;
    for (int k = 0; k < 8; k++) {
      v = (v << 8) | BigInt.from(_bytes[i + k]);
    }
    return v;
  }
}
