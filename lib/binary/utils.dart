import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';
import 'package:blockchain_utils/string/string.dart';

import 'package:blockchain_utils/hex/hex.dart' as hex;

/// A utility class for working with binary data represented as lists of integers (bytes).
class BytesUtils {
  /// Performs a bitwise XOR operation on two lists of bytes.
  ///
  /// Takes two lists of bytes and returns a new list where each byte is the result
  /// of the XOR operation between the corresponding bytes in the input lists.
  static List<int> xor(List<int> dataBytes1, List<int> dataBytes2) {
    return List<int>.from(List<int>.generate(
      dataBytes1.length,
      (index) => dataBytes1[index] ^ dataBytes2[index],
    ));
  }

  /// Converts a list of bytes to a binary string representation.
  ///
  /// Converts the input list of bytes to a binary string, optionally adding leading
  /// zeros to ensure a specific bit length.
  static String toBinary(List<int> dataBytes, {int zeroPadBitLen = 0}) {
    return BigintUtils.toBinary(
        BigintUtils.fromBytes(dataBytes), zeroPadBitLen);
  }

  /// Converts a binary string to a list of bytes.
  ///
  /// Parses a binary string and converts it back to a list of bytes. An optional
  /// parameter allows padding the result with zeros to achieve a specific byte length.
  static List<int> fromBinary(String data, {int zeroPadByteLen = 0}) {
    BigInt intValue = BigInt.parse(data, radix: 2);
    String hexValue = intValue.toRadixString(16).padLeft(zeroPadByteLen, '0');
    return fromHexString(hexValue);
  }

  /// Converts a list of bytes to a hexadecimal string representation.
  ///
  /// Converts the input list of bytes to a hexadecimal string using the `hex` library.
  static String toHexString(List<int> dataBytes) {
    return hex.hex.encode(dataBytes);
  }

  /// Converts a hexadecimal string to a list of bytes.
  ///
  /// Parses a hexadecimal string and converts it to a list of bytes using the `hex` library.
  static List<int> fromHexString(String data) {
    return hex.hex.decode(StringUtils.strip0x(data));
  }

  /// Ensures that each byte is properly represented as an 8-bit integer.
  ///
  /// Performs a bitwise AND operation with a mask (`mask8`) to ensure that each byte in
  /// the input list is represented as an 8-bit integer.
  static List<int> toBytes(List<int> bytes) {
    return bytes.map((e) => e & mask8).toList();
  }
}
