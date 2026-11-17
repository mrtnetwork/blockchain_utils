import 'dart:math';
import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

BigInt _be(List<int> b) {
  var v = BigInt.zero;
  for (final e in b) {
    v = (v << 8) | BigInt.from(e);
  }
  return v;
}

List<int> _le32(BigInt v) {
  final out = List<int>.filled(32, 0);
  var x = v;
  for (var i = 0; i < 32; i++) {
    out[i] = (x & BigInt.from(0xff)).toInt();
    x >>= 8;
  }
  return out;
}

List<int> _be32(BigInt v) => _le32(v).reversed.toList();

String _h(List<int> b) =>
    b.map((e) => e.toRadixString(16).padLeft(2, '0')).join();

const _k1nHex =
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141';
const _k1pHex =
    'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEFFFFFC2F';
const _r1nHex =
    'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551';
const _r1pHex =
    'FFFFFFFF00000001000000000000000000000000FFFFFFFFFFFFFFFFFFFFFFFF';

final BigInt _n1 = BigInt.parse(_k1nHex, radix: 16);
final BigInt _n2 = BigInt.parse(_r1nHex, radix: 16);
final BigInt _p1 = BigInt.parse(_k1pHex, radix: 16);
final BigInt _p2 = BigInt.parse(_r1pHex, radix: 16);

/// scalar hex -> compressed/uncompressed/x-only encodings, verified against
/// the legacy BigInt backend before its removal (n-1 == -G and n-2 == -(2G)
/// cross-check the group law and y-parity handling).
const Map<String, Map<String, String>> _k1Kat = {
  '1': {
    'c': '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
    'u':
        '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8',
    'x': '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
  },
  '2': {
    'c': '02c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5',
    'u':
        '04c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee51ae168fea63dc339a3c58419466ceaeef7f632653266d0e1236431a950cfe52a',
    'x': 'c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5',
  },
  '3': {
    'c': '02f9308a019258c31049344f85f89d5229b531c845836f99b08601f113bce036f9',
  },
  '7': {
    'c': '025cbdf0646e5db4eaa398f365f2ea7a0e3d419b7e0330e39ce92bddedcac4f9bc',
  },
  'deadbeef': {
    'c': '0276d2fdf1302d1fa9556f4df94ec84cefba6d482e54f47c6c2a238c1baa560f0e',
  },
  '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20': {
    'c': '0284bf7562262bbd6940085748f3be6afa52ae317155181ece31b66351ccffa4b0',
  },
  'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd0364140': {
    'c': '0379be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
    'u':
        '0479be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798b7c52588d95c3b9aa25b0403f1eef75702e84bb7597aabe663b82f6f04ef2777',
    'x': '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
  },
  'fffffffffffffffffffffffffffffffebaaedce6af48a03bbfd25e8cd036413f': {
    'c': '03c6047f9441ed7d6d3045406e95c07cd85c778e4b8cef3ca7abac09b95c709ee5',
  },
};

const Map<String, Map<String, String>> _r1Kat = {
  '1': {
    'c': '036b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
    'u':
        '046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c2964fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
    'x': '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
  },
  '2': {
    'c': '037cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978',
    'u':
        '047cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc4766997807775510db8ed040293d9ac69f7430dbba7dade63ce982299e04b79d227873d1',
    'x': '7cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978',
  },
  '3': {
    'c': '025ecbe4d1a6330a44c8f7ef951d4bf165e6c6b721efada985fb41661bc6e7fd6c',
  },
  '7': {
    'c': '028e533b6fa0bf7b4625bb30667c01fb607ef9f8b8a80fef5b300628703187b2a3',
  },
  'deadbeef': {
    'c': '02b487d183dc4806058eb31a29bedefd7bcca987b77a381a3684871d8449c18394',
  },
  '0102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f20': {
    'c': '02515c3d6eb9e396b904d3feca7f54fdcd0cc1e997bf375dca515ad0a6c3b4035f',
  },
  'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc632550': {
    'c': '026b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
    'u':
        '046b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296b01cbd1c01e58065711814b583f061e9d431cca994cea1313449bf97c840ae0a',
    'x': '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
  },
  'ffffffff00000000ffffffffffffffffbce6faada7179e84f3b9cac2fc63254f': {
    'c': '027cf27b188d034f7e8a52380304b51ac3c08969e277f21b35a60b48fc47669978',
  },
};

