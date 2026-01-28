import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/fields/native.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/jubjub/point/extended.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class SaplingKeyUtils {
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
      personalization: keyDiversificationPersonalization,
    );
  }

  static JubJubPoint get proofGenerationKeyGenerator {
    return JubJubAffinePoint(
      u: JubJubFq([
        BigInt.parse('4688329274464987593'),
        BigInt.parse('14151053748480064462'),
        BigInt.parse('14558782058791214728'),
        BigInt.parse('4953935332217131816'),
      ]),
      v: JubJubFq([
        BigInt.parse('6509994339305065288'),
        BigInt.parse('10393745954890678923'),
        BigInt.parse('13091562770945060566'),
        BigInt.parse('3281762369979631463'),
      ]),
    ).toExtended();
  }

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

  static const List<int> keyDiversificationPersonalization = [
    90,
    99,
    97,
    115,
    104,
    95,
    103,
    100,
  ];

  static JubJubAffinePoint get spendAuthGenerator => JubJubAffinePoint(
    u: JubJubFq([
      BigInt.parse("11523136253062974710"),
      BigInt.parse("1565710093821875141"),
      BigInt.parse("9772861389303152376"),
      BigInt.parse("789406954895279390"),
    ]),
    v: JubJubFq([
      BigInt.parse("18114344539046435414"),
      BigInt.parse("8643525643390539237"),
      BigInt.parse("9759478803715485369"),
      BigInt.parse("7916771090361405495"),
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

  static JubJubAffinePoint get bindingGenerator => JubJubAffinePoint(
    u: JubJubFq([
      BigInt.parse("5549540396793142930"),
      BigInt.parse("13424322059144101642"),
      BigInt.parse("15696773774614557624"),
      BigInt.parse("4735710324177639912"),
    ]),
    v: JubJubFq([
      BigInt.parse("9534511422473925453"),
      BigInt.parse("14189824261890655055"),
      BigInt.parse("11868011878947860258"),
      BigInt.parse("2814246734807231969"),
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
