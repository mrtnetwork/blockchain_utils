import 'dart:typed_data';
import 'package:blockchain_utils/binary/utils.dart';

class BigintUtils {
  /// Converts a BigInt 'num' into a List<int> of bytes with a specified 'order'.
  ///
  /// This method converts 'num' into a hexadecimal string, ensuring it's at least
  /// 'l' bytes long, and then creates a List<int> of bytes from this hexadecimal
  /// string.
  ///
  /// Returns a List<int> containing the bytes of 'num' with a length determined
  /// by 'order'.
  ///
  static List<int> bigintToBytesWithPadding(BigInt x, BigInt order) {
    String hexStr = x.toRadixString(16);
    int hexLen = hexStr.length;
    int byteLen = (order.bitLength + 7) ~/ 8;

    if (hexLen < byteLen * 2) {
      hexStr = '0' * (byteLen * 2 - hexLen) + hexStr;
    }

    return BytesUtils.fromHexString(hexStr);
  }

  static int lengthInBytes(BigInt value) {
    return (value.bitLength + 7) ~/ 8;
  }

  /// Converts a sequence of bits represented as a byte array to a BigInt integer.
  ///
  /// This method takes a byte array 'data' containing a sequence of bits and
  /// converts it into a BigInt integer 'x' by interpreting the binary data as
  /// a hexadecimal string. The result 'x' is then right-shifted, if necessary,
  /// to ensure it doesn't exceed 'qlen' bits in length.
  ///
  /// Parameters:
  ///   - data: A List<int> containing the bits to be converted.
  ///   - qlen: The maximum bit length for the resulting integer.
  ///
  /// Returns:
  ///   - BigInt: A BigInt integer representing the converted bits with 'qlen' bits.
  ///
  /// Details:
  ///   - The method first converts the binary data to a hexadecimal string, which
  ///     is then parsed into a BigInt.
  ///   - If the length of 'x' exceeds 'qlen', it's right-shifted to reduce it to
  ///     the specified length. Otherwise, 'x' remains unchanged.
  ///
  /// Note: The method assumes that 'data' is big-endian (most significant bits first).
  ///       Any padding bits will be removed as needed to match 'qlen'.
  static BigInt bitsToBigIntWithLengthLimit(List<int> data, int qlen) {
    BigInt x = BigInt.parse(BytesUtils.toHexString(data), radix: 16);
    int l = data.length * 8;

    if (l > qlen) {
      return (x >> (l - qlen));
    }
    return x;
  }

  /// Converts a sequence of bits represented as a byte array to octets.
  ///
  /// This method takes a byte array 'data' containing a sequence of bits and
  /// converts it to octets by first converting it to a BigInt 'z1' and then
  /// computing 'z2' as 'z1' modulo 'order'. If 'z2' is negative, it is replaced
  /// with 'z1'. The resulting 'z2' is then converted to a byte array with padding
  /// to match the length of 'order' in octets.
  ///
  /// Parameters:
  ///   - data: A List<int> containing the bits to be converted.
  ///   - order: A BigInt representing the order of a cryptographic curve.
  ///
  /// Returns:
  ///   - List<int>: A byte array representing the converted bits as octets.
  ///
  /// Details:
  ///   - The method first converts the binary data to a BigInt 'z1'.
  ///   - It then computes 'z2' by taking 'z1' modulo 'order' and ensures that 'z2'
  ///     is not negative; if it is, 'z2' is replaced with 'z1'.
  ///   - Finally, 'z2' is converted to a byte array with padding to match the length
  ///     of 'order' in octets. The output is a byte array suitable for cryptographic use.
  static List<int> bitsToOctetsWithOrderPadding(List<int> data, BigInt order) {
    BigInt z1 = bitsToBigIntWithLengthLimit(data, order.bitLength);
    BigInt z2 = z1 - order;
    if (z2 < BigInt.zero) {
      z2 = z1;
    }
    final bytes = bigintToBytesWithPadding(z2, order);
    return bytes;
  }

  /// Calculates the byte length required to represent a BigInt 'order'.
  ///
  /// The method converts 'order' to a hexadecimal string representation and
  /// calculates the byte length needed to store the corresponding value.
  ///
  /// Returns the number of bytes required to represent 'order'.
  ///
  static int orderLen(BigInt value) {
    String hexOrder = value.toRadixString(16);
    int byteLength = (hexOrder.length + 1) ~/ 2; // Calculate bytes needed
    return byteLength;
  }

