import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

abstract class BaseSecp256k1FeStorage extends Iterable<Uint64> {
  const BaseSecp256k1FeStorage();
  abstract final List<Uint64> limbs;
  @override
  Iterator<Uint64> get iterator => limbs.iterator;
  Uint64 operator [](int index) => limbs[index];
  Secp256k1FeStorage clone() => Secp256k1FeStorage._(limbs: limbs);
}

class Secp256k1FeStorageConst extends BaseSecp256k1FeStorage {
  @override
  final List<Uint64> limbs;
  const Secp256k1FeStorageConst.unsafe(this.limbs);
}

class Secp256k1FeStorage extends BaseSecp256k1FeStorage {
  List<Uint64> _limbs;
  factory Secp256k1FeStorage() {
    return Secp256k1FeStorage._();
  }
  Secp256k1FeStorage._({List<Uint64>? limbs})
    : _limbs = limbs?.clone() ?? List<Uint64>.filled(4, Uint64.zero);
  // factory Secp256k1FeStorage.constants(
  //   BigInt d7,
  //   BigInt d6,
  //   BigInt d5,
  //   BigInt d4,
  //   BigInt d3,
  //   BigInt d2,
  //   BigInt d1,
  //   BigInt d0,
  // ) {
  //   return Secp256k1FeStorage._(
  //     limbs: [
  //       Uint64.fromBigInt((d0) | (((d1).toU64) << 32)),
  //       Uint64.fromBigInt((d2) | (((d3).toU64) << 32)),
  //       Uint64.fromBigInt((d4) | (((d5.toU64)) << 32)),
  //       Uint64.fromBigInt((d6) | (((d7.toU64)) << 32)),
  //     ],
  //   );
  // }

  void operator []=(int index, Uint64 value) {
    _limbs[index] = value;
  }

  @override
  List<Uint64> get limbs => _limbs;
}
