import 'dart:typed_data';
import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/string/string.dart';
import 'package:blockchain_utils/tuple/tuple.dart';
import 'package:blockchain_utils/numbers/int_utils.dart';

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

  static int bitlengthInBytes(BigInt value) {
    return (value.abs().bitLength + 7) ~/ 8;
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
  static Tuple<BigInt, BigInt> divmod(BigInt value, int radix) {
    final div = value ~/ BigInt.from(radix);
    final mod = value % BigInt.from(radix);
    return Tuple(div, mod);
  }

  /// Converts a BigInt to a list of bytes with the specified length and byte order.
  ///
  /// The [toBytes] method takes a BigInt [val], a required [length] parameter
  /// representing the desired length of the resulting byte list, and an optional [order]
  /// parameter (defaulting to big endian) specifying the byte order.
  ///
  /// If the BigInt is zero, a list filled with zeros of the specified length is returned.
  /// Otherwise, the method converts the BigInt to a byte list, considering the specified
  /// length and byte order.
  ///
  /// Example Usage:
  /// ```dart
  /// BigInt value = BigInt.from(16909060);
  /// List<int> byteList = BigIntUtils.toBytes(value, length: 4); // Result: [0x01, 0x02, 0x03, 0x04]
  /// ```
  ///
  /// Parameters:
  /// - [val]: The BigInt to be converted to a byte list.
  /// - [length]: The desired length of the resulting byte list.
  /// - [order]: The byte order to arrange the bytes in the resulting list (default is big endian).
  /// Returns: A list of bytes representing the BigInt with the specified length and byte order.
  static List<int> toBytes(BigInt val,
      {required int length, Endian order = Endian.big}) {
    if (val == BigInt.zero) {
      return List.filled(length, 0);
    }
    BigInt bigMaskEight = BigInt.from(0xff);
    List<int> byteList = List<int>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      byteList[length - i - 1] = (val & bigMaskEight).toInt();
      val = val >> 8;
    }

    if (order == Endian.little) {
      byteList = byteList.reversed.toList();
    }

    return List<int>.from(byteList);
  }

  /// Converts a list of bytes to a BigInt, considering the specified byte order.
  ///
  /// The [fromBytes] method takes a list of bytes and an optional [byteOrder] parameter
  /// (defaulting to big endian). It interprets the byte sequence as a non-negative integer,
  /// considering the byte order, and returns the corresponding BigInt representation.
  ///
  /// If the byte order is set to little endian, the input bytes are reversed before conversion.
  ///
  /// Example Usage:
  /// ```dart
  /// List<int> bytes = [0x01, 0x02, 0x03, 0x04];
  /// BigInt result = BigIntUtils.fromBytes(bytes); // Result: 16909060
  /// ```
  ///
  /// Parameters:
  /// - [bytes]: The list of bytes to be converted to a BigInt.
  /// - [byteOrder]: The byte order to interpret the byte sequence (default is big endian).
  /// Returns: The BigInt representation of the input byte sequence.
  static BigInt fromBytes(List<int> bytes,
      {Endian byteOrder = Endian.big, bool sign = false}) {
    if (byteOrder == Endian.little) {
      bytes = List<int>.from(bytes.reversed.toList());
    }
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      /// Add each byte to the result, considering its position and byte order.
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    if (result == BigInt.zero) return BigInt.zero;
    if (sign && (bytes[0] & 0x80) != 0) {
      final bitLength = bitlengthInBytes(result) * 8;
      return result.toSigned(bitLength);
    }

    return result;
  }

  /// Converts a list of BigInt values to DER-encoded bytes.
  ///
  /// The [toDer] method takes a list of BigInt values [bigIntList] and encodes them in DER format.
  /// It returns a list of bytes representing the DER-encoded sequence of integers.
  ///
  /// Example Usage:
  /// ```dart
  /// List<BigInt> values = [BigInt.from(123), BigInt.from(456)];
  /// List<int> derBytes = DEREncoding.toDer(values);
  /// ```
  ///
  /// Parameters:
  /// - [bigIntList]: The list of BigInt values to be DER-encoded.
  /// Returns: A list of bytes representing the DER-encoded sequence of integers.
  static List<int> toDer(List<BigInt> bigIntList) {
    List<List<int>> encodedIntegers = bigIntList.map((bi) {
      List<int> bytes = _encodeInteger(bi);
      return bytes;
    }).toList();

    List<int> lengthBytes =
        _encodeLength(encodedIntegers.fold<int>(0, (sum, e) => sum + e.length));
    List<int> contentBytes =
        encodedIntegers.fold<List<int>>([], (prev, e) => [...prev, ...e]);
    _encodeLength(200);
    var derBytes = [
      0x30, ...lengthBytes,

      /// DER SEQUENCE tag and length
      ...contentBytes,
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

    List<int> s = BigintUtils.toBytes(r, length: BigintUtils.orderLen(r));

    int num = s[0];
    if (num <= 0x7F) {
      return [0x02, ..._encodeLength(s.length), ...s];
    } else {
      /// DER integers are two's complement, so if the first byte is
      /// 0x80-0xff then we need an extra 0x00 byte to prevent it from
      /// looking negative.
      return [0x02, ..._encodeLength(s.length + 1), 0x00, ...s];
    }
  }

  /// Parses a dynamic value [v] into a BigInt.
  ///
  /// Tries to convert the dynamic value [v] into a BigInt. It supports parsing
  /// from BigInt, int, List<int>, and String types. If [v] is a String and
  /// represents a hexadecimal number (prefixed with '0x' or not), it is parsed
  /// accordingly.
  ///
  /// Parameters:
  /// - [v]: The dynamic value to be parsed into a BigInt.
  ///
  /// Returns:
  /// - A BigInt representation of the parsed value.
  ///
  /// Throws:
  /// - [ArgumentException] if the input value cannot be parsed into a BigInt.
  ///
  static BigInt parse(dynamic v) {
    try {
      if (v is BigInt) return v;
      if (v is int) return BigInt.from(v);
      if (v is List<int>) {
        return fromBytes(v, sign: true);
      }
      if (v is String) {
        BigInt? parse = BigInt.tryParse(v);
        if (parse == null && StringUtils.ixHexaDecimalNumber(v)) {
          parse = BigInt.parse(StringUtils.strip0x(v), radix: 16);
        }
        return parse!;
      }
      // ignore: empty_catches
    } catch (e) {}
    throw ArgumentException("invalid input for parse bigint");
  }

  /// Tries to parse a dynamic value [v] into a BigInt, returning null if parsing fails.
  ///
  /// Attempts to parse the dynamic value [v] into a BigInt using the [parse] method.
  /// If successful, returns the resulting BigInt; otherwise, returns null.
  ///
  /// Parameters:
  /// - [v]: The dynamic value to be parsed into a BigInt.
  ///
  /// Returns:
  /// - A BigInt if parsing is successful; otherwise, returns null.
  ///
  static BigInt? tryParse(dynamic v) {
    try {
      return parse(v);
    } on ArgumentException {
      return null;
    }
  }

  static List<int> variableNatEncode(BigInt val) {
    BigInt num = val & BigInt.from(mask32);
    List<int> output = [(num & BigInt.from(0xFF)).toInt() & 0x7F];
    num ~/= BigInt.from(128);
    while (num > BigInt.zero) {
      output.add(((num & BigInt.from(0xFF)).toInt() & 0x7F) | 0x80);
      num ~/= BigInt.from(128);
    }
    output = output.reversed.toList();
    return output;
  }

  static Tuple<BigInt, int> variableNatDecode(List<int> bytes) {
    BigInt output = BigInt.zero;
    int bytesRead = 0;
    for (int byte in bytes) {
      output = (output << 7) | BigInt.from(byte & 0x7F);
      if (output > maxU64) {
        throw MessageException(
            "The variable size exceeds the limit for Nat Decode");
      }
      bytesRead++;
      if ((byte & 0x80) == 0) {
        return Tuple(output, bytesRead);
      }
    }
    throw MessageException("Nat Decode failed.");
  }
}
