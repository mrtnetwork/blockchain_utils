import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// CRC-16/CCITT, computed bit-by-bit over the message with 2 zero bytes
/// appended (the "augmented message" trick, so the CRC of `message + CRC`
/// comes out to zero).
class Crc16 {
  static const int _poly = 0x1021;

  /// Computes the 2-byte big-endian CRC-16/CCITT of [data].
  static BuBytes quickIntDigest(List<int> data) {
    int reg = 0;
    final List<int> message = List<int>.filled(data.length + 2, 0);
    message.setAll(0, data);

    for (final byte in message) {
      int mask = 0x80;
      while (mask > 0) {
        reg <<= 1;
        if (byte & mask != 0) {
          reg += 1;
        }
        mask >>= 1;
        if (reg > BinaryOps.mask16) {
          reg &= BinaryOps.mask16;
          reg ^= _poly;
        }
      }
    }
    return BuBytes([reg >> 8, reg & BinaryOps.mask8]);
  }
}
