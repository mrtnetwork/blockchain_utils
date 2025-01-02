import 'dart:typed_data';
import 'package:blockchain_utils/base58/base58_base.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';

import 'ss58_ex.dart';

/// Constants used in the SS58 address encoding and decoding process.
class _Ss58Const {
  /// The maximum value for the simple account format identifier.
  static const int simpleAccountFormatMaxVal = 63;

  /// The maximum value for the format identifier.
  static const int formatMaxVal = 16383;

  /// A list of reserved format identifiers.
  static const List<int> reservedFormats = [46, 47];

  // /// The length of the data part of an SS58 address in bytes.
  // static const int dataByteLen = 32;

  /// The length of the checksum part of an SS58 address in bytes.
  // static const int checksumByteLen = 2;

  /// The prefix used for generating the checksum.
  static final List<int> checksumPrefix =
      List<int>.unmodifiable(<int>[83, 83, 53, 56, 80, 82, 69]);

  static int checkBytesLen(int dataBytesLength) {
    return [33, 34].contains(dataBytesLength) ? 2 : 1;
  }
}

/// Utility methods for SS58 address encoding and decoding.
class _Ss58Utils {
  /// Computes the checksum for a given set of data bytes.
  ///
  /// The checksum is computed by prepending the checksum prefix to the data bytes,
  /// hashing the resulting sequence using the Blake2b-512 algorithm, and then taking
  /// the first [_Ss58Const.checksumByteLen] bytes of the hash as the checksum.
  ///
  /// Parameters:
  /// - [dataBytes]: The data bytes for which the checksum needs to be computed.
  ///
  /// Returns:
  /// A [List<int>] representing the computed checksum.
  static List<int> computeChecksum(List<int> dataBytes) {
    final prefixAndData =
        List<int>.from([..._Ss58Const.checksumPrefix, ...dataBytes]);
    return QuickCrypto.blake2b512Hash(prefixAndData)
        .sublist(0, _Ss58Const.checkBytesLen(dataBytes.length));
  }
}

/// Provides methods to encode SS58 addresses from data bytes and an SS58 format.
class SS58Encoder {
  /// Encodes SS58 address from the provided data bytes and SS58 format.
  ///
  /// Parameters:
  /// - [dataBytes]: The data bytes to be encoded into an SS58 address. It should have a length of [Ss58Const.dataByteLen].
  /// - [ss58Format]: The SS58 format specifying the address type.
  ///
  /// Returns:
  /// A Base58-encoded SS58 address string.
  ///
  /// Throws an [ArgumentException] if the input parameters are invalid, such as incorrect data length, out-of-range SS58 format, or using reserved formats.
  static String encode(List<int> dataBytes, int ss58Format) {
    // Check parameters
    // if (dataBytes.length != _Ss58Const.dataByteLen) {
    //   throw ArgumentException('Invalid data length (${dataBytes.length})');
    // }
    if (ss58Format < 0 || ss58Format > _Ss58Const.formatMaxVal) {
      throw ArgumentException('Invalid SS58 format ($ss58Format)');
    }
    if (_Ss58Const.reservedFormats.contains(ss58Format)) {
      throw ArgumentException('Invalid SS58 format ($ss58Format)');
    }

    List<int> ss58FormatBytes;

    if (ss58Format <= _Ss58Const.simpleAccountFormatMaxVal) {
      ss58FormatBytes = IntUtils.toBytes(ss58Format,
          length: IntUtils.bitlengthInBytes(ss58Format),
          byteOrder: Endian.little);
    } else {
      ss58FormatBytes = List<int>.from([
        ((ss58Format & 0x00FC) >> 2) | 0x0040,
        (ss58Format >> 8) | ((ss58Format & 0x0003) << 6)
      ]);
    }

    final payload = List<int>.from([...ss58FormatBytes, ...dataBytes]);

    final checksum = _Ss58Utils.computeChecksum(payload);

    return Base58Encoder.encode(List<int>.from([...payload, ...checksum]));
  }
}

/// Provides methods to decode SS58 addresses from a Base58-encoded string.
class SS58Decoder {
  /// Decodes the provided Base58-encoded SS58 address string into its SS58 format and data bytes.
  ///
  /// Parameters:
  /// - [dataStr]: The Base58-encoded SS58 address to be decoded.
  ///
  /// Returns:
  /// A tuple containing the SS58 format (address type) and the data bytes of the SS58 address.
  ///
  /// Throws an [ArgumentException] or [SS58ChecksumError] if the input string is invalid, contains an invalid format, or fails the checksum verification.
  static Tuple<int, List<int>> decode(String dataStr) {
    final decBytes = Base58Decoder.decode(dataStr);

    int ss58Format;
    int ss58FormatLen;

    if ((decBytes[0] & 0x40) != 0) {
      ss58FormatLen = 2;
      ss58Format = ((decBytes[0] & 0x3F) << 2) |
          (decBytes[1] >> 6) |
          ((decBytes[1] & 0x3F) << 8);
    } else {
      ss58FormatLen = 1;
      ss58Format = decBytes[0];
    }

    if (_Ss58Const.reservedFormats.contains(ss58Format)) {
      throw ArgumentException('Invalid SS58 format ($ss58Format)');
    }
    final int checkSumLength =
        _Ss58Const.checkBytesLen(decBytes.length - ss58FormatLen);
    final dataBytes = List<int>.from(
        decBytes.sublist(ss58FormatLen, decBytes.length - checkSumLength));
    final checksumBytes = List<int>.unmodifiable(
        decBytes.sublist(decBytes.length - checkSumLength));

    final checksumBytesGot = _Ss58Utils.computeChecksum(
        decBytes.sublist(0, decBytes.length - checkSumLength));

    if (!BytesUtils.bytesEqual(checksumBytesGot, checksumBytes)) {
      throw SS58ChecksumError(
          'Invalid checksum (expected ${BytesUtils.toHexString(checksumBytesGot)}, '
          'got ${BytesUtils.toHexString(checksumBytes)})');
    }

    return Tuple(ss58Format, dataBytes);
  }
}