  /// Calculates the modular multiplicative inverse of 'a' modulo 'm'.
  ///
  /// Returns the value 'x' such that (a * x) % m == 1, or 0 if 'a' has no inverse.
  ///
  static BigInt inverseMod(BigInt a, BigInt m) {
    if (a == BigInt.zero) {
      // 'a' has no inverse; return 0.
      return BigInt.zero;
    }
    if (a >= BigInt.one && a < m) {
      // If 'a' is in the range [1, m-1], use the built-in modInverse method.
      return a.modInverse(m);
    }

    BigInt lm = BigInt.one,
        hm = BigInt.zero; // Initialize low and high quotients.
    BigInt low = a % m, high = m; // Initialize low and high remainders.

    while (low > BigInt.one) {
      // Continue the Euclidean algorithm until 'low' becomes 1.
      BigInt r = high ~/ low;
      BigInt nm = hm - lm * r;
      BigInt newLow = high - low * r;
      hm = lm;
      high = low;
      lm = nm;
      low = newLow;
    }

    return lm % m;
  }

  /// Compute the Non-Adjacent Form (NAF) of a given integer.
  ///
  /// Parameters:
  /// - `mult`: The integer for which NAF is computed.
  ///
  /// Returns:
  /// - A list of BigInt values representing the NAF of the input integer.
  static List<BigInt> computeNAF(BigInt mult) {
    List<BigInt> nafList = [];

    while (mult != BigInt.zero) {
      if (mult.isOdd) {
        BigInt nafDigit = mult % BigInt.from(4);

        // Ensure that the NAF digit is within the range [-2, 2]
        if (nafDigit >= BigInt.two) {
          nafDigit -= BigInt.from(4);
        }

        nafList.add(nafDigit);
        mult -= nafDigit;
      } else {
        nafList.add(BigInt.zero);
      }

      mult ~/= BigInt.two;
    }

    return nafList;
  }

  /// Converts a BigInt value to a binary string with optional zero padding.
  ///
  /// This method converts a given BigInt value to its binary representation as a string.
  /// Optionally, you can specify the desired bit length by providing `zeroPadBitLen`. If provided,
  /// the method will pad the binary string with leading zeros to reach the specified bit length.
  ///
  /// Parameters:
  /// - `value`: The BigInt value to be converted to binary.
  /// - `zeroPadBitLen`: The desired bit length for the binary representation (optional).
  ///
  /// Returns:
  /// A binary string representation of the `value`, possibly zero-padded.
  ///
  /// Example:
  /// ```dart
  /// BigInt number = BigInt.parse('10');
  /// int bitLength = 8; // Desired bit length
  /// String binaryString = toBinary(number, bitLength);
  /// print('Binary representation: $binaryString');
  /// ```
  ///
  /// This method is useful for converting BigInt values to binary strings for various applications.
  ///
  static String toBinary(BigInt value, int zeroPadBitLen) {
    String binaryStr = value.toRadixString(2);
    if (zeroPadBitLen > 0) {
      return binaryStr.padLeft(zeroPadBitLen, '0');
    } else {
      return binaryStr;
    }
  }

  /// Divides a BigInt value by a specified radix and returns both the quotient and the remainder.
  ///
  /// This method divides a given BigInt value by a specified radix and returns a tuple containing
  /// the quotient and the remainder of the division.
  ///
  /// Parameters:
  /// - `value`: The BigInt value to be divided.
  /// - `radix`: The divisor, typically representing a base (e.g., 10 for base 10).
  ///
  /// Returns:
  /// A tuple of two BigInt values where the first element is the quotient, and the second element
  /// is the remainder of the division.
  ///
  /// Example:
  /// ```dart
  /// BigInt number = BigInt.parse('12345');
  /// int radix = 10; // Decimal base
  /// var result = divmod(number, radix);
  /// print('Quotient: ${result.item1}, Remainder: ${result.item2}');
  /// ```
  ///
  /// This method is useful for performing division and obtaining both the quotient and the remainder.
  ///
  static (BigInt, BigInt) divmod(BigInt value, int radix) {
    final div = value ~/ BigInt.from(radix);
    final mod = value % BigInt.from(radix);
    return (div, mod);
  }

