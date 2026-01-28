import 'package:blockchain_utils/utils/binary/binary_operation.dart';

/// A class for calculating and verifying XModem CRC (Cyclic Redundancy Check).
class XModemCrc {
  static List<int> _calculateXmodemCrc(List<int> bytes) {
    int crc = 0;
    for (final byte in bytes) {
      crc = crc ^ byte << 8;
      for (int i = 0; i < 8; i++) {
        if ((crc & 0x8000) != 0) {
          crc = (crc << 1) ^ 0x1021;
        } else {
          crc <<= 1;
        }
      }
    }

    return [(crc >> 8) & BinaryOps.mask8, crc & BinaryOps.mask8];
  }

  /// Calculates the XModem CRC (Cyclic Redundancy Check) for the given [data].
  ///
  /// Parameters:
  /// - [data]: The data block for which to calculate the CRC.
  ///
  static List<int> quickDigest(List<int> data) {
    return _calculateXmodemCrc(data);
  }

  /// Returns the size of the XModem CRC digest, which is always 2 bytes (16 bits).
  static int get digestSize {
    return 2;
  }
}
