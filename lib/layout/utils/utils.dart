import 'dart:typed_data' show Endian;
import 'package:blockchain_utils/bip/substrate/scale/substrate_scale_enc_cuint.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/utils.dart';

class LayoutSerializationUtils {
  static List<int> encodeLength(List<int> bytes) {
    return const SubstrateScaleCUintEncoder().encode(bytes.length.toString());
  }

  static List<int> compactToBytes(BigInt value) {
    return const SubstrateScaleCUintEncoder().encode(value.toString());
  }

  static List<int> compactIntToBytes(int value) {
    return const SubstrateScaleCUintEncoder().encode(value.toString());
  }

  static Tuple<int, BigInt> decodeLength(List<int> bytes, {int offset = 0}) {
    final byte = bytes[offset];

    switch (byte & 0x03) {
      case 0x00:
        return Tuple(1, BigInt.from(byte) >> 2);
      case 0x01:
        final val = fromBytes(
            bytes: bytes,
            offset: offset,
            end: offset + 2,
            sign: false,
            byteOrder: Endian.little);
        return Tuple(2, val >> 2);
      case 0x02:
        final val = fromBytes(
            bytes: bytes,
            offset: offset,
            end: offset + 4,
            byteOrder: Endian.little);
        return Tuple(4, val >> 2);
      default:
        final int o = (byte >> 2) + 5;
        final val = fromBytes(
            bytes: bytes,
            offset: offset + 1,
            end: offset + o,
            byteOrder: Endian.little);
        return Tuple(o, val);
    }
  }

  static int getDataCompactOffset(int bytes, {bool sign = false}) {
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

  static Tuple<int, int> decodeLengthWithDetails(List<int> bytes,
      {int offset = 0}) {
    final decode = decodeLength(bytes, offset: offset);
    if (!decode.item2.isValidInt) {
      throw const MessageException("Invalid variable length. length to large.");
    }
    final bytesLength = decode.item2.toInt();
    final dataOffset = decode.item1;
    final totalLength = bytesLength + dataOffset;
    return Tuple(dataOffset, totalLength);
  }

  // static int fromBytes(
  //     {required List<int> bytes,
  //     required int offset,
  //     required int end,
  //     Endian byteOrder = Endian.big,
  //     bool sign = false}) {
  //   int result = 0;
  //   if (byteOrder == Endian.little) {
  //     int j = 0;
  //     for (int i = offset; i < end; i++) {
  //       /// Add each byte to the result, considering its position and byte order.
  //       result += bytes[i] << (8 * j++);
  //     }
  //   } else {
  //     int j = 0;
  //     for (int i = offset; i < end; i++) {
  //       /// Add each byte to the result, considering its position and byte order.
  //       result += bytes[end - j] << (8 * j++);
  //     }
  //   }
  //   if (sign && (bytes[0] & 0x80) != 0) {
  //     final bitLength = IntUtils.bitlengthInBytes(result) * 8;
  //     return result.toSigned(bitLength);
  //   }
  //   return result;
  // }
  static BigInt fromBytes(
      {required List<int> bytes,
      required int offset,
      required int end,
      Endian byteOrder = Endian.big,
      bool sign = false}) {
    BigInt result = BigInt.zero;
    if (byteOrder == Endian.little) {
      int j = 0;
      for (int i = offset; i < end; i++) {
        /// Add each byte to the result, considering its position and byte order.
        result += BigInt.from(bytes[i]) << (8 * j++);
      }
      if (result == BigInt.zero) return result;
      if (sign && (bytes[end - 1] & 0x80) != 0) {
        return result.toSigned(BigintUtils.bitlengthInBytes(result) * 8);
      }
    } else {
      int j = 0;
      for (int i = offset; i < end; i++) {
        result += BigInt.from(bytes[end - 1 - j]) << (8 * j++);
      }
      if (result == BigInt.zero) return result;
      if (sign && (bytes[offset] & 0x80) != 0) {
        return result.toSigned(BigintUtils.bitlengthInBytes(result) * 8);
      }
    }

    return result;
  }
}
