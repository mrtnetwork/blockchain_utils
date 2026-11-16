import 'dart:convert';
import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/field.dart';
import 'package:blockchain_utils/crypto/crypto/lattice/ml/dsa/src/poly.dart';
import 'package:test/test.dart';
import 'vector.dart';

import '../../../utils.dart';

/// MLDSA
void mlDsaTest() {
  test('verify accepts a freshly generated signature', () {
    for (var i = 0; i < 32; i++) {
      final seed = Uint8List.sublistView(
        Uint8List.fromList(QuickCrypto.generateRandom()),
      );
      final kp = MLDSA.mldsa65.keygen(seed);

      final msg = utf8.encode('post-quantum signature test').immutable;
      final rnd = Uint8List.sublistView(
        Uint8List.fromList(QuickCrypto.generateRandom()),
      ); // deterministic
      final sig = MLDSA.mldsa65.sign(kp.secretKey, msg, rnd: rnd);
      final ok = MLDSA.mldsa65.verify(kp.publicKey, msg, sig);
      expect(ok, true);
    }
  });

  group('ML-DSA parameter sizes', () {
    test('ML-DSA-44 sizes', () {
      expect(MLDSAParams.mldsa44Params.publicKeyBytes, 1312);
      expect(MLDSAParams.mldsa44Params.secretKeyBytes, 2560);
      expect(MLDSAParams.mldsa44Params.signatureBytes, 2420);
    });

    test('ML-DSA-65 sizes', () {
      expect(MLDSAParams.mldsa65Params.publicKeyBytes, 1952);
      expect(MLDSAParams.mldsa65Params.secretKeyBytes, 4032);
      expect(MLDSAParams.mldsa65Params.signatureBytes, 3309);
    });

    test('ML-DSA-87 sizes', () {
      expect(MLDSAParams.mldsa87Params.publicKeyBytes, 2592);
      expect(MLDSAParams.mldsa87Params.secretKeyBytes, 4896);
      expect(MLDSAParams.mldsa87Params.signatureBytes, 4627);
    });
  });

  group('Field arithmetic', () {
    test('reduce / add / sub / mul basic', () {
      expect(MLDSAOperator.fieldReduce(0), 0);
      expect(MLDSAOperator.fieldReduce(MLDSAOperator.q), 0);
      expect(MLDSAOperator.fieldReduce(MLDSAOperator.q + 1), 1);
      expect(MLDSAOperator.fieldReduce(-1), MLDSAOperator.q - 1);

      expect(MLDSAOperator.fieldAdd(MLDSAOperator.q - 1, 1), 0);
      expect(MLDSAOperator.fieldSub(0, 1), MLDSAOperator.q - 1);
      expect(MLDSAOperator.fieldMul(2, 3), 6);
      expect(
        MLDSAOperator.fieldMul(MLDSAOperator.q - 1, 2),
        MLDSAOperator.fieldReduce(-2),
      );
    });

    test('center', () {
      expect(MLDSAOperator.fieldCenter(0), 0);
      expect(MLDSAOperator.fieldCenter(1), 1);
      expect(MLDSAOperator.fieldCenter(MLDSAOperator.q - 1), -1);
    });
  });

  group('NTT round-trip', () {
    test('ntt → invNtt recovers polynomial (random coeffs)', () {
      final p = Poly();
      for (var i = 0; i < 256; i++) {
        p.coeffs[i] = (i * 12345 + 7) % MLDSAOperator.q;
      }
      final original = List<int>.from(p.coeffs);
      p.toNtt();
      p.fromNtt();
      for (var i = 0; i < 256; i++) {
        expect(
          p.coeffs[i],
          original[i],
          reason: 'coeff $i after NTT round-trip',
        );
      }
    });
  });

  group('Sampling', () {
    test('sampleBounded eta=4 produces coeffs in [-4,4]', () {
      final seed = Uint8List(66);
      for (var i = 0; i < 66; i++) {
        seed[i] = i;
      }
      final p = PolyUtils.sampleBounded(seed, 4);
      for (final c in p.coeffs) {
        expect(c.abs() <= 4, true, reason: 'coeff $c out of range');
      }
    });

    test('sampleInBall has exactly tau non-zeros of ±1', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => i + 1));
      final p = PolyUtils.sampleInBall(seed, 49); // ML-DSA-65 tau
      var count = 0;
      for (final c in p.coeffs) {
        if (c != 0) {
          expect(c == 1 || c == -1, true);
          count++;
        }
      }
      expect(count, 49);
    });
  });

  group('ML-DSA-65 keygen', () {
    test('produces correct key lengths', () {
      final seed = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        seed[i] = i;
      }
      final kp = MLDSA.mldsa65.keygen(seed);
      expect(kp.publicKey.length, MLDSAParams.mldsa65Params.publicKeyBytes);
      expect(kp.secretKey.length, MLDSAParams.mldsa65Params.secretKeyBytes);
      expect(kp.seed, seed);
    });

    test('deterministic: same seed → same keys', () {
      final seed = Uint8List.fromList(List.generate(32, (i) => 42 + i));
      final a = MLDSA.mldsa65.keygen(seed);
      final b = MLDSA.mldsa65.keygen(seed);
      expect(a.publicKey, b.publicKey);
      expect(a.secretKey, b.secretKey);
    });

    test('different seeds → different public keys', () {
      final s1 = Uint8List(32)..[0] = 1;
      final s2 = Uint8List(32)..[0] = 2;
      final a = MLDSA.mldsa65.keygen(s1);
      final b = MLDSA.mldsa65.keygen(s2);
      expect(a.publicKey != b.publicKey, true);
    });
  });

  group('ML-DSA-65 sign / verify round-trip', () {
    test('sign produces correct signature length', () {
      final seed = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        seed[i] = i * 3;
      }
      final kp = MLDSA.mldsa65.keygen(seed);
      final msg = utf8.encode('hello ML-DSA');
      // deterministic signing (rnd = 0)
      final rnd = Uint8List(32);
      final sig = MLDSA.mldsa65.sign(kp.secretKey, msg, rnd: rnd);
      expect(sig.length, MLDSAParams.mldsa65Params.signatureBytes);
    });

    test('verify accepts a freshly generated signature', () {
      final seed = Uint8List(32);
      for (var i = 0; i < 32; i++) {
        seed[i] = 7 + i;
      }
      final kp = MLDSA.mldsa65.keygen(seed);
      final msg = utf8.encode('post-quantum signature test');
      final rnd = Uint8List(32); // deterministic
      final sig = MLDSA.mldsa65.sign(kp.secretKey, msg, rnd: rnd);
      final ok = MLDSA.mldsa65.verify(kp.publicKey, msg, sig);
      expect(ok, isTrue);
    });

    test('verify rejects wrong message', () {
      final seed = Uint8List(32)..[0] = 99;
      final kp = MLDSA.mldsa65.keygen(seed);
      final msg = utf8.encode('original');
      final rnd = Uint8List(32);
      final sig = MLDSA.mldsa65.sign(kp.secretKey, msg, rnd: rnd);
      final ok = MLDSA.mldsa65.verify(
        kp.publicKey,
        utf8.encode('tampered'),
        sig,
      );
      expect(ok, false);
    });

    test('verify rejects wrong public key', () {
      final kp1 = MLDSA.mldsa65.keygen(Uint8List(32)..[0] = 1);
      final kp2 = MLDSA.mldsa65.keygen(Uint8List(32)..[0] = 2);
      final msg = utf8.encode('msg');
      final sig = MLDSA.mldsa65.sign(kp1.secretKey, msg, rnd: Uint8List(32));
      final ok = MLDSA.mldsa65.verify(kp2.publicKey, msg, sig);
      expect(ok, false);
    });
  });

  group('All parameter sets keygen', () {
    for (final inst in [MLDSA.mldsa44, MLDSA.mldsa65, MLDSA.mldsa87]) {
      test('${inst.params.k}x${inst.params.l} keygen sizes', () {
        final kp = inst.keygen(Uint8List(32));
        expect(kp.publicKey.length, inst.params.publicKeyBytes);
        expect(kp.secretKey.length, inst.params.secretKeyBytes);
      });
    }
  });
  group("test vector", () {
    test("MLDSA 65 external sign", () {
      for (final data in mlDSA65External) {
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final keys = MLDSA.mldsa65.keygen(keySeed);

        expect(BytesUtils.toHexString(keys.publicKey), data["pk"]);
        expect(BytesUtils.toHexString(keys.secretKey), data["sk"]);
        final pk = MLDSA.mldsa65.publicKeyFromSecretKey(keys.secretKey);
        expect(pk, keys.publicKey);
        final signature = MLDSA.mldsa65.signExternal(
          keys.secretKey,
          message,
          rnd: signSeed,
        );

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = MLDSA.mldsa65.verifyExternal(
          keys.publicKey,
          message,
          signature,
        );

        expect(ok, true);
      }
    });
    test("MLDSA 65", () {
      for (final data in mlDsa65) {
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final keys = MLDSA.mldsa65.keygen(keySeed);

        expect(BytesUtils.toHexString(keys.publicKey), data["pk"]);
        expect(BytesUtils.toHexString(keys.secretKey), data["sk"]);
        final pk = MLDSA.mldsa65.publicKeyFromSecretKey(keys.secretKey);
        expect(pk, keys.publicKey);
        final signature = MLDSA.mldsa65.sign(
          keys.secretKey,
          message,
          rnd: signSeed,
        );

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = MLDSA.mldsa65.verify(keys.publicKey, message, signature);

        expect(ok, true);
      }
    });
    test("MLDSA 44", () {
      for (final data in mlDsa44) {
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final keys = MLDSA.mldsa44.keygen(keySeed);

        expect(BytesUtils.toHexString(keys.publicKey), data["pk"]);

        expect(BytesUtils.toHexString(keys.secretKey), data["sk"]);
        final pk = MLDSA.mldsa44.publicKeyFromSecretKey(keys.secretKey);
        expect(pk, keys.publicKey);
        final signature = MLDSA.mldsa44.sign(
          keys.secretKey,
          message,
          rnd: signSeed,
        );

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = MLDSA.mldsa44.verify(keys.publicKey, message, signature);

        expect(ok, true);
      }
    });
    test("MLDSA 87", () {
      for (final data in mlDsa87) {
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final keys = MLDSA.mldsa87.keygen(keySeed);

        expect(BytesUtils.toHexString(keys.publicKey), data["pk"]);

        expect(BytesUtils.toHexString(keys.secretKey), data["sk"]);
        final signature = MLDSA.mldsa87.sign(
          keys.secretKey,
          message,
          rnd: signSeed,
        );

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = MLDSA.mldsa87.verify(keys.publicKey, message, signature);
        final pk = MLDSA.mldsa87.publicKeyFromSecretKey(keys.secretKey);
        expect(pk, keys.publicKey);
        expect(ok, true);
      }
    });
  });
}

