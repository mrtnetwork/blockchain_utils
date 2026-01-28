import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/utils/utils.dart';

abstract class CryptoFieldElement {}

abstract class CryptoGroupElement<F, SCALAR extends CryptoField<SCALAR>> {
  F double();
  F identity();
  F operator +(F other);
  F operator -(F other);
  F operator *(SCALAR other);
  int recommendedWnafForNumScalars(int total);
  List<int> toBytes();
}

abstract class CofactorGroupElement<
  SCALAR extends CryptoField<SCALAR>,
  F extends CryptoGroupElement<F, SCALAR>
> {
  bool isSmallOrder();

  F clearCofactor();
}

abstract class CryptoPrimeFieldElement<F extends CryptoPrimeFieldElement<F>>
    implements CryptoField<F> {
  const CryptoPrimeFieldElement();
  List<int> toBytes();
}

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

class Coordinates<F extends Object> {
  final F x;
  final F y;
  const Coordinates(this.x, this.y);
}
