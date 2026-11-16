@TestOn('browser')
@Tags(['wasm'])
library;

import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

String hexOf(List<int> b) => BytesUtils.toHexString(b);

void main() {
  setUpAll(() async {
    // Shared harness: injects the glue script (served by the dart-test
    // static handler from test/wasm_assets/), waits for bootstrap, then
    // selects the Rust backend. No .so involved.
    // Optional overrides: BU_WASM_GLUE_URL / BU_WASM_MODULE_URL are VM-only;
    // on web pass an explicit config:
    //   await BlockchainUtilsTestApi.initWasmBrowser(const BuTestConfig(
    //     backend: BuTestBackend.wasm,
    //     wasmGlueUrl: 'https://host/bu.js',
    //     wasmModuleUrl: 'https://host/bu_bg.wasm',
    //   ));
    await BlockchainUtilsTestApi.initWasmBrowser();
  });

  group('wasm backend (BuWasm)', () {
    test('sha256 empty', () {
      expect(
        hexOf(QuickCrypto.sha256Hash([])),
        'e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855',
      );
    });
    test('sha256 abc', () {
      expect(
        hexOf(QuickCrypto.sha256Hash([97, 98, 99])),
        'ba7816bf8f01cfea414140de5dae2223b00361a396177a9cb410ff61f20015ad',
      );
    });
    test('keccak256 empty', () {
      expect(
        hexOf(QuickCrypto.keccak256Hash([])),
        'c5d2460186f7233c927e7db2dcc703c0e500b653ca82273b7bfad8045d85a470',
      );
    });
    test('secp256k1 multBase(1) == G', () {
      final pk = blockchainUtils.api.secp256k1.multBase(
        List<int>.filled(31, 0) + [1],
      );
      expect(
        hexOf(pk),
        '0279be667ef9dcbbac55a06295ce870b07029bfcdb2dce28d959f2815b16f81798',
      );
    });
    test('chacha20poly1305 roundtrip', () {
      final aead = blockchainUtils.api.aed.chacha20Poly1305(
        List<int>.filled(32, 1),
      );
      const nonce = [2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2, 2];
      const pt = [104, 105];
      final ct = aead.encrypt(nonce, pt);
      expect(aead.decrypt(nonce, ct), pt);
    });
    test('pbkdf2-sha256 length', () {
      final dk = QuickCrypto.pbkdf2Sha256DeriveKey(
        password: [1, 2, 3],
        salt: [4, 5, 6],
        iterations: 2,
        dklen: 32,
      );
      expect(dk.length, 32);
    });
    test('monero bp+ prove/verify (M=1)', () {
      final gamma = List<int>.filled(32, 0)..[0] = 7;
      final seed = List<int>.filled(32, 9);
      final proof = blockchainUtils.api.monero.bpPlusProveAmounts(
        amounts: [BigInt.zero],
        gamma: [gamma],
        seed: seed,
      );
      expect(proof.v.length, 1);
      expect(blockchainUtils.api.monero.bpPlusVerify([proof]), true);
    });
  });
}
