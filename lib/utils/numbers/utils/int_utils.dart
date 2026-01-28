import 'dart:typed_data';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'dart:math' as math;

/// Utility class for integer-related operations and conversions.
class IntUtils {
  /// Decodes a variable-length byte array into an integer value according to Bitcoin's variable-length integer encoding scheme.
  static (int, int) decodeVarint(List<int> byteint) {
    final int ni = byteint[0];
    int size = 0;

    if (ni < 253) {
      return (ni, 1);
    }

    if (ni == 253) {
      size = 2;
    } else if (ni == 254) {
      size = 4;
    } else {
      size = 8;
    }

    final BigInt value = BigintUtils.fromBytes(
      byteint.sublist(1, 1 + size),
      byteOrder: Endian.little,
    );
    if (!value.isValidInt) {
      throw ArgumentException.invalidOperationArguments(
        "decodeVarint",
        name: "byteint",
        reason: "Unable to read variable-length in this environment.",
      );
    }
    return (value.toInt(), size + 1);
  }

  /// Encodes an integer into a variable-length byte array according to Bitcoin's variable-length integer encoding scheme.
  static List<int> encodeVarint(int value) {
    if (value < 253) {
      return [value];
    } else if (value < 0x10000) {
      final bytes = List<int>.filled(3, 0);
      bytes[0] = 0xfd;
      BinaryOps.writeUint16LE(value, bytes, 1);
      return bytes;
    } else if (value < 0x100000000) {
      final bytes = List<int>.filled(5, 0);
      bytes[0] = 0xfe;
      BinaryOps.writeUint32LE(value, bytes, 1);
      return bytes;
    } else {
      throw ArgumentException.invalidOperationArguments(
        "encodeVarint",
        name: "byteint",
        reason: "Value is to large.",
      );
    }
  }

  /// Prepends a variable-length integer encoding of the given data length to the provided data.
  static List<int> prependVarint(List<int> data) {
    final varintBytes = encodeVarint(data.length);
    return [...varintBytes, ...data];
  }

  /// Calculates the number of bytes required to represent the bit length of an integer value.
  static int bitlengthInBytes(int val) {
    int bitlength = val.bitLength;
    if (bitlength == 0) return 1;
    if (val.isNegative) {
      bitlength += 1;
    }
    return (bitlength + 7) ~/ 8;
  }

  /// Converts an integer to a byte list with the specified length and endianness.
  static List<int> toBytes(
    int val, {
    int? length,
    Endian byteOrder = Endian.big,
  }) {
    length ??= bitlengthInBytes(val);
    assert(length <= 8);
    if (length > 4) {
      final int lowerPart = val & BinaryOps.mask32;
      final int upperPart = (val >> 32) & BinaryOps.mask32;

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
      byteList[length - i - 1] = val & BinaryOps.mask8;
      val = val >> 8;
    }

    if (byteOrder == Endian.little) {
      return byteList.reversed.toList();
    }

    return byteList;
  }

  static List<bool> toBinaryBool(int value, {int? bitLength}) {
    bitLength ??= bitlengthInBytes(value) * 8;
    // Make sure we have exactly 64 bits
    final bits = List<bool>.filled(bitLength, false);

    for (int i = 0; i < bitLength; i++) {
      // Check if the i-th bit is set
      bits[i] = value & (1 << i) != 0;
    }
    return bits;
  }

  /// Converts a list of bytes to an integer, following the specified byte order.
  static int fromBytes(
    List<int> bytes, {
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    if (bytes.length > 6) {
      final big = BigintUtils.fromBytes(
        bytes,
        byteOrder: byteOrder,
        sign: sign,
      );
      if (big.isValidInt) {
        return big.toInt();
      }
      throw ArgumentException.invalidOperationArguments(
        "fromBytes",
        name: "byteint",
        reason: "Value too large to fit in a Dart int.",
      );
    }
    if (byteOrder == Endian.little) {
      bytes = bytes.reversed.toList();
    }
    int result = 0;
    if (bytes.length > 4) {
      final int lowerPart = fromBytes(
        bytes.sublist(bytes.length - 4, bytes.length),
      );
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

  /// Parses a dynamic value [number] into an integer.
  static int parse(dynamic number, {bool allowHex = true}) {
    if (number is int) return number;
    if (number is BigInt) {
      if (number.isValidInt) {
        return number.toInt();
      }
    } else if (number is String) {
      int? parse = int.tryParse(number);
      if (parse == null && allowHex) {
        parse = int.tryParse(StringUtils.strip0x(number), radix: 16);
      }
      if (parse != null) return parse;
    }
    throw ArgumentException.invalidOperationArguments(
      "parse",
      name: "number",
      reason: "Failed to parse value as int.",
    );
  }

  /// Tries to parse a dynamic value [number] into an integer, returning null if parsing fails.
  static int? tryParse(dynamic number, {bool allowHex = true}) {
    if (number == null) return null;
    try {
      return parse(number, allowHex: allowHex);
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

  static int ctSelectInt(int a, int b, bool choice) {
    final mask = choice ? -1 : 0; // 0 or -1
    final s = a ^ (mask & (a ^ b));
    assert(s == a || s == b);
    return s;
  }

  static bool ctSelectBool(bool a, bool b, bool choice) {
    final ai = a ? 1 : 0;
    final bi = b ? 1 : 0;
    final mask = choice ? -1 : 0; // 0 or -1
    final si = ai ^ (mask & (ai ^ bi));
    return si != 0;
  }
}
