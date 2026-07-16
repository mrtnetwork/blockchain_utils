import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp6.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

import 'fp_test.dart';

void main() {
  test("BLS12/FP6 Native", () {
    final a =
        Bls12Fp6(
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
        ).toNative();

    final b =
        Bls12Fp6(
          c0: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0xf120cb98b16fd84b'),
              Uint64.parseHex('0x5fb510cff3de1d61'),
              Uint64.parseHex('0x0f21a5d069d8c251'),
              Uint64.parseHex('0xaa1fd62f34f2839a'),
              Uint64.parseHex('0x5a1335157f89913f'),
              Uint64.parseHex('0x14a3fe329643c247'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0x3516cb98b16c82f9'),
              Uint64.parseHex('0x926d10c2e1261d5f'),
              Uint64.parseHex('0x1709e01a0cc25fba'),
              Uint64.parseHex('0x96c8c960b8253f14'),
              Uint64.parseHex('0x4927c234207e51a9'),
              Uint64.parseHex('0x18aeb158d542c44e'),
            ]),
          ),
          c1: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0xbf0dcb98b16982fc'),
              Uint64.parseHex('0xa67910b71d1a1d5c'),
              Uint64.parseHex('0xb7c147c2b8fb06ff'),
              Uint64.parseHex('0x1efa710d47d2e7ce'),
              Uint64.parseHex('0xed20a79c7e27653c'),
              Uint64.parseHex('0x02b85294dac1dfba'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0x9d52cb98b18082e5'),
              Uint64.parseHex('0x621d111151761d6f'),
              Uint64.parseHex('0xe79882603b48af43'),
              Uint64.parseHex('0x0ad31637a4f4da37'),
              Uint64.parseHex('0xaeac737c5ac1cf2e'),
              Uint64.parseHex('0x006e7e735b48b824'),
            ]),
          ),
          c2: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0xe148cb98b17d2d93'),
              Uint64.parseHex('0x94d511043ebe1d6c'),
              Uint64.parseHex('0xef80bca9de324cac'),
              Uint64.parseHex('0xf77c0969282795b1'),
              Uint64.parseHex('0x9dc1009afbb68f97'),
              Uint64.parseHex('0x047931999a47ba2b'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0x253ecb98b179d841'),
              Uint64.parseHex('0xc78d10f72c061d6a'),
              Uint64.parseHex('0xf768f6f3811bea15'),
              Uint64.parseHex('0xe424fc9aab5a512b'),
              Uint64.parseHex('0x8cd58db99cab5001'),
              Uint64.parseHex('0x0883e4bfd946bc32'),
            ]),
          ),
        ).toNative();

    final c =
        Bls12Fp6(
          c0: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0x6934cb98b17682ef'),
              Uint64.parseHex('0xfa4510ea194e1d67'),
              Uint64.parseHex('0xff51313d2405877e'),
              Uint64.parseHex('0xd0cdefcc2e8d0ca5'),
              Uint64.parseHex('0x7bea1ad83da0106b'),
              Uint64.parseHex('0x0c8e97e61845be39'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0x4779cb98b18d82d8'),
              Uint64.parseHex('0xb5e911444daa1d7a'),
              Uint64.parseHex('0x2f286bdaa6532fc2'),
              Uint64.parseHex('0xbca694f68baeff0f'),
              Uint64.parseHex('0x3d75e6b81a3a7a5d'),
              Uint64.parseHex('0x0a44c3c498cc96a3'),
            ]),
          ),
          c1: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0x8b6fcb98b18a2d86'),
              Uint64.parseHex('0xe8a111373af21d77'),
              Uint64.parseHex('0x3710a624493ccd2b'),
              Uint64.parseHex('0xa94f88280ee1ba89'),
              Uint64.parseHex('0x2c8a73d6bb2f3ac7'),
              Uint64.parseHex('0x0e4f76ead7cb98aa'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0xcf65cb98b186d834'),
              Uint64.parseHex('0x1b59112a283a1d74'),
              Uint64.parseHex('0x3ef8e06dec266a95'),
              Uint64.parseHex('0x95f87b5992147603'),
              Uint64.parseHex('0x1b9f00f55c23fb31'),
              Uint64.parseHex('0x125a2a1116ca9ab1'),
            ]),
          ),
          c2: Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0x135bcb98b18382e2'),
              Uint64.parseHex('0x4e11111d15821d72'),
              Uint64.parseHex('0x46e11ab78f1007fe'),
              Uint64.parseHex('0x82a16e8b1547317d'),
              Uint64.parseHex('0x0ab38e13fd18bb9b'),
              Uint64.parseHex('0x1664dd3755c99cb8'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0xce65cb98b1318334'),
              Uint64.parseHex('0xc7590fdb7c3a1d2e'),
              Uint64.parseHex('0x6fcb81649d1c8eb3'),
              Uint64.parseHex('0x0d44004d1727356a'),
              Uint64.parseHex('0x3746b738a7d0d296'),
              Uint64.parseHex('0x136c144a96b134fc'),
            ]),
          ),
        ).toNative();

    // Squaring
    expect(a.square(), a * a);
    expect(b.square(), b * b);
    expect(c.square(), c * c);

    // Distributive property
    expect((a + b) * c.square(), (c * c * a) + (c * c * b));

    // Inversion
    expect((a.invert()! * b.invert()!), (a * b).invert()!);
    expect(a.invert()! * a, Bls12NativeFp6.one());
  });
}

extension _ToNative on Bls12Fp2 {
  Bls12NativeFp2 toNative() {
    return Bls12NativeFp2(c0: c0.toNative(), c1: c1.toNative());
  }
}

extension Bls12NativeFp6ToNative on Bls12Fp6 {
  Bls12NativeFp6 toNative() =>
      Bls12NativeFp6(c0: c0.toNative(), c1: c1.toNative(), c2: c2.toNative());
}
