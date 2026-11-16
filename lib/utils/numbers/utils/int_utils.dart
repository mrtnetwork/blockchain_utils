import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
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
    if (!value.isSafeInt()) {
      throw CoreErrors.invalidOperationArguments(
        "decodeVarint",
        name: "byteint",
        reason: "Unable to read variable-length in this environment.",
      );
    }
    return (value.toInt(), size + 1);
  }

  static BuBytes encodeVarint(int value) {
    if (value < 253) {
      return BuBytes([value]);
    } else if (value < 0x10000) {
      final bytes = BuBytes.zero(3);
      bytes[0] = 0xfd;
      BinaryOps.writeUint16LE(value, bytes, 1);
      return bytes;
    } else if (value < 0x100000000) {
      final bytes = BuBytes.zero(5);
      bytes[0] = 0xfe;
      BinaryOps.writeUint32LE(value, bytes, 1);
      return bytes;
    } else {
      throw CoreErrors.invalidOperationArguments(
        "encodeVarint",
        name: "byteint",
        reason: "Value is too large.",
      );
    }
  }

  static BuBytes prependVarint(List<int> data) {
    final varintBytes = encodeVarint(data.length);
    return BuBytes.concat([varintBytes, data]);
  }

  /// Minimum number of bytes needed to hold [value] (add a sign bit when [sign] is true).
  static int bitlengthInBytes(int value, {bool sign = false}) {
    if (value < 0 && !sign) {
      throw CoreErrors.invalidOperationArguments(
        'bitlengthInBytes',
        name: 'value',
        reason: 'Negative value requires sign: true.',
      );
    }
    int bits = value.bitLength;
    if (sign) bits += 1;
    if (bits == 0) return 1;
    return (bits + 7) ~/ 8;
  }

  /// Expands [value] into individual bits, LSB first.
  static List<bool> toBinaryBool(int value, {int? bitLength}) {
    bitLength ??= bitlengthInBytes(value) * 8;
    final bits = List<bool>.filled(bitLength, false);

    for (int i = 0; i < bitLength; i++) {
      bits[i] = value & (1 << i) != 0;
    }
    return bits;
  }

  /// Converts an integer to a byte list with the given length and byte
  /// order. Pass `sign: true` to allow/encode negative values as two's
  /// complement. Length auto-sizing (when [length] is omitted) uses the
  /// same [sign] convention, so the result always round-trips correctly.
  static BuBytes toBytes(
    int val, {
    int? length,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    if (val < 0 && !sign) {
      throw CoreErrors.invalidOperationArguments(
        'toBytes',
        name: 'val',
        reason: 'Negative value requires sign: true.',
      );
    }

    length ??= bitlengthInBytes(val, sign: sign);
    assert(length > 0);

    if (length > 6) {
      return BigintUtils.toBytes(
        BigInt.from(val),
        length: length,
        byteOrder: byteOrder,
        sign: sign,
      );
    }

    // Fold negative values into their two's-complement magnitude up front;
    // length*8 <= 48 here, well within safe-int shift range.
    final int unsigned = val < 0 ? (1 << (length * 8)) + val : val;

    if (length > 4) {
      final int lowerPart = unsigned & BinaryOps.mask32;
      final int upperPart = (unsigned ~/ 0x100000000) & BinaryOps.mask32;
      final bytes = BuBytes([
        ..._toBytesUpTo4(upperPart, length - 4),
        ..._toBytesUpTo4(lowerPart, 4),
      ]);
      return byteOrder == Endian.little ? bytes.reverse() : bytes;
    }

    return BuBytes(_toBytesUpTo4(unsigned, length, byteOrder: byteOrder));
  }

  static List<int> _toBytesUpTo4(
    int val,
    int length, {
    Endian byteOrder = Endian.big,
  }) {
    final byteList = List<int>.filled(length, 0);
    for (var i = 0; i < length; i++) {
      byteList[length - i - 1] = val & BinaryOps.mask8;
      val >>= 8;
    }
    return byteOrder == Endian.little ? byteList.reversed.toList() : byteList;
  }

  /// Converts a list of bytes to an integer, following the given byte order.
  ///
  /// [offset] specifies the starting index within [bytes] to read from.
  /// [length] specifies how many bytes to read (defaults to the rest of the list).
  ///
  /// Uses native int math when safe; otherwise decodes via BigInt and
  /// checks `isValidInt` before converting back, throwing instead of
  /// silently losing precision.
  static int fromBytes(
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

    if (len == 0) return 0;

    // Large inputs: hand off directly to BigInt decoding using
    // offset/length, without copying the (potentially huge) slice here.
    if (len > 6) {
      final big = BigintUtils.fromBytes(
        bytes,
        offset: offset,
        length: len,
        byteOrder: byteOrder,
        sign: sign,
      );
      if (big.isSafeInt()) return big.toInt();
      throw CoreErrors.invalidOperationArguments(
        'fromBytes',
        name: 'bytes',
        reason: 'Value too large to fit in a Dart int.',
      );
    }

    // Small inputs (<= 6 bytes): build a tiny local list directly,
    // no need to touch/copy anything beyond the relevant window.
    final ordered = List<int>.generate(
      len,
      (i) =>
          byteOrder == Endian.little
              ? bytes[offset + len - 1 - i]
              : bytes[offset + i],
    );

    int result;
    if (ordered.length > 4) {
      final int upperPart = _fromBytesUpTo4(
        ordered.sublist(0, ordered.length - 4),
      );
      final int lowerPart = _fromBytesUpTo4(
        ordered.sublist(ordered.length - 4),
      );
      result = upperPart * 0x100000000 + lowerPart; // avoid << 32
    } else {
      result = _fromBytesUpTo4(ordered);
    }

    if (sign && (ordered[0] & 0x80) != 0) {
      final int n = ordered.length * 8;
      final int subtrahend =
          n < 32 ? (1 << n) : ((1 << (n - 32)) * 0x100000000);
      result -= subtrahend;
    }

    return result;
  }

  static int _fromBytesUpTo4(List<int> bytes) {
    int result = 0;
    for (var i = 0; i < bytes.length; i++) {
      result = (result << 8) | (bytes[i] & BinaryOps.mask8);
    }
    return result;
  }

  // ---- Fixed-width decode ----

  /// Reads a single byte as an integer.
  static int fromBytes8(
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

  /// Reads 2 bytes as an integer.
  static int fromBytes16(
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

  /// Reads 4 bytes as an integer.
  static int fromBytes32(
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

  /// Reads 8 bytes as an integer.
  static int fromBytes64(
    List<int> bytes, {
    int offset = 0,
    Endian byteOrder = Endian.big,
    bool sign = false,
  }) {
    _checkLength(bytes, 8, 'fromBytes64', offset: offset);
    // Routed through the BigInt + isValidInt path inside fromBytes
    // automatically, since 8 > 6. Throws if the decoded value can't
    // be represented as a Dart int.
    return fromBytes(
      bytes,
      offset: offset,
      length: 8,
      byteOrder: byteOrder,
      sign: sign,
    );
  }

  /// Throws if [bytes] doesn't have [expected] bytes available from [offset].
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

  /// Parses a dynamic value [number] into an integer.
  static int parse(dynamic number, {bool allowHex = true}) {
    if (number is int) return number;
    if (number is double && number == number.truncateToDouble()) {
      return number.toInt();
    } else if (number is BigInt) {
      if (number.isSafeInt()) {
        return number.toInt();
      }
    } else if (number is String) {
      num? parse = num.tryParse(number);
      if (parse == null && allowHex) {
        parse = int.tryParse(StringUtils.strip0x(number), radix: 16);
      }
      if (parse != null) {
        if (parse is int) return parse;
        if (parse.toDouble() == parse.truncateToDouble()) {
          return parse.toInt();
        }
      }
    }
    throw CoreErrors.invalidOperationArguments(
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
    } on BuError catch (e) {
      if (e.type != DefaultErrorType.invalidArgument) rethrow;
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

  /// Branchless select: returns [b] if [choice] else [a].
  static int ctSelectInt(int a, int b, bool choice) {
    final mask = choice ? -1 : 0; // 0 or -1
    final s = a ^ (mask & (a ^ b));
    assert(s == a || s == b);
    return s;
  }

  /// Branchless select: returns [b] if [choice] else [a].
  static bool ctSelectBool(bool a, bool b, bool choice) {
    final ai = a ? 1 : 0;
    final bi = b ? 1 : 0;
    final mask = choice ? -1 : 0; // 0 or -1
    final si = ai ^ (mask & (ai ^ bi));
    return si != 0;
  }

  /// Integer division rounding up instead of toward zero.
  static int ceilDiv(int a, int b) => (a + b - 1) ~/ b;
}
