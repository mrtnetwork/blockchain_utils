// BN254 smoke tests: field round-trips, G1/G2 generator, doubling, EIP-197 codecs.
import 'package:test/test.dart';

import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/fr.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g1.dart';
import 'package:blockchain_utils/crypto/crypto/group/bn254/src/g2.dart';

List<int> hex(String s) {
  s = s.startsWith('0x') ? s.substring(2) : s;
  if (s.length.isOdd) s = '0$s';
  final out = <int>[];
  for (int i = 0; i < s.length; i += 2) {
    out.add(int.parse(s.substring(i, i + 2), radix: 16));
  }
  return out;
}

void main() {
  test('Fp round-trip', () {
    final v = Bn254Fp.fromBytes(
      hex('30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd46'),
    );
    expect(
      v.toBytes().toList(),
      hex('30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd46'),
    );
    expect(Bn254Fp.one.toBytes().toList().length, 32);
    expect((Bn254Fp.one + Bn254Fp.one).toBytes().length, 32);
  });

  test('G1 generator on curve + 2*G vector', () {
    final g = Bn254G1Projective.generator;
    expect(g.isOnCurve(), true);
    expect(g.isIdentity(), false);
    final gAff = g.toAffine();
    expect(gAff.toBytes().toList().length, 64);
    // 2*G known answer (computed via sage/python):
    // x = 0x30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3
    // y = 0x15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4
    final two = g.double().toAffine().toBytes().toList();
    final expX = hex(
      '30644e72e131a029b85045b68181585d97816a916871ca8d3c208c16d87cfd3',
    );
    final expY = hex(
      '15ed738c0e0a7c92e7845f96b2ae9c0a68a6a449e3538fc7ff3ebf7a5a18a2c4',
    );
    expect(two.sublist(0, 32), expX);
    expect(two.sublist(32, 64), expY);
    // scalar mul by 2 (BE) agrees with double
    final twoMul =
        g
            .multiply(
              hex(
                '0000000000000000000000000000000000000000000000000000000000000002',
              ),
            )
            .toAffine()
            .toBytes()
            .toList();
    expect(twoMul, two);
    // 0 * G = inf, 1 * G = G
    expect(g.multiply(List.filled(32, 0)).isIdentity(), true);
    expect(
      g
          .multiply(
            hex(
              '0000000000000000000000000000000000000000000000000000000000000001',
            ),
          )
          .toAffine()
          .toBytes()
          .toList(),
      gAff.toBytes().toList(),
    );
    // EIP-197 zero = infinity
    expect(
      Bn254G1AffinePoint.fromBytesUnchecked(List.filled(64, 0)).isIdentity(),
      true,
    );
    // add/neg round-trip
    expect((g + (-g)).isIdentity(), true);
  });

  test('G2 generator on curve + subgroup', () {
    final g = Bn254G2Projective.generator;
    expect(g.isOnCurve(), true);
    expect(g.isIdentity(), false);
    final aff = g.toAffine();
    expect(aff.toBytes().toList().length, 128);
    // codec round-trip (x1,x0,y1,y0)
    final rt = Bn254G2AffinePoint.fromBytesUnchecked(aff.toBytes().toList());
    expect(rt.x == aff.x && rt.y == aff.y, true);
    expect(aff.isTorsionFree(), true);
    // zero = infinity
    expect(
      Bn254G2AffinePoint.fromBytesUnchecked(List.filled(128, 0)).isIdentity(),
      true,
    );
    // double == mul(2)
    final d = g.double().toAffine().toBytes().toList();
    final m =
        g
            .multiply(
              hex(
                '0000000000000000000000000000000000000000000000000000000000000002',
              ),
            )
            .toAffine()
            .toBytes()
            .toList();
    expect(m, d);
    expect((g + (-g)).isIdentity(), true);
  });

  test('Fr reduce + G1 r*G == 0', () {
    final r = Bn254Fr.fromBytes(
      hex('30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001')
        ..[31] = 0x00,
    );
    // r-1 exists
    expect(r.isZero(), false);
    // G1 order check: [r]G == inf
    const rBe = [
      0x30,
      0x64,
      0x4e,
      0x72,
      0xe1,
      0x31,
      0xa0,
      0x29,
      0xb8,
      0x50,
      0x45,
      0xb6,
      0x81,
      0x81,
      0x58,
      0x5d,
      0x28,
      0x33,
      0xe8,
      0x48,
      0x79,
      0xb9,
      0x70,
      0x91,
      0x43,
      0xe1,
      0xf5,
      0x93,
      0xf0,
      0x00,
      0x00,
      0x01,
    ];
    expect(Bn254G1Projective.generator.multiply(rBe).isIdentity(), true);
  });
}
