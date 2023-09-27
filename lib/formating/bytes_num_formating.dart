import 'dart:core';
import 'dart:typed_data';
import 'package:convert/convert.dart';

/// Convert a list of integers (bytes) to a hexadecimal string representation.
/// This function takes a List of integers and returns a string containing
/// the hexadecimal representation of the bytes.
String bytesToHex(List<int> bytes) => hex.encode(bytes);

/// Decode a list of integers (bytes) into a BigInt.
/// This function takes a List of integers representing bytes
/// and converts them into a BigInt, considering byte order.
BigInt decodeBigInt(List<int> bytes) {
  BigInt result = BigInt.from(0);
  for (int i = 0; i < bytes.length; i++) {
    /// Add each byte to the result, considering its position and byte order.
    result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
  }
  return result;
}

/// Encode a BigInt into a Uint8List.
/// This function takes a BigInt integer and encodes it into a Uint8List
/// representation, considering necessary padding and byte order.
Uint8List encodeBigInt(BigInt number) {
  int needsPaddingByte;
  int rawSize;

  /// Determine the raw size of the encoding and whether a padding byte is needed.
  if (number > BigInt.zero) {
    rawSize = (number.bitLength + 7) >> 3;
    needsPaddingByte =
        ((number >> (rawSize - 1) * 8) & BigInt.from(0x80)) == BigInt.from(0x80)
            ? 1
            : 0;

    /// Ensure that a padding byte is added if the raw size is less than 32 bytes.
    if (rawSize < 32) {
      needsPaddingByte = 1;
    }
  } else {
    needsPaddingByte = 0;
    rawSize = (number.bitLength + 8) >> 3;
  }

  /// Calculate the final size of the Uint8List.
  final size = rawSize < 32 ? rawSize + needsPaddingByte : rawSize;

  /// Initialize the result Uint8List.
  var result = Uint8List(size);

  /// Encode the BigInt into the Uint8List while considering byte order.
  for (int i = 0; i < size; i++) {
    result[size - i - 1] = (number & BigInt.from(0xff)).toInt();
    number = number >> 8;
  }

  return result;
}

/// Convert a list of integers from one bit size to another.
/// This function takes a list of integers, 'data', and converts them from a given
/// 'fromBits' size to a 'toBits' size, optionally padding the output list.
/// It returns a new list of integers with the converted values or null if conversion
/// is not possible due to invalid input.
List<int>? convertBits(List<int> data, int fromBits, int toBits,
    {bool pad = true}) {
  int acc = 0;

  /// Accumulator to store intermediate values.
  int bits = 0;

  /// Number of bits in 'acc' that are valid.
  List<int> ret = [];

  /// Resulting list of converted integers.
  int maxv = (1 << toBits) - 1;

  /// Maximum value that can fit in 'toBits' bits.
  int maxAcc = (1 << (fromBits + toBits - 1)) - 1;

  /// Maximum accumulator value.

  /// Iterate through each value in the input 'data'.
  for (int value in data) {
    /// Check for invalid values.
    if (value < 0 || (value >> fromBits) > 0) {
      return null;
    }

    /// Update the accumulator with the new value and maintain 'bits'.
    acc = ((acc << fromBits) | value) & maxAcc;
    bits += fromBits;

    /// Extract and add full 'toBits' sized values to the result.
    while (bits >= toBits) {
      bits -= toBits;
      ret.add((acc >> bits) & maxv);
    }
  }

  /// Optionally pad the result if 'pad' is true.
  if (pad) {
    if (bits > 0) {
      ret.add((acc << (toBits - bits)) & maxv);
    }
  } else {
    /// Check for potential invalid padding or remaining bits.
    if (bits >= fromBits || ((acc << (toBits - bits)) & maxv) > 0) {
      return null;
    }
  }

  /// Return the converted list of integers.
  return ret;
}

