import 'package:blockchain_utils/exception/exception.dart';

/// An exception class for errors related to square root calculations.
///
/// This exception is thrown when there is an issue with computing the square root
/// of a BigInt value within the defined constraints.
///
class SquareRootError implements BlockchainUtilsException {
  @override
  final String message;

  @override
  final Map<String, dynamic>? details;

  const SquareRootError(this.message, {this.details});

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

  @override
  final Map<String, dynamic>? details;

  const JacobiError(this.message, {this.details});

  @override
  String toString() {
    return message;
  }
}
