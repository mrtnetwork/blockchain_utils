import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:blockchain_utils/utils/utils.dart';

abstract class BaseSecp256k1Scalar extends Iterable<Uint64>
    with ConstantEquality<BaseSecp256k1Scalar> {
  const BaseSecp256k1Scalar();
  abstract final List<Uint64> limbs;
  @override
  Iterator<Uint64> get iterator => limbs.iterator;
  Uint64 operator [](int index) => limbs[index];
  Secp256k1Scalar clone() => Secp256k1Scalar._(limbs: limbs);

  @override
  bool constantEquality(BaseSecp256k1Scalar other) {
    return Uint64.ctEquals(limbs, other.limbs);
  }
}

class Secp256k1ScalarConst extends BaseSecp256k1Scalar {
  @override
  final List<Uint64> limbs;
  const Secp256k1ScalarConst.unsafe(this.limbs);

  static Secp256k1ScalarConst constants(
    BigInt d7,
    BigInt d6,
    BigInt d5,
    BigInt d4,
    BigInt d3,
    BigInt d2,
    BigInt d1,
    BigInt d0,
  ) {
    return Secp256k1ScalarConst.unsafe(
      [
        Uint64.fromBigInt(((d1.toU64)) << 32 | (d0)),
        Uint64.fromBigInt(((d3.toU64)) << 32 | (d2)),
        Uint64.fromBigInt(((d5.toU64)) << 32 | (d4)),
        Uint64.fromBigInt(((d7.toU64)) << 32 | (d6)),
      ].immutable,
    );
  }
}

class Secp256k1Scalar extends BaseSecp256k1Scalar {
  final List<Uint64> _limbs;

  factory Secp256k1Scalar() {
    return Secp256k1Scalar._();
  }
  Secp256k1Scalar._({List<Uint64>? limbs})
    : _limbs = limbs?.clone() ?? List<Uint64>.filled(4, Uint64.zero);

  void operator []=(int index, Uint64 value) {
    _limbs[index] = value;
  }

  void fill(BaseSecp256k1Scalar other) {
    for (int i = 0; i < 4; i++) {
      _limbs[i] = other.limbs[i];
    }
  }

  void fillZero() {
    for (int i = 0; i < 4; i++) {
      _limbs[i] = Uint64.zero;
    }
  }

  @override
  List<Uint64> get limbs => _limbs;
}
