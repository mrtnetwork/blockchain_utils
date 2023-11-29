import 'dart:typed_data';

import 'package:blockchain_utils/binary/binary_operation.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/numbers/bigint_utils.dart';

/// Utility class for integer-related operations and conversions.
class IntUtils {
  static (int, int) decodeVarint(List<int> byteint) {
    int ni = byteint[0];
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

    BigInt value = BigintUtils.fromBytes(byteint.sublist(1, 1 + size),
        byteOrder: Endian.little);
    if (!value.isValidInt) {
      throw MessageException("cannot read variable-length in this ENV");
    }
    return (value.toInt(), size + 1);
  }

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

  static List<int> prependVarint(List<int> data) {
    final varintBytes = encodeVarint(data.length);
    return [...varintBytes, ...data];
  }

  static int bitlengthInBytes(int val) {
    return ((val > 0 ? val.bitLength : 1) + 7) ~/ 8;
  }

  /// Converts an integer to a byte list with the specified length and endianness.
  ///
  /// If the [length] is not provided, it is calculated based on the bit length
  /// of the integer, ensuring minimal byte usage. The [byteOrder] determines
  /// whether the most significant bytes are at the beginning (big-endian) or end
  /// (little-endian) of the resulting byte list.
  static List<int> toBytes(int val,
      {required int length, Endian byteOrder = Endian.big}) {
    // length ??= (val.bitLength / 8).ceil();
    List<int> byteList = List<int>.filled(length, 0);

    for (var i = 0; i < length; i++) {
      byteList[i] = (val & mask8);
      val >>= 8;
    }

    if (byteOrder == Endian.little) {
      byteList = List<int>.from(byteList.reversed.toList());
    }

    return byteList;
  }

  static int fromBytes(List<int> bytes, {Endian byteOrder = Endian.big}) {
    if (byteOrder == Endian.little) {
      bytes = List<int>.from(bytes.reversed.toList());
    }

    int result = 0;
    for (var i = 0; i < bytes.length; i++) {
      result |= (bytes[i] << (8 * i));
    }

    return result;
  }
}
