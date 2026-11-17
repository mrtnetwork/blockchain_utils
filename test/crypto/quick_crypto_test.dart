import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../utils.dart';

void quickCryptoScopedTest() {
  group('Scoped hash instances', () {
    test('sha256 result matches one-shot helper', () {
      final viaScoped = QuickCrypto.sha256((h) {
        h.update([1, 2, 3]);
        return h.digest().toHex();
      });
      expect(viaScoped, QuickCrypto.sha256Hash([1, 2, 3]).toHex());
    });

    test('sha256 return value passes through', () {
      final r = QuickCrypto.sha256((h) => 42);
      expect(r, 42);
    });

    test('hmac-sha256 matches one-shot helper', () {
      final key = List<int>.filled(20, 0x0b);
      final data = BytesUtils.fromHexString('4869205468657265');
      final viaScoped = QuickCrypto.hmacSha256(key, (h) {
        h.update(data);
        return h.digest().toHex();
      });
      expect(viaScoped, QuickCrypto.hmacsha256Hash(key, data).toHex());
    });

    test('blake2b keyed matches direct helper', () {
      final key = List<int>.filled(32, 7);
      final viaScoped = QuickCrypto.blake2b(
        (h) {
          h.update([9, 9, 9]);
          return h.digest().toHex();
        },
        digestLength: 32,
        config: Blake2Config.blake2b(key: key),
      );
      expect(
        viaScoped,
        QuickCrypto.blake2b256Hash([9, 9, 9], key: key).toHex(),
      );
    });

    test('shake256 XOF output length', () {
      final out = QuickCrypto.shake256((h) {
        h.update([1, 2, 3]);
        final b = BuBytes.fill(64, 0);
        h.finish(b);
        return b;
      });
      expect(out.length, 64);
    });

    test('exceptions from use propagate', () {
      expect(
        () => QuickCrypto.sha256((h) {
          h.update([0]);
          throw CoreErrors.cryptoFailed("test", reason: "boom");
        }),
        throwsA(isA<BuError>()),
      );
    });

    test('nullable results allowed', () {
      final r = QuickCrypto.sha256((h) => null);
      expect(r, isNull);
    });
  });

  group('Scoped cipher instances', () {
    test('aes-ecb roundtrip', () {
      final key = List<int>.filled(32, 1);
      final enc = QuickCrypto.aesEcb(key, (c) => c.encrypt([2, 3, 4]));
      final dec = QuickCrypto.aesEcb(
        key,
        (c) => c.decrypt(enc),
        padding: PaddingAlgorithm.pkcs7,
      );
      expect(dec, [2, 3, 4]);
    });

    test('aes-ctr roundtrip', () {
      final key = List<int>.filled(16, 2);
      final ctr = List<int>.filled(16, 3);
      final out = QuickCrypto.aesCtr(key, ctr, (c) {
        final dst = BuBytes.fill(4, 0);
        c.process([5, 6, 7, 8], dst);
        return dst;
      });
      final back = QuickCrypto.aesCtr(key, ctr, (c) {
        final dst = BuBytes.fill(4, 0);
        c.process(out, dst);
        return dst;
      });
      expect(back.toList(), [5, 6, 7, 8]);
    });

    test('chacha20 stream roundtrip', () {
      final key = List<int>.filled(32, 9);
      final nonce = List<int>.filled(12, 0);
      final ct = QuickCrypto.chacha20(
        key,
        (c) => c.process([1, 2, 3], nonce: nonce),
      );
      final pt = QuickCrypto.chacha20(key, (c) => c.process(ct, nonce: nonce));
      expect(pt.toList(), [1, 2, 3]);
    });

    test('chacha20-poly1305 roundtrip', () {
      final key = List<int>.filled(32, 4);
      final nonce = List<int>.filled(12, 1);
      final ct = QuickCrypto.chacha20Poly1305(
        key,
        (aead) => aead.encrypt(nonce, [10, 20, 30]),
      );
      final pt = QuickCrypto.chacha20Poly1305(
        key,
        (aead) => aead.decrypt(nonce, ct),
      );
      expect(pt?.toList(), [10, 20, 30]);
    });

    test('xsalsa20-poly1305 roundtrip', () {
      final key = List<int>.filled(32, 5);
      final nonce = List<int>.filled(24, 2);
      final ct = QuickCrypto.xsalsa20Poly1305(
        key,
        (box) => box.encrypt(nonce, [7, 8]),
      );
      final pt = QuickCrypto.xsalsa20Poly1305(
        key,
        (box) => box.decrypt(nonce, ct),
      );
      expect(pt?.toList(), [7, 8]);
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(quickCryptoScopedTest, "QuickCryptoScoped");
}
