import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/extended.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';

class SaplingKeyUtils {
  static const String saplingInternalPersonalization = "Zcash_SaplingInt";
  static JubJubNativeFr crhIvk({required List<int> ak, required List<int> nk}) {
    final List<int> zcashIvk = [90, 99, 97, 115, 104, 105, 118, 107];
    final hash = QuickCrypto.blake2s256Hash(
      ak.exc(
        operation: "crhIvk",
        name: "ak",
        reason: "Invalid ak bytes length.",
        length: 32,
      ),
      extraBlocks: [
        nk.exc(
          operation: "crhIvk",
          name: "nk",
          reason: "Invalid nk bytes length.",
          length: 32,
        ),
      ],
      personalization: zcashIvk,
    );
    hash[31] &= 7;
    return JubJubNativeFr.fromBytes(hash);
  }

  static E? groupHash<
    SCALAR extends JubJubScalar<SCALAR>,
    E extends BaseJubJubPoint<SCALAR, E>
  >({
    required List<int> tag,
    required List<int> personalization,
    required E Function(List<int> bytes) fromBytes,
  }) {
    assert(personalization.length == 8);
    final hash = QuickCrypto.blake2s256Hash(
      ghFirstBlock,
      extraBlocks: [tag],
      personalization: personalization,
    );
    try {
      final p = fromBytes(hash).mulByCofactor();
      if (p.isIdentity()) return null;
      return p;
    } catch (_) {}
    return null;
  }

  static E? diversifyHash<
    SCALAR extends JubJubScalar<SCALAR>,
    E extends BaseJubJubPoint<SCALAR, E>
  >({required List<int> d, required E Function(List<int> bytes) fromBytes}) {
    return groupHash<SCALAR, E>(
      fromBytes: fromBytes,
      tag: d.exc(
        operation: "diversifyHash",
        name: "d",
        reason: "Invalid d bytes length.",
        length: 11,
      ),
      personalization: "Zcash_gd".codeUnits,
    );
  }

  static const JubJubPoint proofGenerationKeyGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(1091586722, 2727143881),
      Uint64.unsafe(3294798952, 2744990670),
      Uint64.unsafe(3389730597, 2425659016),
      Uint64.unsafe(1153427952, 84874024),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(1515726172, 873794376),
      Uint64.unsafe(2419982560, 2800321163),
      Uint64.unsafe(3048116986, 1692970710),
      Uint64.unsafe(764094844, 3957409639),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(1091586722, 2727143881),
      Uint64.unsafe(3294798952, 2744990670),
      Uint64.unsafe(3389730597, 2425659016),
      Uint64.unsafe(1153427952, 84874024),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(1515726172, 873794376),
      Uint64.unsafe(2419982560, 2800321163),
      Uint64.unsafe(3048116986, 1692970710),
      Uint64.unsafe(764094844, 3957409639),
    ]),
  );

  static JubJubNativePoint get proofGenerationKeyGeneratorNative =>
      JubJubAffineNativePoint(
        u: JubJubNativeFq.nP(
          BigInt.parse(
            "9201111513613159952332790701602097324772839388200533360387436201225747309937",
          ),
        ),
        v: JubJubNativeFq.nP(
          BigInt.parse(
            "38317288103109448611012419043659719984035489099661802521426844652233060903143",
          ),
        ),
      ).toExtended();

  static const List<int> ghFirstBlock = [
    48,
    57,
    54,
    98,
    51,
    54,
    97,
    53,
    56,
    48,
    52,
    98,
    102,
    97,
    99,
    101,
    102,
    49,
    54,
    57,
    49,
    101,
    49,
    55,
    51,
    99,
    51,
    54,
    54,
    97,
    52,
    55,
    102,
    102,
    53,
    98,
    97,
    56,
    52,
    97,
    52,
    52,
    102,
    50,
    54,
    100,
    100,
    100,
    55,
    101,
    56,
    100,
    57,
    102,
    55,
    57,
    100,
    53,
    98,
    52,
    50,
    100,
    102,
    48,
  ];

  static const JubJubPoint spendAuthGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(2682939230, 3057552630),
      Uint64.unsafe(364545288, 3950973893),
      Uint64.unsafe(2275421607, 2626387704),
      Uint64.unsafe(183798129, 1774290206),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(4217574498, 1692818006),
      Uint64.unsafe(2012477638, 4249212389),
      Uint64.unsafe(2272305731, 2557111993),
      Uint64.unsafe(1843266908, 2702364727),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(2682939230, 3057552630),
      Uint64.unsafe(364545288, 3950973893),
      Uint64.unsafe(2275421607, 2626387704),
      Uint64.unsafe(183798129, 1774290206),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(4217574498, 1692818006),
      Uint64.unsafe(2012477638, 4249212389),
      Uint64.unsafe(2272305731, 2557111993),
      Uint64.unsafe(1843266908, 2702364727),
    ]),
  );

  static JubJubAffineNativePoint
  get spendAuthGeneratorNative => JubJubAffineNativePoint(
    u: JubJubNativeFq.nP(
      BigInt.parse(
        "4139425550610461525665941076812662132363359224232624900223172373014329534291",
      ),
    ),
    v: JubJubNativeFq.nP(
      BigInt.parse(
        "39635691377166599497441725607757882405510648532010642268690928210480481875248",
      ),
    ),
  );
  static const JubJubPoint bindingGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(1292103062, 2441682578),
      Uint64.unsafe(3125593545, 2780397322),
      Uint64.unsafe(3654689941, 999388088),
      Uint64.unsafe(1102618482, 4022475240),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(2219926431, 1802924877),
      Uint64.unsafe(3303825916, 993411919),
      Uint64.unsafe(2763236844, 2865606434),
      Uint64.unsafe(655242878, 2860314081),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(1292103062, 2441682578),
      Uint64.unsafe(3125593545, 2780397322),
      Uint64.unsafe(3654689941, 999388088),
      Uint64.unsafe(1102618482, 4022475240),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(2219926431, 1802924877),
      Uint64.unsafe(3303825916, 993411919),
      Uint64.unsafe(2763236844, 2865606434),
      Uint64.unsafe(655242878, 2860314081),
    ]),
  );

  static JubJubAffineNativePoint
  get bindingGeneratorNative => JubJubAffineNativePoint(
    u: JubJubNativeFq.nP(
      BigInt.parse(
        "47042227020334719030310671629496501061777616454137182971856918820250544653111",
      ),
    ),
    v: JubJubNativeFq.nP(
      BigInt.parse(
        "49531484613049745751551498609154147537293487462303198979615882148044956461707",
      ),
    ),
  );
}
