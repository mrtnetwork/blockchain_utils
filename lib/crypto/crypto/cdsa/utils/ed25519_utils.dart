import 'dart:typed_data';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';

/// Utility class for Ed25519-specific operations.
class Ed25519Utils {
  /// Reduces a scalar represented as a byte array.
  ///
  /// This method takes a byte array 'scalar' representing an Ed25519 scalar
  /// and reduces it modulo the order of the Ed25519 curve. The result is
  /// returned as a byte array of appropriate length.
  ///
  /// Parameters:
  ///   - scalar: A byte array representing the scalar value.
  ///
  /// Returns:
  ///   - List<int>: A reduced byte array representing the scalar modulo the Ed25519 curve order.
  ///
  /// Details:
  ///   - The method converts the byte array to a BigInt, performs the reduction
  ///     operation, and converts the result back to a byte array. This ensures
  ///     that the scalar remains within the valid range for Ed25519 operations.
  static List<int> scalarReduce(List<int> scalar) {
    final toint = BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    final reduce = toint % Curves.generatorED25519.order!;
    final tobytes = BigintUtils.toBytes(reduce,
        order: Endian.little,
        length: BigintUtils.orderLen(Curves.generatorED25519.order!));
    return tobytes;
  }
}
