import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_cuint.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/layout/core/core/core.dart';
import 'package:blockchain_utils/layout/exception/exception.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

class LayoutSerializationUtils {
  static List<int> encodeLength(String length) {
    return const SubstrateScaleCUintEncoder().encode(length.toString());
  }

  static LayoutDecodeResult<BigInt> decodeScale(
    List<int> bytes, {
    int offset = 0,
  }) {
    final byte = bytes[offset];

    switch (byte & 0x03) {
      case 0x00:
        return LayoutDecodeResult(consumed: 1, value: BigInt.from(byte) >> 2);
      case 0x01:
        final val = fromBytes(
          bytes: bytes,
          offset: offset,
          end: offset + 2,
          sign: false,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: 2, value: val >> 2);
      case 0x02:
        final val = fromBytes(
          bytes: bytes,
          offset: offset,
          end: offset + 4,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: 4, value: val >> 2);
      default:
        final int o = (byte >> 2) + 5;
        final val = fromBytes(
          bytes: bytes,
          offset: offset + 1,
          end: offset + o,
          byteOrder: Endian.little,
        );
        return LayoutDecodeResult(consumed: o, value: val);
    }
  }

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

  static LayoutDecodeResult<BigInt> decodeVarint(
    List<int> bytes, {
    int offset = 0,
  }) {
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

    final BigInt value = fromBytes(
      bytes: bytes,
      offset: offset + 1,
      end: offset + 1 + size,
      byteOrder: Endian.little,
    );
    if (!value.isValidInt) {
      throw LayoutException(
        "Failed to decode varint integer. values is to large.",
      );
    }
    return LayoutDecodeResult(consumed: size + 1, value: value);
  }

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
      throw LayoutException("Failed to encode value as varint.");
    }
  }

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

  static List<int> encodeVarintBigInt(BigInt value) {
    // Range check: 0 ≤ value ≤ 2^64 - 1
    if (value < BigInt.zero || value > BinaryOps.maxU64) {
      throw LayoutException("Failed to encode value as varint.");
    }
    // Fits in 1 byte
    if (value < BigInt.from(253)) {
      return [value.toInt()];
    }

    // Fits in 2 bytes
    if (value < BigInt.from(0x10000)) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      BinaryOps.writeUint16LE(value.toInt(), bytes, 1);
      return bytes;
    }

    // Fits in 4 bytes
    if (value < BigInt.from(0x100000000)) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      BinaryOps.writeUint32LE(value.toInt(), bytes, 1);
      return bytes;
    }
    return [0xff, ...value.toLeBytes(length: 8)];
  }

  static BigInt fromBytes({
    required List<int> bytes,
    required int offset,
    required int end,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    final int length = end - offset;
    if (length <= 0) return BigInt.zero;

    BigInt result = BigInt.zero;
    bool negative;

    if (byteOrder == Endian.little) {
      // Most significant byte is at `end - 1`; walk backwards so each
      // subsequent byte is shifted further left.
      for (int i = end - 1; i >= offset; i--) {
        result = (result << 8) | BigInt.from(bytes[i] & 0xff);
      }
      negative = sign && (bytes[end - 1] & 0x80) != 0;
    } else {
      // Most significant byte is at `offset`.
      for (int i = offset; i < end; i++) {
        result = (result << 8) | BigInt.from(bytes[i] & 0xff);
      }
      negative = sign && (bytes[offset] & 0x80) != 0;
    }

    if (negative) {
      result -= BigInt.one << (length * 8);
    }

    return result;
  }
}
