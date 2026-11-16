import 'dart:typed_data';
import 'package:blockchain_utils/exception/exception/core_errors.dart';

import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Utility class for encoding and decoding double values.
class DoubleCoder {
  /// Converts a double value to bytes.
  ///
  /// - [value] : The double value to encode.
  /// - [byteOrder] (optional): The byte order for encoding. Defaults to big endian.
  static BuBytes toBytes(double value, {Endian byteOrder = Endian.big}) {
    final ByteData byteData = ByteData(8);
    byteData.setFloat64(0, value, byteOrder);
    return BuBytes.unsafeMutable(byteData.buffer.asUint8List());
  }

  /// Converts bytes to a double value.
  ///
  /// - [bytes] : The bytes to decode. Must be exactly 8 bytes.
  /// - [byteOrder] (optional): The byte order for decoding. Defaults to big endian.
  ///
  static double fromBytes(List<int> bytes, {Endian byteOrder = Endian.big}) {
    if (bytes.length != 8) {
      throw CoreErrors.invalidOperationArguments(
        "fromBytes",
        name: "bytes",
        reason: "Double requires exactly 8 bytes.",
      );
    }
    final ByteData byteData = ByteData.sublistView(Uint8List.fromList(bytes));
    return byteData.getFloat64(0, byteOrder);
  }
}
