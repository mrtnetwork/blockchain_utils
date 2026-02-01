import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';

/// ---------------------------------------------------------------------------
/// Native vs Non-Native representations
///
/// * Both native and non-native field implementations are backed by `BigInt`.
///
/// * Non-native types (e.g. `JubJubFq`, `Bls12Point`) represent field elements as
///   multiple fixed-size limbs (typically 6 `BigInt`s) and use algorithms written
///   in a constant-time style. However, because they rely on `BigInt`, these
///   implementations are **not guaranteed to be constant-time** at the machine
///   level and should not be considered fully side-channel resistant. They are,
///   however, safer than native representations.
///
/// * Native types (e.g. `JubJubNativeFq`, `Bls12NativePoint`) represent each field
///   element as a single `BigInt` and use variable-time algorithms. These are not
///   constant-time and are not intended to be safe against side-channel attacks.
///
/// Both representations share identical curve and algebraic semantics; the
/// differences lie in representation, performance, and side-channel behavior.
/// ---------------------------------------------------------------------------

/// Base class for BLS12 curve points parameterized by scalar field and point type.
/// Used by both native (single BigInt) and non-native representations.
abstract class BaseBls12Point<
  SCALAR extends JubJubField<SCALAR>,
  P extends BaseBls12Point<SCALAR, P>
>
    extends ECPoint<SCALAR, P> {
  bool isIdentity();
}

/// Generic BLS12 point using non-native field representation
/// (field elements may be split into limbs).
abstract class Bls12Point<P extends Bls12Point<P>>
    extends BaseBls12Point<JubJubFq, Bls12Point<P>> {
  /// Point addition.
  @override
  P operator +(Bls12Point<P> rhs);

  /// Scalar multiplication using non-native field elements.
  @override
  P operator *(JubJubFq rhs);

  /// Point negation.
  @override
  Bls12Point<P> operator -();

  /// Point doubling.
  P double();
}

/// BLS12 point using native field representation
/// (each field element is backed by a single BigInt).
abstract class Bls12NativePoint<P extends Bls12NativePoint<P>>
    extends BaseBls12Point<JubJubNativeFq, Bls12NativePoint<P>> {
  /// Point addition using native (single BigInt) field arithmetic.
  @override
  P operator +(Bls12NativePoint<P> rhs);

  /// Scalar multiplication using native field elements.
  @override
  P operator *(JubJubNativeFq rhs);

  /// Point negation.
  @override
  Bls12NativePoint<P> operator -();

  /// Point doubling.
  P double();
}

/// Affine-coordinate BLS12 point with non-native field elements.
abstract class Bls12AffinePoint<P extends Bls12Point<P>>
    extends Bls12Point<P> {}

/// Affine-coordinate BLS12 point with native field elements
/// (coordinates stored as single BigInts).
abstract class Bls12NativeAffinePoint<P extends Bls12NativePoint<P>>
    extends Bls12NativePoint<P> {}

/// Base interface for BLS scalar or base fields.
abstract class BlsField<F extends BlsField<F>>
    extends CryptoPrimeFieldElement<F> {
  /// Returns whether or not this element is strictly lexicographically
  /// larger than its negation.
  bool lexicographicallyLargest();
}
