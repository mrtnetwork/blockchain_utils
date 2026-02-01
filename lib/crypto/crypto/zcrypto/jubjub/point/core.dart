import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';

/// ---------------------------------------------------------------------------
/// Native vs Non-Native representations
///
/// * Both native and non-native field implementations are backed by `BigInt`.
///
/// * Non-native types (e.g. `JubJubFq`, `JubJubPoint`) represent field elements as
///   multiple fixed-size limbs (typically 4 `BigInt`s) and use algorithms written
///   in a constant-time style. However, because they rely on `BigInt`, these
///   implementations are **not guaranteed to be constant-time** at the machine
///   level and should not be considered fully side-channel resistant. They are,
///   however, safer than native representations.
///
/// * Native types (e.g. `JubJubNativeFq`, `JubJubNativePoint`) represent each field
///   element as a single `BigInt` and use variable-time algorithms. These are not
///   constant-time and are not intended to be safe against side-channel attacks.
///
/// Both representations share identical curve and algebraic semantics; the
/// differences lie in representation, performance, and side-channel behavior.
/// --------------------------------------------

/// Base abstract class for JubJub points in extended/projective coordinates.
abstract class BaseRedJubJubPoint<SCALAR extends JubJubScalar<SCALAR>>
    extends ECPoint<SCALAR, BaseRedJubJubPoint<SCALAR>> {
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