void mlDsaTestNative(BlockchainUtilsApi api) {
  group('ML-DSA-65 sign / verify round-trip', () {
    test('verify rejects wrong message', () {
      final seed = Uint8List(32)..[0] = 99;
      final kp = api.signing.mldsa.keygen(level: 65, seed: seed);
      final msg = utf8.encode('original');
      final rnd = Uint8List(32);
      final sig = api.signing.mldsa.sign(sk: kp.$2, message: msg, rnd: rnd);
      final ok = api.signing.mldsa.verify(
        pk: kp.$1,
        message: utf8.encode('tampered'),
        signature: sig,
      );
      expect(ok, false);
    });
  });

  group("native test vector", () {
    test("MLDSA 65", () {
      for (final data in mlDsa65) {
        final signing = api.signing.mldsa;
        final int level = 65;
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final (pk, sk) = signing.keygen(seed: keySeed, level: level);

        expect(BytesUtils.toHexString(pk), data["pk"]);
        expect(BytesUtils.toHexString(sk), data["sk"]);
        final pkFromSk = signing.publicKeyFromSecret(sk: sk);
        expect(pk, pkFromSk);
        final signature = signing.sign(sk: sk, message: message, rnd: signSeed);

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = signing.verify(
          pk: pk,
          message: message,
          signature: signature,
        );

        expect(ok, true);
      }
    });
    test("MLDSA 44", () {
      for (final data in mlDsa44) {
        final signing = api.signing.mldsa;
        final int level = 44;
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final (pk, sk) = signing.keygen(seed: keySeed, level: level);

        expect(BytesUtils.toHexString(pk), data["pk"]);
        expect(BytesUtils.toHexString(sk), data["sk"]);
        final pkFromSk = signing.publicKeyFromSecret(sk: sk);
        expect(pk, pkFromSk);
        final signature = signing.sign(sk: sk, message: message, rnd: signSeed);

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = signing.verify(
          pk: pk,
          message: message,
          signature: signature,
        );

        expect(ok, true);
      }
    });
    test("MLDSA 87", () {
      for (final data in mlDsa87) {
        final signing = api.signing.mldsa;
        final int level = 87;
        final keySeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["key_seed"]),
        );

        final signSeed = Uint8List.fromList(
          BytesUtils.fromHexString(data["sign_seed"]),
        );

        final message = Uint8List.fromList(
          BytesUtils.fromHexString(data["message"]),
        );
        final (pk, sk) = signing.keygen(seed: keySeed, level: level);

        expect(BytesUtils.toHexString(pk), data["pk"]);
        expect(BytesUtils.toHexString(sk), data["sk"]);
        final pkFromSk = signing.publicKeyFromSecret(sk: sk);
        expect(pk, pkFromSk);
        final signature = signing.sign(sk: sk, message: message, rnd: signSeed);

        expect(BytesUtils.toHexString(signature), data["signature"]);

        final ok = signing.verify(
          pk: pk,
          message: message,
          signature: signature,
        );

        expect(ok, true);
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(
    mlDsaTest,
    "Ml Dsa",
    onNative: mlDsaTestNative,
  );
}
