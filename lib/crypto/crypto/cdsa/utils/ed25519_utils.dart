import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/cdsa/crypto_ops/crypto_ops.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/utils/exp.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/utils/utils.dart';

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
  ///   - `List<int>`: A reduced byte array representing the scalar modulo the Ed25519 curve order.
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

  static BigInt asScalarInt(List<int> scalar) {
    if (CryptoOps.scCheck(scalar) == 0) {
      return BigintUtils.fromBytes(scalar, byteOrder: Endian.little);
    }
    throw const SquareRootError(
        "The provided scalar exceeds the allowed range.");
  }

  /// Adds two scalar values represented as `List<int>` and returns the result as a `List<int>`.
  ///
  /// This method adds two scalar values, `scalar1` and `scalar2`, and stores the result in the `out` `List<int>`.
  /// The addition is performed according to Ristretto255 scalar operations.
  ///
  /// Parameters:
  ///   - scalar1: The first scalar value to add.
  ///   - scalar2: The second scalar value to add.
  ///
  /// Returns:
  ///   A `List<int>` representing the result of the addition.
  static List<int> add(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(out, CryptoOpsConst.infinity, scalar1, scalar2);
    return BytesUtils.toBytes(out);
  }

  /// Subtracts one scalar value from another and returns the result as a `List<int>`.
  ///
  /// This method subtracts `scalar2` from `scalar1` and stores the result in the `out` `List<int>`.
  /// The subtraction is performed according to Ristretto255 scalar operations.
  ///
  /// Parameters:
  ///   - scalar1: The scalar value to subtract from.
  ///   - scalar2: The scalar value to subtract.
  ///
  /// Returns:
  ///   A `List<int>` representing the result of the subtraction.
  static List<int> sub(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(out, CryptoOpsConst.scMinusOne, scalar2, scalar1);
    return BytesUtils.toBytes(out);
  }

  /// Negates a scalar value and returns the result as a `List<int>`.
  ///
  /// This method negates the given `scalar` and stores the result in the `out` `List<int>`.
  /// The negation is performed according to Ristretto255 scalar operations.
  ///
  /// Parameters:
  ///   - scalar: The scalar value to negate.
  ///
  /// Returns:
  ///   A `List<int>` representing the negated scalar.
  static List<int> neg(List<int> scalar) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(
        out, CryptoOpsConst.scMinusOne, scalar, CryptoOpsConst.zero);
    return BytesUtils.toBytes(out);
  }

  /// Multiplies two scalar values represented as `List<int>` and returns the result as a `List<int>`.
  ///
  /// This method multiplies two scalar values, `scalar1` and `scalar2`, and stores the result in the `out` `List<int>`.
  /// The multiplication is performed according to Ristretto255 scalar operations.
  ///
  /// Parameters:
  ///   - scalar1: The first scalar value to multiply.
  ///   - scalar2: The second scalar value to multiply.
  ///
  /// Returns:
  ///   A `List<int>` representing the result of the multiplication.
  static List<int> mul(List<int> scalar1, List<int> scalar2) {
    final out = List<int>.filled(32, 0);
    CryptoOps.scMulAdd(out, scalar1, scalar2, CryptoOpsConst.zero);
    return BytesUtils.toBytes(out);
  }

  static bool isValidScalar(List<int> bytes) {
    return CryptoOps.scCheck(bytes) == 0;
  }

  static bool isValidPoint(List<int> bytes) {
    final GroupElementP3 p = GroupElementP3();
    return CryptoOps.geFromBytesVartime_(p, bytes) == 0;
  }

  static List<int> zero() {
    return CryptoOpsConst.zero.clone();
  }

  static List<int> secretKeyToPubKey({required List<int> secretKey}) {
    if (CryptoOps.scCheck(secretKey) != 0) {
      throw const SquareRootError(
          "The provided scalar exceeds the allowed range.");
    }
    final List<int> pubKey = zero();
    final GroupElementP3 point = GroupElementP3();
    CryptoOps.geScalarMultBase(point, secretKey);

    CryptoOps.geP3Tobytes(pubKey, point);
    return pubKey;
  }
}
