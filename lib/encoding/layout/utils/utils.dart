import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/encoding/layout/core/core/core.dart';
import 'package:blockchain_utils/protocol/substrate/scale/substrate_scale_enc_uint.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// SCALE compact-integer and Bitcoin-style varint codecs used by the layout types.
class LayoutSerializationUtils {
  /// SCALE compact-encodes [length] (given as a decimal string).
  static List<int> encodeLength(String length) {
    return const SubstrateScaleCUintEncoder().encode(length.toString());
  }

  /// Decodes a SCALE compact integer at [offset].
  ///
  static LayoutDecodeResult<BigInt> decodeScale(
    List<int> bytes, {
    int offset = 0,
  }) {
    _requireAvailable(bytes, offset, 1);
    final byte = bytes[offset];

    switch (byte & 0x03) {
      case 0x00:
        return LayoutDecodeResult(consumed: 1, value: BigInt.from(byte) >> 2);
      case 0x01:
        _requireAvailable(bytes, offset, 2);
        final val = BigintUtils.fromBytes(
          bytes,
          offset: offset,
          length: 2,
          sign: false,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: 2, value: val >> 2);
      case 0x02:
        _requireAvailable(bytes, offset, 4);
        final val = BigintUtils.fromBytes(
          bytes,
          offset: offset,
          length: 4,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: 4, value: val >> 2);
      default:
        final int dataLen = (byte >> 2) + 4;
        _requireAvailable(bytes, offset + 1, dataLen);
        final val = BigintUtils.fromBytes(
          bytes,
          offset: offset + 1,
          length: dataLen,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: dataLen + 1, value: val);
    }
  }

  /// Throws [LayoutException] unless [length] bytes at [offset] exist.
  static void _requireAvailable(List<int> bytes, int offset, int length) {
    if (offset < 0 || length < 0 || offset + length > bytes.length) {
      throw const BuError(
        DefaultErrorType.invalidLength,
        "Truncated layout bytes.",
      );
    }
  }

  /// Number of bytes a SCALE compact-integer header (starting with [bytes]) occupies.
  static int getScaleRequiredLength(int bytes, {bool sign = false}) {
    switch (bytes & 0x03) {
      case 0x00:
        return 1;
      case 0x01:
        return 2;
      case 0x02:
        return 4;
      default:
        return (bytes >> 2) + 5;
    }
  }

  /// Number of bytes a varint value occupies, given its first data byte.
  static int getDataVarintOffset(int bytes, {bool sign = false}) {
    if (bytes < 253) {
      return 1;
    }
    if (bytes == 253) {
      return 2;
    } else if (bytes == 254) {
      return 4;
    } else {
      return 8;
    }
  }

  /// Decodes a Bitcoin-style varint at [offset].
  static LayoutDecodeResult<BigInt> decodeVarint(
    List<int> bytes, {
    int offset = 0,
  }) {
    _requireAvailable(bytes, offset, 1);
    final int ni = bytes[offset];
    int size = 0;

    if (ni < 253) {
      return LayoutDecodeResult(consumed: 1, value: BigInt.from(ni));
    }

    if (ni == 253) {
      size = 2;
    } else if (ni == 254) {
      size = 4;
    } else {
      size = 8;
    }

    _requireAvailable(bytes, offset + 1, size);
    final BigInt value = BigintUtils.fromBytes(
      bytes,
      offset: offset + 1,
      length: size,
      byteOrder: Endian.little,
    );
    if (!value.isSafeInt()) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Failed to decode varint integer. Value is too large.",
      );
    }
    return LayoutDecodeResult(consumed: size + 1, value: value);
  }

  /// Encodes [i] as a Bitcoin-style varint.
  static List<int> encodeVarint(int i) {
    if (i < 253) {
      return [i];
    } else if (i < 0x10000) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      BinaryOps.writeUint16LE(i, bytes, 1);
      return bytes;
    } else if (i < 0x100000000) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      BinaryOps.writeUint32LE(i, bytes, 1);
      return bytes;
    } else {
      throw BuError(
        DefaultErrorType.badCbor,
        "Failed to encode value as varint.",
      );
    }
  }

  /// Number of bytes a varint header occupies, given its first byte.
  static int getVarintLength(int byte, {bool sign = false}) {
    if (byte < 253) {
      return 1;
    }

    if (byte == 253) {
      return 3;
    } else if (byte == 254) {
      return 5;
    } else {
      return 9;
    }
  }

  /// Encodes [value] (0 to 2^64-1) as a Bitcoin-style varint.
  static List<int> encodeVarintBigInt(BigInt value) {
    if (value < BigInt.zero || value > BinaryOps.maxU64) {
      throw BuError(
        DefaultErrorType.badCbor,
        "Failed to encode value as varint.",
      );
    }
    if (value < BigInt.from(253)) {
      return [value.toInt()];
    }
    if (value < BigInt.from(0x10000)) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      BinaryOps.writeUint16LE(value.toInt(), bytes, 1);
      return bytes;
    }
    if (value < BigInt.from(0x100000000)) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      BinaryOps.writeUint32LE(value.toInt(), bytes, 1);
      return bytes;
    }
    return [0xff, ...value.toLeBytes(length: 8)];
  }
}
