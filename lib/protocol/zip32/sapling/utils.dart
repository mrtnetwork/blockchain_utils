import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/core.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/point/extended.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/string/string.dart';

class SaplingKeyUtils {
  static const String saplingInternalPersonalization = "Zcash_SaplingInt";
  static JubJubFr crhIvk({required List<int> ak, required List<int> nk}) {
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
    return JubJubFr.fromBytes(hash);
  }

  static E? groupHash<
    SCALAR extends JubJubScalar<SCALAR>,
    E extends BaseJubJubPoint<SCALAR, E>
  >({
    required List<int> tag,
    required List<int> personalization,
    required E Function(List<int> bytes) fromBytes,
  }) {
    final hash = QuickCrypto.blake2s256Hash(
      ghFirstBlock,
      extraBlocks: [tag],
      personalization: personalization,
    );
    try {
      final cleared = blockchainUtils.api.jubjub.clearCofactor(hash);
      if (cleared == null) return null;
      return fromBytes(cleared);
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
      personalization: StringUtils.encode("Zcash_gd"),
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

  /// RedJubjub spend-authorizing basepoint, canonical 32-byte base encoding (Zcash protocol §5.4.8).
  static const BuBytes spendAuthGeneratorBytes = BuBytes.unsafe([
    48,
    181,
    242,
    170,
    173,
    50,
    86,
    48,
    188,
    221,
    219,
    206,
    77,
    103,
    101,
    109,
    5,
    253,
    28,
    194,
    208,
    55,
    187,
    83,
    117,
    182,
    233,
    109,
    158,
    1,
    161,
    215,
  ]);

  /// RedJubjub binding basepoint, canonical 32-byte base encoding (Zcash protocol §5.4.8).
  static const BuBytes bindingGeneratorBytes = BuBytes.unsafe([
    139,
    106,
    11,
    56,
    185,
    250,
    174,
    60,
    59,
    128,
    59,
    71,
    176,
    241,
    70,
    173,
    80,
    171,
    34,
    30,
    110,
    42,
    251,
    230,
    219,
    222,
    69,
    203,
    169,
    211,
    129,
    237,
  ]);

  /// Value-commitment value generator V (`cv = v*V + rcv*R`).
  static const JubJubPoint valueCommitmentValueGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(1084024856, 937392624),
      Uint64.unsafe(1016643811, 4234017976),
      Uint64.unsafe(236997629, 1948113576),
      Uint64.unsafe(1820578921, 1374007876),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(2916834258, 2115861188),
      Uint64.unsafe(3296893845, 4186960602),
      Uint64.unsafe(1550461729, 1051631681),
      Uint64.unsafe(300426357, 2672010263),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(1084024856, 937392624),
      Uint64.unsafe(1016643811, 4234017976),
      Uint64.unsafe(236997629, 1948113576),
      Uint64.unsafe(1820578921, 1374007876),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(2916834258, 2115861188),
      Uint64.unsafe(3296893845, 4186960602),
      Uint64.unsafe(1550461729, 1051631681),
      Uint64.unsafe(300426357, 2672010263),
    ]),
  );

  /// Note-commitment randomness generator h (`cm = pedersen(...) + h*rcm`).
  static const JubJubPoint noteCommitmentRandomnessGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(4063409095, 945270375),
      Uint64.unsafe(2854345487, 2439569067),
      Uint64.unsafe(198963222, 2166155905),
      Uint64.unsafe(1724884292, 977806925),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(340695194, 4094550160),
      Uint64.unsafe(3424694893, 1137148806),
      Uint64.unsafe(1413171875, 1941980869),
      Uint64.unsafe(499256276, 2912322036),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(4063409095, 945270375),
      Uint64.unsafe(2854345487, 2439569067),
      Uint64.unsafe(198963222, 2166155905),
      Uint64.unsafe(1724884292, 977806925),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(340695194, 4094550160),
      Uint64.unsafe(3424694893, 1137148806),
      Uint64.unsafe(1413171875, 1941980869),
      Uint64.unsafe(499256276, 2912322036),
    ]),
  );

  /// Nullifier-position generator J (`rho = cm + [pos]*J`).
  static const JubJubPoint nullifierPositionGenerator = JubJubPoint(
    u: JubJubFq.unsafe([
      Uint64.unsafe(3628576777, 3929234384),
      Uint64.unsafe(67070218, 3691082097),
      Uint64.unsafe(1175092178, 611076758),
      Uint64.unsafe(1912475077, 3056722785),
    ]),
    v: JubJubFq.unsafe([
      Uint64.unsafe(1878151400, 535827100),
      Uint64.unsafe(2466199045, 2525320003),
      Uint64.unsafe(3324503045, 1074621922),
      Uint64.unsafe(1253571260, 2869670691),
    ]),
    z: JubJubFq.unsafe([
      Uint64.unsafe(1, 4294967294),
      Uint64.unsafe(1485092858, 215042),
      Uint64.unsafe(2576109551, 3971764213),
      Uint64.unsafe(405057881, 2898593135),
    ]),
    t1: JubJubFq.unsafe([
      Uint64.unsafe(3628576777, 3929234384),
      Uint64.unsafe(67070218, 3691082097),
      Uint64.unsafe(1175092178, 611076758),
      Uint64.unsafe(1912475077, 3056722785),
    ]),
    t2: JubJubFq.unsafe([
      Uint64.unsafe(1878151400, 535827100),
      Uint64.unsafe(2466199045, 2525320003),
      Uint64.unsafe(3324503045, 1074621922),
      Uint64.unsafe(1253571260, 2869670691),
    ]),
  );
}
