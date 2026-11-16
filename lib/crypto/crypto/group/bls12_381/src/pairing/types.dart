/// Interface for performing multi-Miller loop computations over multiple term pairs.
abstract mixin class MultiMillerLoop<
  TERMS extends Object,
  RESULT extends Object
> {
  RESULT multiMillerLoop(TERMS terms);
}

/// Interface defining operations required to drive a Miller loop computation.
abstract class MillerLoopDriver<O> {
  /// Performs a doubling step on the accumulated value.
  O doublingStep(O acc);

  /// Performs an addition step on the accumulated value.
  O additionStep(O acc);

  /// Squares the accumulated output.
  O squareOutput(O acc);

  /// Computes the conjugate of the accumulated value.
  O conjugate(O acc);

  /// Returns the multiplicative identity element for the accumulation.
  O one();
}
