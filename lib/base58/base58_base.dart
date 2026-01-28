import 'package:blockchain_utils/base58/base58_ex.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/binary/utils.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';

enum Base58Alphabets {
  bitcoin("123456789ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz"),
  ripple("rpshnaf39wBUDNEGHJKLM4PQRST7VWXYZ2bcdeCg65jkm8oFqi1tuvAxyz");

  final String alphabet;
  const Base58Alphabets(this.alphabet);
}

/// Constants related to Base58 encoding.
class Base58Const {
  /// The radix for Base58 encoding.
  static const int radix = 58;

  /// The length (in bytes) of the checksum used in Base58 encoding.
  static const int checksumByteLen = 4;
}

class Base58Utils {
  /// Compute and return the checksum for the provided List [dataBytes].
  /// The checksum is obtained by performing a double SHA-256 hash and extracting
  /// the first [Base58Const.checksumByteLen] bytes.
  ///
  /// Parameters:
  /// - dataBytes: The List of data bytes for which the checksum is computed.
  ///
  /// Returns:
  /// A List containing the computed checksum.
  static List<int> computeChecksum(List<int> dataBytes) {
    final doubleSha256Digest = QuickCrypto.sha256DoubleHash(dataBytes);
    return doubleSha256Digest.sublist(0, Base58Const.checksumByteLen);
  }
}

/// A utility class for encoding List data into a Base58 format using a specified alphabet.
class Base58Encoder {
  /// Encodes the provided List [dataBytes] into a Base58 encoded string using the specified [base58alphabets].
  ///
  /// Parameters:
  /// - dataBytes: The List of data bytes to be encoded.
  /// - base58alphabets: Optional Base58Alphabets enum to choose the alphabet (default is Base58Alphabets.bitcoin).
  ///
  /// Returns:
  /// A Base58 encoded string of the input dataBytes.
  static String encode(
    List<int> dataBytes, [
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  ]) {
    final alphabet = base58alphabets.alphabet;

    /// Convert the dataBytes into a BigInteger for encoding.
    BigInt val = BigintUtils.fromBytes(dataBytes);
    String enc = "";
    while (val > BigInt.zero) {
      /// Perform division by Base58 radix and get remainder for encoding.
      final result = BigintUtils.divmod(val, Base58Const.radix);
      val = result.$1;
      final mod = result.$2;
      enc = alphabet[mod.toInt()] + enc;
    }

    /// Count leading zero bytes in the dataBytes for leading zero characters in the encoded string.
    int zero = 0;
    for (final int byte in dataBytes) {
      if (byte == 0) {
        zero++;
      } else {
        break;
      }
    }
    final int leadingZeros = dataBytes.length - (dataBytes.length - zero);

    /// Append leading zero characters to the encoded string.
    return (alphabet[0] * leadingZeros) + enc;
  }

  /// Encodes the provided List [dataBytes] with a checksum using a specified Base58 alphabet.
  ///
  /// This method appends a checksum to the data and then encodes the result into a Base58 encoded string.
  ///
  /// Parameters:
  /// - dataBytes: The List of data bytes to be encoded with a checksum.
  /// - base58alphabets: Optional Base58Alphabets enum to choose the alphabet (default is Base58Alphabets.bitcoin).
  ///
  /// Returns:
  /// A Base58 encoded string of the input dataBytes with a checksum.
  static String checkEncode(
    List<int> dataBytes, [
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  ]) {
    dataBytes = dataBytes.asImmutableBytes;
    final checksum = Base58Utils.computeChecksum(dataBytes);
    return encode([...dataBytes, ...checksum], base58alphabets);
  }
}

/// A utility class for decoding Base58 encoded strings into List data using a specified alphabet.
class Base58Decoder {
  /// Decode the provided Base58 encoded [data] into a List of data bytes using the specified [base58alphabets].
  ///
  /// Parameters:
  /// - data: The Base58 encoded string to be decoded.
  /// - base58alphabets: Optional Base58Alphabets enum to choose the alphabet (default is Base58Alphabets.bitcoin).
  ///
  /// Returns:
  /// A List containing the decoded data bytes.
  static List<int> decode(
    String data, [
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  ]) {
    final alphabet = base58alphabets.alphabet;
    var val = BigInt.zero;

    for (int i = 0; i < data.length; i++) {
      final c = data[data.length - 1 - i];
      final charIndex = alphabet.indexOf(c);
      if (charIndex == -1) {
        throw ArgumentException.invalidOperationArguments(
          "decode",
          name: "data",
          reason: "Invalid Base58 string.",
        );
      }
      val += BigInt.from(charIndex) * BigInt.from(Base58Const.radix).pow(i);
    }
    List<int> bytes = [];
    if (val != BigInt.zero) {
      bytes = BigintUtils.toBytes(val);
    }

    // Remove leading zeros from bytes
    var padLen = 0;
    for (var i = 0; i < data.length; i++) {
      if (data[i] == alphabet[0]) {
        padLen++;
      } else {
        break;
      }
    }

    return [...List<int>.filled(padLen, 0), ...bytes];
  }

  /// Decode and verify the provided Base58 encoded [data] into a List of data bytes using a specified Base58 alphabet.
  ///
  /// This method verifies the checksum of the decoded data to ensure its integrity.
  ///
  /// Parameters:
  /// - data: The Base58 encoded string to be decoded and verified.
  /// - base58alphabets: Optional Base58Alphabets enum to choose the alphabet (default is Base58Alphabets.bitcoin).
  ///
  /// Returns:
  /// A List containing the decoded data bytes if the checksum is valid.
  ///
  /// Throws:
  /// - Base58ChecksumError: If the checksum verification fails.
  static List<int> checkDecode(
    String data, [
    Base58Alphabets base58alphabets = Base58Alphabets.bitcoin,
  ]) {
    final decodedBytes = decode(data, base58alphabets);
    final dataBytes = decodedBytes.sublist(
      0,
      decodedBytes.length - Base58Const.checksumByteLen,
    );
    final checksumBytes = decodedBytes.sublist(
      decodedBytes.length - Base58Const.checksumByteLen,
    );

    final computedChecksum = Base58Utils.computeChecksum(dataBytes);
    if (!BytesUtils.bytesEqual(checksumBytes, computedChecksum)) {
      throw Base58ChecksumError();
    }

    return dataBytes;
  }
}
