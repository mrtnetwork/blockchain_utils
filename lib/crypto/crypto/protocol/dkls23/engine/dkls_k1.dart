import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_engine.dart';

/// secp256k1 (K1) suite engine: typed [Secp256k1Fr]/[Secp256k1Point]
/// math, no `dynamic`, no per-call curve dispatch.
class DklsK1Engine
    extends DklsEngine<Secp256k1Fr, Secp256k1Fp, Secp256k1Point> {
  const DklsK1Engine();

  @override
  Secp256k1Fr? scalarFromBe(List<int> bytes) {
    if (bytes.length != 32) return null;
    try {
      return Secp256k1Fr.fromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Secp256k1Fr scalarMod(List<int> bytes) {
    return Secp256k1Fr.fromBytesUnchecked(bytes);
  }

  @override
  Secp256k1Fr scalarZero() => Secp256k1Fr.zero;

  @override
  Secp256k1Fr scalarOne() => Secp256k1Fr.one;

  @override
  Secp256k1Point identity() => Secp256k1Point.identity_;

  @override
  Secp256k1Point baseMult(Secp256k1Fr s) => Secp256k1Point.generator_ * s;

  @override
  Secp256k1Point pointFromBytes(List<int> bytes) {
    return Secp256k1Point.fromBytes(bytes);
  }

  @override
  List<int> pointToCompressed(Secp256k1Point p) => List<int>.from(p.toBytes());

  @override
  List<int> pointXBytes(Secp256k1Point p) => List<int>.from(p.toXOnly());
}
