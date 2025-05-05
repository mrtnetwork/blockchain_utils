import 'dart:typed_data' show Endian;

import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/utils/numbers/numbers.dart';

class CryptoSignatureUtils {
  static bool isValidSchnorrSignature(List<int> signature) {
    if (signature.length != CryptoSignerConst.schnoorSginatureLength &&
        signature.length != CryptoSignerConst.schnoorSginatureLength + 1) {
      return false;
    }

    final r = BigintUtils.fromBytes(signature.sublist(0, 32));

    final s = BigintUtils.fromBytes(signature.sublist(32, 64));
    if (r >= Curves.curveSecp256k1.p || s >= Curves.generatorSecp256k1.order!) {
      return false;
    }
    return true;
  }

  static bool isValidBitcoinDERSignature(List<int> signature) {
    if (signature.length < 9 || signature.length > 73) {
      return false;
    }

    if (signature[0] != 0x30) {
      return false;
    }
    if (signature[1] > signature.length - 2) {
      return false;
    }
    int lenR = signature[3];
    if (5 + lenR >= signature.length) {
      return false;
    }

    int lenS = signature[5 + lenR];
    int total = lenR + lenS + 6;
    if (total != signature.length && total + 1 != signature.length) {
      return false;
    }

    // Verify R and S are positive integers (first byte cannot be negative)
    if (signature[4] & 0x80 != 0) {
      return false;
    }
    if (lenR > 1 && (signature[4] == 0x00) && (signature[5] & 0x80 == 0)) {
      return false;
    }
    if (signature[lenR + 4] != 0x02) return false;
    if (lenS == 0) return false;
    // Negative numbers are not allowed for S.
    if ((signature[lenR + 6] & 0x80) != 0) return false;
    // Null bytes at the start of S are not allowed, unless S would otherwise be
    // interpreted as a negative number.
    if (lenS > 1 &&
        (signature[lenR + 6] == 0x00) &&
        (signature[lenR + 7] & 0x80 == 0)) {
      return false;
    }
    return true;
  }

  /// Converts a list of BigInt values to DER-encoded bytes.
  ///
  /// The [toDer] method takes a list of BigInt values [bigIntList] and encodes them in DER format.
  /// It returns a list of bytes representing the DER-encoded sequence of integers.
  ///
  /// Example Usage:
  /// ```dart
  /// List<BigInt> values = [BigInt.from(123), BigInt.from(456)];
  /// `List<int>` derBytes = DEREncoding.toDer(values);
  /// ```
  ///
  /// Parameters:
  /// - [bigIntList]: The list of BigInt values to be DER-encoded.
  /// Returns: A list of bytes representing the DER-encoded sequence of integers.
  static List<int> toDer(List<BigInt> bigIntList) {
    final List<List<int>> encodedIntegers = bigIntList.map((bi) {
      final List<int> bytes = _encodeInteger(bi);
      return bytes;
    }).toList();
    final content = encodedIntegers.expand((e) => e);
    final List<int> lengthBytes = _encodeLength(content.length);
    final derBytes = [
      0x30,
      ...lengthBytes,
      ...encodedIntegers.expand((e) => e)
    ];

    return derBytes;
  }

  /// Encodes the length of DER content.
  ///
  /// The [_encodeLength] method takes an integer [length] and returns a list of bytes
  /// representing the DER-encoded length for the content.
  ///
  /// Parameters:
  /// - [length]: The length of the DER content.
  /// Returns: A list of bytes representing the DER-encoded length.
  static List<int> _encodeLength(int length) {
    if (length < 128) {
      return [length];
    } else {
      final encodeLen = IntUtils.toBytes(length,
          length: IntUtils.bitlengthInBytes(length), byteOrder: Endian.little);
      return [0x80 | encodeLen.length, ...encodeLen];
    }
  }

  /// Encodes a BigInt as a DER-encoded integer.
  ///
  /// The [_encodeInteger] method takes a BigInt [r] and returns a list of bytes
  /// representing the DER-encoded integer.
  ///
  /// Parameters:
  /// - [r]: The BigInt value to be DER-encoded.
  /// Returns: A list of bytes representing the DER-encoded integer.
  static List<int> _encodeInteger(BigInt r) {
    /// can't support negative numbers yet
    assert(r >= BigInt.zero);

    final len = BigintUtils.orderLen(r);
    final List<int> s = BigintUtils.toBytes(r, length: len);

    final int num = s[0];
    if (num <= 0x7F) {
      return [0x02, ..._encodeLength(s.length), ...s];
    } else {
      /// DER integers are two's complement, so if the first byte is
      /// 0x80-0xff then we need an extra 0x00 byte to prevent it from
      /// looking negative.
      return [0x02, ..._encodeLength(s.length + 1), 0x00, ...s];
    }
  }

  static List<int> derStripLeadingZeroIfNeeded(List<int> bytes) {
    if (bytes.length > 1 && bytes[0] == 0x00 && bytes[1] >= 0x80) {
      return bytes.sublist(1);
    }
    return bytes;
  }
}