Secp256k1Fr _k1fr(BigInt v) =>
    Secp256k1Fr.fromBytes(_le32(v), endian: Endian.little);
Secp256r1Fr _r1fr(BigInt v) =>
    Secp256r1Fr.fromBytes(_le32(v), endian: Endian.little);
Secp256k1Fr _k1frN(BigInt v) => _k1fr(v % _n1);
Secp256r1Fr _r1frN(BigInt v) => _r1fr(v % _n2);

/// 32 random bits from two 16-bit draws: `nextInt(1 << 32)` is invalid on
/// dart2js (JS bitwise ops truncate to 32 bits), so never use `1 << N`
/// with N >= 32 on ints in browser-compiled tests.
int _rand32(Random rng) => (rng.nextInt(1 << 16) << 16) | rng.nextInt(1 << 16);

List<BigInt> _scalars(BigInt n) {
  final rng = Random(0xC0FFEE);
  final out = [
    BigInt.one,
    BigInt.two,
    BigInt.from(7),
    n - BigInt.one,
    n - BigInt.two,
  ];
  for (var i = 0; i < 10; i++) {
    var v = BigInt.zero;
    for (var j = 0; j < 8; j++) {
      v = (v << 32) | BigInt.from(_rand32(rng));
    }
    v %= n;
    if (v == BigInt.zero) v = BigInt.one;
    out.add(v);
  }
  return out;
}

