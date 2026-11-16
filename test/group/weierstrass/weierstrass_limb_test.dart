import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:test/test.dart';

BigInt _be(List<int> b) {
  var v = BigInt.zero;
  for (final x in b) {
    v = (v << 8) | BigInt.from(x);
  }
  return v;
}

List<int> _le32(BigInt v) {
  final o = List<int>.filled(32, 0);
  for (int i = 0; i < 32; i++) {
    o[i] = (v & BigInt.from(0xFF)).toInt();
    v >>= 8;
  }
  return o;
}

/// Field prime / group order, derived from the fields themselves
/// (`-1 mod m` serializes as `m - 1`): no external constants needed.
final BigInt _p1k =
    _be((-Secp256k1Fp.one).toBytes()) + BigInt.one;
final BigInt _n1k =
    _be((-Secp256k1Fr.one).toBytes()) + BigInt.one;
final BigInt _p2r =
    _be((-Secp256r1Fp.one).toBytes()) + BigInt.one;
final BigInt _n2r =
    _be((-Secp256r1Fr.one).toBytes()) + BigInt.one;

void main() {
  group('Weierstrass limb fields (Pasta-style 4xUint64 Montgomery)', () {
    test('Secp256k1Fp vs BigInt', () {
      final p = _p1k;
      final vals = [
        BigInt.one,
        BigInt.from(2),
        BigInt.from(7),
        p - BigInt.one,
        p - BigInt.from(2),
        BigInt.parse(
          '79BE667EF9DCBBAC55A06295CE870B07029BFCDB2DCE28D959F2815B16F81798',
          radix: 16,
        ),
      ];
      for (final aB in vals) {
        for (final bB in vals) {
          final a = Secp256k1Fp.fromBytes(_le32(aB), endian: Endian.little);
          final b = Secp256k1Fp.fromBytes(_le32(bB), endian: Endian.little);
          expect(_be(a.toBytes(endian: Endian.big)), aB);
          expect(_be((a + b).toBytes(endian: Endian.big)), (aB + bB) % p);
          expect(_be((a - b).toBytes(endian: Endian.big)), (aB - bB) % p);
          expect(_be((a * b).toBytes(endian: Endian.big)), (aB * bB) % p);
          expect(_be(a.square().toBytes(endian: Endian.big)), (aB * aB) % p);
          expect(_be((-a).toBytes(endian: Endian.big)), (-aB) % p);
        }
        if (aB != BigInt.zero) {
          final a = Secp256k1Fp.fromBytes(_le32(aB), endian: Endian.little);
          expect(
            _be(a.invert()!.toBytes(endian: Endian.big)),
            aB.modInverse(p),
          );
          final s = a.sqrt();
          if (s.isSquare) {
            expect(
              (_be(s.result.toBytes(endian: Endian.big)) *
                      _be(s.result.toBytes(endian: Endian.big))) %
                  p,
              aB,
            );
          }
        }
      }
    });

    test('Secp256r1Fp vs BigInt', () {
      final p = _p2r;
      for (final aB in [
        BigInt.one,
        BigInt.from(2),
        p - BigInt.one,
        BigInt.parse(
          '6B17D1F2E12C4247F8BCE6E563A440F277037D812DEB33A0F4A13945D898C296',
          radix: 16,
        ),
      ]) {
        final a = Secp256r1Fp.fromBytes(_le32(aB), endian: Endian.little);
        expect(_be((a + a).toBytes(endian: Endian.big)), (aB + aB) % p);
        expect(_be((a * a).toBytes(endian: Endian.big)), (aB * aB) % p);
        if (aB != BigInt.zero) {
          expect(
            _be(a.invert()!.toBytes(endian: Endian.big)),
            aB.modInverse(p),
          );
        }
      }
    });

    test('Secp256k1Fr wrap + Secp256r1Fr wrap', () {
      final n1 = _n1k;
      expect(
        _be(
          (Secp256r1Fr.fromBytes(
                    _le32(_n2r - BigInt.one),
                    endian: Endian.little,
                  ) +
                  Secp256r1Fr.fromBytes(_le32(BigInt.one), endian: Endian.little))
              .toBytes(endian: Endian.big),
        ),
        BigInt.zero,
      );
      expect(
        _be(
          Secp256k1Fr.fromBytes(
            _le32(BigInt.from(123456789)),
            endian: Endian.little,
          ).toBytes(endian: Endian.big),
        ),
        BigInt.from(123456789) % n1,
      );
    });

    test('Secp256k1Point generator/doubling (KAT)', () {
      final g = Secp256k1Point.generator_;
      expect(g.isOnCurve(), true);
      String h(List<int> b) =>
          b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      expect(
        h(g.toCompressed()),
        '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
      );
      final d = g.double();
      expect(
        h(d.toCompressed()),
        '02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5',
      );
      final t = d + g;
      expect(
        h(t.toCompressed()),
        '02f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
      );
      final s3 = Secp256k1Fr.fromBytes(_le32(BigInt.from(3)), endian: Endian.little);
      expect(g * s3 == t, true);
      expect(
        (g * Secp256k1Fr.fromBytes(_le32(BigInt.zero), endian: Endian.little)).isIdentity(),
        true,
      );
      final comp = g.toCompressed();
      expect(Secp256k1Point.fromCompressed(comp.toList()) == g, true);
    });

    test('Secp256r1Point generator/doubling (KAT)', () {
      String h(List<int> b) =>
          b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();
      final g = Secp256r1Point.generator_;
      expect(g.isOnCurve(), true);
      expect(
        h(g.toCompressed()),
        '036b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
      );
      final d = g.double();
      expect(
        h(d.toCompressed()),
        '037cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978',
      );
      expect(
        h((d + g).toCompressed()),
        '025ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c',
      );
      expect(
        Secp256r1Point.fromCompressed(g.toCompressed().toList()) == g,
        true,
      );
      final s7 = Secp256r1Fr.fromBytes(_le32(BigInt.from(7)), endian: Endian.little);
      final m7 = g * s7;
      expect(
        h(m7.toCompressed()),
        '028e533b6fa0bf7b4625bb30667c01fb607ef9f8b8a80fef5b300628703187b2a3',
      );
    });

    test('Field edges: zero/one/double/select/bytes', () {
      // zero / one / double
      expect(Secp256k1Fp.zero.isZero(), true);
      expect(Secp256k1Fp.one == Secp256k1Fp.fromBytes(_le32(BigInt.one), endian: Endian.little), true);
      expect(Secp256k1Fp.zero + Secp256k1Fp.zero == Secp256k1Fp.zero, true);
      expect(Secp256k1Fp.zero.double() == Secp256k1Fp.zero, true);
      final two = Secp256k1Fp.one + Secp256k1Fp.one;
      expect(_be(two.toBytes(endian: Endian.big)), BigInt.two);
      expect(two.double() == two + two, true);
      // conditionalSelect
      final a = Secp256k1Fp.fromBytes(_le32(BigInt.one), endian: Endian.little);
      final b = Secp256k1Fp.fromBytes(_le32(BigInt.from(2)), endian: Endian.little);
      expect(Secp256k1Fp.conditionalSelect(a, b, false) == a, true);
      expect(Secp256k1Fp.conditionalSelect(a, b, true) == b, true);
      // invert zero -> null, sqrt zero -> (0,true)
      expect(Secp256k1Fp.zero.invert(), isNull);
      final sz = Secp256k1Fp.zero.sqrt();
      expect(sz.isSquare, true);
      expect(sz.result.isZero(), true);
      // non-square: 3 is non-residue for k1 (legendre -1)? check flag, don't enforce
      final ns = Secp256k1Fp.fromBytes(_le32(BigInt.from(3)), endian: Endian.little).sqrt();
      expect(
        ns.result.square() == Secp256k1Fp.fromBytes(_le32(BigInt.from(3)), endian: Endian.little) ||
            !ns.isSquare,
        true,
      );
      // fromBytes out of range (>=p) throws, unchecked wraps via mul
      expect(
        () => Secp256k1Fp.fromBytes(_le32(_p1k), endian: Endian.little),
        throwsA(anything),
      );
      expect(
        () => Secp256k1Fp.fromBytes(List.filled(31, 0)),
        throwsA(anything),
      );
      // toBytes BE/LE roundtrip
      final v =
          BigInt.parse(
            '123456789ABCDEF123456789ABCDEF123456789ABCDEF123456789ABCDEF1234',
            radix: 16,
          ) %
          _p1k;
      final f = Secp256k1Fp.fromBytes(_le32(v), endian: Endian.little);
      expect(_be(f.toBytes(endian: Endian.big)), v);
      expect(
        f ==
            Secp256k1Fp.fromBytes(
              f.toBytes(endian: Endian.little).toList(),
              endian: Endian.little,
            ),
        true,
      );
      expect(
        f ==
            Secp256k1Fp.fromBytesUnchecked(
              f.toBytes(endian: Endian.little).toList(),
              endian: Endian.little,
            ),
        true,
      );
      // fromBytes64 / _fromU512 consistency: low32=v, high32=0 => same as fromBytes
      final b64 = [..._le32(v), ...List.filled(32, 0)];
      expect(Secp256k1Fp.fromBytes64(b64) == f, true);
      // r1 same edges
      expect(Secp256r1Fp.zero.invert(), isNull);
      expect(
        () => Secp256r1Fp.fromBytes(_le32(_p2r), endian: Endian.little),
        throwsA(anything),
      );
      // scalar sub wrap: 0-1 == n-1
      final n1 = _n1k;
      final zm = Secp256k1Fr.fromBytes(_le32(BigInt.zero), endian: Endian.little);
      final om = Secp256k1Fr.fromBytes(_le32(BigInt.one), endian: Endian.little);
      expect(_be((zm - om).toBytes(endian: Endian.big)), n1 - BigInt.one);
      expect(_be((om + om).toBytes(endian: Endian.big)), BigInt.two);
      expect((om * om) == om, true);
    });

    test('Point edges: inf/neg/mul-by-n/compressed-errors', () {
      final g1 = Secp256k1Point.generator_;
      // P + inf = P, inf + inf = inf, double inf = inf
      expect((g1 + Secp256k1Point.identity_) == g1, true);
      expect(
        (Secp256k1Point.identity_ + Secp256k1Point.identity_).isIdentity(),
        true,
      );
      expect(Secp256k1Point.identity_.double().isIdentity(), true);
      // P + (-P) = inf, double == add self
      expect((g1 + (-g1)).isIdentity(), true);
      expect(g1.double() == g1 + g1, true);
      // mul by 1 / n-1
      final one = Secp256k1Fr.fromBytes(_le32(BigInt.one), endian: Endian.little);
      expect(g1 * one == g1, true);
      final n1 = _n1k;
      final nm1 = Secp256k1Fr.fromBytes(_le32(n1 - BigInt.one), endian: Endian.little);
      expect(g1 * nm1 == -g1, true);
      // scalar-mult self-consistency (k1): distributivity + on-curve.
      for (final sb in [
        BigInt.from(0x123456),
        BigInt.from(0xDEADBEEF),
        BigInt.parse(
          'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364140',
          radix: 16,
        ),
      ]) {
        final s = Secp256k1Fr.fromBytes(_le32(sb % n1), endian: Endian.little);
        final got = g1 * s;
        expect(got.isOnCurve(), true, reason: 'k1 mul $sb');
        // s*G + s*G == (2s)*G, s*G - s*G == inf.
        final dbl = got + got;
        final twoS = Secp256k1Fr.fromBytes(
          _le32((sb % n1 * BigInt.two) % n1),
          endian: Endian.little,
        );
        expect(dbl == g1 * twoS, true, reason: 'k1 dbl $sb');
        expect((got + (-got)).isIdentity(), true, reason: 'k1 neg $sb');
      }
      // compressed errors (k1)
      expect(
        () => Secp256k1Point.fromCompressed([0x04, ...List.filled(32, 0)]),
        throwsA(anything),
      );
      expect(
        () => Secp256k1Point.fromCompressed(List.filled(32, 2)),
        throwsA(anything),
      );
      expect(
        () =>
            Secp256k1AffinePoint.fromCompressed([0x02, ...List.filled(31, 0)]),
        throwsA(anything),
      );
      // tampered x -> not on curve or sqrt fail (use x=1 for k1: 1+7=8 not square? just check isOnCurve false for crafted proj)
      final bad = Secp256k1Point(
        x: Secp256k1Fp.one,
        y: Secp256k1Fp.one,
        z: Secp256k1Fp.one,
      );
      expect(bad.isOnCurve(), false);
      // r1 same edges
      final g2 = Secp256r1Point.generator_;
      expect((g2 + (-g2)).isIdentity(), true);
      expect(g2.double() == g2 + g2, true);
      final n2 = _n2r;
      expect(g2 * Secp256r1Fr.fromBytes(_le32(n2 - BigInt.one), endian: Endian.little) == -g2, true);
      expect(
        () => Secp256r1Point.fromCompressed([0x05, ...List.filled(32, 0)]),
        throwsA(anything),
      );
    });
  });
}
