/// An exception class for errors related to square root calculations.
///
/// This exception is thrown when there is an issue with computing the square root
/// of a BigInt value within the defined constraints.
///
class SquareRootError implements Exception {
  final String? message;

  const SquareRootError([this.message]);

  @override
  String toString() {
    return message ?? super.toString();
  }
}

/// An exception class for errors related to Jacobi symbol calculations.
///
/// This exception is thrown when there is an issue with computing the Jacobi symbol
/// for a pair of BigInt values within the defined constraints.
///
class JacobiError implements Exception {
  final String? message;

  const JacobiError([this.message]);

  @override
  String toString() {
    return message ?? super.toString();
  }
}
