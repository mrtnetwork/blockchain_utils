import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// Rust-vs-Dart parity for formerly capped inputs in `blockchain-utils`
/// (Rust core). See `src/aead/chacha20poly1305.rs`, `src/hash/hkdf.rs`,
/// `src/cipher/modes/{cbc,ecb}.rs`.
///
/// Oracle: pure-Dart backend (`setDartApi`, streaming, no fixed buffers).
/// Subject: whatever backend the suite selected (default `ffi` = Rust).
/// Every case asserts byte equality between the two backends across the
/// size matrix empty → 10 B → 10 KiB.
///
/// NOTE: CBC has no multi-block padded API on the Dart side (both backends
/// expose only single-block CBC), so CBC sizes are covered by the Rust unit
/// test `cbc_padded_sizes_roundtrip` instead.
void rustLimitsParityTest() {
  group('rust-vs-dart parity: byte equality over input sizes', () {
    BuBytes withDartBackend(BuBytes Function() fn) {
      final active = blockchainUtils.api;
      blockchainUtils.setDartApi();
      try {
        return fn();
      } finally {
        blockchainUtils.setApi(active);
      }
    }

    List<int> bytes(int len, [int seed = 1]) =>
        List<int>.generate(len, (i) => ((i * 5 + seed) & 0xff));

    group('chacha20poly1305', () {
      for (final ptLen in [0, 10, 10 * 1024]) {
        test('plaintext $ptLen B roundtrips identically', () {
          final key = bytes(32);
          final nonce = bytes(12, 7);
          final pt = bytes(ptLen);
          final aad = bytes(10, 9);

          final expected = withDartBackend(
            () => QuickCrypto.chaCha20Poly1305Encrypt(
              key: key,
              nonce: nonce,
              plainText: pt,
              assocData: aad,
            ),
          );
          // Pre-fix Rust: BuError(internal: chacha20poly1305_encrypt: 6)
          // once aad+ciphertext exceeded the 4KiB stack buffer.
          final actual = QuickCrypto.chaCha20Poly1305Encrypt(
            key: key,
            nonce: nonce,
            plainText: pt,
            assocData: aad,
          );
          expect(
            actual.toHex(),
            expected.toHex(),
            reason: 'chacha encrypt pt=$ptLen B must match Dart backend',
          );

          final expectedPt = withDartBackend(
            () => QuickCrypto.chaCha20Poly1305Decrypt(
              key: key,
              nonce: nonce,
              cipherText: expected,
              assocData: aad,
            ),
          );
          final actualPt = QuickCrypto.chaCha20Poly1305Decrypt(
            key: key,
            nonce: nonce,
            cipherText: actual,
            assocData: aad,
          );
          expect(
            actualPt.toHex(),
            expectedPt.toHex(),
            reason: 'chacha decrypt pt=$ptLen B must match Dart backend',
          );
          expect(actualPt.toHex(), pt.toHex());
        });
      }

      test('large aad (10 KiB) matches', () {
        final key = bytes(32);
        final nonce = bytes(12, 7);
        final pt = bytes(10);
        final aad = bytes(10 * 1024, 3);
        final expected = withDartBackend(
          () => QuickCrypto.chaCha20Poly1305Encrypt(
            key: key,
            nonce: nonce,
            plainText: pt,
            assocData: aad,
          ),
        );
        final actual = QuickCrypto.chaCha20Poly1305Encrypt(
          key: key,
          nonce: nonce,
          plainText: pt,
          assocData: aad,
        );
        expect(
          actual.toHex(),
          expected.toHex(),
          reason: 'chacha encrypt aad=10KiB must match Dart backend',
        );
      });
    });

    group('hkdf', () {
      for (final entry
          in {
            'sha256': QuickCrypto.hkdfDeriveSha256,
            'sha512': QuickCrypto.hkdfDeriveSha512,
          }.entries) {
        for (final infoLen in [0, 10, 10 * 1024]) {
          test('${entry.key} info $infoLen B matches', () {
            final ikm = List<int>.filled(22, 0x0b);
            final salt = List<int>.generate(13, (i) => i);
            final info = bytes(infoLen);
            final expected = withDartBackend(
              () => entry.value(ikm: ikm, length: 64, salt: salt, info: info),
            );
            final actual = entry.value(
              ikm: ikm,
              length: 64,
              salt: salt,
              info: info,
            );
            expect(
              actual.toHex(),
              expected.toHex(),
              reason: 'hkdf-${entry.key} info=$infoLen B must match',
            );
          });
        }
      }
    });

    group('aes-ecb padded', () {
      for (final ptLen in [0, 10, 10 * 1024]) {
        test('pkcs7 plaintext $ptLen B matches', () {
          final key = bytes(32, 2);
          final pt = bytes(ptLen, 4);
          final expected = withDartBackend(
            () => QuickCrypto.aesEcbEncrypt(
              key,
              pt,
              paddingAlgorithm: PaddingAlgorithm.pkcs7,
            ),
          );
          final actual = QuickCrypto.aesEcbEncrypt(
            key,
            pt,
            paddingAlgorithm: PaddingAlgorithm.pkcs7,
          );
          expect(
            actual.toHex(),
            expected.toHex(),
            reason: 'ecb pt=$ptLen B must match Dart backend',
          );
          final roundtrip = QuickCrypto.aesEcbDecrypt(
            key,
            actual,
            paddingAlgorithm: PaddingAlgorithm.pkcs7,
          );
          expect(roundtrip.toHex(), pt.toHex());
        });
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(rustLimitsParityTest, 'Rust limits parity');
}
