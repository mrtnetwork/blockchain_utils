import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

// Sui zkLogin v1 Groth16 BN254 verification through the Rust backend
// (FFI on the VM, WASM in the browser). There is no pure-Dart pairing
// implementation, so the Dart backend skips.
//
// Fixtures: fastcrypto `test_verify_zk_login` v1 vector (Google JWT proof,
// address_seed) + the insecure v1 VK (`insecure_pvk`, test-only).
// VK blob layout (`SuiVkBytes`): alpha64 + beta/gamma/delta 128 (EIP-197
// x1,x0,y1,y0) + u32be IC count + IC*64; proof 256B (a64+b128+c64);
// public input: address_seed as 32-byte big-endian.
const String _suiZkLoginTestVkHex =
    '2d4d9aa7e302d9df41749d5507949d05dbea33fbb16c643b22f599a2be6df2e2'
    '14bedd503c37ceb061d8ec60209fe345ce89830a19230301f076caff004d1926'
    '0967032fcbf776d1afc985f88877f182d38480a653f2decaa9794cbc3bf3060c'
    '0e187847ad4c798374d0d6732bf501847dd68bc0e071241e0213bc7fc13db7ab'
    '304cfbd1e08a704a99f5e847d93f8c3caafddec46b7a0d379da69a4d112346a7'
    '1739c1b1a457a8c7313123d24d2f9192f896b7c63eea05a9d57f06547ad0cec8'
    '198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2'
    '1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed'
    '090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b'
    '12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa'
    '198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2'
    '1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed'
    '090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b'
    '12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa'
    '000000022dc48631509ecb47cd041ef352a6f88992cdfcd9b847882b356bc23b'
    '0e416dbc061e0f715210dee4967ecdd2aa2d0dfe36a3647367d41e915bf12043'
    '89020bc5011baaa7d9561ed150ecf83aee95a17c9a157141eca30bd6e0f8d605'
    '3e9321681de85e42ce108405741671da4375c0a43585a1bef88e1d52201407f5'
    '84177697';
const String _suiZkLoginTestProofHex =
    '10ba57499b13954745df299637dc1c2cac1a7dbec3c4d4b1fa913582fcbc75ea'
    '2806c8a8fc3055997e112cc4f3f46139f93dde81ab2c5011f1ff7ed0ad6f494b'
    '1a5f02b5db1ed7433b19f0758703de41fdf3a32d418467a68bd26644b8ac4d91'
    '1922c1a87a17b99d47743373170f544b85f6bea635a76d0162c8c0d93d421912'
    '077becbb646f6d4fc62960ca2cf6631192b7e12271992c0c619449e9136bc1fc'
    '05bdebfc940664480c5549124b7923275f6e825d183193a9831328bf538753da'
    '00dfa4662d1adb0b84d7dfc43b047d8e4ad5c6ff4d5c3ef45b883cdf2d86e071'
    '2f61528a7f9150c67aec539d395a13085365b82c87d993f86988cb77f9949353';
// The single Groth16 public input is the v1 `all_inputs_hash`, NOT the raw
// address_seed: Poseidon(first, second, seed, maxEpoch, issHash, indexMod4,
// headerHash, modulusHash) for the fastcrypto `test_verify_zk_login`
// fixture (eph key 0x00…da8, Google JWK, maxEpoch 10000). Value produced by
// `calculateZkLoginAllInputsHashV1` (on_chain) and proven correct by the
// end-to-end verify in `on_chain/test/sui/zklogin_proof_verify_test.dart`.
const String _suiZkLoginTestInputHash =
    '1139610851336904743990936813861460733526000848854008602331892116611761423325';
BuBytes _hex(String h) => BuBytes(BytesUtils.fromHexString(h));

void suiZkloginVerifyTest() {
  test('sui zkLogin v1 test proof verifies', () {
    if (blockchainUtils.backend == null) {
      markTestSkipped('Groth16 needs the Rust backend (ffi/wasm).');
      return;
    }
    final proof = _hex(_suiZkLoginTestProofHex);
    final vk = _hex(_suiZkLoginTestVkHex);
    final inputs = BuBytes(
      BigintUtils.toBytes(BigInt.parse(_suiZkLoginTestInputHash), length: 32),
    );
    expect(proof.length, 256);
    final res = blockchainUtils.groth16.verifyBn254(
      proof: proof,
      vk: vk,
      publicInputs: inputs,
    );
    expect(res.isOk, isTrue);
  });

  test('tampered proof fails', () {
    if (blockchainUtils.backend == null) {
      markTestSkipped('Groth16 needs the Rust backend (ffi/wasm).');
      return;
    }
    final bad = BytesUtils.fromHexString(_suiZkLoginTestProofHex);
    bad[10] ^= 0xff;
    final res = blockchainUtils.groth16.verifyBn254(
      proof: BuBytes(bad),
      vk: _hex(_suiZkLoginTestVkHex),
      publicInputs: BuBytes(
        BigintUtils.toBytes(BigInt.parse(_suiZkLoginTestInputHash), length: 32),
      ),
    );
    expect(res.isErr, isTrue);
  });

  test('wrong public input fails', () {
    if (blockchainUtils.backend == null) {
      markTestSkipped('Groth16 needs the Rust backend (ffi/wasm).');
      return;
    }
    final res = blockchainUtils.groth16.verifyBn254(
      proof: _hex(_suiZkLoginTestProofHex),
      vk: _hex(_suiZkLoginTestVkHex),
      publicInputs: BuBytes(BigintUtils.toBytes(BigInt.one, length: 32)),
    );
    expect(res.isErr, isTrue);
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(suiZkloginVerifyTest, "Sui Zklogin Verify");
}
