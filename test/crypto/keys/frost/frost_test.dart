import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

void main() {
  BlockchainUtilsTestApi.runTest(() {
    test('Frost secp256k1: fromSecretKeys 2of2, sign, verify', () {
      final secrets = [
        Secp256k1PrivateKey.fromBytes(bytes(0x11, 32)),
        Secp256k1PrivateKey.fromBytes(bytes(0x22, 32)),
      ];
      final key = FrostSecp256k1PrivateKey.fromSecretKeys(
        secrets,
        threshold: 2,
        coefficients: bytes(0x30, 64),
      );
      expect(key.type, CryptoKeyType.frostK1);
      expect(key.publicKey.threshold, 2);
      expect(key.publicKey.n, 2);
      expect(key.identifiers, [1, 2]);
      final back = FrostSecp256k1PrivateKey.fromBytes(key.toBytes());
      expect(back.publicKey, key.publicKey);
      expect(back.secretKeys.length, 2);
      final pkBack = FrostSecp256k1PublicKey.fromBytes(
        key.publicKey.toBytes(),
      );
      expect(pkBack, key.publicKey);
      expect(
        IPublicKey.fromBytes(
          key.publicKey.toBytes(),
          CryptoKeyType.frostK1,
        ),
        key.publicKey,
      );

      final msg = 'frost-k1-2of2'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 1],
          randomness: bytes(0x40, 128),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: 'nope'.codeUnits, signature: sig),
        ),
        isFalse,
      );
      key.dispose();
    });

    test('Frost secp256k1 2-of-3: every pair signs, auto-subset signs', () {
      final key = FrostSecp256k1PrivateKey.fromSecretKeys(
        [
          Secp256k1PrivateKey.fromBytes(bytes(0x41, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0x42, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0x43, 32)),
        ],
        threshold: 2,
        coefficients: bytes(0x44, 96),
      );
      final msg = 'frost-k1-2of3'.codeUnits;
      for (final pair in [
        [0, 1],
        [0, 2],
        [1, 2],
      ]) {
        final rand = pair.expand((i) => bytes(0x50 + i, 64)).toList();
        final sig = key.sign(
          FrostSigningParams(message: msg, subset: pair, randomness: rand),
        );
        expect(
          key.publicKey.verify(
            FrostVerifyingParams(message: msg, signature: sig),
          ),
          isTrue,
          reason: 'pair $pair must sign',
        );
      }
      final auto = key.sign(
        FrostSigningParams(message: msg, randomness: bytes(0x60, 128)),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: auto),
        ),
        isTrue,
      );
      final random = key.sign(FrostSigningParams(message: msg));
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: random),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('Frost secp256k1 fromSecretKeys threshold group rebuild', () {
      final secrets = [
        Secp256k1PrivateKey.fromBytes(bytes(0x71, 31) + [0x01]),
        Secp256k1PrivateKey.fromBytes(bytes(0x72, 31) + [0x02]),
      ];
      final key = FrostSecp256k1PrivateKey.fromSecretKeys(
        secrets,
        threshold: 2,
        coefficients: bytes(0x73, 64),
      );
      expect(key.publicKey.threshold, 2);
      expect(key.publicKey.n, 2);
      final agg = FrostSecp256k1PublicKey.aggPublicKeys(
        key.publicKey.members!.map((m) => m.key).toList(),
        threshold: 2,
      );
      expect(agg.aggKey, key.publicKey.aggKey);
      final msg = 'frost-k1-import'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 1],
          randomness: bytes(0x80, 128),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('Frost secp256k1 signing validation', () {
      final key = FrostSecp256k1PrivateKey.fromSecretKeys(
        [
          Secp256k1PrivateKey.fromBytes(bytes(0xB1, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0xB2, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0xB3, 32)),
        ],
        threshold: 2,
        coefficients: bytes(0xB4, 96),
      );
      final msg = 'frost-k1-validate'.codeUnits;
      expect(
        () => key.sign(
          FrostSigningParams(message: msg, subset: [0], randomness: bytes(0xC0, 64)),
        ),
        throwsA(anything),
      );
      expect(
        () => key.sign(
          FrostSigningParams(message: msg, subset: [0, 9], randomness: bytes(0xC1, 128)),
        ),
        throwsA(anything),
      );
      expect(
        () => FrostSigningParams(
          message: msg,
          subset: [0, 1],
          randomness: bytes(0xC2, 64),
        ),
        throwsA(anything),
      );
      key.dispose();
    });

    test('Frost Ed25519: fromSecretKeys seeds threshold, sign, verify', () {
      final key = FrostEd25519PrivateKey.fromSecretKeys([
        ED25519PrivateKey.fromBytes(bytes(0x11, 32)),
        ED25519PrivateKey.fromBytes(bytes(0x22, 32)),
      ], threshold: 2, coefficients: bytes(0x33, 64));
      expect(key.type, CryptoKeyType.frostEd25519);
      expect(key.publicKey.threshold, 2);
      final back = FrostEd25519PrivateKey.fromBytes(key.toBytes());
      expect(back.publicKey, key.publicKey);
      expect(
        IPublicKey.fromBytes(
          key.publicKey.toBytes(),
          CryptoKeyType.frostEd25519,
        ),
        key.publicKey,
      );

      final msg = 'frost-ed-2of2'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 1],
          randomness: bytes(0x30, 128),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('Frost Ed25519 additive (threshold null) full-set signs', () {
      final seeds = [
        ED25519PrivateKey.fromBytes(bytes(0xF1, 32)),
        ED25519PrivateKey.fromBytes(bytes(0xF2, 32)),
      ];
      final key = FrostEd25519PrivateKey.fromSecretKeys(seeds);
      expect(key.publicKey.threshold, isNull);
      final agg = FrostEd25519PublicKey.aggPublicKeys(
        seeds.map((e) => e.publicKey).toList(),
      );
      expect(key.publicKey, agg);
      final msg = 'frost-ed-additive'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 1],
          randomness: bytes(0xF3, 128),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      final groupKey = ED25519PublicKey.fromBytes(
        key.publicKey.aggKey.toBytes(),
      );
      expect(
        groupKey.verify(
          Ed25519VerifyingParams(
            Ed25519SigningParams(message: msg),
            ED25519Signature.fromBytes(sig.toBytes()),
          ),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('Frost Ed25519 2-of-3: every pair signs', () {
      final key = FrostEd25519PrivateKey.fromSecretKeys([
        ED25519PrivateKey.fromBytes(bytes(0xD1, 32)),
        ED25519PrivateKey.fromBytes(bytes(0xD2, 32)),
        ED25519PrivateKey.fromBytes(bytes(0xD3, 32)),
      ], threshold: 2, coefficients: bytes(0xD4, 96));
      final msg = 'frost-ed-2of3'.codeUnits;
      for (final pair in [
        [0, 1],
        [0, 2],
        [1, 2],
      ]) {
        final rand = pair.expand((i) => bytes(0xE0 + i, 64)).toList();
        final sig = key.sign(
          FrostSigningParams(message: msg, subset: pair, randomness: rand),
        );
        expect(
          key.publicKey.verify(
            FrostVerifyingParams(message: msg, signature: sig),
          ),
          isTrue,
          reason: 'pair $pair must sign',
        );
      }
      final auto = key.sign(FrostSigningParams(message: msg));
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: auto),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('Frost Ed25519 threshold signature verifies as plain Ed25519', () {
      final key = FrostEd25519PrivateKey.fromSecretKeys([
        ED25519PrivateKey.fromBytes(bytes(0x11, 32)),
        ED25519PrivateKey.fromBytes(bytes(0x22, 32)),
        ED25519PrivateKey.fromBytes(bytes(0x33, 32)),
      ], threshold: 3, coefficients: bytes(0x44, 192));
      final msg = 'frost-ed-3of3'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 1, 2],
          randomness: bytes(0x30, 192),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      final groupKey = ED25519PublicKey.fromBytes(
        key.publicKey.aggKey.toBytes(),
      );
      expect(groupKey, key.publicKey.aggKey);
      final plainSig = ED25519Signature.fromBytes(sig.toBytes());
      expect(
        groupKey.verify(
          Ed25519VerifyingParams(
            Ed25519SigningParams(message: msg),
            plainSig,
          ),
        ),
        isTrue,
      );
      final rebuilt = FrostEd25519PublicKey.aggPublicKeys(
        key.publicKey.members!.map((m) => m.key).toList(),
        threshold: 3,
      );
      expect(rebuilt.aggKey, groupKey);
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(
            message: 'nope'.codeUnits,
            signature: sig,
          ),
        ),
        isFalse,
      );
      key.dispose();
    });

    test(
        'Frost secp256k1 2-of-3 threshold signature verifies at backend',
        () {
      final key = FrostSecp256k1PrivateKey.fromSecretKeys(
        [
          Secp256k1PrivateKey.fromBytes(bytes(0x51, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0x52, 32)),
          Secp256k1PrivateKey.fromBytes(bytes(0x53, 32)),
        ],
        threshold: 2,
        coefficients: bytes(0x54, 96),
      );
      final msg = 'frost-k1-2of3-plain'.codeUnits;
      final sig = key.sign(
        FrostSigningParams(
          message: msg,
          subset: [0, 2],
          randomness: bytes(0x60, 128),
        ),
      );
      expect(
        key.publicKey.verify(
          FrostVerifyingParams(message: msg, signature: sig),
        ),
        isTrue,
      );
      final memberKeys =
          key.publicKey.members!.map((m) => m.key).toList();
      final rebuilt = FrostSecp256k1PublicKey.aggPublicKeys(
        memberKeys,
        threshold: 2,
      );
      expect(rebuilt.aggKey, key.publicKey.aggKey);
      final groupKey = Secp256k1PublicKey.fromBytes(
        rebuilt.aggKey.toBytes(),
      );
      final frost = blockchainUtils.api.frost;
      expect(
        frost.k1Verify(
          commitment: sig.r.toList(),
          z: sig.z,
          groupPublicKey: groupKey.keyBytes,
          message: msg,
        ),
        isTrue,
      );
      expect(
        frost.k1Verify(
          commitment: sig.r.toList(),
          z: sig.z,
          groupPublicKey: groupKey.keyBytes,
          message: 'nope'.codeUnits,
        ),
        isFalse,
      );
      key.dispose();
    });
  }, 'Frost Keys');
}
