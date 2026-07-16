import 'package:blockchain_utils/crypto/crypto/ec/projective/secp256k1/types/types.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

class Secp256k1Const {
  static const int secp256k1TagPubkeyOdd = 0x03;
  static const int secp256k1TagPubkeyUncompressed = 0x04;
  static const int secp256k1TagPubkeyHybridEven = 0x06;
  static const int secp256k1TagPubkeyHybridOdd = 0x07;
  static const int secp256k1TagPubkeyEven = 0x02;

  static const int combBits = 258;
  static const Uint64 mask52 = Uint64.unsafe(1048575, 4294967295);
  static const Uint64 mask48 = Uint64.unsafe(65535, 4294967295);
  static const Uint64 mask47 = Uint64.unsafe(1048574, 4294966319);
  static const Uint64 mask33 = Uint64.unsafe(1, 977);

  static const Uint64 mask62 = Uint64.unsafe(1073741823, 4294967295);
  static const Uint64 high4Mask52 = Uint64.unsafe(983040, 0);
  static const Uint64 bit33Mask = Uint64.unsafe(16, 15632);
  static const Int64 minosOne = Int64.unsafe(
    Uint64.unsafe(4294967295, 4294967295),
  );
  static const int constGroupSize = 5;
  static const int constTableSize = (1 << (constGroupSize - 1));
  static const int constGroup = ((129 + constGroupSize - 1) ~/ constGroupSize);
  static const int ecmultConstBits = (constGroup * constGroupSize);
  static const int secp256k1B = 7;
  static const Uint64 secp256k1n0 = Uint64.unsafe(3218235020, 3493216577);
  static const Uint64 secp256k1n1 = Uint64.unsafe(3132021990, 2940772411);
  static const Uint64 secp256k1n2 = Uint64.unsafe(4294967295, 4294967294);
  static const Uint64 secp256k1n3 = Uint64.unsafe(4294967295, 4294967295);
  // Limbs of 2^256 minus the secp256k1 order
  static const Uint64 secp256k1NC0 = Uint64.unsafe(1076732275, 801750719);
  static const Uint64 secp256k1NC1 = Uint64.unsafe(1162945305, 1354194884);
  static const Uint64 secp256k1NC2 = Uint64.one;

  // Limbs of half the secp256k1 order
  static const Uint64 secp256k1NH0 = Uint64.unsafe(3756601158, 1746608288);
  static const Uint64 secp256k1NH1 = Uint64.unsafe(1566010995, 1470386205);
  static const Uint64 secp256k1NH2 = Uint64.unsafe(4294967295, 4294967295);
  static const Uint64 secp256k1NH3 = Uint64.unsafe(2147483647, 4294967295);

  static const int secp256k1GeXMagnitudeMax = 4;
  static const int secp256k1GeYMagnitudeMax = 3;
  static const int secp256k1GejXMagnitudeMax = 4;
  static const int secp256k1GejYMagnitudeMax = 4;
  static const int secp256k1GejZMagnitudeMax = 1;
  static const Secp256k1ModinvSignedConst secp256k1Signed62One =
      Secp256k1ModinvSignedConst([
        Int64.one,
        Int64.zero,
        Int64.zero,
        Int64.zero,
        Int64.zero,
      ]);

  static const Secp256k1ModinvInfoConst secp256k1ConstModinfoScalar =
      Secp256k1ModinvInfoConst(
        modulus: Secp256k1ModinvSignedConst([
          Int64.unsafe(Uint64.unsafe(1070751372, 3493216577)),
          Int64.unsafe(Uint64.unsafe(716927898, 3173155054)),
          Int64.unsafe(Uint64.unsafe(4294967295, 4294967275)),
          Int64.unsafe(Uint64.zero),
          Int64.unsafe(Uint64.unsafe(0, 256)),
        ]),
        modulusInv: Uint64.unsafe(888275097, 2859945665),
      );

  static const BaseSecp256k1ModinvSigned modeInvOne =
      Secp256k1ModinvSignedConst([
        Int64.one,
        Int64.zero,
        Int64.zero,
        Int64.zero,
        Int64.zero,
      ]);

