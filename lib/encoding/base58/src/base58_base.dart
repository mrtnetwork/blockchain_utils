/// Base58 encoding/decoding (Bitcoin/Ripple alphabets), plus a
/// checksummed variant (Base58Check-style: 4-byte double-SHA256 prefix
/// check appended before encoding, verified again on decode).
library;

import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// The Base58 alphabets available to [Base58Encoder]/[Base58Decoder].
enum Base58Alphabets {
  bitcoin("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"),
  ripple("rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz");

  final String alphabet;
  const Base58Alphabets(this.alphabet);
}

/// Fixed constants for Base58 (Bitcoin-style) encoding.
class Base58Const {
  /// Base58 has 58 symbols, so each digit position is worth a power of 58.
  static const int radix = 58;

  /// Number of checksum bytes appended by [Base58Encoder.encodeWithChecksum]
  /// / verified by [Base58Decoder.decodeWithChecksum].
  static const int checksumByteLen = 4;
}

/// Checksum helper shared by the encode/decode-with-checksum methods below.
class Base58Utils {
  /// Double-SHA256 of [dataBytes], truncated to the first
  /// [Base58Const.checksumByteLen] bytes.
  static BuBytes computeChecksum(List<int> dataBytes) {
    final doubleSha256Digest = QuickCrypto.sha256DoubleHash(dataBytes);
    return BuBytes(doubleSha256Digest.sublist(0, Base58Const.checksumByteLen));
  }
}

/// Encodes bytes into a Base58 string.
class Base58Encoder {
  /// Encodes [dataBytes] as plain Base58 (no checksum) using [alphabet].
  ///
  /// Each leading zero byte in [dataBytes] becomes one literal leading
  /// `alphabet[0]` character in the output - this is the standard Base58
  /// convention for preserving byte-length information that would
  /// otherwise be lost (a leading zero byte doesn't change the numeric
  /// value, but it does change how many bytes decode() should produce).
  static String encode(
    List<int> dataBytes, [
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  ]) {
    final table = alphabet.alphabet;
    if (dataBytes.isEmpty) return '';

    var leadingZeroCount = 0;
    for (final byte in dataBytes) {
      if (byte != 0) break;
      leadingZeroCount++;
    }

    // Little-endian base-58 digits, built up one input byte at a time.
    final digits = <int>[];
    for (final byte in dataBytes) {
      var carry = byte;
      for (var i = 0; i < digits.length; i++) {
        carry += digits[i] << 8;
        digits[i] = carry % Base58Const.radix;
        carry ~/= Base58Const.radix;
      }
      while (carry > 0) {
        digits.add(carry % Base58Const.radix);
        carry ~/= Base58Const.radix;
      }
    }

    final out = StringBuffer(table[0] * leadingZeroCount);
    for (var i = digits.length - 1; i >= 0; i--) {
      out.write(table[digits[i]]);
    }
    return out.toString();
  }

  /// Encodes [dataBytes] with a 4-byte checksum appended (double-SHA256,
  /// truncated), so [Base58Decoder.decodeWithChecksum] can later detect a
  /// mistyped or corrupted string. This is what Bitcoin addresses/WIF keys
  /// use under the hood.
  static String encodeWithChecksum(
    List<int> dataBytes, [
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  ]) {
    dataBytes = dataBytes.asImmutableBytes;
    final checksum = Base58Utils.computeChecksum(dataBytes);
    return encode([...dataBytes, ...checksum], alphabet);
  }
}

/// Decodes Base58 strings back into bytes.
class Base58Decoder {
  /// Decodes [data] (produced by [Base58Encoder.encode]) back to bytes
  /// using [alphabet].
  ///
  /// Throws [Base58FormatError] if [data] contains a character that isn't
  /// in [alphabet].
  static BuBytes decode(
    String data, [
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  ]) {
    final table = alphabet.alphabet;
    if (data.isEmpty) return BuBytes.empty();

    var leadingZeroCount = 0;
    for (var i = 0; i < data.length; i++) {
      if (data[i] != table[0]) break;
      leadingZeroCount++;
    }

    // Little-endian bytes, built up one input character at a time.
    final bytes = <int>[];
    for (var i = 0; i < data.length; i++) {
      final digit = table.indexOf(data[i]);
      if (digit == -1) {
        throw BuError(
          DefaultErrorType.badBase58,
          "Invalid Base58 string.",
          details: {
            "reason": 'Invalid Base58 character "${data[i]}" at index $i.',
          },
        );
      }
      var carry = digit;
      for (var j = 0; j < bytes.length; j++) {
        carry += bytes[j] * Base58Const.radix;
        bytes[j] = carry & 0xFF;
        carry >>= 8;
      }
      while (carry > 0) {
        bytes.add(carry & 0xFF);
        carry >>= 8;
      }
    }

    final result = List<int>.filled(leadingZeroCount + bytes.length, 0);
    for (var i = 0; i < bytes.length; i++) {
      result[leadingZeroCount + i] = bytes[bytes.length - 1 - i];
    }
    return BuBytes(result);
  }

  /// Decodes [data] and verifies its trailing 4-byte checksum, returning
  /// only the data bytes (checksum stripped) once verified.
  ///
  /// Throws [Base58ChecksumError] if the checksum doesn't match, or
  /// [Base58FormatError] if [data] contains an invalid character.
  static BuBytes decodeWithChecksum(
    String data, [
    Base58Alphabets alphabet = Base58Alphabets.bitcoin,
  ]) {
    final decoded = decode(data, alphabet);
    if (decoded.length < Base58Const.checksumByteLen) {
      throw BuError(
        DefaultErrorType.invalidChecksum,
        "Invalid checksum.",
        details: {
          'reason':
              'Decoded data (${decoded.length} bytes) is shorter than the '
              '${Base58Const.checksumByteLen}-byte checksum.',
        },
      );
    }
    final dataBytes = decoded.sublist(
      0,
      decoded.length - Base58Const.checksumByteLen,
    );
    final checksumBytes = decoded.sublist(
      decoded.length - Base58Const.checksumByteLen,
    );

    final expectedChecksum = Base58Utils.computeChecksum(dataBytes);
    if (!BytesUtils.bytesEqual(checksumBytes, expectedChecksum)) {
      throw const BuError(DefaultErrorType.badBase58, "Invalid Base58 string.");
    }
    return BuBytes(dataBytes);
  }
}
