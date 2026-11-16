import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';

/// Pallas base-field (Fp) domain parameters and isogeny constants.
/// Generated data — do not hand-edit the numeric values.
class PallasFPConst {
  static const int S = 32;
  static const int numBits = 255;
  static const int capacity = numBits - 1;
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
