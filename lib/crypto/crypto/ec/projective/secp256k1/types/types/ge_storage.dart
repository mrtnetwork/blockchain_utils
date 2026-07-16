import 'fe_storage.dart';

abstract class BaseSecp256k1GeStorage<GE extends BaseSecp256k1FeStorage> {
  final GE x;
  final GE y;
  const BaseSecp256k1GeStorage({required this.x, required this.y});
}

class Secp256k1GeStorageConst
    extends BaseSecp256k1GeStorage<Secp256k1FeStorageConst> {
  const Secp256k1GeStorageConst({required super.x, required super.y});
}

class Secp256k1GeStorage extends BaseSecp256k1GeStorage<Secp256k1FeStorage> {
  Secp256k1GeStorage({Secp256k1FeStorage? x, Secp256k1FeStorage? y})
    : super(x: x ?? Secp256k1FeStorage(), y: y ?? Secp256k1FeStorage());
  // factory Secp256k1GeStorage.constants(
  //   BigInt a,
  //   BigInt b,
  //   BigInt c,
  //   BigInt d,
  //   BigInt e,
  //   BigInt f,
  //   BigInt g,
  //   BigInt h,
  //   BigInt i,
  //   BigInt j,
  //   BigInt k,
  //   BigInt l,
  //   BigInt m,
  //   BigInt n,
  //   BigInt o,
  //   BigInt p,
  // ) {
  //   return Secp256k1GeStorage(
  //     x: Secp256k1FeStorage.constants(a, b, c, d, e, f, g, h),
  //     y: Secp256k1FeStorage.constants((i), (j), (k), (l), (m), (n), (o), (p)),
  //   );
  // }
}
