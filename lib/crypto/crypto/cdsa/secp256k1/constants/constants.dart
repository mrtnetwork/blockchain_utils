import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/types/types.dart';
import 'package:blockchain_utils/utils/binary/binary_operation.dart';

class Secp256k1Const {
  static const int combBits = 258;
  static final BigInt mask52 = BigInt.from(0xFFFFFFFFFFFFF);
  static final BigInt mask48 = BigInt.from(0x0FFFFFFFFFFFF);
  static final BigInt mask47 = BigInt.from(0xFFFFEFFFFFC2F);
  static final BigInt mask33 = BigInt.from(0x1000003D1);
  static final BigInt mask62 = maxU64 >> 2;
  static final BigInt high4Mask52 = BigInt.from(0xF000000000000);
  static final BigInt bit33Mask = BigInt.from(0x1000003D10);
  static final BigInt minosOne = BigInt.from(-1);
  static const int constGroupSize = 5;
  static const int constTableSize = (1 << (constGroupSize - 1));
  static const int constGroup = ((129 + constGroupSize - 1) ~/ constGroupSize);
  static const int ecmultConstBits = (constGroup * constGroupSize);
  static const int secp256k1B = 7;
  static final BigInt secp256k1n0 = BigInt.parse('13822214165235122497');
  static final BigInt secp256k1n1 = BigInt.parse('13451932020343611451');
  static final BigInt secp256k1n2 = BigInt.parse('18446744073709551614');
  static final BigInt secp256k1n3 = BigInt.parse('18446744073709551615');
  // Limbs of 2^256 minus the secp256k1 order
  static final BigInt secp256k1NC0 = BigInt.parse("4624529908474429119");
  static final BigInt secp256k1NC1 = BigInt.parse("4994812053365940164");
  static final BigInt secp256k1NC2 = BigInt.one;

// Limbs of half the secp256k1 order
  static final BigInt secp256k1NH0 = BigInt.parse("16134479119472337056");
  static final BigInt secp256k1NH1 = BigInt.parse("6725966010171805725");
  static final BigInt secp256k1NH2 = BigInt.parse("18446744073709551615");
  static final BigInt secp256k1NH3 = BigInt.parse("9223372036854775807");

