import 'package:blockchain_utils/exception/exception.dart';

/// An exception class for errors related to square root calculations.
///
/// This exception is thrown when there is an issue with computing the square root
/// of a BigInt value within the defined constraints.
///
class SquareRootError implements BlockchainUtilsException {
  @override
  final String message;

  const SquareRootError(this.message);

  @override
  String toString() {
    return message;
  }
}

/// An exception class for errors related to Jacobi symbol calculations.
///
/// This exception is thrown when there is an issue with computing the Jacobi symbol
/// for a pair of BigInt values within the defined constraints.
///
class JacobiError implements BlockchainUtilsException {
  @override
  final String message;

  const JacobiError(this.message);

  @override
  String toString() {
    return message;
  }
}
