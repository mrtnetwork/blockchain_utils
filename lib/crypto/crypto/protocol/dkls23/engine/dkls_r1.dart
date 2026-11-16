import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';

import 'package:blockchain_utils/crypto/crypto/protocol/dkls23/engine/dkls_engine.dart';

/// secp256r1 (R1) suite engine: typed [Secp256r1Fr]/[Secp256r1Point]
/// math, no `dynamic`, no per-call curve dispatch.
class DklsR1Engine
    extends DklsEngine<Secp256r1Fr, Secp256r1Fp, Secp256r1Point> {
  const DklsR1Engine();

  @override
  Secp256r1Fr? scalarFromBe(List<int> bytes) {
    if (bytes.length != 32) return null;
    try {
      return Secp256r1Fr.fromBytes(bytes);
    } catch (_) {
      return null;
    }
  }

  @override
  Secp256r1Fr scalarMod(List<int> bytes) {
    return Secp256r1Fr.fromBytesUnchecked(bytes);
  }

  @override
  Secp256r1Fr scalarZero() => Secp256r1Fr.zero;

  @override
  Secp256r1Fr scalarOne() => Secp256r1Fr.one;

  @override
  Secp256r1Point identity() => Secp256r1Point.identity_;

  @override
  Secp256r1Point baseMult(Secp256r1Fr s) => Secp256r1Point.generator_ * s;

  @override
  Secp256r1Point pointFromBytes(List<int> bytes) {
    return Secp256r1Point.fromBytes(bytes);
  }

  @override
  List<int> pointToCompressed(Secp256r1Point p) => p.toBytes();

  @override
  List<int> pointXBytes(Secp256r1Point p) => p.toXOnly();
}