/// Strip the '0x' prefix from a hexadecimal string.
/// This function takes a hexadecimal string 'hex' and removes the '0x' prefix
/// if it exists. It returns the string with the prefix removed or the original
/// string if no prefix is present.
String strip0x(String hex) {
  if (hex.startsWith('0x')) {
    /// If the string starts with '0x', remove the prefix.
    return hex.substring(2);
  }

  /// If no '0x' prefix is found, return the original string.
  return hex;
}

/// Convert a hexadecimal string to a Uint8List.
/// This function takes a hexadecimal string 'hexStr', removes the '0x' prefix if present,
/// and converts it into a Uint8List containing the corresponding byte values.
/// It returns the Uint8List representation of the hexadecimal string.
Uint8List hexToBytes(String hexStr) {
  /// Remove the '0x' prefix from the hexadecimal string.
  final bytes = hex.decode(strip0x(hexStr));

  /// Check if the result is already a Uint8List.
  if (bytes is Uint8List) {
    return bytes;
  }

  /// If not, create a new Uint8List from the list of bytes.
  return Uint8List.fromList(bytes);
}

/// Convert a list of bytes to an integer with the specified endianness.
/// This function takes a list of bytes 'bytes' and an 'endian' parameter indicating
/// the byte order (Endian.little or Endian.big), and converts the bytes into an integer.
/// It supports byte lengths of 1, 2, and 4 bytes, and throws an error for unsupported lengths.
/// If 'bytes' is empty, it raises an ArgumentError.
int intFromBytes(List<int> bytes, Endian endian) {
  if (bytes.isEmpty) {
    throw ArgumentError("Input bytes should not be empty");
  }

  /// Create a Uint8List from the input bytes.
  final buffer = Uint8List.fromList(bytes);

  /// Create a ByteData view from the Uint8List.
  final byteData = ByteData.sublistView(buffer);

  /// Use a switch statement to handle different byte lengths.
  switch (bytes.length) {
    case 1:
      return byteData.getInt8(0);
    case 2:
      return byteData.getInt16(0, endian);
    case 4:
      return byteData.getInt32(0, endian);
    default:
      throw ArgumentError("Unsupported byte length: ${bytes.length}");
  }
}

/// Compare two lists of bytes for equality.
/// This function compares two lists of bytes 'a' and 'b' for equality. It returns true
/// if the lists are equal (including null check), false if they have different lengths
/// or contain different byte values, and true if the lists reference the same object.
bool bytesListEqual(List<int>? a, List<int>? b) {
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

/// Pack a 32-bit integer into a Big-Endian (BE) Uint8List.
/// This function takes a 32-bit integer 'value' and packs it into a Uint8List
/// in Big-Endian (BE) format, where the most significant byte is stored at the
/// lowest index and the least significant byte at the highest index.
/// It returns the resulting Uint8List representation of the integer.
Uint8List packUint32BE(int value) {
  /// Create a Uint8List with a length of 4 bytes to store the packed value.
  var bytes = Uint8List(4);

  /// Pack the 32-bit integer into the Uint8List in Big-Endian order.
  bytes[0] = (value >> 24) & 0xFF;
  bytes[1] = (value >> 16) & 0xFF;
  bytes[2] = (value >> 8) & 0xFF;
  bytes[3] = value & 0xFF;

  /// Return the packed Uint8List.
  return bytes;
}

/// Convert a binary string to an integer.
/// This function takes a binary string 'binary' and converts it into an integer.
/// It uses the 'int.parse' method with a radix of 2 to interpret the binary string.
/// The resulting integer represents the value of the binary string.
int binaryToByte(String binary) {
  return int.parse(binary, radix: 2);
}

/// Convert a Uint8List of bytes to a binary string.
/// This function takes a Uint8List 'bytes' and converts it into a binary string.
/// It maps each byte in the list to its binary representation with 8 bits, left-padded
/// with zeros if needed. Then, it concatenates these binary representations to form
/// the resulting binary string.
/// The returned string represents the binary data of the input bytes.
String bytesToBinary(Uint8List bytes) {
  return bytes.map((byte) => byte.toRadixString(2).padLeft(8, '0')).join('');
}
