import 'package:blockchain_utils/crypto/crypto/group/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// ---------------------------------------------------------------------------
/// Field and point representations
///
/// * Field elements (e.g. `Bls12Fp`) represent values as multiple
///   fixed-size limbs (typically 6 `Uint64`s) and use algorithms written
///   in a constant-time style. However, because they ultimately rely on
///   `BigInt`-backed `Uint64` primitives in pure Dart, these
///   implementations are **not guaranteed to be constant-time** at the machine
///   level and should not be considered fully side-channel resistant.
///
/// All types share identical curve and algebraic semantics; the
/// representation is fixed to limbs only.
/// ---------------------------------------------------------------------------

/// Base class for BLS12 curve points parameterized by scalar field and point type.
abstract class BaseBls12Point<
  SCALAR extends JubJubField<SCALAR>,
  P extends BaseBls12Point<SCALAR, P>
>
    extends ECPoint<SCALAR, P> {
  const BaseBls12Point();
  bool isIdentity();

  @override
  BuBytes toBytes({CryptoKeyEncoding mode = CryptoKeyEncoding.base});
}

/// Generic BLS12 point using limbs field representation
/// (field elements are split into limbs).
abstract class Bls12Point<P extends Bls12Point<P>>
    extends BaseBls12Point<JubJubFq, Bls12Point<P>> {
  const Bls12Point();

  /// Point addition.
  @override
  P operator +(Bls12Point<P> rhs);

  /// Scalar multiplication using limbs field elements.
  @override
  P operator *(JubJubFq rhs);

  /// Point negation.
  @override
  Bls12Point<P> operator -();

  /// Point doubling.
  P double();
}

/// Affine-coordinate BLS12 point with limbs field elements.
abstract class Bls12AffinePoint<P extends Bls12Point<P>> extends Bls12Point<P> {
  const Bls12AffinePoint();
}

/// Base interface for BLS scalar or base fields.
abstract class BlsField<F extends BlsField<F>>
    extends CryptoPrimeFieldElement<F> {
  const BlsField();

  /// Returns whether or not this element is strictly lexicographically
  /// larger than its negation.
  bool lexicographicallyLargest();
}
