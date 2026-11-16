import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

List<int> seeds(int n, int base) =>
    List<int>.generate(n * 32, (i) => (base + (i ~/ 32)) & 0xFF);

void main() {
  BlockchainUtilsTestApi.runTest(() {
    test('DKLs23 secp256k1 keys: generate, sign, verify', () {
      final sid = 'dkls23-dart-k1-2of2'.codeUnits;
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: sid,
        n: 2,
        threshold: 2,
        seeds: seeds(2, 0x10),
      );
      expect(key.type, CryptoKeyType.dkls23K1);
      expect(key.publicKey.threshold, 2);
      expect(key.publicKey.n, 2);
      // Serialization round-trip (private + aggregate).
      final blob = key.toBytes();
      final back = Dkls23Secp256k1PrivateKey.fromBytes(blob);
      expect(back.publicKey, key.publicKey);
      expect(back.secretKeys.length, 2);
      final pkBlob = key.publicKey.toBytes();
      final pkBack = Dkls23Secp256k1PublicKey.fromBytes(pkBlob);
      expect(pkBack, key.publicKey);
      expect(
        IPublicKey.fromBytes(pkBlob, CryptoKeyType.dkls23K1),
        key.publicKey,
      );
      // x-only is the group key's x-coordinate.
      expect(key.publicKey.xOnly(), key.publicKey.aggKey.toBytes().sublist(1, 33));

      final msgHash = List<int>.generate(32, (i) => (0xA0 + i) & 0xFF);
      final sig = key.sign(
        Dkls23SignParams(
          sid: sid,
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(2, 0x20),
        ),
      );
      expect(sig.toBytes(), hasLength(64));
      expect(
        key.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: sig),
        ),
        isTrue,
      );
      // Wrong hash fails.
      final bad = List<int>.generate(32, (i) => (0xB0 + i) & 0xFF);
      expect(
        key.publicKey.verify(
          Dkls23VerifyParams(msgHash: bad, signature: sig),
        ),
        isFalse,
      );
      key.dispose();
    });

    test('DKLs23 secp256r1 keys: generate, sign, verify', () {
      final sid = 'dkls23-dart-r1-2of2'.codeUnits;
      final key = Dkls23Secp256r1PrivateKey.generate(
        sid: sid,
        n: 2,
        threshold: 2,
        seeds: seeds(2, 0x30),
      );
      expect(key.type, CryptoKeyType.dkls23R1);
      final msgHash = List<int>.generate(32, (i) => (0xC0 + i) & 0xFF);
      final sig = key.sign(
        Dkls23SignParams(
          sid: sid,
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(2, 0x40),
        ),
      );
      expect(
        key.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: sig),
        ),
        isTrue,
      );
      final pkBack = Dkls23Secp256r1PublicKey.fromBytes(
        key.publicKey.toBytes(),
      );
      expect(pkBack, key.publicKey);
      key.dispose();
    });

    test('DKLs23 2-of-3: every pair signs, auto-subset signs (k1)', () {
      final sid = 'dkls23-dart-k1-2of3'.codeUnits;
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: sid,
        n: 3,
        threshold: 2,
        seeds: seeds(3, 0x50),
      );
      expect(key.publicKey.threshold, 2);
      expect(key.publicKey.n, 3);
      final msgHash = List<int>.generate(32, (i) => (0xD0 + i) & 0xFF);
      for (final pair in [
        [0, 1],
        [0, 2],
        [1, 2],
      ]) {
        final subSeeds = pair.expand((i) => seeds(3, 0x60).sublist(i * 32, i * 32 + 32)).toList();
        final sig = key.sign(
          Dkls23SignParams(sid: sid, msgHash: msgHash, subset: pair, seeds: subSeeds),
        );
        expect(
          key.publicKey.verify(
            Dkls23VerifyParams(msgHash: msgHash, signature: sig),
          ),
          isTrue,
          reason: 'pair $pair must sign',
        );
      }
      // Null subset auto-picks the first `t` shares.
      final auto = key.sign(
        Dkls23SignParams(sid: sid, msgHash: msgHash, seeds: seeds(2, 0x61)),
      );
      expect(
        key.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: auto),
        ),
        isTrue,
      );
      // Fully random signing (no sid/seeds) also verifies.
      final random = key.sign(Dkls23SignParams(msgHash: msgHash));
      expect(
        key.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: random),
        ),
        isTrue,
      );
      key.dispose();
    });

    test('DKLs23 generate defaults threshold to n', () {
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: 'dkls23-dart-default-t'.codeUnits,
        n: 2,
        seeds: seeds(2, 0x81),
      );
      expect(key.publicKey.threshold, 2);
      expect(key.publicKey.n, 2);
      key.dispose();
    });

    test('DKLs23 signing validation', () {
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: 'dkls23-dart-validate'.codeUnits,
        n: 3,
        threshold: 2,
        seeds: seeds(3, 0x82),
      );
      final msgHash = List<int>.generate(32, (i) => i & 0xFF);
      // Under-quorum subset.
      expect(
        () => key.sign(
          Dkls23SignParams(
            sid: [1],
            msgHash: msgHash,
            subset: [0],
            seeds: seeds(1, 0x83),
          ),
        ),
        throwsA(anything),
      );
      // Out-of-range index.
      expect(
        () => key.sign(
          Dkls23SignParams(
            sid: [1],
            msgHash: msgHash,
            subset: [0, 9],
            seeds: seeds(2, 0x84),
          ),
        ),
        throwsA(anything),
      );
      // Misaligned seeds.
      expect(
        () => Dkls23SignParams(
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(1, 0x85),
        ),
        throwsA(anything),
      );
      key.dispose();
    });

    test('DKLs23 empty session id rejected', () {
      expect(
        () => Dkls23Secp256k1PrivateKey.generate(
          sid: [],
          n: 2,
          seeds: seeds(2, 0x90),
        ),
        throwsA(anything),
      );
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: 'nonempty'.codeUnits,
        n: 2,
        seeds: seeds(2, 0x91),
      );
      expect(
        () => key.refresh(sid: [], seeds: seeds(2, 0x92)),
        throwsA(anything),
      );
      expect(
        () => Dkls23SignParams(msgHash: List<int>.filled(32, 1), sid: []),
        throwsA(anything),
      );
      key.dispose();
    });

    test('DKLs23 refresh keeps the group key (k1)', () {
      final key = Dkls23Secp256k1PrivateKey.generate(
        sid: 'dkls23-dart-k1-refresh'.codeUnits,
        n: 2,
        threshold: 2,
        seeds: seeds(2, 0x70),
      );
      final after = key.refresh(
        sid: 'refresh-1'.codeUnits,
        seeds: seeds(2, 0x71),
      );
      expect(after.publicKey, key.publicKey);
      final msgHash = List<int>.generate(32, (i) => (0xE0 + i) & 0xFF);
      final sig = after.sign(
        Dkls23SignParams(
          sid: 'refresh-sign'.codeUnits,
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(2, 0x72),
        ),
      );
      expect(
        after.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: sig),
        ),
        isTrue,
      );
      key.dispose();
      after.dispose();
    });

    test('DKLs23 aggPublicKeys matches import group key (k1)', () {
      final k1Secrets = [
        Secp256k1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x11 : 0x01)),
        Secp256k1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x22 : 0x02)),
      ];
      final agg = Dkls23Secp256k1PublicKey.aggPublicKeys(
        k1Secrets.map((e) => e.publicKey).toList(),
      );
      // Additive import quorum uses the plain member sum.
      final key = Dkls23Secp256k1PrivateKey.fromSecretKeys(k1Secrets);
      expect(key.publicKey, agg);
      expect(agg.threshold, k1Secrets.length);
      expect(agg.n, k1Secrets.length);
      // Explicit threshold is stored.
      final aggT = Dkls23Secp256k1PublicKey.aggPublicKeys(
        k1Secrets.map((e) => e.publicKey).toList(),
        threshold: 2,
      );
      expect(aggT.threshold, 2);
      key.dispose();
    });

    test('DKLs23 fromSecretKeys: established keys sign (k1 + r1)', () {
      final k1Secrets = [
        Secp256k1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x11 : 0x01)),
        Secp256k1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x22 : 0x02)),
      ];
      final k1 = Dkls23Secp256k1PrivateKey.fromSecretKeys(k1Secrets);
      // Group key is the member-point sum (additive quorum).
      final sum = Dkls23Secp256k1PublicKey.aggPublicKeys(
        k1Secrets.map((e) => e.publicKey).toList(),
      );
      expect(k1.publicKey, sum);
      final sid = 'dkls23-dart-import'.codeUnits;
      final msgHash = List<int>.generate(32, (i) => (0xF0 + i) & 0xFF);
      final sig = k1.sign(
        Dkls23SignParams(
          sid: sid,
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(2, 0x91),
        ),
      );
      expect(
        k1.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: sig),
        ),
        isTrue,
      );
      k1.dispose();

      final r1Secrets = [
        Secp256r1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x33 : 0x03)),
        Secp256r1PrivateKey.fromBytes(List<int>.generate(32, (i) => i == 31 ? 0x44 : 0x04)),
      ];
      final r1 = Dkls23Secp256r1PrivateKey.fromSecretKeys(r1Secrets);
      final sigR1 = r1.sign(
        Dkls23SignParams(
          sid: sid,
          msgHash: msgHash,
          subset: [0, 1],
          seeds: seeds(2, 0x92),
        ),
      );
      expect(
        r1.publicKey.verify(
          Dkls23VerifyParams(msgHash: msgHash, signature: sigR1),
        ),
        isTrue,
      );
      r1.dispose();
    });
  }, 'DKLs23 Keys');
}
