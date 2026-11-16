import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class for calculating and verifying XModem CRC (Cyclic Redundancy Check).
class XModemCrc {
  /// Computes the 2-byte big-endian XMODEM CRC-16 of [bytes]
  static BuBytes _calculateXmodemCrc(List<int> bytes) {
    int crc = 0;
    for (final byte in bytes) {
      crc = crc ^ (byte << 8);
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }

    return BuBytes([(crc >> 8) & BinaryOps.mask8, crc & BinaryOps.mask8]);
  }

  /// Calculates the XModem CRC (Cyclic Redundancy Check) for the given [data].
  ///
  /// Parameters:
  /// - [data]: The data block for which to calculate the CRC.
  ///
  static BuBytes quickDigest(List<int> data) {
    return _calculateXmodemCrc(data);
  }

  /// Returns the size of the XModem CRC digest, which is always 2 bytes (16 bits).
  static int get digestSize {
    return 2;
  }
}
