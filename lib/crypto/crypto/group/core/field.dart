import 'package:blockchain_utils/crypto/crypto/group/pasta/utils/utils.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Marker base for a field element type.
abstract class CryptoFieldElement {}

/// Contract for a point on an elliptic curve group over scalar field [SCALAR].
abstract class CryptoGroupElement<F, SCALAR extends CryptoField<SCALAR>> {
  const CryptoGroupElement();
  F double();
  F identity();
  F operator +(F other);
  F operator -(F other);
  F operator *(SCALAR other);
  int recommendedWnafForNumScalars(int total);
  BuBytes toBytes();
}

/// Contract for a group element on a curve with a non-trivial cofactor.
abstract class CofactorGroupElement<
  SCALAR extends CryptoField<SCALAR>,
  F extends CryptoGroupElement<F, SCALAR>
> {
  /// Whether this point has small order (lies in the cofactor subgroup).
  bool isSmallOrder();

  /// Multiplies this point by the cofactor, projecting it into the prime-order subgroup.
  F clearCofactor();
}

/// A [CryptoField] element backed by a prime field (as opposed to an extension field).
abstract class CryptoPrimeFieldElement<F extends CryptoPrimeFieldElement<F>>
    implements CryptoField<F> {
  const CryptoPrimeFieldElement();
  BuBytes toBytes();
}

/// Contract for a field element (prime field or an extension field built on top of one).
abstract class CryptoField<F extends CryptoField<F>> {
  const CryptoField();
  F operator +(F other);
  F operator -(F other);
  F operator *(F other);
  F operator -();
  F square();
  F double();
  F? invert();
  FieldSqrtResult<F> sqrt();
  bool isZero();
}

/// A pair of field-element coordinates (e.g. affine x/y).
class Coordinates<F extends Object> {
  final F x;
  final F y;
  const Coordinates(this.x, this.y);
}
