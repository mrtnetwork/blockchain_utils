import 'dart:typed_data';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class BigintUtils {
  static BigInt max(BigInt a, BigInt b) {
    return a.compareTo(b) > 0 ? a : b;
  }

  static int bitlengthInBytes(BigInt value) {
    int bitlength = value.bitLength;
    if (bitlength == 0) return 1;
    if (value.isNegative) {
      bitlength++;
    }
    return (bitlength + 7) ~/ 8;
  }

  /// Calculates the modular multiplicative inverse of 'a' modulo 'm'.
  static BigInt inverseMod(BigInt a, BigInt m) {
    if (a == BigInt.zero) {
      // 'a' has no inverse; return 0.
      return BigInt.zero;
    }
    if (a >= BigInt.one && a < m) {
      // If 'a' is in the range [1, m-1], use the built-in modInverse method.
      return a.modInverse(m);
    }

    BigInt lm = BigInt.one, hm = BigInt.zero;
    BigInt low = a % m, high = m;

    while (low > BigInt.one) {
      // Continue the Euclidean algorithm until 'low' becomes 1.
      final BigInt r = high ~/ low;
      final BigInt nm = hm - lm * r;
      final BigInt newLow = high - low * r;
      hm = lm;
      high = low;
      lm = nm;
      low = newLow;
    }

    return lm % m;
  }

  /// Converts a BigInt value to a binary string with optional zero padding.
  static String toBinary(BigInt value, {int zeroPadBitLen = 0}) {
    final String binaryStr = value.toRadixString(2);
    if (zeroPadBitLen > 0) {
      return binaryStr.padLeft(zeroPadBitLen, '0');
    } else {
      return binaryStr;
    }
  }

  static List<bool> toBinaryBool(BigInt value, {int? bitLength}) {
    bitLength ??= bitlengthInBytes(value) * 8;
    // Make sure we have exactly 64 bits
    final bits = List<bool>.filled(bitLength, false);

    for (int i = 0; i < bitLength; i++) {
      // Check if the i-th bit is set
      bits[i] = value & (BigInt.one << i) != BigInt.zero;
    }
    return bits;
  }

  /// Divides a BigInt value by a specified radix and returns both the quotient and the remainder.
  static (BigInt, BigInt) divmod(BigInt value, int radix) {
    final div = value ~/ BigInt.from(radix);
    final mod = value % BigInt.from(radix);
    return (div, mod);
  }

  /// Converts a BigInt to a list of bytes with the specified length and byte order.
  static List<int> toBytes(
    BigInt val, {
    int? length,
    Endian order = Endian.big,
  }) {
    length ??= bitlengthInBytes(val);
    if (val == BigInt.zero) {
      return List.filled(length, 0, growable: true);
    }
    List<int> byteList = List<int>.filled(length, 0, growable: true);
    for (var i = 0; i < length; i++) {
      byteList[length - i - 1] = (val & BinaryOps.maskBig8).toInt();
      val = val >> 8;
    }

    if (order == Endian.little) {
      byteList = byteList.reversed.toList();
    }

    return byteList;
  }

  /// Converts a list of bytes to a BigInt, considering the specified byte order.
  static BigInt fromBytes(
    List<int> bytes, {
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    if (byteOrder == Endian.little) {
      bytes = bytes.reversed.toList();
    }
    BigInt result = BigInt.zero;
    for (int i = 0; i < bytes.length; i++) {
      result += BigInt.from(bytes[bytes.length - i - 1]) << (8 * i);
    }
    if (result == BigInt.zero) return result;
    if (sign && (bytes[0] & 0x80) != 0) {
      return result.toSigned(bitlengthInBytes(result) * 8);
    }

    return result;
  }

  /// Parses a dynamic value [number] into a BigInt.
  ///
  /// Throws:
  /// - [ArgumentException] if the input value cannot be parsed into a BigInt.
  ///
  static BigInt parse(dynamic number, {bool allowHex = true}) {
    if (number is BigInt) return number;
    if (number is int) return BigInt.from(number);
    if (number is String) {
      BigInt? parse = BigInt.tryParse(number);
      if (parse == null && allowHex) {
        parse = BigInt.tryParse(StringUtils.strip0x(number), radix: 16);
      }
      if (parse != null) return parse;
    }
    throw ArgumentException.invalidOperationArguments(
      "parse",
      name: "number",
      reason: "Failed to parse value as BigInt",
    );
  }

  /// Tries to parse a dynamic value [number] into a BigInt, returning null if parsing fails.
  static BigInt? tryParse(dynamic number, {bool allowHex = true}) {
    if (number == null) return null;
    try {
      return parse(number, allowHex: allowHex);
    } on ArgumentException {
      return null;
    }
  }

  static List<int> variableNatEncode(BigInt val) {
    BigInt num = val & BinaryOps.maskBig32;
    List<int> output = [(num & BinaryOps.maskBig8).toInt() & 0x7F];
    num ~/= BigInt.from(128);
    while (num > BigInt.zero) {
      output.add(((num & BinaryOps.maskBig8).toInt() & 0x7F) | 0x80);
      num ~/= BigInt.from(128);
    }
    output = output.reversed.toList();
    return output;
  }

  static (BigInt, int) variableNatDecode(List<int> bytes) {
    BigInt output = BigInt.zero;
    int bytesRead = 0;
    for (final byte in bytes) {
      output = (output << 7) | BigInt.from(byte & 0x7F);
      if (output > BinaryOps.maxU64) {
        throw ArgumentException.invalidOperationArguments(
          "variableNatDecode",
          name: "bytes",
          reason: "The variable size exceeds the limit for nat decode.",
        );
      }
      bytesRead++;
      if ((byte & 0x80) == 0) {
        return (output, bytesRead);
      }
    }
    throw ArgumentException.invalidOperationArguments(
      "variableNatDecode",
      name: "bytes",
      reason: "Invalid nat encode bytes.",
    );
  }

  static List<BigInt> splitU256ToU64Parts(
    BigInt number, {
    Endian order = Endian.big,
  }) {
    if (number.isNegative || number.bitLength > 256) {
      if (number.isNegative) {
        throw ArgumentException.invalidOperationArguments(
          "splitU256ToU64Parts",
          name: "number",
          reason: "Invalid unsigned integer.",
        );
      }
      throw ArgumentException.invalidOperationArguments(
        "splitU256ToU64Parts",
        name: "number",
        reason: "Number is to large.",
      );
    }

    final BigInt hiHi = (number >> 192).toUnsigned(64);
    final BigInt hiLo = (number >> 128).toUnsigned(64);
    final BigInt loHi = (number >> 64).toUnsigned(64);
    final BigInt loLo = number.toUnsigned(64);

    // Return order depends on Endian type
    if (order == Endian.little) {
      // Matches Rust/Substrate `[u64;4]` layout (little-endian)
      return [loLo, loHi, hiLo, hiHi];
    } else {
      // Big-endian (most significant first)
      return [hiHi, hiLo, loHi, loLo];
    }
  }

  static BigInt combineU256FromU64Parts(
    List<BigInt> parts, {
    Endian order = Endian.big,
  }) {
    if (parts.length != 4) {
      throw ArgumentException.invalidOperationArguments(
        "combineU256FromU64Parts",
        name: "number",
        reason: "Invalid parts length.",
      );
    }

    BigInt result = BigInt.zero;

    if (order == Endian.little) {
      // Little-endian: [loLo, loHi, hiLo, hiHi]
      result =
          (parts[3] << 192) | (parts[2] << 128) | (parts[1] << 64) | parts[0];
    } else {
      // Big-endian: [hiHi, hiLo, loHi, loLo]
      result =
          (parts[0] << 192) | (parts[1] << 128) | (parts[2] << 64) | parts[3];
    }

    return result;
  }

  static BigInt ctSelectBigInt(BigInt a, BigInt b, bool choice) {
    final mask = choice ? BigInt.from(-1) : BigInt.zero; // 0 or -1
    final s = a ^ (mask & (a ^ b));
    assert(s == a || s == b);
    return s;
  }

  // /// Add With Carry: returns (sumLow, carryHigh)
  static List<BigInt> adc(BigInt a, BigInt b, BigInt carry) {
    final BigInt sum = a + b + carry;
    assert(sum <= BinaryOps.maxU128);

    final BigInt low = sum.toU64;
    final BigInt high = (sum >> 64);
    assert(high <= BinaryOps.maxU64);
    return [low, high];
  }

  static List<BigInt> sbb(BigInt a, BigInt b, BigInt borrow) {
    final s = b + (borrow >> 63);
    assert(s <= BinaryOps.maxU128);
    BigInt diff = (a - s);

    BigInt low = diff.toU64;
    BigInt high = (diff >> 64).toU64;
    return [low, high];
  }

  static List<BigInt> mac(BigInt a, BigInt b, BigInt c, BigInt carry) {
    final BigInt prod = a + (b * c) + carry;
    assert(prod <= BinaryOps.maxU128);
    final BigInt low = prod.toU64;
    final BigInt high = prod >> 64;
    assert(high <= BinaryOps.maxU64);
    return [low, high];
  }
}
