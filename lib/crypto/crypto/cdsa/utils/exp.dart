import 'package:blockchain_utils/exception/exceptions.dart';

/// An exception class for errors related to square root calculations.
///
/// This exception is thrown when there is an issue with computing the square root
/// of a BigInt value within the defined constraints.
///
class SquareRootError extends BlockchainUtilsException {
  const SquareRootError(super.message, {super.details});
}

/// An exception class for errors related to Jacobi symbol calculations.
///
/// This exception is thrown when there is an issue with computing the Jacobi symbol
/// for a pair of BigInt values within the defined constraints.
///
class JacobiError extends BlockchainUtilsException {
  const JacobiError(super.message, {super.details});
}
