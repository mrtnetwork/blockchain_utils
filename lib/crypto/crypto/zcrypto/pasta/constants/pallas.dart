import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

class PallasFPConst {
  static const int S = 32;
  static const int numBits = 255;
  static const int capacity = numBits - 1;
  static List<PallasNativeFp> get isogenyConstantsNative => [
    PallasNativeFp(
      BigInt.parse(
        "6432893846517566412420610278260439325191790329320346825767705947633326140075",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "23989696149150192365340222745168215001509815558210986772351135915822265203574",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "10492611921771203378452795982353351666191589197598957448093274638589204800759",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "12865787693035132824841220556520878650383580658640693651535411895266652280192",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "13271109177048389296812780941310096270046944650307955939477485891950613419807",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "22768321103861051515190775253992702316905399997697804654926324362758820947460",
      ),
    ),

    PallasNativeFp(
      BigInt.parse(
        "11793638718615538422771118843477472096184948937087302513907460903994431256804",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "11994848074575096182670111372584107500754907779105493386175567957911132601787",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "28823569610051396102362669851238297121581474897215657071023781420043761726004",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "1072148974419594402070101713043406554198631721553391137627950991272221023311",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "5432652610908059517272798285879155923388888734491153551238890455750936314542",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "10408918692925056833786833257634153023990087029210292532869619559576527581706",
      ),
    ),
    PallasNativeFp(
      BigInt.parse(
        "28948022309329048855892746252171976963363056481941560715954676764349967629797",
      ),
    ),
  ];
  static const List<PallasFp> isogenyConstants = [
    PallasFp.unsafe([
      Uint64.unsafe(3336583072, 477218589),
      Uint64.unsafe(319473348, 3904437291),
      Uint64.zero,
      Uint64.unsafe(1073741824, 0),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(1282303218, 842882286),
      Uint64.unsafe(1344225743, 3529425392),
      Uint64.unsafe(98494318, 2285853863),
      Uint64.unsafe(857226392, 322096217),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(1782507385, 2650104694),
      Uint64.unsafe(309033387, 2026313007),
      Uint64.unsafe(845205959, 961508313),
      Uint64.unsafe(1068442649, 2174100045),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(1860903627, 954437009),
      Uint64.unsafe(2239401767, 2913043743),
      Uint64.unsafe(4294967295, 4294967273),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(2141533704, 3290973271),
      Uint64.unsafe(3777700202, 607781297),
      Uint64.unsafe(886448866, 3392815584),
      Uint64.unsafe(198844760, 2898865953),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(2785767873, 2833349976),
      Uint64.unsafe(1982483324, 3408785202),
      Uint64.unsafe(1345724419, 190920673),
      Uint64.unsafe(930664112, 2866126372),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(3400475353, 3022384394),
      Uint64.unsafe(3161486656, 1353492247),
      Uint64.unsafe(2863311530, 2863311530),
      Uint64.unsafe(715827882, 2863311530),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(641151609, 421441143),
      Uint64.unsafe(2819596519, 3912196344),
      Uint64.unsafe(2196730807, 1142926931),
      Uint64.unsafe(428613196, 161048108),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(1689544865, 2558771715),
      Uint64.unsafe(2271277867, 1235072944),
      Uint64.unsafe(235776986, 2093874715),
      Uint64.unsafe(696397576, 813421339),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(4003126549, 2227020219),
      Uint64.unsafe(100280610, 2375062331),
      Uint64.unsafe(1431655765, 1431655784),
      Uint64.unsafe(357913941, 1431655765),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(202271107, 2788976259),
      Uint64.unsafe(1659109021, 989691672),
      Uint64.unsafe(3477156948, 794256081),
      Uint64.unsafe(835138053, 53331633),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(3217552234, 4205082630),
      Uint64.unsafe(502378622, 1324342112),
      Uint64.unsafe(4037173257, 572762020),
      Uint64.unsafe(644508690, 8444524),
    ]),
    PallasFp.unsafe([
      Uint64.unsafe(1833750448, 2160),
      Uint64.unsafe(866832014, 2037766364),
      Uint64.unsafe(0, 289),
      Uint64.zero,
    ]),
  ];

  static const tMinus1Over2 = [
    Uint64.unsafe(78019725, 3432421494),
    Uint64.unsafe(0, 287526014),
    Uint64.zero,
    Uint64.unsafe(0, 536870912),
  ];
  static const modulus = PallasFp.unsafe([
    Uint64.unsafe(2569875693, 1),
    Uint64.unsafe(575052028, 156039451),
    Uint64.zero,
    Uint64.unsafe(1073741824, 0),
  ]);
  static const inv = Uint64.unsafe(2569875692, 4294967295);
}
