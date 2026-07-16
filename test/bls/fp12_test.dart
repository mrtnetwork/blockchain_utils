import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  test("BLS12/FP12", _testArithmetic);
}

void _testArithmetic() {
  // Construct Fp12 elements a, b, c
  final a = Bls12Fp12(
    c0: Bls12Fp6(
      c0: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x47f9cb98b1b82d58'),
          Uint64.parseHex('0x5fe911eba3aa1d9d'),
          Uint64.parseHex('0x96bf1b5f4dd81db3'),
          Uint64.parseHex('0x8100d27cc9259f5b'),
          Uint64.parseHex('0xafa20b9674640eab'),
          Uint64.parseHex('0x09bbcea7d8d9497d'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x0303cb98b1662daa'),
          Uint64.parseHex('0xd93110aa0a621d5a'),
          Uint64.parseHex('0xbfa9820c5be4a468'),
          Uint64.parseHex('0x0ba3643ecb05a348'),
          Uint64.parseHex('0xdc3534bb1f1c25a6'),
          Uint64.parseHex('0x06c305bb19c0e1c1'),
        ]),
      ),
      c1: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x46f9cb98b162d858'),
          Uint64.parseHex('0x0be9109cf7aa1d57'),
          Uint64.parseHex('0xc791bc55fece41d2'),
          Uint64.parseHex('0xf84c57704e385ec2'),
          Uint64.parseHex('0xcb49c1d9c010e60f'),
          Uint64.parseHex('0x0acdb8e158bfe3c8'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x8aefcb98b15f8306'),
          Uint64.parseHex('0x3ea1108fe4f21d54'),
          Uint64.parseHex('0xcf79f69fa1b7df3b'),
          Uint64.parseHex('0xe4f54aa1d16b1a3c'),
          Uint64.parseHex('0xba5e4ef86105a679'),
          Uint64.parseHex('0x0ed86c0797bee5cf'),
        ]),
      ),
      c2: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0xcee5cb98b15c2db4'),
          Uint64.parseHex('0x71591082d23a1d51'),
          Uint64.parseHex('0xd76230e944a17ca4'),
          Uint64.parseHex('0xd19e3dd3549dd5b6'),
          Uint64.parseHex('0xa972dc1701fa66e3'),
          Uint64.parseHex('0x12e31f2dd6bde7d6'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0xad2acb98b1732d9d'),
          Uint64.parseHex('0x2cfd10dd06961d64'),
          Uint64.parseHex('0x07396b86c6ef24e8'),
          Uint64.parseHex('0xbd76e2fdb1bfc820'),
          Uint64.parseHex('0x6afea7f6de94d0d5'),
          Uint64.parseHex('0x10994b0c5744c040'),
        ]),
      ),
    ),
    c1: Bls12Fp6(
      c0: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x47f9cb98b1b82d58'),
          Uint64.parseHex('0x5fe911eba3aa1d9d'),
          Uint64.parseHex('0x96bf1b5f4dd81db3'),
          Uint64.parseHex('0x8100d27cc9259f5b'),
          Uint64.parseHex('0xafa20b9674640eab'),
          Uint64.parseHex('0x09bbcea7d8d9497d'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x0303cb98b1662daa'),
          Uint64.parseHex('0xd93110aa0a621d5a'),
          Uint64.parseHex('0xbfa9820c5be4a468'),
          Uint64.parseHex('0x0ba3643ecb05a348'),
          Uint64.parseHex('0xdc3534bb1f1c25a6'),
          Uint64.parseHex('0x06c305bb19c0e1c1'),
        ]),
      ),
      c1: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x46f9cb98b162d858'),
          Uint64.parseHex('0x0be9109cf7aa1d57'),
          Uint64.parseHex('0xc791bc55fece41d2'),
          Uint64.parseHex('0xf84c57704e385ec2'),
          Uint64.parseHex('0xcb49c1d9c010e60f'),
          Uint64.parseHex('0x0acdb8e158bfe3c8'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x8aefcb98b15f8306'),
          Uint64.parseHex('0x3ea1108fe4f21d54'),
          Uint64.parseHex('0xcf79f69fa1b7df3b'),
          Uint64.parseHex('0xe4f54aa1d16b1a3c'),
          Uint64.parseHex('0xba5e4ef86105a679'),
          Uint64.parseHex('0x0ed86c0797bee5cf'),
        ]),
      ),
      c2: Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0xcee5cb98b15c2db4'),
          Uint64.parseHex('0x71591082d23a1d51'),
          Uint64.parseHex('0xd76230e944a17ca4'),
          Uint64.parseHex('0xd19e3dd3549dd5b6'),
          Uint64.parseHex('0xa972dc1701fa66e3'),
          Uint64.parseHex('0x12e31f2dd6bde7d6'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0xad2acb98b1732d9d'),
          Uint64.parseHex('0x2cfd10dd06961d64'),
          Uint64.parseHex('0x07396b86c6ef24e8'),
          Uint64.parseHex('0xbd76e2fdb1bfc820'),
          Uint64.parseHex('0x6afea7f6de94d0d5'),
          Uint64.parseHex('0x10994b0c5744c040'),
        ]),
      ),
    ),
  );

  final b = a;
  final c = a; // Similarly

  // Some arbitrary transformations to differentiate elements
  final aTransformed = a.square().invert()!.square() + c;
  final bTransformed = b.square().invert()!.square() + aTransformed;
  final cTransformed = c.square().invert()!.square() + bTransformed;

  // Assertions
  expect(aTransformed.square(), aTransformed * aTransformed);
  expect(bTransformed.square(), bTransformed * bTransformed);
  expect(cTransformed.square(), cTransformed * cTransformed);

  expect(
    (aTransformed + bTransformed) * cTransformed.square(),
    (cTransformed.square() * aTransformed) +
        (cTransformed.square() * bTransformed),
  );

  expect(
    aTransformed.invert()! * bTransformed.invert()!,
    (aTransformed * bTransformed).invert()!,
  );
  expect(aTransformed.invert()! * aTransformed, Bls12Fp12.one);

  expect(aTransformed != aTransformed.frobeniusMap(), true);
  expect(
    aTransformed,
    aTransformed
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap()
        .frobeniusMap(),
  );
}
