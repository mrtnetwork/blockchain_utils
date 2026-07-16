import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

class VestaFQConst {
  static const int S = 32;
  static const int numBits = 255;

  static const Uint64 inv = Uint64.unsafe(2353457952, 4294967295);

  static List<VestaNativeFq> get isogenyNativeConstants => [
    VestaNativeFq.nP(
      BigInt.parse(
        '25731575386070265649682441113041757300767161317281464337493104665238544842753',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '13377367003779316331268047403600734872799183885837485433911493934102207511749',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '11064082577423419940183149293632076317553812518550871517841037420579891210813',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '22515128462811482443472135973911537638171266152621281295306466582083726737451',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '4604213796697651557841441623718706001740429044770779386484474413346415813353',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '9250006497141849826017568406346290940322373181457057184910582871723433210981',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '8577191795356755216560813704347252433589053772427154779164368221746181614251',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '21162694656554182593580396827886355918081120183889566406795618341247785229923',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '11620280474556824258112134491145636201000922752744881519070727793732904824884',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '13937936667454727226911322269564285204582212380194126516142098360337545123123',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '21380331849711001764708535561664047484292171808126992769566582994216305194078',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '27750019491425549478052705219038872820967119544371171554731748615170299632943',
      ),
    ),
    VestaNativeFq.nP(
      BigInt.parse(
        '28948022309329048855892746252171976963363056481941647379679742748393362947557',
      ),
    ),
  ];

  /// Constants used for computing the isogeny from IsoEq to Eq.
  static const List<VestaFq> isogenyConstants = [
    VestaFq.unsafe([
      Uint64.unsafe(2909083598, 1908874354),
      Uint64.unsafe(2991100870, 990156621),
      Uint64.unsafe(2863311530, 2863311530),
      Uint64.unsafe(715827882, 2863311530),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(1177948497, 2838842699),
      Uint64.unsafe(1746634135, 4096898960),
      Uint64.unsafe(2725972293, 1233924495),
      Uint64.unsafe(983877443, 1301480824),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(870216970, 4061209031),
      Uint64.unsafe(4145321727, 4245418536),
      Uint64.unsafe(1560173897, 1426339327),
      Uint64.unsafe(1018477247, 1664261129),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3220764371, 3817748539),
      Uint64.unsafe(3287689514, 585479257),
      Uint64.unsafe(1431655765, 1431655742),
      Uint64.unsafe(357913941, 1431655765),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(363807446, 4074747803),
      Uint64.unsafe(2529356407, 1226452262),
      Uint64.unsafe(3058914159, 2515385865),
      Uint64.unsafe(264962397, 3123392829),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3314115054, 2278461412),
      Uint64.unsafe(3058105442, 3233680538),
      Uint64.unsafe(3469989563, 4151423483),
      Uint64.unsafe(655340079, 1985377532),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(1107010736, 636291452),
      Uint64.unsafe(4243713172, 3300522072),
      Uint64.unsafe(2386092942, 954437176),
      Uint64.unsafe(954437176, 3817748707),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3913186873, 1419421350),
      Uint64.unsafe(3308326729, 4276301878),
      Uint64.unsafe(1362986146, 2764445895),
      Uint64.unsafe(1028809633, 2798224060),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(2641530746, 3437853655),
      Uint64.unsafe(781139039, 3684655172),
      Uint64.unsafe(1425670327, 2366599338),
      Uint64.unsafe(871105043, 375667746),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3482788088, 3181457396),
      Uint64.unsafe(641393868, 4003172203),
      Uint64.unsafe(3340530119, 477218607),
      Uint64.unsafe(477218588, 1908874353),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3869923794, 3964638057),
      Uint64.unsafe(1934076976, 4067530791),
      Uint64.unsafe(2440887591, 1625595150),
      Uint64.unsafe(934314508, 2537605596),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(3293919914, 2540416939),
      Uint64.unsafe(9329708, 950369522),
      Uint64.unsafe(1820034099, 3864335859),
      Uint64.unsafe(892278414, 1661165302),
    ]),
    VestaFq.unsafe([
      Uint64.unsafe(2522867312, 2160),
      Uint64.unsafe(866832016, 3595619663),
      Uint64.unsafe(0, 289),
      Uint64.zero,
    ]),
  ];
  static const modulus = VestaFq.unsafe([
    Uint64.unsafe(2353457953, 1),
    Uint64.unsafe(575052028, 160737501),
    Uint64.zero,
    Uint64.unsafe(1073741824, 0),
  ]);

  static const List<Uint64> tMinus1Over2 = [
    Uint64.unsafe(80368750, 3324212624),
    Uint64.unsafe(0, 287526014),
    Uint64.zero,
    Uint64.unsafe(0, 536870912),
  ];
}
