import 'dart:typed_data';
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/int_utils.dart';

import 'ss58_ex.dart';

/// Constants used in the SS58 address encoding and decoding process.
class _Ss58Const {
  /// The maximum value for the simple account format identifier.
  static const int simpleAccountFormatMaxVal = 63;

  /// The maximum value for the format identifier.
  static const int formatMaxVal = 16383;

  /// A list of reserved format identifiers.
  static const List<int> reservedFormats = [46, 47];

  /// The prefix used for generating the checksum.
  static const List<int> checksumPrefix = [83, 83, 53, 56, 80, 82, 69];

  static int checkBytesLen(int dataBytesLength) {
    return [33, 34].contains(dataBytesLength) ? 2 : 1;
  }
}

/// Utility methods for SS58 address encoding and decoding.
class _Ss58Utils {
  /// Computes the checksum for a given set of data bytes.
  ///
  /// Parameters:
  /// - [dataBytes]: The data bytes for which the checksum needs to be computed.
  ///
  static List<int> computeChecksum(List<int> dataBytes) {
    final prefixAndData = [..._Ss58Const.checksumPrefix, ...dataBytes];
    return QuickCrypto.blake2b512Hash(
      prefixAndData,
    ).sublist(0, _Ss58Const.checkBytesLen(dataBytes.length));
  }
}

/// Provides methods to encode SS58 addresses from data bytes and an SS58 format.
class SS58Encoder {
  /// Encodes SS58 address from the provided data bytes and SS58 format.
  ///
  /// Parameters:
  /// - [dataBytes]: The data bytes to be encoded into an SS58 address.
  /// - [ss58Format]: The SS58 format specifying the address type.
  ///
  /// Throws an [ArgumentException] if the input parameters are invalid, such as incorrect data length, out-of-range SS58 format, or using reserved formats.
  ///
  static String encode(List<int> dataBytes, int ss58Format) {
    if (ss58Format < 0 ||
        ss58Format > _Ss58Const.formatMaxVal ||
        _Ss58Const.reservedFormats.contains(ss58Format)) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "ss58Str",
        reason: "Invalid SS58.",
      );
    }
    List<int> ss58FormatBytes;

    if (ss58Format <= _Ss58Const.simpleAccountFormatMaxVal) {
      ss58FormatBytes = IntUtils.toBytes(ss58Format, byteOrder: Endian.little);
    } else {
      ss58FormatBytes = [
        ((ss58Format & 0x00FC) >> 2) | 0x0040,
        (ss58Format >> 8) | ((ss58Format & 0x0003) << 6),
      ];
    }

    final payload = [...ss58FormatBytes, ...dataBytes];

    final checksum = _Ss58Utils.computeChecksum(payload);

    return Base58Encoder.encode([...payload, ...checksum]);
  }
}

/// Provides methods to decode SS58 addresses from a Base58-encoded string.
class SS58Decoder {
  /// Decodes the provided Base58-encoded SS58 address string into its SS58 format and data bytes.
  ///
  /// Parameters:
  /// - [ss58Str]: The Base58-encoded SS58 address to be decoded.
  ///
  /// Throws an [ArgumentException] or [SS58ChecksumError] if the input string is invalid, contains an invalid format, or fails the checksum verification.
  ///
  static (int, List<int>) decode(String ss58Str) {
    final decBytes = Base58Decoder.decode(ss58Str);

    int ss58Format;
    int ss58FormatLen;

    if ((decBytes[0] & 0x40) != 0) {
      ss58FormatLen = 2;
      ss58Format =
          ((decBytes[0] & 0x3F) << 2) |
          (decBytes[1] >> 6) |
          ((decBytes[1] & 0x3F) << 8);
    } else {
      ss58FormatLen = 1;
      ss58Format = decBytes[0];
    }

    if (_Ss58Const.reservedFormats.contains(ss58Format)) {
      throw ArgumentException.invalidOperationArguments(
        "decode",
        name: "ss58Str",
        reason: "Invalid SS58 format.",
      );
    }
    final int checkSumLength = _Ss58Const.checkBytesLen(
      decBytes.length - ss58FormatLen,
    );
    final dataBytes = decBytes.sublist(
      ss58FormatLen,
      decBytes.length - checkSumLength,
    );
    final checksumBytes = List<int>.unmodifiable(
      decBytes.sublist(decBytes.length - checkSumLength),
    );

    final checksumBytesGot = _Ss58Utils.computeChecksum(
      decBytes.sublist(0, decBytes.length - checkSumLength),
    );

    if (!BytesUtils.bytesEqual(checksumBytesGot, checksumBytes)) {
      throw SS58ChecksumError.invalidChecksum;
    }

    return (ss58Format, dataBytes);
  }
}
