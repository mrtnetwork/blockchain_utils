import 'dart:typed_data';

import 'package:blockchain_utils/binary/binary_operation.dart';

/// Utility class for integer-related operations and conversions.
class IntUtils {
  /// Converts an integer to a byte list with the specified length and endianness.
  ///
  /// If the [length] is not provided, it is calculated based on the bit length
  /// of the integer, ensuring minimal byte usage. The [endianness] determines
  /// whether the most significant bytes are at the beginning (big-endian) or end
  /// (little-endian) of the resulting byte list.
  static List<int> toBytesLength(int dataInt,
      {int? length, Endian endianness = Endian.big}) {
    length = length ?? ((dataInt > 0 ? dataInt.bitLength : 1) + 7) ~/ 8;
    List<int> bytes = toBytes(dataInt, length: length, byteOrder: endianness);

    return bytes;
  }

  /// Converts an integer to a byte list with the specified length and endianness.
  ///
  /// If the [length] is not provided, it is calculated based on the bit length
  /// of the integer, ensuring minimal byte usage. The [byteOrder] determines
  /// whether the most significant bytes are at the beginning (big-endian) or end
  /// (little-endian) of the resulting byte list.
  static List<int> toBytes(int val,
      {int? length, Endian byteOrder = Endian.big}) {
    length ??= (val.bitLength / 8).ceil();
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