  static const Secp256k1GeConst g7 = Secp256k1GeConst(
    x: Secp256k1FeConst.unsafe([
      Uint64.unsafe(798939, 4111888138),
      Uint64.unsafe(460043, 1258678300),
      Uint64.unsafe(827435, 2615527120),
      Uint64.unsafe(1041478, 1026740209),
      Uint64.unsafe(26210, 1561538943),
    ]),
    y: Secp256k1FeConst.unsafe([
      Uint64.unsafe(344460, 4283085007),
      Uint64.unsafe(272586, 1155625906),
      Uint64.unsafe(534351, 4100203823),
      Uint64.unsafe(51138, 3746818921),
      Uint64.unsafe(7776, 3902252992),
    ]),
    infinity: 0,
  );
  static const Secp256k1GeConst g13 = Secp256k1GeConst(
    x: Secp256k1FeConst.unsafe([
      Uint64.unsafe(90911, 3231122683),
      Uint64.unsafe(752217, 343477191),
      Uint64.unsafe(358689, 3688946988),
      Uint64.unsafe(323066, 1361457118),
      Uint64.unsafe(41544, 804801523),
    ]),
    y: Secp256k1FeConst.unsafe([
      Uint64.unsafe(867097, 3129258053),
      Uint64.unsafe(692571, 2326176102),
      Uint64.unsafe(933444, 1071585322),
      Uint64.unsafe(608547, 2801912894),
      Uint64.unsafe(37925, 919315428),
    ]),
    infinity: 0,
  );
  static const Secp256k1GeConst g199 = Secp256k1GeConst(
    x: Secp256k1FeConst.unsafe([
      Uint64.unsafe(703189, 522650541),
      Uint64.unsafe(520273, 4095630198),
      Uint64.unsafe(690154, 741675146),
      Uint64.unsafe(245157, 1401957927),
      Uint64.unsafe(32688, 2069680252),
    ]),
    y: Secp256k1FeConst.unsafe([
      Uint64.unsafe(995606, 3543136617),
      Uint64.unsafe(285065, 2428662692),
      Uint64.unsafe(790749, 1299017543),
      Uint64.unsafe(279433, 1386624250),
      Uint64.unsafe(2597, 356080460),
    ]),
    infinity: 0,
  );
  static const Secp256k1GeConst G = Secp256k1GeConst(
    x: Secp256k1FeConst.unsafe([
      Uint64.unsafe(164187, 385357720),
      Uint64.unsafe(897756, 3800929695),
      Uint64.unsafe(952075, 117611516),
      Uint64.unsafe(768709, 1510353244),
      Uint64.unsafe(31166, 1719597532),
    ]),
    y: Secp256k1FeConst.unsafe([
      Uint64.unsafe(512143, 4212184248),
      Uint64.unsafe(297576, 1430362564),
      Uint64.unsafe(921864, 2835158964),
      Uint64.unsafe(804437, 3662659520),
      Uint64.unsafe(18490, 3665241763),
    ]),
    infinity: 0,
  );

  static const Secp256k1ModinvInfoConst secp256k1ConstModinfoFe =
      Secp256k1ModinvInfoConst(
        modulus: Secp256k1ModinvSignedConst([
          Int64.unsafe(Uint64.unsafe(4294967294, 4294966319)),
          Int64.unsafe(Uint64.zero),
          Int64.unsafe(Uint64.zero),
          Int64.unsafe(Uint64.zero),
          Int64.unsafe(Uint64.unsafe(0, 256)),
        ]),
        modulusInv: Uint64.unsafe(667416290, 769313487),
      );

  static const minusB1 = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(1867808681, 180348099),
    Uint64.unsafe(3829628630, 17729576),
    Uint64.zero,
    Uint64.zero,
  ]);
  static const minusB2 = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(3613773224, 1035032108),
    Uint64.unsafe(2317880005, 125056109),
    Uint64.unsafe(4294967295, 4294967294),
    Uint64.unsafe(4294967295, 4294967295),
  ]);
  static const g1 = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(3901956250, 1172025393),
    Uint64.unsafe(1034586644, 1911081599),
    Uint64.unsafe(3899429092, 2458184469),
    Uint64.unsafe(814141985, 2815716301),
  ]);
  static const g2 = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(359773358, 2328133489),
    Uint64.unsafe(571607212, 2650080966),
    Uint64.unsafe(1867808681, 180348100),
    Uint64.unsafe(3829628630, 17729576),
  ]);
  static const sOffset = Secp256k1ScalarConst.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.one,
    Uint64.zero,
  ]);
  static const secp256k1ScalarOne = Secp256k1ScalarConst.unsafe([
    Uint64.one,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const secp256k1ScalarZero = Secp256k1ScalarConst.unsafe([
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const secp256k1ECmultConstK = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(3049439708, 3734477017),
    Uint64.unsafe(1486547016, 649734628),
    Uint64.unsafe(3267221183, 2081525099),
    Uint64.unsafe(2766703229, 3407020878),
  ]);
  static const secp256k1ConstLambda = Secp256k1ScalarConst.unsafe([
    Uint64.unsafe(3741488764, 455327090),
    Uint64.unsafe(305013482, 545351288),
    Uint64.unsafe(2770738178, 2282906714),
    Uint64.unsafe(1399041356, 3227267296),
  ]);
  static const Secp256k1FeConst secp256k1FeOne = Secp256k1FeConst.unsafe([
    Uint64.one,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
    Uint64.zero,
  ]);
  static const Secp256k1FeConst secp256k1ConstBeta = Secp256k1FeConst.unsafe([
    Uint64.unsafe(617512, 1905590766),
    Uint64.unsafe(479535, 1486445587),
    Uint64.unsafe(799796, 3919376457),
    Uint64.unsafe(28934, 3863247338),
    Uint64.unsafe(31465, 1781228924),
  ]);
  static const Secp256k1FeConst secp256k1PMinusOrder = Secp256k1FeConst.unsafe([
    Uint64.unsafe(893298, 801749742),
    Uint64.unsafe(103691, 1979466754),
    Uint64.unsafe(0, 21319971),
    Uint64.zero,
    Uint64.zero,
  ]);
}
