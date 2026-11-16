// bls_hash_to_g1_test.dart
//
// Official RFC 9380 Appendix J.9.1 test vectors for
// BLS12381G1_XMD:SHA-256_SSWU_RO_. These are the same 5 vectors this
// implementation was verified against (via an independent from-scratch
// Python port, checked step-by-step against the compiled zkcrypto/
// bls12_381 Rust crate) before translation to Dart -- this file re-checks
// that translation compiles and runs correctly in your actual Dart
// environment against your real Bls12Fp / G1Projective types.
//
// Run: dart test bls_hash_to_g1_test.dart

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

const dst = 'QUUX-V01-CS02-with-BLS12381G1_XMD:SHA-256_SSWU_RO_';

class G1Vector {
  final String msg;
  final String expectedUncompressedHex; // x (48B) || y (48B), big-endian
  const G1Vector(this.msg, this.expectedUncompressedHex);
}

final vectors = <G1Vector>[
  const G1Vector(
    '',
    '052926add2207b76ca4fa57a8734416c8dc95e24501772c814278700eed6d1e4e8cf62d9c09db0fac349612b759e79a1'
        '08ba738453bfed09cb546dbb0783dbb3a5f1f566ed67bb6be0e8c67e2e81a4cc68ee29813bb7994998f3eae0c9c6a265',
  ),
  const G1Vector(
    'abc',
    '03567bc5ef9c690c2ab2ecdf6a96ef1c139cc0b2f284dca0a9a7943388a49a3aee664ba5379a7655d3c68900be2f6903'
        '0b9c15f3fe6e5cf4211f346271d7b01c8f3b28be689c8429c85b67af215533311f0b8dfaaa154fa6b88176c229f2885d',
  ),
  const G1Vector(
    'abcdef0123456789',
    '11e0b079dea29a68f0383ee94fed1b940995272407e3bb916bbf268c263ddd57a6a27200a784cbc248e84f357ce82d98'
        '03a87ae2caf14e8ee52e51fa2ed8eefe80f02457004ba4d486d6aa1f517c0889501dc7413753f9599b099ebcbbd2d709',
  ),
  G1Vector(
    'q128_${'q' * 128}',
    '15f68eaa693b95ccb85215dc65fa81038d69629f70aeee0d0f677cf22285e7bf58d7cb86eefe8f2e9bc3f8cb84fac488'
        '1807a1d50c29f430b8cafc4f8638dfeeadf51211e1602a5f184443076715f91bb90a48ba1e370edce6ae1062f5e6dd38',
  ),
  G1Vector(
    'a512_${'a' * 512}',
    '082aabae8b7dedb0e78aeb619ad3bfd9277a2f77ba7fad20ef6aabdc6c31d19ba5a6d12283553294c1825c4b3ca2dcfe'
        '05b84ae5a942248eea39e1d91030458c40153f3b654ab7872d779ad1e942856a20c438e8d99bc8abfbf74729ce1f7ac8',
  ),
];

void hashTest() {
  group('BlsHashToG1 (RFC 9380 official test vectors)', () {
    for (final v in vectors) {
      test(
        'msg="${v.msg.length > 20 ? '${v.msg.substring(0, 20)}...' : v.msg}" '
        '(len=${v.msg.length})',
        () {
          final point = BlsHashToG1.hashToG1(
            utf8Encode(v.msg),
            dst: utf8Encode(dst),
          );
          final affine = point.toAffine();

          expect(
            affine.toBytes(mode: CryptoKeyEncoding.uncompressed),
            BytesUtils.fromHexString(v.expectedUncompressedHex),
          );
        },
      );
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hashTest, "Hash");
}

List<int> utf8Encode(String s) => List<int>.from(s.codeUnits);
