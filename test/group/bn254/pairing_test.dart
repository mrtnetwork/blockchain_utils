// BN254 pairing smoke tests.
import 'package:test/test.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g2.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/pairing.dart';

void main() {
  test('e(G1,G2) != 1 and has order r', () {
    final p = Bn254G1AffinePoint.generator;
    final q = Bn254G2AffinePoint.generator;
    final e = Bn254Pairing.pairing(p, q);
    expect(e == Bn254Fp12.one, false);
    // e^r == 1
    final r = BigInt.parse(
      '30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001',
      radix: 16,
    );
    expect(e.powVarTime(r) == Bn254Fp12.one, true);
  });

  test('bilinearity e(aP,Q) == e(P,aQ)', () {
    final p = Bn254G1AffinePoint.generator;
    final q = Bn254G2AffinePoint.generator;
    // 5*G via repeated add (avoids scalar-codec duplication here)
    var acc = Bn254G1Projective.generator;
    for (var i = 1; i < 5; i++) {
      acc = acc + Bn254G1Projective.generator;
    }
    final fiveP = acc.toAffine();
    var acc2 = Bn254G2Projective.generator;
    for (var i = 1; i < 5; i++) {
      acc2 = acc2 + Bn254G2Projective.generator;
    }
    final fiveQ = acc2.toAffine();
    final left = Bn254Pairing.pairing(fiveP, q);
    final right = Bn254Pairing.pairing(p, fiveQ);
    expect(left == right, true);
    expect(left == Bn254Fp12.one, false);
  });

  test('identity pairs to one; batch matches single', () {
    final p = Bn254G1AffinePoint.generator;
    final q = Bn254G2AffinePoint.generator;
    expect(
      Bn254Pairing.pairing(Bn254G1AffinePoint.identity, q) == Bn254Fp12.one,
      true,
    );
    expect(
      Bn254Pairing.pairing(p, Bn254G2AffinePoint.identity) == Bn254Fp12.one,
      true,
    );
    final single = Bn254Pairing.pairing(p, q);
    final batch = Bn254Pairing.pairingBatch([(p, q)]);
    expect(batch == single, true);
  });
}
