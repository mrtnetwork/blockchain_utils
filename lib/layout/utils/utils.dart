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

  static Tuple<int, BigInt> decodeLength(List<int> bytes, {bool sign = false}) {
    switch (bytes[0] & 0x03) {
      case 0x00:
        return Tuple(1, BigInt.from(bytes[0]) >> 2);
      case 0x01:
        final val = BigintUtils.fromBytes(bytes.sublist(0, 2),
            sign: sign, byteOrder: Endian.little);
        return Tuple(2, val >> 2);
      case 0x02:
        final val = BigintUtils.fromBytes(bytes.sublist(0, 4),
            sign: sign, byteOrder: Endian.little);
        return Tuple(4, val >> 2);
      default:
        final int offset = (bytes[0] >> 2) + 5;
        final val = BigintUtils.fromBytes(bytes.sublist(1, offset),
            sign: sign, byteOrder: Endian.little);
        return Tuple(offset, val);
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

  static Tuple<int, int> decodeLengthWithDetails(List<int> bytes) {
    final decode = decodeLength(bytes, sign: false);
    if (!decode.item2.isValidInt) {
      throw const MessageException("Invalid variable length. length to large.");
    }
    final bytesLength = decode.item2.toInt();
    final dataOffset = decode.item1;
    final totalLength = bytesLength + dataOffset;
    return Tuple(dataOffset, totalLength);
  }
}
