import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/hex/hex.dart' as hex;
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';

import 'binary_operation.dart';

/// A utility class for working with binary data represented as lists of integers (bytes).
class BytesUtils {
  /// Performs a bitwise XOR operation on two lists of bytes.
  ///
  /// Takes two lists of bytes and returns a new list where each byte is the result
  /// of the XOR operation between the corresponding bytes in the input lists.
  static List<int> xor(List<int> dataBytes1, List<int> dataBytes2) {
    return List<int>.from(List<int>.generate(
        dataBytes1.length, (index) => dataBytes1[index] ^ dataBytes2[index]));
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
    final BigInt intValue = BigInt.parse(data, radix: 2);
    final String hexValue =
        intValue.toRadixString(16).padLeft(zeroPadByteLen, '0');
    return fromHexString(hexValue);
  }

  /// Converts a List of integers representing bytes, [dataBytes], into a
  /// hexadecimal string.
  ///
  /// The method uses the `hex` library to encode the byte list into a
  /// hexadecimal string. It allows customization of the string's case
  /// (lowercase or uppercase) using the [lowerCase] parameter, and an optional
  /// [prefix] string can be appended to the resulting hexadecimal string.
  ///
  /// Parameters:
  /// - [dataBytes]: A List of integers representing bytes to be converted.
  /// - [lowerCase]: Whether the resulting hexadecimal string should be in
  ///   lowercase (default is true).
  /// - [prefix]: An optional string to append as a prefix to the hexadecimal string.
  ///
  /// Returns:
  /// - A hexadecimal string representation of [dataBytes].
  ///
  static String toHexString(List<int> dataBytes,
      {bool lowerCase = true, String? prefix}) {
    final String toHex = hex.hex.encode(dataBytes, lowerCase: lowerCase);
    return "${prefix ?? ''}$toHex";
  }

  /// Tries to convert a list of integers representing bytes, [dataBytes], into a
  /// hexadecimal string.
  ///
  /// If [dataBytes] is null, returns null. Otherwise, attempts to convert the
  /// byte list into a hexadecimal string using the [toHexString] function.
  /// If successful, returns the resulting hexadecimal string; otherwise, returns null.
  ///
  /// Parameters:
  /// - [dataBytes]: A List of integers representing bytes to be converted.
  /// - [lowerCase]: Whether the resulting hexadecimal string should be in
  ///   lowercase (default is true).
  /// - [prefix]: An optional string to append as a prefix to the hexadecimal string.
  ///
  /// Returns:
  /// - A hexadecimal string representation of [dataBytes], or null if conversion fails.
  ///
  static String? tryToHexString(List<int>? dataBytes,
      {bool lowerCase = true, String? prefix}) {
    if (dataBytes == null) return null;
    try {
      return toHexString(dataBytes, lowerCase: lowerCase, prefix: prefix);
    } catch (e) {
      return null;
    }
  }

  /// Converts a hexadecimal string [data] into a List of integers representing bytes.
  ///
  /// The method removes the '0x' prefix, strips leading zeros, and decodes the
  /// resulting hexadecimal string into bytes. Optionally, it pads zero if the
  /// string length is odd and the [paddingZero] parameter is set to true.
  ///
  /// Parameters:
  /// - [data]: The hexadecimal string to be converted.
  /// - [paddingZero]: Whether to pad a zero to the string if its length is odd
  ///   (default is false).
  ///
  /// Returns:
  /// - A List of integers representing bytes converted from the hexadecimal string.
  ///
  /// Throws:
  /// - [ArgumentException] if the input is not a valid hexadecimal string.
  ///
  static List<int> fromHexString(String data, {bool paddingZero = false}) {
    try {
      String hexString = StringUtils.strip0x(data);
      if (hexString.isEmpty) return [];
      if (paddingZero && hexString.length.isOdd) {
        hexString = "0$hexString";
      }
      return hex.hex.decode(hexString);
    } catch (e) {
      throw const ArgumentException("invalid hex bytes");
    }
  }

