import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/cipher/api/src/dart.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:test/test.dart';

import '../../utils.dart';

/// Rust-vs-Dart byte parity for every hash routed through the backend
/// (`blockchainUtils.api.hash.*`, same core behind FFI and WASM) plus FF1
/// (`DartFf1Api` vs the native backend held by `blockchainUtils`).
///
/// Oracle: pure-Dart backend (`setDartApi`). Subject: whatever backend the
/// suite selected (default `ffi` = Rust, `-p chrome` = Rust WASM).
/// Every case asserts byte equality across input sizes empty → 10 B → 10 KiB.
void hashFf1ParityTest() {
  group('hash parity: byte equality over input sizes', () {
    BuBytes withDartBackend(BuBytes Function() fn) {
      final active = blockchainUtils.api;
      blockchainUtils.setDartApi();
      try {
        return fn();
      } finally {
        blockchainUtils.setApi(active);
      }
    }

    BuBytes digestOnce(BuSerializableHash h, List<int> msg) {
      try {
        // Split update exercises streaming on both sides.
        const split = 7;
        if (msg.length <= split) {
          h.update(msg);
        } else {
          h.update(msg.sublist(0, split));
          h.update(msg.sublist(split));
        }
        return h.digest().asBytes;
      } finally {
        h.clean();
      }
    }

    List<int> bytes(int len, [int seed = 1]) =>
        List<int>.generate(len, (i) => ((i * 5 + seed) & 0xff));

    final algos = <String, BuSerializableHash Function()>{
      'sha1': () => blockchainUtils.api.hash.sha1(),
      'sha224': () => blockchainUtils.api.hash.sha224(),
      'sha256': () => blockchainUtils.api.hash.sha256(),
      'sha384': () => blockchainUtils.api.hash.sha384(),
      'sha512': () => blockchainUtils.api.hash.sha512(),
      'sha512_256': () => blockchainUtils.api.hash.sha512256(),
      'md4': () => blockchainUtils.api.hash.md4(),
      'md5': () => blockchainUtils.api.hash.md5(),
      'ripemd128': () => blockchainUtils.api.hash.ripemd128(),
      'ripemd160': () => blockchainUtils.api.hash.ripemd160(),
      'ripemd256': () => blockchainUtils.api.hash.ripemd256(),
      'ripemd320': () => blockchainUtils.api.hash.ripemd320(),
      'keccak32': () => blockchainUtils.api.hash.keccak(digestLength: 32),
      'keccak64': () => blockchainUtils.api.hash.keccak(digestLength: 64),
      'sha3_32': () => blockchainUtils.api.hash.sha3(digestLength: 32),
      'sha3_64': () => blockchainUtils.api.hash.sha3(digestLength: 64),
      'blake2b64': () => blockchainUtils.api.hash.blake2b(digestLength: 64),
      'blake2b32': () => blockchainUtils.api.hash.blake2b(digestLength: 32),
      'blake2s32': () => blockchainUtils.api.hash.blake2s(digestLength: 32),
      'blake2s16': () => blockchainUtils.api.hash.blake2s(digestLength: 16),
      'xxh64': () => blockchainUtils.api.hash.xxHash(bitLength: 64),
      'xxh256': () => blockchainUtils.api.hash.xxHash(bitLength: 256),
      'shake128': () => blockchainUtils.api.hash.shake128(),
      'shake256': () => blockchainUtils.api.hash.shake256(),
      'hmac-sha256':
          () => blockchainUtils.api.hash.hmacSha256(List<int>.filled(32, 0x0b)),
      'hmac-sha384':
          () => blockchainUtils.api.hash.hmacSha384(List<int>.filled(32, 0x0b)),
      'hmac-sha512':
          () => blockchainUtils.api.hash.hmacSha512(List<int>.filled(32, 0x0b)),
    };

    for (final entry in algos.entries) {
      for (final len in [0, 10, 10 * 1024]) {
        test('${entry.key} input $len B matches', () {
          final msg = bytes(len);
          final expected = withDartBackend(
            () => digestOnce(entry.value(), msg),
          );
          final actual = digestOnce(entry.value(), msg);
          expect(
            actual.toHex(),
            expected.toHex(),
            reason: '${entry.key} len=$len B must match Dart backend',
          );
        });
      }
    }

    test('keccakF1600 matches', () {
      final state = bytes(200, 9);
      final expected = withDartBackend(
        () => QuickCrypto.keccakF1600(BuBytes.from(state)),
      );
      final actual = QuickCrypto.keccakF1600(BuBytes.from(state));
      expect(
        actual.toHex(),
        expected.toHex(),
        reason: 'keccakF1600 must match Dart backend',
      );
    });
  });

  group('ff1 parity: byte equality', () {
    final dartFf1 = DartFf1Api();

    BuFf1Api? tryNativeFf1() => blockchainUtils.backend?.ff1;

    List<int> digits(int len, int radix, [int seed = 3]) =>
        List<int>.generate(len, (i) => ((i * 7 + seed) % radix));

    group('flexible', () {
      for (final radix in [10, 16]) {
        for (final len in [10, 19, 100]) {
          for (final tweakLen in [0, 3]) {
            test(
              'radix $radix len $len tweak $tweakLen B roundtrip matches',
              () {
                final key = List<int>.generate(16, (i) => (i * 11 + 2) & 0xff);
                final pt = digits(len, radix);
                final tweak = digits(tweakLen, 256, 9);
                final dartCt = dartFf1.encrypt(
                  key: key,
                  radix: radix,
                  pt: pt,
                  tweak: tweak,
                );
                final native = tryNativeFf1();
                if (native == null) {
                  // No native backend (pure-Dart run): lock the API wiring
                  // against the direct class instead.
                  final direct = FF1Flexible(
                    radix: radix,
                    aes: QuickCrypto.aesInstance(key),
                  ).encrypt(FlexibleNumeralString(pt), tweak: tweak);
                  expect(dartCt.toHex(), direct.digits.toHex());
                } else {
                  final nativeCt =
                      native
                          .encrypt(key: key, radix: radix, pt: pt, tweak: tweak)
                          .unwrapOrThrowCryptoError()
                          .asBytes;
                  expect(
                    nativeCt.toHex(),
                    dartCt.toHex(),
                    reason: 'ff1 radix=$radix len=$len must match Dart backend',
                  );
                  final nativePt =
                      native
                          .decrypt(
                            key: key,
                            radix: radix,
                            ct: nativeCt,
                            tweak: tweak,
                          )
                          .unwrapOrThrowCryptoError()
                          .asBytes;
                  expect(nativePt.toHex(), pt.toHex());
                }
                final dartPt = dartFf1.decrypt(
                  key: key,
                  radix: radix,
                  ct: dartCt,
                  tweak: tweak,
                );
                expect(dartPt.toHex(), pt.toHex());
              },
            );
          }
        }
      }
    });

    group('binary', () {
      // NOTE: Dart requires radix-2 numeral count >= 20 (NIST domain rule),
      // Rust only requires >= 2. Sizes stay in the overlap. Rust max is
      // 4096 bits, so 10 KiB is not expressible for binary FF1.
      for (final len in [4, 16, 64]) {
        for (final tweakLen in [0, 3]) {
          test('bytes $len tweak $tweakLen B roundtrip matches', () {
            final key = List<int>.generate(16, (i) => (i * 11 + 2) & 0xff);
            final pt = List<int>.generate(
              len,
              (i) => (((i * 13 + 5) & 0xff) | (i == 0 ? 0x80 : 0)),
            );
            final tweak = digits(tweakLen, 256, 9);
            final dartCt = dartFf1.encryptBinary(
              key: key,
              pt: pt,
              tweak: tweak,
            );
            final native = tryNativeFf1();
            if (native == null) {
              final direct = FF1Binary(
                aes: QuickCrypto.aesInstance(key),
              ).encrypt(BinaryNumeralString(pt), tweak: tweak);
              expect(dartCt.toHex(), direct.data.toHex());
            } else {
              final nativeCt =
                  native
                      .encryptBinary(key: key, pt: pt, tweak: tweak)
                      .unwrapOrThrowCryptoError()
                      .asBytes;
              expect(
                nativeCt.toHex(),
                dartCt.toHex(),
                reason: 'ff1-binary len=$len must match Dart backend',
              );
              final nativePt =
                  native
                      .decryptBinary(key: key, ct: nativeCt, tweak: tweak)
                      .unwrapOrThrowCryptoError()
                      .asBytes;
              expect(nativePt.toHex(), pt.toHex());
            }
            final dartPt = dartFf1.decryptBinary(
              key: key,
              ct: dartCt,
              tweak: tweak,
            );
            expect(dartPt.toHex(), pt.toHex());
          });
        }
      }
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hashFf1ParityTest, 'Hash+FF1 parity');
}
