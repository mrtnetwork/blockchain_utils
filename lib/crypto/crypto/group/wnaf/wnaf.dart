import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';

/// Fixed-base / fixed-scalar scalar-multiplication helpers.
///
/// An earlier revision evaluated these through a windowed non-adjacent form
/// (wNAF) with secret-dependent branches and secret-indexed table lookups
/// (`wnafForm`/`wnafExp`/`wnafTable`). That path was removed: it sat on a
/// secret-scalar path (the Sinsemilla commit blinder). Every entry point
/// below now delegates to the curve's own branchless scalar multiplication
/// ([CryptoGroupElement.operator *]: double-and-add-always with Uint64 mask
/// selects), so secret scalars stay straight-line.
class WnafBase<
  SCALAR extends CryptoPrimeFieldElement<SCALAR>,
  G extends CryptoGroupElement<G, SCALAR>
> {
  final G base;
  const WnafBase._({required this.base});
  factory WnafBase(G base) => WnafBase._(base: base);

  /// Multiplies the fixed base point by [scalar] (branchless).
  G mult(SCALAR scalar) => base * scalar;

  /// Multiplies the fixed base point by [scalar] (branchless).
  G operator *(WnafScalar<SCALAR, G> scalar) => base * scalar.scalar;
}

/// A scalar for repeated multiplication against different base points.
class WnafScalar<
  SCALAR extends CryptoPrimeFieldElement<SCALAR>,
  G extends CryptoGroupElement<G, SCALAR>
> {
  final SCALAR scalar;
  const WnafScalar._({required this.scalar});
  factory WnafScalar(SCALAR scalar) => WnafScalar._(scalar: scalar);

  /// Multiplies [base] by this scalar (branchless).
  G mult(G base) => base * scalar;

  /// Multiplies [base] by this scalar (branchless).
  G operator *(WnafBase<SCALAR, G> base) => base.base * scalar;
}
