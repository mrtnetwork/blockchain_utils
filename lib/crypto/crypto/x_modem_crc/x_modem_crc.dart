import 'package:blockchain_utils/utils/utils.dart';

/// A class for calculating and verifying XModem CRC (Cyclic Redundancy Check).
///
/// XModem CRC is a simple error-checking algorithm often used for file
/// transfers. This class provides methods to calculate and verify the CRC value
/// for data blocks.
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

    // Convert the 16-bit CRC integer to a `List<int>` with two bytes
    final crcBytes = List<int>.filled(2, 0);
    crcBytes[0] = (crc >> 8) & mask8;
    crcBytes[1] = crc & mask8;

    return crcBytes;
  }

  /// Calculates the XModem CRC (Cyclic Redundancy Check) for the given [data].
  ///
  /// This method computes the CRC value for a block of data using the XModem CRC
  /// algorithm and returns the result as a 16-bit [`List<int>`].
  ///
  /// Parameters:
  /// - [data]: The data block for which to calculate the CRC.
  ///
  /// Returns:
  /// A 16-bit CRC value as a `List<int>`.
  static List<int> quickDigest(List<int> data) {
    return _calculateXmodemCrc(data);
  }

  /// Returns the size of the XModem CRC digest, which is always 2 bytes (16 bits).
  static int get digestSize {
    return 2;
  }
}