  /// Converts a BigInt to a list of bytes with the specified byte order and optional length.
  ///
  /// This method converts a BigInt into a list of bytes, with the option to specify the
  /// desired byte order (Endian.big or Endian.little) and an optional length.
  ///
  /// Parameters:
  /// - `val`: The BigInt to be converted into bytes.
  /// - `length`: The optional length of the resulting byte list (in bytes).
  /// - `order`: The byte order (Endian) used for the byte representation.
  ///
  /// Returns:
  /// A list of bytes representing the BigInt value with the specified byte order and length.
  ///
  /// Example:
  /// ```dart
  /// BigInt number = BigInt.parse('123456789');
  /// List<int> bytes = toBytes(number, order: Endian.big, length: 4);
  /// ```
  ///
  /// This method is useful for encoding BigInt values into byte arrays with control over
  /// byte order and length.
  ///
  static List<int> toBytes(BigInt val,
      {int? length, Endian order = Endian.big}) {
    if (length == null) {
      String byteData =
          val.toRadixString(16).padLeft((val.bitLength / 4).ceil(), '0');
      if (byteData.length.isOdd) {
        byteData = "0$byteData"; // Add a leading "0" if the length is odd
      }
      List<int> byteList = <int>[];
      for (var i = 0; i < byteData.length; i += 2) {
        byteList.add(int.parse(byteData.substring(i, i + 2), radix: 16));
      }

      return List<int>.from(byteList);
    }
    if (length == 0) {
      return [];
    }

    final byteData = val.toRadixString(16).padLeft(length * 2, '0');
    List<int> byteList = <int>[];
    for (var i = 0; i < byteData.length; i += 2) {
      byteList.add(int.parse(byteData.substring(i, i + 2), radix: 16));
    }

    if (order == Endian.little) {
      byteList = byteList.reversed.toList();
    }
    assert(byteList.length == length);
    return List<int>.from(byteList);
  }

  /// Converts a list of bytes to a BigInt using the specified byte order.
  ///
  /// This method takes a list of bytes and converts it into a BigInt value,
  /// considering the specified byte order (Endian.big or Endian.little).
  ///
  /// Parameters:
  /// - `bytes`: The list of bytes to convert to a BigInt.
  /// - `byteOrder`: The byte order (Endian) used when interpreting the byte sequence.
  ///
  /// Returns:
  /// A BigInt representing the value of the provided byte sequence.
  ///
  /// Example:
  /// ```dart
  /// List<int> byteList = [0x12, 0x34, 0x56];
  /// BigInt result = fromBytes(byteList, byteOrder: Endian.big);
  /// ```
  ///
  /// This method is useful for decoding byte arrays into BigInt values with the desired byte order.
  ///
  static BigInt fromBytes(List<int> bytes, {Endian byteOrder = Endian.big}) {
    if (byteOrder == Endian.little) {
      bytes = List<int>.from(bytes.reversed.toList());
    }
    BigInt result = BigInt.from(0);
    for (int i = 0; i < bytes.length; i++) {
      /// Add each byte to the result, considering its position and byte order.
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }

    return result;
  }

  /// Converts a BigInt to a list of bytes with the specified length and endianness.
  ///
  /// This method takes a BigInt and converts it into a list of bytes, ensuring
  /// that the resulting byte list has the specified length and byte order.
  ///
  /// Parameters:
  /// - `dataInt`: The BigInt to convert to bytes.
  /// - `length`: The desired length of the byte list (in bytes). If not provided, it will be calculated.
  /// - `order`: The byte order (Endian) of the resulting byte list (Endian.big or Endian.little).
  ///
  /// Returns:
  /// A list of bytes representing the BigInt value.
  ///
  /// Throws:
  /// - [ArgumentError] if attempting to convert a negative BigInt to bytes.
  ///
  /// Example:
  /// ```dart
  /// BigInt value = BigInt.from(12345);
  /// List<int> bytes = toBytesLen(value, length: 2, order: Endian.big);
  /// ```
  ///
  /// This method is useful for converting BigInt values to byte arrays with specified properties.
  ///
  static List<int> toBytesLen(
    BigInt dataInt, {
    int? length,
    Endian order = Endian.big,
  }) {
    // Calculate the number of bytes needed to represent the BigInt
    length = length ?? (dataInt.bitLength + 7) ~/ 8;
    // Ensure the BigInt is non-negative
    if (dataInt.isNegative) {
      throw ArgumentError('Cannot convert negative BigInt to bytes');
    }

    List<int> byteList = [];

    for (int i = 0; i < length; i++) {
      final byte = dataInt.toUnsigned(8).toInt();
      byteList.add(byte);
      dataInt >>= 8;
    }

    if (order == Endian.little) {
      byteList = byteList.reversed.toList();
    }

    return byteList;
  }
}
