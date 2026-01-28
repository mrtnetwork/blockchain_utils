import 'package:blockchain_utils/crypto/crypto/ec/core/field.dart';
import 'package:blockchain_utils/crypto/crypto/ec/core/point.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';

abstract class BaseRedJubJubPoint<SCALAR extends JubJubScalar<SCALAR>>
    extends ECPoint<SCALAR, BaseRedJubJubPoint<SCALAR>> {
  BaseJubJubNielsPoint<SCALAR> toNiels();
  @override
  BaseRedJubJubPoint<SCALAR> operator *(SCALAR rhs);
  BaseRedJubJubPoint<SCALAR> multiply(List<int> by);
}

abstract class BaseJubJubPoint<
  SCALAR extends JubJubScalar<SCALAR>,
  P extends BaseJubJubPoint<SCALAR, P>
>
    extends BaseRedJubJubPoint<SCALAR>
    implements CryptoGroupElement<P, SCALAR>, CofactorGroupElement<SCALAR, P> {
  P mulByCofactor();
  @override
  bool isSmallOrder();
  bool isIdentity();
  @override
  P double();
  @override
  P clearCofactor() {
    return mulByCofactor();
  }

  @override
  P operator +(BaseRedJubJubPoint<SCALAR> rhs);
}

abstract class BaseJubJubAffinePoint<SCALAR extends JubJubScalar<SCALAR>>
    extends BaseRedJubJubPoint<SCALAR> {
  BaseJubJubAffinePoint<SCALAR> operator -(BaseRedJubJubPoint<SCALAR> rhs);
}

abstract class BaseJubJubNielsPoint<SCALAR extends JubJubScalar<SCALAR>>
    extends BaseRedJubJubPoint<SCALAR> {
  BaseRedJubJubPoint<SCALAR> operator -(BaseRedJubJubPoint<SCALAR> rhs);
}
