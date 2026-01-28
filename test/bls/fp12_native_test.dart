import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp12.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:test/test.dart';

import 'fp6_native_test.dart';

void main() {
  test("BLS12/FP12 Native", () {
    _testArithmetic();
  });
}

void _testArithmetic() {
  // Construct Fp12 elements a, b, c
  final a =
      Bls12Fp12(
        c0: Bls12Fp6(
          c0: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0x47f9cb98b1b82d58'),
              BigInt.parse('0x5fe911eba3aa1d9d'),
              BigInt.parse('0x96bf1b5f4dd81db3'),
              BigInt.parse('0x8100d27cc9259f5b'),
              BigInt.parse('0xafa20b9674640eab'),
              BigInt.parse('0x09bbcea7d8d9497d'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0x0303cb98b1662daa'),
              BigInt.parse('0xd93110aa0a621d5a'),
              BigInt.parse('0xbfa9820c5be4a468'),
              BigInt.parse('0x0ba3643ecb05a348'),
              BigInt.parse('0xdc3534bb1f1c25a6'),
              BigInt.parse('0x06c305bb19c0e1c1'),
            ]),
          ),
          c1: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0x46f9cb98b162d858'),
              BigInt.parse('0x0be9109cf7aa1d57'),
              BigInt.parse('0xc791bc55fece41d2'),
              BigInt.parse('0xf84c57704e385ec2'),
              BigInt.parse('0xcb49c1d9c010e60f'),
              BigInt.parse('0x0acdb8e158bfe3c8'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0x8aefcb98b15f8306'),
              BigInt.parse('0x3ea1108fe4f21d54'),
              BigInt.parse('0xcf79f69fa1b7df3b'),
              BigInt.parse('0xe4f54aa1d16b1a3c'),
              BigInt.parse('0xba5e4ef86105a679'),
              BigInt.parse('0x0ed86c0797bee5cf'),
            ]),
          ),
          c2: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0xcee5cb98b15c2db4'),
              BigInt.parse('0x71591082d23a1d51'),
              BigInt.parse('0xd76230e944a17ca4'),
              BigInt.parse('0xd19e3dd3549dd5b6'),
              BigInt.parse('0xa972dc1701fa66e3'),
              BigInt.parse('0x12e31f2dd6bde7d6'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0xad2acb98b1732d9d'),
              BigInt.parse('0x2cfd10dd06961d64'),
              BigInt.parse('0x07396b86c6ef24e8'),
              BigInt.parse('0xbd76e2fdb1bfc820'),
              BigInt.parse('0x6afea7f6de94d0d5'),
              BigInt.parse('0x10994b0c5744c040'),
            ]),
          ),
        ),
        c1: Bls12Fp6(
          c0: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0x47f9cb98b1b82d58'),
              BigInt.parse('0x5fe911eba3aa1d9d'),
              BigInt.parse('0x96bf1b5f4dd81db3'),
              BigInt.parse('0x8100d27cc9259f5b'),
              BigInt.parse('0xafa20b9674640eab'),
              BigInt.parse('0x09bbcea7d8d9497d'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0x0303cb98b1662daa'),
              BigInt.parse('0xd93110aa0a621d5a'),
              BigInt.parse('0xbfa9820c5be4a468'),
              BigInt.parse('0x0ba3643ecb05a348'),
              BigInt.parse('0xdc3534bb1f1c25a6'),
              BigInt.parse('0x06c305bb19c0e1c1'),
            ]),
          ),
          c1: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0x46f9cb98b162d858'),
              BigInt.parse('0x0be9109cf7aa1d57'),
              BigInt.parse('0xc791bc55fece41d2'),
              BigInt.parse('0xf84c57704e385ec2'),
              BigInt.parse('0xcb49c1d9c010e60f'),
              BigInt.parse('0x0acdb8e158bfe3c8'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0x8aefcb98b15f8306'),
              BigInt.parse('0x3ea1108fe4f21d54'),
              BigInt.parse('0xcf79f69fa1b7df3b'),
              BigInt.parse('0xe4f54aa1d16b1a3c'),
              BigInt.parse('0xba5e4ef86105a679'),
              BigInt.parse('0x0ed86c0797bee5cf'),
            ]),
          ),
          c2: Bls12Fp2(
            c0: Bls12Fp([
              BigInt.parse('0xcee5cb98b15c2db4'),
              BigInt.parse('0x71591082d23a1d51'),
              BigInt.parse('0xd76230e944a17ca4'),
              BigInt.parse('0xd19e3dd3549dd5b6'),
              BigInt.parse('0xa972dc1701fa66e3'),
              BigInt.parse('0x12e31f2dd6bde7d6'),
            ]),
            c1: Bls12Fp([
              BigInt.parse('0xad2acb98b1732d9d'),
              BigInt.parse('0x2cfd10dd06961d64'),
              BigInt.parse('0x07396b86c6ef24e8'),
              BigInt.parse('0xbd76e2fdb1bfc820'),
              BigInt.parse('0x6afea7f6de94d0d5'),
              BigInt.parse('0x10994b0c5744c040'),
            ]),
          ),
        ),
      ).toNative();

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
  expect(aTransformed.invert()! * aTransformed, Bls12NativeFp12.one());

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

extension Bls12Fp12ToNative on Bls12Fp12 {
  Bls12NativeFp12 toNative() =>
      Bls12NativeFp12(c0: c0.toNative(), c1: c1.toNative());
}
