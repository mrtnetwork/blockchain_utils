import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';

/// Field elements are represented as multiple fixed-size limbs (typically
/// 4 `Uint64`s) with algorithms written in a constant-time style. Because
/// they rely on multi-precision arithmetic over Dart ints, these
/// implementations are **not guaranteed to be constant-time** at the machine
/// level and should not be considered fully side-channel resistant.

/// Base abstract class for JubJub points in extended/projective coordinates.
abstract class BaseRedJubJubPoint<SCALAR extends JubJubScalar<SCALAR>>
    extends ECPoint<SCALAR, BaseRedJubJubPoint<SCALAR>> {
  const BaseRedJubJubPoint();

  /// Converts this point to its Niels representation for faster arithmetic.
  BaseJubJubNielsPoint<SCALAR> toNiels();

  /// Scalar multiplication of this point.
  @override
  BaseRedJubJubPoint<SCALAR> operator *(SCALAR rhs);

  /// Scalar multiplication from raw bytes.
  BaseRedJubJubPoint<SCALAR> multiply(List<int> by);
}

/// Base abstract class for JubJub points with full group and cofactor operations.
abstract class BaseJubJubPoint<
  SCALAR extends JubJubScalar<SCALAR>,
  P extends BaseJubJubPoint<SCALAR, P>
>
    extends BaseRedJubJubPoint<SCALAR>
    implements CryptoGroupElement<P, SCALAR>, CofactorGroupElement<SCALAR, P> {
  const BaseJubJubPoint();

  /// Multiplies the point by the group cofactor.
  P mulByCofactor();

  /// Checks whether the point has small order.
  @override
  bool isSmallOrder();

  /// Checks whether the point is the identity.
  bool isIdentity();

  /// Point doubling.
  @override
  P double();

  /// Clears the cofactor (alias for `mulByCofactor`).
  @override
  P clearCofactor() => mulByCofactor();

  /// Point addition with another JubJub point.
  @override
  P operator +(BaseRedJubJubPoint<SCALAR> rhs);
}

/// Base class for affine JubJub points.
abstract class BaseJubJubAffinePoint<SCALAR extends JubJubScalar<SCALAR>>
    extends BaseRedJubJubPoint<SCALAR> {
  /// Affine point subtraction.
  BaseJubJubAffinePoint<SCALAR> operator -(BaseRedJubJubPoint<SCALAR> rhs);
}

/// Base class for Niels-form JubJub points (used for fast addition).
abstract class BaseJubJubNielsPoint<SCALAR extends JubJubScalar<SCALAR>>
    extends BaseRedJubJubPoint<SCALAR> {
  /// Subtracts another point from this Niels point.
  BaseRedJubJubPoint<SCALAR> operator -(BaseRedJubJubPoint<SCALAR> rhs);
}
