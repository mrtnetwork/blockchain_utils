import 'fe.dart';

class Secp256k1Gej {
  final Secp256k1Fe x;
  final Secp256k1Fe y;
  final Secp256k1Fe z;
  int _infinity;
  int get infinity => _infinity;
  Secp256k1Gej clone() {
    return Secp256k1Gej(
      x: x.clone(),
      y: y.clone(),
      z: z.clone(),
      infinity: _infinity,
    );
  }

  Secp256k1Gej({
    Secp256k1Fe? x,
    Secp256k1Fe? y,
    Secp256k1Fe? z,
    int infinity = 0,
  }) : x = x ?? Secp256k1Fe(),
       y = y ?? Secp256k1Fe(),
       z = z ?? Secp256k1Fe(),
       _infinity = infinity;
  factory Secp256k1Gej.constants(
    BigInt a,
    BigInt b,
    BigInt c,
    BigInt d,
    BigInt e,
    BigInt f,
    BigInt g,
    BigInt h,
    BigInt i,
    BigInt j,
    BigInt k,
    BigInt l,
    BigInt m,
    BigInt n,
    BigInt o,
    BigInt p,
  ) {
    return Secp256k1Gej(
      x: Secp256k1Fe.constants(a, b, c, d, e, f, g, h),
      y: Secp256k1Fe.constants((i), (j), (k), (l), (m), (n), (o), (p)),
      z: Secp256k1Fe.constants(
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.one,
      ),
      infinity: 0,
    );
  }

  factory Secp256k1Gej.infinity() {
    return Secp256k1Gej(
      x: Secp256k1Fe.constants(
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
      ),
      y: Secp256k1Fe.constants(
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
      ),
      z: Secp256k1Fe.constants(
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
      ),
      infinity: 1,
    );
  }

  void fill(Secp256k1Gej other) {
    fillX(other.x);
    fillY(other.y);
    fillZ(other.z);
    _infinity = other._infinity;
  }

  void fillX(BaseSecp256k1Fe x) {
    this.x.fill(x);
  }

  void fillY(BaseSecp256k1Fe y) {
    this.y.fill(y);
  }

  void fillZ(BaseSecp256k1Fe z) {
    this.z.fill(z);
  }

  void setZero() {
    y.fillZero();
    x.fillZero();
    z.fillZero();
  }

  void setInfinity(int infinity) {
    _infinity = infinity;
  }
}
