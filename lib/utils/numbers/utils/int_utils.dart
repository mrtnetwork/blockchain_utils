import 'dart:typed_data';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/utils/tuple/tuple.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'dart:math' as math;

/// Utility class for integer-related operations and conversions.
class IntUtils {
  /// Decodes a variable-length byte array into an integer value according to Bitcoin's variable-length integer encoding scheme.
  ///
  /// [byteint] The list of bytes representing the encoded variable-length integer.
  /// Returns a tuple containing the decoded integer value and the number of bytes consumed from the input.
  ///
  /// If the first byte is less than 253, a single byte is used, returning the value and consuming 1 byte.
  /// If the first byte is 253, a 2-byte encoding is used, returning the value and consuming 2 bytes.
  /// If the first byte is 254, a 4-byte encoding is used, returning the value and consuming 4 bytes.
  /// If the first byte is 255, an 8-byte encoding is used, returning the value and consuming 8 bytes.
  ///
  /// Throws a MessageException if the decoded value cannot fit into an integer in the current environment.
  static Tuple<int, int> decodeVarint(List<int> byteint) {
    final int ni = byteint[0];
    int size = 0;

    if (ni < 253) {
      return Tuple(ni, 1);
    }

    if (ni == 253) {
      size = 2;
    } else if (ni == 254) {
      size = 4;
    } else {
      size = 8;
    }

    final BigInt value = BigintUtils.fromBytes(byteint.sublist(1, 1 + size),
        byteOrder: Endian.little);
    if (!value.isValidInt) {
      throw const MessageException(
          "cannot read variable-length in this environment");
    }
    return Tuple(value.toInt(), size + 1);
  }