  /// Tries to convert a hexadecimal string [data] into a List of integers.
  ///
  /// If [data] is null, returns null. Otherwise, attempts to parse the
  /// hexadecimal string using the [fromHexString] function. If successful,
  /// returns the resulting List of integers; otherwise, returns null.
  static List<int>? tryFromHexString(String? data) {
    if (data == null) return null;
    try {
      return fromHexString(data);
    } catch (e) {
      return null;
    }
  }

  /// Ensures that each byte is properly represented as an 8-bit integer.
  ///
  /// Performs a bitwise AND operation with a mask (`mask8`) to ensure that each byte in
  /// the input list is represented as an 8-bit integer.
  static List<int> toBytes(Iterable<int> bytes, {bool unmodifiable = false}) {
    final toBytes = bytes.map((e) => e & mask8).toList();
    if (unmodifiable) {
      return List<int>.unmodifiable(toBytes);
    }
    return toBytes;
  }

  static List<int>? tryToBytes(List<int>? bytes, {bool unmodifiable = false}) {
    if (bytes == null) return null;
    return toBytes(bytes, unmodifiable: unmodifiable);
  }

  /// Validates a list of integers representing bytes.
  ///
  /// Ensures that each integer in the provided [bytes] list falls within the
  /// valid byte range (0 to 255). If any byte is outside this range,
  /// throws an [ArgumentException] with a descriptive error message.
  ///
  /// Parameters:
  /// - [bytes]: A List of integers representing bytes to be validated.
  ///
  /// Throws:
  /// - [ArgumentException] if any byte is outside the valid range.
  ///
  static void validateBytes(Iterable<int> bytes, {String? onError}) {
    for (int i = 0; i < bytes.length; i++) {
      final int byte = bytes.elementAt(i);
      if (byte < 0 || byte > mask8) {
        throw ArgumentException(
            "${onError ?? "Invalid bytes"} at index $i $byte");
      }
    }
  }

  static void validateListOfBytes(List<int> bytes, {String? onError}) {
    for (int i = 0; i < bytes.length; i++) {
      final int byte = bytes[i];
      if (byte < 0 || byte > mask8) {
        throw ArgumentError("${onError ?? "Invalid bytes"} at index $i: $byte");
      }
    }
  }

  static bool isValidBytes(Iterable<int> bytes) {
    try {
      validateBytes(bytes);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Compare two Uint8Lists lexicographically.
  static int compareBytes(List<int> a, List<int> b) {
    final length = a.length < b.length ? a.length : b.length;

    for (var i = 0; i < length; i++) {
      if (a[i] < b[i]) {
        return -1;
      } else if (a[i] > b[i]) {
        return 1;
      }
    }

    if (a.length < b.length) {
      return -1;
    } else if (a.length > b.length) {
      return 1;
    }

    return 0;
  }

  static bool isContains(List<List<int>> a, List<int> part) {
    for (final i in a) {
      if (bytesEqual(i, part)) return true;
    }
    return false;
  }

  /// Compare two lists of bytes for equality.
  /// This function compares two lists of bytes 'a' and 'b' for equality. It returns true
  /// if the lists are equal (including null check), false if they have different lengths
  /// or contain different byte values, and true if the lists reference the same object.
  static bool bytesEqual(List<int>? a, List<int>? b) {
    /// Check if 'a' is null and handle null comparison.
    if (a == null) {
      return b == null;
    }

    /// Check if 'b' is null or if the lengths of 'a' and 'b' are different.
    if (b == null || a.length != b.length) {
      return false;
    }

    /// Check if 'a' and 'b' reference the same object (identity comparison).
    if (identical(a, b)) {
      return true;
    }

    /// Compare the individual byte values in 'a' and 'b'.
    for (int index = 0; index < a.length; index += 1) {
      if (a[index] != b[index]) {
        return false;
      }
    }

    /// If no differences were found, the lists are equal.
    return true;
  }

  static bool isLessThanBytes(List<int> thashedA, List<int> thashedB) {
    for (int i = 0; i < thashedA.length && i < thashedB.length; i++) {
      if (thashedA[i] < thashedB[i]) {
        return true;
      } else if (thashedA[i] > thashedB[i]) {
        return false;
      }
    }
    return thashedA.length < thashedB.length;
  }
}
