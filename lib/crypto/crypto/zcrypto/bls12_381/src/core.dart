import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';

abstract class BaseBls12Point<
  SCALAR extends JubJubField<SCALAR>,
  P extends BaseBls12Point<SCALAR, P>
>
    extends ECPoint<SCALAR, P> {
  bool isIdentity();
}

abstract class Bls12Point<P extends Bls12Point<P>>
    extends BaseBls12Point<JubJubFq, Bls12Point<P>> {
  @override
  P operator +(Bls12Point<P> rhs);
  @override
  P operator *(JubJubFq rhs);
  @override
  Bls12Point<P> operator -();
  P double();
}

abstract class Bls12NativePoint<P extends Bls12NativePoint<P>>
    extends BaseBls12Point<JubJubNativeFq, Bls12NativePoint<P>> {
  @override
  P operator +(Bls12NativePoint<P> rhs);
  @override
  P operator *(JubJubNativeFq rhs);
  @override
  Bls12NativePoint<P> operator -();
  P double();
}

abstract class Bls12AffinePoint<P extends Bls12Point<P>>
    extends Bls12Point<P> {}

abstract class Bls12NativeAffinePoint<P extends Bls12NativePoint<P>>
    extends Bls12NativePoint<P> {}

abstract class BlsField<F extends BlsField<F>>
    extends CryptoPrimeFieldElement<F> {
  bool lexicographicallyLargest();
}
