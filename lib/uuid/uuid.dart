import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';

class UUID {
  /// Generates a version 4 (random) UUID (Universally Unique Identifier).
  static String generateUUIDv4() {
    /// Generate random bytes for the UUIDv4.
    final bytes = List<int>.generate(16, (i) {
      if (i == 6) {
        return (QuickCrypto.generateRandomInt(16) & 0x0f) | 0x40;
      } else if (i == 8) {
        return (QuickCrypto.generateRandomInt(4) & 0x03) | 0x08;
      } else {
        return QuickCrypto.generateRandomInt(256);
      }
    });

    /// Set the 6th high-order bit of the 6th byte to indicate version 4.
    bytes[6] = (bytes[6] & 0x0f) | 0x40;

    /// Set the 7th high-order bit of the 8th byte to indicate variant RFC4122.
    bytes[8] = (bytes[8] & 0x3f) | 0x80;

    /// Convert bytes to a hexadecimal string with hyphen-separated groups.
    final List<String> hexBytes =
        bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();

    return '${hexBytes.sublist(0, 4).join('')}-${hexBytes.sublist(4, 6).join('')}-'
        '${hexBytes.sublist(6, 8).join('')}-${hexBytes.sublist(8, 10).join('')}-'
        '${hexBytes.sublist(10).join('')}';
  }

  /// Converts a UUID string to a binary buffer.
  ///
  /// Parameters:
  /// - [uuidString]: The UUID string to convert to a binary buffer.
  ///
  static List<int> toBuffer(String uuidString, {bool validate = true}) {
    if (validate && !isValidUUIDv4(uuidString)) {
      throw ArgumentException.invalidOperationArguments(
        "toBuffer",
        name: "uuidString",
        reason: "Invalid UUID string.",
      );
    }
    final buffer = List<int>.filled(16, 0);

    /// Remove dashes and convert the hexadecimal string to bytes
    final cleanUuidString = uuidString.replaceAll('-', '');
    final bytes = BytesUtils.fromHexString(cleanUuidString);

    /// Copy the bytes into the buffer
    for (var i = 0; i < 16; i++) {
      buffer[i] = bytes[i];
    }

    return buffer;
  }

  /// Converts a binary buffer to a UUIDv4 string.
  ///
  /// Parameters:
  /// - [buffer]: The binary buffer representing the UUID.
  ///
  /// Throws:
  /// - [ArgumentException] if the input buffer's length is not 16 bytes, as UUIDv4
  ///   buffers must be exactly 16 bytes long.
  ///
  static String fromBuffer(List<int> buffer) {
    if (buffer.length != 16) {
      throw ArgumentException.invalidOperationArguments(
        "fromBuffer",
        name: "buffer",
        reason: "Invalid UUID V4 bytes length.",
        expecteLen: 16,
      );
    }

    final List<String> hexBytes =
        buffer.map((byte) => byte.toRadixString(16).padLeft(2, '0')).toList();

    /// Insert dashes at appropriate positions to form a UUIDv4 string
    return '${hexBytes.sublist(0, 4).join('')}-${hexBytes.sublist(4, 6).join('')}-${hexBytes.sublist(6, 8).join('')}-${hexBytes.sublist(8, 10).join('')}-${hexBytes.sublist(10).join('')}';
  }

  /// Validates whether a string is a valid UUIDv4.
  static bool isValidUUIDv4(String uuid) {
    /// Regular expression pattern for UUIDv4
    final pattern = RegExp(
      r'^[0-9a-fA-F]{8}-[0-9a-fA-F]{4}-4[0-9a-fA-F]{3}-[89abAB][0-9a-fA-F]{3}-[0-9a-fA-F]{12}$',
    );

    /// Check if the input string matches the pattern
    return pattern.hasMatch(uuid);
  }
}
