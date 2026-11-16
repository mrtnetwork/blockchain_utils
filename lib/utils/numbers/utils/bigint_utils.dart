import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class BigintUtils {
  /// Returns the larger of [a] and [b].
  static BigInt max(BigInt a, BigInt b) {
    return a.compareTo(b) > 0 ? a : b;
  }

  /// Minimum number of bytes needed to represent [value].
  /// Pass `sign: true` to reserve room for the sign bit (two's-complement
  /// encoding) — required for negative values, and also affects positive
  /// values whose top bit would otherwise be misread as a sign bit.
  static int bitlengthInBytes(BigInt value, {bool sign = false}) {
    if (value.isNegative && !sign) {
      throw CoreErrors.invalidOperationArguments(
        'bitlengthInBytes',
        name: 'value',
        reason: 'Negative value requires sign: true.',
      );
    }
    int bits = value.bitLength;
    if (sign) bits += 1; // reserve the sign bit for positive and negative alike
    if (bits == 0) return 1; // value == 0
    return (bits + 7) ~/ 8;
  }

  /// Calculates the modular multiplicative inverse of [a] modulo [m].
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

  /// Expands [value] into individual bits, LSB first.
  static List<bool> toBinaryBool(BigInt value, {int? bitLength}) {
    bitLength ??= bitlengthInBytes(value) * 8;
    final bits = List<bool>.filled(bitLength, false);

    for (int i = 0; i < bitLength; i++) {
      bits[i] = value & (BigInt.one << i) != BigInt.zero;
    }
    return bits;
  }

  /// Divides [value] by [radix], returning (quotient, remainder).
  static (BigInt, BigInt) divmod(BigInt value, int radix) {
    final div = value ~/ BigInt.from(radix);
    final mod = value % BigInt.from(radix);
    return (div, mod);
  }

  /// Converts a BigInt to a byte list with the given length and byte order.
  /// Pass [sign] = true to encode negative values as two's complement.
  static BuBytes toBytes(
    BigInt val, {
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    if (val.isNegative && !sign) {
      throw CoreErrors.invalidOperationArguments(
        'toBytes',
        name: 'val',
        reason: 'Negative value requires sign: true.',
      );
    }

    // Size the encoding against the magnitude, using the same `sign`
    // convention that will actually be used to encode.
    length ??= bitlengthInBytes(
      val.isNegative ? (-val - BigInt.one) : val,
      sign: sign,
    );

    BigInt unsigned = val;
    if (val.isNegative) {
      // Two's complement over `length` bytes: (2^(8*length) + val).
      unsigned = (BigInt.one << (length * 8)) + val;
    }

    if (unsigned.bitLength > length * 8) {
      throw CoreErrors.invalidOperationArguments(
        'toBytes',
        name: 'length',
        reason: 'Value does not fit in $length byte(s).',
      );
    }

    final byteList = BuBytes.zero(length);
    for (var i = 0; i < length; i++) {
      byteList[length - i - 1] = (unsigned & BinaryOps.maskBig8).toInt();
      unsigned >>= 8;
    }

    return byteOrder == Endian.little ? byteList.reverse() : byteList;
  }

  /// Converts a list of bytes to a BigInt, considering byte order and sign.
  ///
  /// [offset] specifies the starting index within [bytes] to read from.
  /// [length] specifies how many bytes to read (defaults to the rest of the list).
  static BigInt fromBytes(
    List<int> bytes, {
    int offset = 0,
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    final int len = length ?? (bytes.length - offset);

    if (offset < 0 || len < 0 || offset + len > bytes.length) {
      throw CoreErrors.invalidOperationArguments(
        'fromBytes',
        name: 'offset',
        reason:
            'Invalid offset/length: offset=$offset, length=$len, bytes.length=${bytes.length}.',
      );
    }

    if (len == 0) return BigInt.zero;
    final BigInt byte256 = BigInt.from(256);

    BigInt result = BigInt.zero;
    int firstByte;

    if (byteOrder == Endian.little) {
      // Most significant byte is the last one in the range; walk backwards
      // from there without ever materializing a reversed copy.
      firstByte = bytes[offset + len - 1];
      for (var i = offset + len - 1; i >= offset; i--) {
        result = result * byte256 + BigInt.from(bytes[i]);
      }
    } else {
      firstByte = bytes[offset];
      for (var i = offset; i < offset + len; i++) {
        result = result * byte256 + BigInt.from(bytes[i]);
      }
    }

    if (sign && (firstByte & 0x80) != 0) {
      result -= BigInt.one << (len * 8);
    }

    return result;
  }

  static BigInt fromBytes8(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 1, 'fromBytes8', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 1,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static BigInt fromBytes16(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 2, 'fromBytes16', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 2,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static BigInt fromBytes32(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 4, 'fromBytes32', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 4,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static BigInt fromBytes64(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 8, 'fromBytes64', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 8,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static BigInt fromBytes128(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 16, 'fromBytes128', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 16,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static BigInt fromBytes256(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 32, 'fromBytes256', offset: offset);
    return fromBytes(
      bytes,
      offset: offset,
      length: 32,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  static void _checkLength(
    List<int> bytes,
    int expected,
    String method, {
    int offset = 0,
  }) {
    if (offset < 0 || offset > bytes.length) {
      throw CoreErrors.invalidOperationArguments(
        method,
        name: 'offset',
        reason:
            'Offset $offset is out of range for a list of length ${bytes.length}.',
      );
    }
    final available = bytes.length - offset;
    if (available < expected) {
      throw CoreErrors.invalidOperationArguments(
        method,
        name: 'bytes',
        reason:
            'Expected at least $expected byte(s) starting at offset $offset, got $available.',
      );
    }
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
    throw CoreErrors.invalidOperationArguments(
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
    } on BuError catch (e) {
      if (e.type != DefaultErrorType.invalidArgument) rethrow;
      return null;
    }
  }

  /// LEB128-style variable-length encoding of a non-negative [val].
  static BuBytes variableNatEncode(BigInt val) {
    if (val.isNegative) {
      throw CoreErrors.invalidOperationArguments(
        "variableNatEncode",
        name: "val",
        reason: "Negative value cannot be nat-encoded.",
      );
    }
    BigInt num = val;
    List<int> output = [(num & BinaryOps.maskBig8).toInt() & 0x7F];
    num ~/= BigInt.from(128);
    while (num > BigInt.zero) {
      output.add(((num & BinaryOps.maskBig8).toInt() & 0x7F) | 0x80);
      num ~/= BigInt.from(128);
    }
    output = output.reversed.toList();
    return BuBytes(output);
  }

  /// Decodes a value encoded by [variableNatEncode], returning (value, bytesRead).
  static (BigInt, int) variableNatDecode(List<int> bytes) {
    BigInt output = BigInt.zero;
    int bytesRead = 0;
    for (final byte in bytes) {
      output = (output << 7) | BigInt.from(byte & 0x7F);
      if (output > BinaryOps.maxU64) {
        throw CoreErrors.invalidOperationArguments(
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
    throw CoreErrors.invalidOperationArguments(
      "variableNatDecode",
      name: "bytes",
      reason: "Invalid nat encode bytes.",
    );
  }

  /// Splits a 256-bit unsigned [number] into four 64-bit limbs.
  static List<BigInt> splitU256ToU64Parts(
    BigInt number, {
    Endian order = Endian.big,
  }) {
    if (number.isNegative || number.bitLength > 256) {
      if (number.isNegative) {
        throw CoreErrors.invalidOperationArguments(
          "splitU256ToU64Parts",
          name: "number",
          reason: "Invalid unsigned integer.",
        );
      }
      throw CoreErrors.invalidOperationArguments(
        "splitU256ToU64Parts",
        name: "number",
        reason: "Number is too large.",
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

  /// Reassembles a 256-bit value from four 64-bit limbs (see [splitU256ToU64Parts]).
  static BigInt combineU256FromU64Parts(
    List<BigInt> parts, {
    Endian order = Endian.big,
  }) {
    if (parts.length != 4) {
      throw CoreErrors.invalidOperationArguments(
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

  /// Branchless select: returns [b] if [choice] else [a].
  static BigInt ctSelectBigInt(BigInt a, BigInt b, bool choice) {
    final mask = choice ? BigInt.from(-1) : BigInt.zero; // 0 or -1
    final s = a ^ (mask & (a ^ b));
    assert(s == a || s == b);
    return s;
  }

  /// Add-with-carry: `a + b + carry`, returning [sumLow, carryHigh].
  static List<BigInt> adc(BigInt a, BigInt b, BigInt carry) {
    final BigInt sum = a + b + carry;
    assert(sum <= BinaryOps.maxU128);

    final BigInt low = sum.toU64;
    final BigInt high = (sum >> 64);
    assert(high <= BinaryOps.maxU64);
    return [low, high];
  }

  /// Subtract-with-borrow: `a - b - borrow`, returning [diffLow, diffHigh].
  static List<BigInt> sbb(BigInt a, BigInt b, BigInt borrow) {
    final s = b + (borrow >> 63);
    assert(s <= BinaryOps.maxU128);
    BigInt diff = (a - s);

    BigInt low = diff.toU64;
    BigInt high = (diff >> 64).toU64;
    return [low, high];
  }

  /// Multiply-accumulate: `a + b*c + carry`, returning [resultLow, resultHigh].
  static List<BigInt> mac(BigInt a, BigInt b, BigInt c, BigInt carry) {
    final BigInt prod = a + (b * c) + carry;
    assert(prod <= BinaryOps.maxU128);
    final BigInt low = prod.toU64;
    final BigInt high = prod >> 64;
    assert(high <= BinaryOps.maxU64);
    return [low, high];
  }
}