  static const int secp256k1GeXMagnitudeMax = 4;
  static const int secp256k1GeYMagnitudeMax = 3;
  static const int secp256k1GejXMagnitudeMax = 4;
  static const int secp256k1GejYMagnitudeMax = 4;
  static const int secp256k1GejZMagnitudeMax = 1;
  static final Secp256k1ModinvSigned secp256k1Signed62One =
      Secp256k1ModinvSigned.constants(
          [BigInt.one, BigInt.zero, BigInt.zero, BigInt.zero, BigInt.zero]);
  static Secp256k1Scalar get minusB1 => Secp256k1Scalar.constants(
      BigInt.from(0x00000000),
      BigInt.from(0x00000000),
      BigInt.from(0x00000000),
      BigInt.from(0x00000000),
      BigInt.from(0xE4437ED6),
      BigInt.from(0x010E8828),
      BigInt.from(0x6F547FA9),
      BigInt.from(0x0ABFE4C3));
  static Secp256k1Scalar get minusB2 => Secp256k1Scalar.constants(
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFF),
      BigInt.from(0xFFFFFFFE),
      BigInt.from(0x8A280AC5),
      BigInt.from(0x0774346D),
      BigInt.from(0xD765CDA8),
      BigInt.from(0x3DB1562C));
  static Secp256k1Scalar get g1 => Secp256k1Scalar.constants(
      BigInt.from(0x3086D221),
      BigInt.from(0xA7D46BCD),
      BigInt.from(0xE86C90E4),
      BigInt.from(0x9284EB15),
      BigInt.from(0x3DAA8A14),
      BigInt.from(0x71E8CA7F),
      BigInt.from(0xE893209A),
      BigInt.from(0x45DBB031));
  static Secp256k1Scalar get g2 => Secp256k1Scalar.constants(
      BigInt.from(0xE4437ED6),
      BigInt.from(0x010E8828),
      BigInt.from(0x6F547FA9),
      BigInt.from(0x0ABFE4C4),
      BigInt.from(0x221208AC),
      BigInt.from(0x9DF506C6),
      BigInt.from(0x1571B4AE),
      BigInt.from(0x8AC47F71));

  static Secp256k1Scalar get sOffset => Secp256k1Scalar.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.one,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero);

  static Secp256k1Scalar get secp256k1ScalarOne => Secp256k1Scalar.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.one);

  static Secp256k1Scalar get secp256k1ScalarZero => Secp256k1Scalar.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero);

  static Secp256k1Fe get secp256k1FeOne => Secp256k1Fe.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.one);
  static Secp256k1Fe get secp256k1ConstBeta => Secp256k1Fe.constants(
      BigInt.from(0x7ae96a2b),
      BigInt.from(0x657c0710),
      BigInt.from(0x6e64479e),
      BigInt.from(0xac3434e9),
      BigInt.from(0x9cf04975),
      BigInt.from(0x12f58995),
      BigInt.from(0xc1396c28),
      BigInt.from(0x719501ee));

  static Secp256k1Fe get secp256k1PMinusOrder => Secp256k1Fe.constants(
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
      BigInt.one,
      BigInt.from(0x45512319),
      BigInt.from(0x50B75FC4),
      BigInt.from(0x402DA172),
      BigInt.from(0x2FC9BAEE));

  static Secp256k1ModinvInfo get secp256k1ConstModinfoScalar =>
      Secp256k1ModinvInfo(
          modulus: Secp256k1ModinvSigned.constants([
            BigInt.parse("4598842128380346689"),
            BigInt.parse("3079181878673178862"),
            BigInt.from(-21),
            BigInt.zero,
            BigInt.from(256)
          ]),
          modulusInv: BigInt.parse("3815112494326173377"));

  static Secp256k1ModinvInfo get secp256k1FieldModinfo => Secp256k1ModinvInfo(
      modulus: Secp256k1ModinvSigned.constants([
        BigInt.from(0x414036CD8BFD25BB),
        BigInt.from(0x03A64AF6DCEBAE00),
        BigInt.from(0xFFFFFEFFFFFEFFFF),
        BigInt.from(0xFFFFFFFFFFFFFFFF),
        BigInt.from(0xFFFFFFFFFFFFFFFF),
      ]),
      modulusInv: BigInt.from(0xD838091DD2253531));
  static Secp256k1ModinvSigned get modeInvOne =>
      Secp256k1ModinvSigned.constants([
        BigInt.one,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
      ]);
  static Secp256k1Ge get g7 => Secp256k1Ge.constants(
        BigInt.from(0x66625d13),
        BigInt.from(0x317ffe44),
        BigInt.from(0x63d32cff),
        BigInt.from(0x1ca02b9b),
        BigInt.from(0xe5c6d070),
        BigInt.from(0x50b4b05e),
        BigInt.from(0x81cc30db),
        BigInt.from(0xf5166f0a),
        BigInt.from(0x1e60e897),
        BigInt.from(0xa7c00c7c),
        BigInt.from(0x2df53eb6),
        BigInt.from(0x98274ff4),
        BigInt.from(0x64252f42),
        BigInt.from(0x8ca44e17),
        BigInt.from(0x3b25418c),
        BigInt.from(0xff4ab0cf),
      );
  static Secp256k1Ge get g13 => Secp256k1Ge.constants(
        BigInt.from(0xa2482ff8),
        BigInt.from(0x4bf34edf),
        BigInt.from(0xa51262fd),
        BigInt.from(0xe57921db),
        BigInt.from(0xe0dd2cb7),
        BigInt.from(0xa5914790),
        BigInt.from(0xbc71631f),
        BigInt.from(0xc09704fb),
        BigInt.from(0x942536cb),
        BigInt.from(0xa3e49492),
        BigInt.from(0x3a701cc3),
        BigInt.from(0xee3e443f),
        BigInt.from(0xdf182aa9),
        BigInt.from(0x15b8aa6a),
        BigInt.from(0x166d3b19),
        BigInt.from(0xba84b045),
      );
  static Secp256k1Ge get g199 => Secp256k1Ge.constants(
        BigInt.from(0x7fb07b5c),
        BigInt.from(0xd07c3bda),
        BigInt.from(0x553902e2),
        BigInt.from(0x7a87ea2c),
        BigInt.from(0x35108a7f),
        BigInt.from(0x051f41e5),
        BigInt.from(0xb76abad5),
        BigInt.from(0x1f2703ad),
        BigInt.from(0x0a251539),
        BigInt.from(0x5b4c4438),
        BigInt.from(0x952a634f),
        BigInt.from(0xac10dd4d),
        BigInt.from(0x6d6f4745),
        BigInt.from(0x98990c27),
        BigInt.from(0x3a4f3116),
        BigInt.from(0xd32ff969),
      );
  static Secp256k1Ge get G => Secp256k1Ge.constants(
        BigInt.from(0x79be667e),
        BigInt.from(0xf9dcbbac),
        BigInt.from(0x55a06295),
        BigInt.from(0xce870b07),
        BigInt.from(0x029bfcdb),
        BigInt.from(0x2dce28d9),
        BigInt.from(0x59f2815b),
        BigInt.from(0x16f81798),
        BigInt.from(0x483ada77),
        BigInt.from(0x26a3c465),
        BigInt.from(0x5da4fbfc),
        BigInt.from(0x0e1108a8),
        BigInt.from(0xfd17b448),
        BigInt.from(0xa6855419),
        BigInt.from(0x9c47d08f),
        BigInt.from(0xfb10d4b8),
      );
  static Secp256k1ModinvInfo get secp256k1ConstModinfoFe => Secp256k1ModinvInfo(
      modulus: Secp256k1ModinvSigned.constants([
        BigInt.from(-4294968273),
        BigInt.zero,
        BigInt.zero,
        BigInt.zero,
        BigInt.from(256)
      ]),
      modulusInv: BigInt.parse('2866531139136965327'));

  static Secp256k1Scalar get secp256k1ECmultConstK => Secp256k1Scalar.constants(
      BigInt.from(0xa4e88a7d),
      BigInt.from(0xcb13034e),
      BigInt.from(0xc2bdd6bf),
      BigInt.from(0x7c118d6b),
      BigInt.from(0x589ae848),
      BigInt.from(0x26ba29e4),
      BigInt.from(0xb5c2c1dc),
      BigInt.from(0xde9798d9));

  static Secp256k1Scalar get secp256k1ConstLambda => Secp256k1Scalar.constants(
      BigInt.from(0x5363AD4C),
      BigInt.from(0xC05C30E0),
      BigInt.from(0xA5261C02),
      BigInt.from(0x8812645A),
      BigInt.from(0x122E22EA),
      BigInt.from(0x20816678),
      BigInt.from(0xDF02967C),
      BigInt.from(0x1B23BD72));
}