void main() {
  group('secp256k1 point encodings', () {
    final g = Secp256k1Point.generator_;

    test('generator known-answer vectors', () {
      expect(
        _h(g.toCompressed()),
        '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
      );
      final u = g.toUncompressed();
      expect(u.length, 65);
      expect(u[0], 0x04);
      expect(
        _h(u.sublist(1, 33)),
        '79be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
      );
      expect(
        _h(u.sublist(33, 65)),
        '483ada7726a3c4655da4fbfc0e1108a8fd17b448a68554199c47d08ffb10d4b8',
      );
      expect(g.isOnCurve(), true);
      expect(g.isIdentity(), false);
    });

    test('identity encodes as zero buffers', () {
      final id = Secp256k1Point.identity_;
      expect(id.toBytes().toList(), List.filled(33, 0));
      expect(
        id.toBytes(CryptoKeyEncoding.uncompressed).toList(),
        List.filled(65, 0),
      );
      expect(id.toXOnly().toList(), List.filled(32, 0));
      expect(id.toUncompressed().toList(), List.filled(65, 0));
      for (final buf in [
        [0x00],
        List.filled(33, 0),
        List.filled(65, 0),
      ]) {
        final a = Secp256k1Point.fromBytes(buf);
        expect(a.isIdentity(), true, reason: 'len=${buf.length}');
        expect(a.isZero(), true);
      }
    });

    test('scalar multiples match known-answer vectors', () {
      for (final e in _k1Kat.entries) {
        final p = g * _k1fr(BigInt.parse(e.key, radix: 16));
        expect(_h(p.toCompressed()), e.value['c'], reason: 'k=${e.key}');
        final u = e.value['u'];
        if (u != null) {
          expect(_h(p.toUncompressed()), u, reason: 'k=${e.key}');
        }
        final x = e.value['x'];
        if (x != null) {
          expect(_h(p.toXOnly()), x, reason: 'k=${e.key}');
        }
        expect(
          Secp256k1Point.fromCompressed(p.toCompressed().toList()) == p,
          true,
        );
        expect(
          Secp256k1Point.fromUncompressed(p.toUncompressed().toList()) == p,
          true,
        );
      }
    });

    test('encode/decode roundtrips', () {
      for (final k in _scalars(_n1)) {
        final p = g * _k1fr(k);
        expect(
          Secp256k1Point.fromCompressed(p.toCompressed().toList()) == p,
          true,
        );
        expect(
          Secp256k1Point.fromUncompressed(p.toUncompressed().toList()) == p,
          true,
        );
        expect(Secp256k1Point.fromBytes(p.toBytes().toList()) == p, true);
        expect(
          Secp256k1Point.fromBytes(
                p.toBytes(CryptoKeyEncoding.uncompressed).toList(),
              ) ==
              p,
          true,
        );
        final raw = [...p.toXOnly(), ...p.toAffine().y.toBytes()];
        expect(Secp256k1Point.fromBytes(raw) == p, true);
        expect(
          Secp256k1Point.fromUncompressed(
                Secp256k1Point.fromCompressed(
                  p.toCompressed().toList(),
                ).toUncompressed().toList(),
              ) ==
              p,
          true,
        );
      }
    });

    test('compressed prefix tracks y parity, y preserved exactly', () {
      var saw02 = false;
      var saw03 = false;
      for (final k in _scalars(_n1)) {
        final p = g * _k1fr(k);
        final c = p.toCompressed();
        final u = p.toUncompressed();
        final yOdd = (_be(u.sublist(33, 65)).isOdd);
        expect(c[0], yOdd ? 0x03 : 0x02);
        if (yOdd) {
          saw03 = true;
        } else {
          saw02 = true;
        }
        expect(_be(u.sublist(1, 33)), _be(c.sublist(1, 33)));
        expect(_be(u.sublist(33, 65)), _be(p.toAffine().y.toBytes()));
      }
      expect(saw02 && saw03, true, reason: 'both parities exercised');
    });

    test('group law and order', () {
      expect((g * _k1frN(_n1)).isIdentity(), true, reason: 'n*G == inf');
      expect(() => _k1fr(_n1), throwsA(anything), reason: 'n not canonical');
      expect(((g * _k1fr(_n1 - BigInt.one)) + g).isIdentity(), true);
      expect((g + (-g)).isIdentity(), true);
      expect(g.double() == g + g, true);
      expect(g.double() == g * _k1fr(BigInt.two), true);
      expect((g * _k1fr(BigInt.one)) == g, true);
      expect((g * _k1fr(BigInt.zero)).isIdentity(), true);
      final rng = Random(7);
      for (var i = 0; i < 5; i++) {
        var a = BigInt.zero;
        var b = BigInt.zero;
        for (var j = 0; j < 8; j++) {
          a = (a << 32) | BigInt.from(_rand32(rng));
          b = (b << 32) | BigInt.from(_rand32(rng));
        }
        a %= _n1;
        b %= _n1;
        expect(
          (g * _k1fr((a + b) % _n1)) == (g * _k1fr(a)) + (g * _k1fr(b)),
          true,
        );
        expect(
          (g * _k1fr(a)) - (g * _k1fr(b)) == (g * _k1fr((a - b) % _n1)),
          true,
        );
      }
    });

    test('equality and hashCode contract', () {
      for (final k in _scalars(_n1).take(6)) {
        final p = g * _k1fr(k);
        final viaAdd = p + p;
        final viaDbl = p.double();
        expect(viaAdd == viaDbl, true);
        expect(viaAdd.hashCode, viaDbl.hashCode);
        expect({viaAdd, viaDbl}.length, 1);
      }
      final infs = {
        Secp256k1Point.identity_,
        g + (-g),
        g * _k1frN(_n1),
        Secp256k1Point(x: g.x, y: g.y, z: Secp256k1Fp.zero),
      };
      for (final inf in infs) {
        expect(inf.isIdentity(), true);
      }
      expect(infs.map((e) => e.hashCode).toSet().length, 1);
      expect(infs.length, 1);
    });

    test('strict decoding rejects garbage', () {
      List<int> be32(BigInt v) => _be32(v);
      final p = _p1;
      for (final len in [0, 2, 32, 34, 66, 100]) {
        expect(
          () => Secp256k1Point.fromBytes(List.filled(len, 0)),
          throwsA(anything),
          reason: 'len=$len',
        );
      }
      expect(() => Secp256k1Point.fromBytes([0x01]), throwsA(anything));
      for (final prefix in [0x00, 0x01, 0x04, 0x05, 0x06, 0x07]) {
        expect(
          () => Secp256k1Point.fromCompressed([prefix, ...List.filled(32, 1)]),
          throwsA(anything),
          reason: 'compressed prefix=$prefix',
        );
      }
      expect(
        () => Secp256k1Point.fromCompressed([0x02, ...be32(p)]),
        throwsA(anything),
      );
      expect(
        () => Secp256k1Point.fromCompressed([
          0x03,
          ...be32((BigInt.one << 256) - BigInt.one),
        ]),
        throwsA(anything),
      );
      var nonResidue = -1;
      for (var x = 1; x < 100; x++) {
        try {
          Secp256k1Point.fromCompressed([0x02, ...be32(BigInt.from(x))]);
        } catch (_) {
          nonResidue = x;
          break;
        }
      }
      expect(nonResidue != -1, true);
      expect(
        () => Secp256k1Point.fromUncompressed(List.filled(64, 0)),
        throwsA(anything),
      );
      for (final prefix in [0x00, 0x02, 0x03, 0x05, 0x06, 0x07]) {
        final good = g.toUncompressed().toList();
        good[0] = prefix;
        expect(
          () => Secp256k1Point.fromUncompressed(good),
          throwsA(anything),
          reason: 'uncompressed prefix=$prefix',
        );
      }
      final badY = g.toUncompressed().toList();
      badY.setRange(33, 65, be32(p));
      expect(() => Secp256k1Point.fromUncompressed(badY), throwsA(anything));
      final offU = g.toUncompressed().toList();
      final xPlus = (_be(offU.sublist(1, 33)) + BigInt.one) % p;
      offU.setRange(1, 33, be32(xPlus));
      expect(() => Secp256k1Point.fromUncompressed(offU), throwsA(anything));
      expect(
        () => Secp256k1Point.fromBytes([
          ...be32(BigInt.one),
          ...be32(BigInt.one),
        ]),
        throwsA(anything),
      );
      expect(
        () => Secp256k1Point.fromBytes(List.filled(64, 0)),
        throwsA(anything),
      );
      expect(() => g.identity().toCompressed(), throwsA(anything));
      expect(
        () => Secp256k1Point.fromCompressed(List.filled(33, 0)),
        throwsA(anything),
      );
    });

    test('affine on-curve checks', () {
      expect(g.toAffine().isOnCurve(), true);
      expect(Secp256k1AffinePoint.identity().isOnCurve(), true);
      expect(
        const Secp256k1AffinePoint(
          x: Secp256k1Fp.zero,
          y: Secp256k1Fp.zero,
        ).isOnCurve(),
        true,
      );
      final one = Secp256k1Fp.fromBytes(
        _le32(BigInt.one),
        endian: Endian.little,
      );
      expect(Secp256k1AffinePoint(x: one, y: one).isOnCurve(), false);
      expect(Secp256k1AffinePoint.identity().toCurve().isIdentity(), true);
    });
  });

  group('secp256r1 point encodings', () {
    final g = Secp256r1Point.generator_;

    test('generator known-answer vectors', () {
      expect(
        _h(g.toCompressed()),
        '036b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
      );
      final u = g.toUncompressed();
      expect(u.length, 65);
      expect(u[0], 0x04);
      expect(
        _h(u.sublist(1, 33)),
        '6b17d1f2e12c4247f8bce6e563a440f277037d812deb33a0f4a13945d898c296',
      );
      expect(
        _h(u.sublist(33, 65)),
        '4fe342e2fe1a7f9b8ee7eb4a7c0f9e162bce33576b315ececbb6406837bf51f5',
      );
      expect(g.isOnCurve(), true);
      expect(g.isIdentity(), false);
    });

    test('identity encodes as zero buffers', () {
      final id = Secp256r1Point.identity_;
      expect(id.toBytes().toList(), List.filled(33, 0));
      expect(
        id.toBytes(CryptoKeyEncoding.uncompressed).toList(),
        List.filled(65, 0),
      );
      expect(id.toXOnly().toList(), List.filled(32, 0));
      expect(id.toUncompressed().toList(), List.filled(65, 0));
      for (final buf in [
        [0x00],
        List.filled(33, 0),
        List.filled(65, 0),
      ]) {
        final a = Secp256r1Point.fromBytes(buf);
        expect(a.isIdentity(), true, reason: 'len=${buf.length}');
        expect(a.isZero(), true);
      }
    });

    test('scalar multiples match known-answer vectors', () {
      for (final e in _r1Kat.entries) {
        final p = g * _r1fr(BigInt.parse(e.key, radix: 16));
        expect(_h(p.toCompressed()), e.value['c'], reason: 'k=${e.key}');
        final u = e.value['u'];
        if (u != null) {
          expect(_h(p.toUncompressed()), u, reason: 'k=${e.key}');
        }
        final x = e.value['x'];
        if (x != null) {
          expect(_h(p.toXOnly()), x, reason: 'k=${e.key}');
        }
        expect(
          Secp256r1Point.fromCompressed(p.toCompressed().toList()) == p,
          true,
        );
        expect(
          Secp256r1Point.fromUncompressed(p.toUncompressed().toList()) == p,
          true,
        );
      }
    });

    test('encode/decode roundtrips', () {
      for (final k in _scalars(_n2)) {
        final p = g * _r1fr(k);
        expect(
          Secp256r1Point.fromCompressed(p.toCompressed().toList()) == p,
          true,
        );
        expect(
          Secp256r1Point.fromUncompressed(p.toUncompressed().toList()) == p,
          true,
        );
        expect(Secp256r1Point.fromBytes(p.toBytes().toList()) == p, true);
        expect(
          Secp256r1Point.fromBytes(
                p.toBytes(CryptoKeyEncoding.uncompressed).toList(),
              ) ==
              p,
          true,
        );
        final raw = [...p.toXOnly(), ...p.toAffine().y.toBytes()];
        expect(Secp256r1Point.fromBytes(raw) == p, true);
        expect(
          Secp256r1Point.fromUncompressed(
                Secp256r1Point.fromCompressed(
                  p.toCompressed().toList(),
                ).toUncompressed().toList(),
              ) ==
              p,
          true,
        );
      }
    });

    test('compressed prefix tracks y parity, y preserved exactly', () {
      var saw02 = false;
      var saw03 = false;
      for (final k in _scalars(_n2)) {
        final p = g * _r1fr(k);
        final c = p.toCompressed();
        final u = p.toUncompressed();
        final yOdd = (_be(u.sublist(33, 65)).isOdd);
        expect(c[0], yOdd ? 0x03 : 0x02);
        if (yOdd) {
          saw03 = true;
        } else {
          saw02 = true;
        }
        expect(_be(u.sublist(1, 33)), _be(c.sublist(1, 33)));
        expect(_be(u.sublist(33, 65)), _be(p.toAffine().y.toBytes()));
      }
      expect(saw02 && saw03, true, reason: 'both parities exercised');
    });

    test('group law and order', () {
      expect((g * _r1frN(_n2)).isIdentity(), true, reason: 'n*G == inf');
      expect(() => _r1fr(_n2), throwsA(anything), reason: 'n not canonical');
      expect(((g * _r1fr(_n2 - BigInt.one)) + g).isIdentity(), true);
      expect((g + (-g)).isIdentity(), true);
      expect(g.double() == g + g, true);
      expect(g.double() == g * _r1fr(BigInt.two), true);
      expect((g * _r1fr(BigInt.one)) == g, true);
      expect((g * _r1fr(BigInt.zero)).isIdentity(), true);
      final rng = Random(9);
      for (var i = 0; i < 5; i++) {
        var a = BigInt.zero;
        var b = BigInt.zero;
        for (var j = 0; j < 8; j++) {
          a = (a << 32) | BigInt.from(_rand32(rng));
          b = (b << 32) | BigInt.from(_rand32(rng));
        }
        a %= _n2;
        b %= _n2;
        expect(
          (g * _r1fr((a + b) % _n2)) == (g * _r1fr(a)) + (g * _r1fr(b)),
          true,
        );
        expect(
          (g * _r1fr(a)) - (g * _r1fr(b)) == (g * _r1fr((a - b) % _n2)),
          true,
        );
      }
    });

    test('equality and hashCode contract', () {
      for (final k in _scalars(_n2).take(6)) {
        final p = g * _r1fr(k);
        final viaAdd = p + p;
        final viaDbl = p.double();
        expect(viaAdd == viaDbl, true);
        expect(viaAdd.hashCode, viaDbl.hashCode);
        expect({viaAdd, viaDbl}.length, 1);
      }
      final infs = {
        Secp256r1Point.identity_,
        g + (-g),
        g * _r1frN(_n2),
        Secp256r1Point(x: g.x, y: g.y, z: Secp256r1Fp.zero),
      };
      for (final inf in infs) {
        expect(inf.isIdentity(), true);
      }
      expect(infs.map((e) => e.hashCode).toSet().length, 1);
      expect(infs.length, 1);
    });

    test('strict decoding rejects garbage', () {
      List<int> be32(BigInt v) => _be32(v);
      final p = _p2;
      for (final len in [0, 2, 32, 34, 66, 100]) {
        expect(
          () => Secp256r1Point.fromBytes(List.filled(len, 0)),
          throwsA(anything),
          reason: 'len=$len',
        );
      }
      expect(() => Secp256r1Point.fromBytes([0x01]), throwsA(anything));
      for (final prefix in [0x00, 0x01, 0x04, 0x05, 0x06, 0x07]) {
        expect(
          () => Secp256r1Point.fromCompressed([prefix, ...List.filled(32, 1)]),
          throwsA(anything),
          reason: 'compressed prefix=$prefix',
        );
      }
      expect(
        () => Secp256r1Point.fromCompressed([0x02, ...be32(p)]),
        throwsA(anything),
      );
      expect(
        () => Secp256r1Point.fromCompressed([
          0x03,
          ...be32((BigInt.one << 256) - BigInt.one),
        ]),
        throwsA(anything),
      );
      var nonResidue = -1;
      for (var x = 1; x < 100; x++) {
        try {
          Secp256r1Point.fromCompressed([0x02, ...be32(BigInt.from(x))]);
        } catch (_) {
          nonResidue = x;
          break;
        }
      }
      expect(nonResidue != -1, true);
      expect(
        () => Secp256r1Point.fromUncompressed(List.filled(64, 0)),
        throwsA(anything),
      );
      for (final prefix in [0x00, 0x02, 0x03, 0x05, 0x06, 0x07]) {
        final good = g.toUncompressed().toList();
        good[0] = prefix;
        expect(
          () => Secp256r1Point.fromUncompressed(good),
          throwsA(anything),
          reason: 'uncompressed prefix=$prefix',
        );
      }
      final badY = g.toUncompressed().toList();
      badY.setRange(33, 65, be32(p));
      expect(() => Secp256r1Point.fromUncompressed(badY), throwsA(anything));
      final offU = g.toUncompressed().toList();
      final xPlus = (_be(offU.sublist(1, 33)) + BigInt.one) % p;
      offU.setRange(1, 33, be32(xPlus));
      expect(() => Secp256r1Point.fromUncompressed(offU), throwsA(anything));
      expect(
        () => Secp256r1Point.fromBytes([
          ...be32(BigInt.one),
          ...be32(BigInt.one),
        ]),
        throwsA(anything),
      );
      expect(
        () => Secp256r1Point.fromBytes(List.filled(64, 0)),
        throwsA(anything),
      );
      expect(() => g.identity().toCompressed(), throwsA(anything));
      expect(
        () => Secp256r1Point.fromCompressed(List.filled(33, 0)),
        throwsA(anything),
      );
    });

    test('affine on-curve checks', () {
      expect(g.toAffine().isOnCurve(), true);
      expect(Secp256r1AffinePoint.identity().isOnCurve(), true);
      final one = Secp256r1Fp.fromBytes(
        _le32(BigInt.one),
        endian: Endian.little,
      );
      expect(Secp256r1AffinePoint(x: one, y: one).isOnCurve(), false);
      expect(Secp256r1AffinePoint.identity().toCurve().isIdentity(), true);
    });
  });
}
