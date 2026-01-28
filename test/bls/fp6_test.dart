import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:test/test.dart';

void main() {
  test("BLS12/FP6", () {
    final a = Bls12Fp6(
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
    );

    final b = Bls12Fp6(
      c0: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0xf120cb98b16fd84b'),
          BigInt.parse('0x5fb510cff3de1d61'),
          BigInt.parse('0x0f21a5d069d8c251'),
          BigInt.parse('0xaa1fd62f34f2839a'),
          BigInt.parse('0x5a1335157f89913f'),
          BigInt.parse('0x14a3fe329643c247'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0x3516cb98b16c82f9'),
          BigInt.parse('0x926d10c2e1261d5f'),
          BigInt.parse('0x1709e01a0cc25fba'),
          BigInt.parse('0x96c8c960b8253f14'),
          BigInt.parse('0x4927c234207e51a9'),
          BigInt.parse('0x18aeb158d542c44e'),
        ]),
      ),
      c1: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0xbf0dcb98b16982fc'),
          BigInt.parse('0xa67910b71d1a1d5c'),
          BigInt.parse('0xb7c147c2b8fb06ff'),
          BigInt.parse('0x1efa710d47d2e7ce'),
          BigInt.parse('0xed20a79c7e27653c'),
          BigInt.parse('0x02b85294dac1dfba'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0x9d52cb98b18082e5'),
          BigInt.parse('0x621d111151761d6f'),
          BigInt.parse('0xe79882603b48af43'),
          BigInt.parse('0x0ad31637a4f4da37'),
          BigInt.parse('0xaeac737c5ac1cf2e'),
          BigInt.parse('0x006e7e735b48b824'),
        ]),
      ),
      c2: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0xe148cb98b17d2d93'),
          BigInt.parse('0x94d511043ebe1d6c'),
          BigInt.parse('0xef80bca9de324cac'),
          BigInt.parse('0xf77c0969282795b1'),
          BigInt.parse('0x9dc1009afbb68f97'),
          BigInt.parse('0x047931999a47ba2b'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0x253ecb98b179d841'),
          BigInt.parse('0xc78d10f72c061d6a'),
          BigInt.parse('0xf768f6f3811bea15'),
          BigInt.parse('0xe424fc9aab5a512b'),
          BigInt.parse('0x8cd58db99cab5001'),
          BigInt.parse('0x0883e4bfd946bc32'),
        ]),
      ),
    );

    final c = Bls12Fp6(
      c0: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0x6934cb98b17682ef'),
          BigInt.parse('0xfa4510ea194e1d67'),
          BigInt.parse('0xff51313d2405877e'),
          BigInt.parse('0xd0cdefcc2e8d0ca5'),
          BigInt.parse('0x7bea1ad83da0106b'),
          BigInt.parse('0x0c8e97e61845be39'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0x4779cb98b18d82d8'),
          BigInt.parse('0xb5e911444daa1d7a'),
          BigInt.parse('0x2f286bdaa6532fc2'),
          BigInt.parse('0xbca694f68baeff0f'),
          BigInt.parse('0x3d75e6b81a3a7a5d'),
          BigInt.parse('0x0a44c3c498cc96a3'),
        ]),
      ),
      c1: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0x8b6fcb98b18a2d86'),
          BigInt.parse('0xe8a111373af21d77'),
          BigInt.parse('0x3710a624493ccd2b'),
          BigInt.parse('0xa94f88280ee1ba89'),
          BigInt.parse('0x2c8a73d6bb2f3ac7'),
          BigInt.parse('0x0e4f76ead7cb98aa'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0xcf65cb98b186d834'),
          BigInt.parse('0x1b59112a283a1d74'),
          BigInt.parse('0x3ef8e06dec266a95'),
          BigInt.parse('0x95f87b5992147603'),
          BigInt.parse('0x1b9f00f55c23fb31'),
          BigInt.parse('0x125a2a1116ca9ab1'),
        ]),
      ),
      c2: Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('0x135bcb98b18382e2'),
          BigInt.parse('0x4e11111d15821d72'),
          BigInt.parse('0x46e11ab78f1007fe'),
          BigInt.parse('0x82a16e8b1547317d'),
          BigInt.parse('0x0ab38e13fd18bb9b'),
          BigInt.parse('0x1664dd3755c99cb8'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('0xce65cb98b1318334'),
          BigInt.parse('0xc7590fdb7c3a1d2e'),
          BigInt.parse('0x6fcb81649d1c8eb3'),
          BigInt.parse('0x0d44004d1727356a'),
          BigInt.parse('0x3746b738a7d0d296'),
          BigInt.parse('0x136c144a96b134fc'),
        ]),
      ),
    );

    // Squaring
    expect(a.square(), a * a);
    expect(b.square(), b * b);
    expect(c.square(), c * c);

    // Distributive property
    expect((a + b) * c.square(), (c * c * a) + (c * c * b));

    // Inversion
    expect((a.invert()! * b.invert()!), (a * b).invert()!);
    expect(a.invert()! * a, Bls12Fp6.one());
  });
}
