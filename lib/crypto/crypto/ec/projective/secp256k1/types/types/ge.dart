import 'fe.dart';

abstract class BaseSecp256k1Ge<GE extends BaseSecp256k1Fe> {
  final GE x;
  final GE y;
  int get infinity;
  const BaseSecp256k1Ge({required this.x, required this.y});
  Secp256k1Ge clone() {
    return Secp256k1Ge(x: x.clone(), y: y.clone(), infinity: infinity);
  }
}

class Secp256k1GeConst extends BaseSecp256k1Ge<Secp256k1FeConst> {
  @override
  final int infinity;
  const Secp256k1GeConst({
    required super.x,
    required super.y,
    required this.infinity,
  });
}

class Secp256k1Ge extends BaseSecp256k1Ge<Secp256k1Fe> {
  int _infinity;
  @override
  int get infinity => _infinity;
  Secp256k1Ge({Secp256k1Fe? x, Secp256k1Fe? y, int infinity = 0})
    : _infinity = infinity,
      super(x: x ?? Secp256k1Fe(), y: y ?? Secp256k1Fe());

  factory Secp256k1Ge.infinity() => Secp256k1Ge(infinity: 1);

  void fillWithInfinity() {
    x.fillZero();
    y.fillZero();
    _infinity = 1;
  }

  void fill(BaseSecp256k1Ge other) {
    x.fill(other.x);
    y.fill(other.y);
    _infinity = other.infinity;
  }

  void fillX(BaseSecp256k1Fe x) {
    this.x.fill(x);
  }

  void fillY(BaseSecp256k1Fe y) {
    this.y.fill(y);
  }

  void setInfinity(int infinity) {
    _infinity = infinity;
  }

  // factory Secp256k1Ge.constants(
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
  //   return Secp256k1Ge(
  //     x: Secp256k1Fe.constants(a, b, c, d, e, f, g, h),
  //     y: Secp256k1Fe.constants((i), (j), (k), (l), (m), (n), (o), (p)),
  //     infinity: 0,
  //   );
  // }
  // factory Secp256k1Ge.infinity() {
  //   return Secp256k1Ge(
  //     x: Secp256k1Fe.constants(
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //     ),
  //     y: Secp256k1Fe.constants(
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //       BigInt.zero,
  //     ),
  //     infinity: 1,
  //   );
  // }
}
