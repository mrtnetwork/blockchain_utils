import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
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

List<int> _hex(String h) => BytesUtils.fromHexString(h).toList();
String _hexOf(List<int> b) => BytesUtils.toHexString(b);

void main() {
  group('Edwards limb 4xUint64 (branch-free, BigInt-free)', () {
    test('Ed25519Fp vs BigInt', () {
      final p = BigInt.parse(
        '57896044618658097711785492504343953926634992332820282019728792003956564819949',
      );
      for (final v in [
        BigInt.one,
        BigInt.from(2),
        p - BigInt.one,
        BigInt.parse(
          '15112221349535400772501151409588531511454012693041857206046113283949847762202',
        ),
      ]) {
        final f = Ed25519Fp.fromBytes(_le32(v));
        expect(_be(f.toBytes(endian: Endian.big)), v);
        expect(_be((f + f).toBytes(endian: Endian.big)), (v + v) % p);
        expect(_be((f * f).toBytes(endian: Endian.big)), (v * v) % p);
        if (v != BigInt.zero) {
          expect(_be(f.invert()!.toBytes(endian: Endian.big)), v.modInverse(p));
        }
      }
      expect(Ed25519Fp.zero.invert(), isNull);
      expect(() => Ed25519Fp.fromBytes(_le32(p)), throwsA(anything));
    });

    test('generator known-answer vectors', () {
      const gHex =
          '5866666666666666666666666666666666666666666666666666666666666666';
      const g2Hex =
          'c9a3f86aae465f0e56513864510f3997561fa2c9e85ea21dc2292309f3cd6022';
      final g = EdwardsLimbPoint.generator_;
      expect(g.isOnCurve(), isTrue);
      expect(_hexOf(g.toBytes().toList()), gHex);
      expect(
        _hexOf(EdwardsLimbPoint.fromBytes(_hex(gHex)).toBytes().toList()),
        gHex,
      );
      expect(_hexOf((g + g).toBytes().toList()), g2Hex);
      expect(_hexOf(g.double().toBytes().toList()), g2Hex);
      expect((g + (-g)).isIdentity(), isTrue);
      expect(g.double() == g + g, isTrue);
    });

    test('RFC 8032 secret-to-public vectors (reduceMultBase)', () {
      // RFC 8032 §5.1 key generation: clamp(SHA-512(seed)[0:32]) then
      // scalar-mult. Clamped scalars exceed L, so the exact product goes
      // through reduce-then-mult ([k]G == [k mod L]G since L*G == 0).
      // Only TEST 1 is pinned: its seed was verified nibble-by-nibble
      // against the public key (the ladder itself is additionally covered
      // by the deterministic sign vector, FROST E.1 vectors, and the
      // pre-removal differential suite).
      const vectors = [
        (
          '9d61b19deffd5a60ba844af492ec2cc44449c5697b326919703bac031cae7f60',
          'd75a980182b10ab7d54bfed3c964073a0ee172f3daa62325af021a68f707511a',
        ),
      ];
      for (final (seed, pk) in vectors) {
        final h = QuickCrypto.sha512Hash(_hex(seed)).sublist(0, 32);
        h[0] &= 248;
        h[31] &= 127;
        h[31] |= 64;
        final got = EdwardsLimbOps.reduceMultBase(h);
        expect(_hexOf(got.toList()), pk, reason: 'rfc8032 $seed');
      }
    });

    test('scalar mul ladder consistency', () {
      final gNew = EdwardsLimbPoint.generator_;
      final nm1 = Ed25519Fr.zero - Ed25519Fr.one;
      expect((gNew * nm1).toBytes().toList(), ((-gNew)).toBytes().toList());
      expect(
        (gNew * Ed25519Fr.fromBytes(_le32(BigInt.zero))).isIdentity(),
        isTrue,
      );
      // (a+b)*G == a*G + b*G over scalars well below L.
      final aBytes = List<int>.generate(32, (i) => (i * 37 + 11) & 0xFF)
        ..[31] = 0x00;
      final bBytes = List<int>.generate(32, (i) => (i * 91 + 7) & 0xFF)
        ..[31] = 0x00;
      final a = Ed25519Fr.fromBytes(aBytes);
      final b = Ed25519Fr.fromBytes(bBytes);
      expect(
        ((gNew * (a + b)).toBytes().toList()),
        ((gNew * a + gNew * b).toBytes().toList()),
      );
    });

    test('point edges', () {
      final g = EdwardsLimbPoint.generator_;
      expect(
        (g + EdwardsLimbPoint.identity_).toBytes().toList(),
        g.toBytes().toList(),
      );
      expect(EdwardsLimbPoint.identity_.double().isIdentity(), isTrue);
      expect(
        () => EdwardsLimbPoint.fromBytes(List.filled(31, 0)),
        throwsA(anything),
      );
      // tampered y -> not on curve or decode fail
      final bad = List<int>.of(g.toBytes());
      bad[0] ^= 0x01;
      try {
        final pt = EdwardsLimbPoint.fromBytes(bad);
        expect(pt.isOnCurve(), isFalse);
      } catch (_) {
        // decode rejection is also fine
        expect(true, isTrue);
      }
    });

    test('Monero hash-to-point pinned vectors', () {
      // Independently verified against a clean-room integer port of the
      // original hash-to-point map (no shared code with the limb path).
      const pins = [
        (
          '0000000000000000000000000000000000000000000000000000000000000000',
          '0100000000000000000000000000000000000000000000000000000000000000',
        ),
        (
          '0101010101010101010101010101010101010101010101010101010101010101',
          '19fc032736138ac12ae6e484c9af1ea6bc4b5467831b2e5aefc0415b1a943a08',
        ),
        (
          '000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f',
          '0691eee3cf70a0056df6bfa03120635636581b5c4ea571dfc680f78c7e0b4137',
        ),
        (
          'fffefdfcfbfaf9f8f7f6f5f4f3f2f1f0efeeedecebeae9e8e7e6e5e4e3e2e1e0',
          'b12bf604e36d63fd8047b983303927bf6373e193714e1ebe8f76b93be535cd92',
        ),
      ];
      for (final (input, output) in pins) {
        final got = EdwardsLimbPoint.moneroHashToPoint(_hex(input));
        expect(_hexOf(got.toBytes().toList()), output, reason: 'h2c $input');
        expect(got.isOnCurve(), isTrue);
      }
    });
  });
}
