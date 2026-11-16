import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

List<int> _scalar(int v) => List<int>.filled(31, 0) + [v];

void multikeyLayoutTest() {
  group('BLS aggregate private layout mirror', () {
    test('G1 wire format is u32 LE count || scalars', () {
      final key = Bls12G1AggregatePrivateKey.fromSecretKeys([
        Bls12G1PrivateKey.fromBytes(_scalar(0x11)),
        Bls12G1PrivateKey.fromBytes(_scalar(0x22)),
      ]);
      expect(
        List<int>.from(key.toBytes()),
        [2, 0, 0, 0, ..._scalar(0x11), ..._scalar(0x22)],
      );
    });

    test('G2 wire format is u32 LE count || scalars', () {
      final key = Bls12G2AggregatePrivateKey.fromSecretKeys([
        Bls12G2PrivateKey.fromBytes(_scalar(0x11)),
        Bls12G2PrivateKey.fromBytes(_scalar(0x22)),
      ]);
      expect(
        List<int>.from(key.toBytes()),
        [2, 0, 0, 0, ..._scalar(0x11), ..._scalar(0x22)],
      );
    });

    test('G1/G2 roundtrip via layout', () {
      final g1 = Bls12G1AggregatePrivateKey.fromSecretKeys([
        Bls12G1PrivateKey.fromBytes(_scalar(0x11)),
      ]);
      expect(Bls12G1AggregatePrivateKey.fromBytes(g1.toBytes()), g1);
      expect(
        Bls12G1AggregatePublicKey.fromBytes(g1.publicKey.toBytes()),
        g1.publicKey,
      );
      final g2 = Bls12G2AggregatePrivateKey.fromSecretKeys([
        Bls12G2PrivateKey.fromBytes(_scalar(0x11)),
      ]);
      expect(Bls12G2AggregatePrivateKey.fromBytes(g2.toBytes()), g2);
      expect(
        Bls12G2AggregatePublicKey.fromBytes(g2.publicKey.toBytes()),
        g2.publicKey,
      );
    });

    test('G1/G2 reject short, empty and trailing-garbage input', () {
      for (final bytes in [
        <int>[],
        [1, 2, 3],
        [1, 0, 0, 0, ..._scalar(0x11), 0x00],
        [2, 0, 0, 0, ..._scalar(0x11)],
      ]) {
        expect(
          () => Bls12G1AggregatePrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
          reason: 'G1 $bytes',
        );
        expect(
          () => Bls12G2AggregatePrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
          reason: 'G2 $bytes',
        );
        expect(Bls12G1AggregatePrivateKey.isValidBytes(bytes), isFalse);
        expect(Bls12G2AggregatePrivateKey.isValidBytes(bytes), isFalse);
      }
      final good = Bls12G1AggregatePrivateKey.fromSecretKeys([
        Bls12G1PrivateKey.fromBytes(_scalar(0x11)),
      ]).toBytes();
      expect(Bls12G1AggregatePrivateKey.isValidBytes(good), isTrue);
    });
  });

  group('MuSig2 layout roundtrip + rejects', () {
    test('private and aggregate public roundtrip', () {
      final keys = [
        Secp256k1PrivateKey.fromBytes(_scalar(0x11)),
        Secp256k1PrivateKey.fromBytes(_scalar(0x22)),
      ];
      final key = Musig2PrivateKey.generate(keys, sortPubKeys: true);
      expect(Musig2PrivateKey.fromBytes(key.toBytes()), key);
      expect(
        MuSig2AggregatePublicKey.fromBytes(key.publicKey.toBytes()),
        key.publicKey,
      );
    });

    test('short and empty input throws', () {
      for (final bytes in [
        <int>[],
        [1, 2, 3],
      ]) {
        expect(
          () => Musig2PrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => MuSig2AggregatePublicKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
      }
    });
  });

  group('FROST layout roundtrip + rejects', () {
    FrostSecp256k1PrivateKey k1() {
      return FrostSecp256k1PrivateKey.fromSecretKeys(
        [
          Secp256k1PrivateKey.fromBytes(_scalar(0x11)),
          Secp256k1PrivateKey.fromBytes(_scalar(0x22)),
        ],
        threshold: 2,
        coefficients: List<int>.filled(64, 0x30),
      );
    }

    FrostEd25519PrivateKey ed() {
      return FrostEd25519PrivateKey.fromSecretKeys([
        ED25519PrivateKey.fromBytes(_scalar(0x11)),
        ED25519PrivateKey.fromBytes(_scalar(0x22)),
      ], threshold: 2, coefficients: List<int>.filled(64, 0x33));
    }

    test('k1/ed private and public roundtrip', () {
      final a = k1();
      expect(FrostSecp256k1PrivateKey.fromBytes(a.toBytes()).publicKey, a.publicKey);
      expect(
        FrostSecp256k1PublicKey.fromBytes(a.publicKey.toBytes()),
        a.publicKey,
      );
      final b = ed();
      expect(FrostEd25519PrivateKey.fromBytes(b.toBytes()).publicKey, b.publicKey);
      expect(
        FrostEd25519PublicKey.fromBytes(b.publicKey.toBytes()),
        b.publicKey,
      );
    });

    test('short and empty input throws', () {
      for (final bytes in [
        <int>[],
        [1, 2, 3],
      ]) {
        expect(
          () => FrostSecp256k1PrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => FrostSecp256k1PublicKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => FrostEd25519PrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => FrostEd25519PublicKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
      }
    });
  });

  group('DKLs layout roundtrip + rejects', () {
    test('k1/r1 private and public roundtrip', () {
      final k1 = Dkls23Secp256k1PrivateKey.fromSecretKeys([
        Secp256k1PrivateKey.fromBytes(_scalar(0x11)),
        Secp256k1PrivateKey.fromBytes(_scalar(0x22)),
      ]);
      expect(
        Dkls23Secp256k1PrivateKey.fromBytes(k1.toBytes()).publicKey,
        k1.publicKey,
      );
      expect(
        Dkls23Secp256k1PublicKey.fromBytes(k1.publicKey.toBytes()),
        k1.publicKey,
      );
      final r1 = Dkls23Secp256r1PrivateKey.fromSecretKeys([
        Secp256r1PrivateKey.fromBytes(_scalar(0x11)),
        Secp256r1PrivateKey.fromBytes(_scalar(0x22)),
      ]);
      expect(
        Dkls23Secp256r1PrivateKey.fromBytes(r1.toBytes()).publicKey,
        r1.publicKey,
      );
      expect(
        Dkls23Secp256r1PublicKey.fromBytes(r1.publicKey.toBytes()),
        r1.publicKey,
      );
    });

    test('short and empty input throws', () {
      for (final bytes in [
        <int>[],
        [1, 2, 3],
      ]) {
        expect(
          () => Dkls23Secp256k1PrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => Dkls23Secp256k1PublicKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => Dkls23Secp256r1PrivateKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
        expect(
          () => Dkls23Secp256r1PublicKey.fromBytes(bytes),
          throwsA(isA<BuError>()),
        );
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(multikeyLayoutTest, "MultikeyLayout");
}