  /// Encodes an integer into a variable-length byte array according to Bitcoin's variable-length integer encoding scheme.
  ///
  /// [i] The integer to be encoded.
  /// Returns a list of bytes representing the encoded variable-length integer.
  ///
  /// If the integer is less than 253, a single byte is used.
  /// If the integer is less than 0x10000, a 3-byte encoding is used with the first byte set to 0xfd.
  /// If the integer is less than 0x100000000, a 5-byte encoding is used with the first byte set to 0xfe.
  /// For integers larger than or equal to 0x100000000, an ArgumentException is thrown since they are not supported in Bitcoin's encoding.
  static List<int> encodeVarint(int i) {
    if (i < 253) {
      return [i];
    } else if (i < 0x10000) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      writeUint16LE(i, bytes, 1);
      return bytes;
    } else if (i < 0x100000000) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      writeUint32LE(i, bytes, 1);
      return bytes;
    } else {
      throw ArgumentException("Integer is too large: $i");
    }
  }

  /// Prepends a variable-length integer encoding of the given data length to the provided data.
  ///
  /// [data] The list of bytes representing the data.
  /// Returns a new list of bytes with the variable-length integer encoding prepended to the data.
  static List<int> prependVarint(List<int> data) {
    final varintBytes = encodeVarint(data.length);
    return [...varintBytes, ...data];
  }

  /// Calculates the number of bytes required to represent the bit length of an integer value.
  ///
  /// [val] The integer value for which to calculate the bit length in bytes.
  /// Returns the number of bytes required to represent the bit length of the integer value.
  static int bitlengthInBytes(int val) {
    int bitlength = val.bitLength;
    if (bitlength == 0) return 1;
    if (val.isNegative) {
      bitlength += 1;
    }
    return (bitlength + 7) ~/ 8;
  }

  /// Converts an integer to a byte list with the specified length and endianness.
  ///
  /// If the [length] is not provided, it is calculated based on the bit length
  /// of the integer, ensuring minimal byte usage. The [byteOrder] determines
  /// whether the most significant bytes are at the beginning (big-endian) or end
  /// (little-endian) of the resulting byte list.
  static List<int> toBytes(int val,
      {required int length, Endian byteOrder = Endian.big}) {
    assert(length <= 8);
    if (length > 4) {
      final int lowerPart = val & mask32;
      final int upperPart = (val >> 32) & mask32;

      final bytes = [
        ...toBytes(upperPart, length: length - 4),
        ...toBytes(lowerPart, length: 4),
      ];
      if (byteOrder == Endian.little) {
        return bytes.reversed.toList();
      }
      return bytes;
    }
    final List<int> byteList = List<int>.filled(length, 0);

    for (var i = 0; i < length; i++) {
      byteList[length - i - 1] = val & mask8;
      val = val >> 8;
    }

    if (byteOrder == Endian.little) {
      return byteList.reversed.toList();
    }

    return byteList;
  }

  /// Converts a list of bytes to an integer, following the specified byte order.
  ///
  /// [bytes] The list of bytes representing the integer value.
  /// [byteOrder] The byte order, defaults to Endian.big.
  /// Returns the corresponding integer value.
  static int fromBytes(List<int> bytes,
      {Endian byteOrder = Endian.big, bool sign = false}) {
    assert(bytes.length <= 8);
    if (byteOrder == Endian.little) {
      bytes = List<int>.from(bytes.reversed.toList());
    }
    int result = 0;
    if (bytes.length > 4) {
      final int lowerPart =
          fromBytes(bytes.sublist(bytes.length - 4, bytes.length));
      final int upperPart = fromBytes(bytes.sublist(0, bytes.length - 4));
      result = (upperPart << 32) | lowerPart;
    } else {
      for (var i = 0; i < bytes.length; i++) {
        result |= (bytes[bytes.length - i - 1] << (8 * i));
      }
    }

    if (sign && (bytes[0] & 0x80) != 0) {
      return result.toSigned(bitlengthInBytes(result) * 8);
    }

    return result;
  }

  /// Parses a dynamic value [v] into an integer.
  ///
  /// Tries to convert the dynamic value [v] into an integer. It supports parsing
  /// from int, BigInt, `List<int>`, and String types. If [v] is a String and
  /// represents a hexadecimal number (prefixed with '0x' or not), it is parsed
  /// accordingly.
  ///
  /// Parameters:
  /// - [v]: The dynamic value to be parsed into an integer.
  ///
  /// Returns:
  /// - An integer representation of the parsed value.
  ///
  static int parse(dynamic v) {
    try {
      if (v is int) return v;
      if (v is BigInt) return v.toInt();
      if (v is List<int>) {
        return fromBytes(v, sign: true);
      }
      if (v is String) {
        int? parse = int.tryParse(v);
        if (parse == null && StringUtils.ixHexaDecimalNumber(v)) {
          parse = int.parse(StringUtils.strip0x(v), radix: 16);
        }
        return parse!;
      }
    } catch (_) {}
    throw const ArgumentException("invalid input for parse int");
  }

  /// Tries to parse a dynamic value [v] into an integer, returning null if parsing fails.
  ///
  /// If the input value [v] is null, directly returns null. Otherwise, attempts to
  /// parse the dynamic value [v] into an integer using the [parse] method.
  /// If successful, returns the resulting integer; otherwise, returns null.
  ///
  /// Parameters:
  /// - [v]: The dynamic value to be parsed into an integer.
  ///
  /// Returns:
  /// - An integer if parsing is successful; otherwise, returns null.
  ///
  static int? tryParse(dynamic v) {
    if (v == null) return null;
    try {
      return parse(v);
    } on ArgumentException {
      return null;
    }
  }

  static double sqrt(num x) => math.sqrt(x);
  static double log(num x) => math.log(x);
  static double cos(num x) => math.cos(x);
  static double exp(num x) => math.exp(x);
  static num pow(num x, num exponent) => math.pow(x, exponent);
  static double get pi => math.pi;
  static int max(int a, int b) {
    if (a > b) return a;
    return b;
  }

  static int min(int a, int b) {
    if (a > b) return b;
    return a;
  }
}
