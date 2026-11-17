import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/protocol/zip32/base/context.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/point/pallas.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class OrchardKeyUtils {
  static BuBytes diversifyHash(List<int> bytes) {
    const String keyDiversificationPersonalization = "z.cash:Orchard-gd";
    final pallas = blockchainUtils.api.pallas;
    final point = pallas.hashToCurvePasta(
      domainPrefix: keyDiversificationPersonalization,
      message: bytes.exc(
        length: 11,
        operation: "Diversify Hash",
        reason: "Invalid diversify key bytes length.",
      ),
    );
    if (BytesUtils.bytesEqualConst(point, pallas.identity())) {
      throw CoreErrors.orchardFailed(
        "Diversify Hash",
        reason: "Hash-to-curve returned the identity element",
      );
    }
    return point;
  }

  static PallasPoint kaOrchard({required List<int> base, required VestaFq sk}) {
    final mult = blockchainUtils.api.pallas.mult(sk.toBytes(), base);
    final PallasPoint p = PallasPoint.fromBytes(mult);
    if (p.isIdentity()) {
      throw CoreErrors.orchardFailed(
        "kaOrchard",
        reason: "Scalar multiplication resulted in the identity point.",
      );
    }
    return p;
  }

  static BuBytes prfNf({
    required List<int> nk,
    required List<int> rho,
    required ZCryptoContext context,
  }) {
    return context.pseudoRando(nk: nk, rho: rho);
  }

  /// RedPallas spend-authorizing basepoint, canonical 32-byte base encoding.
  static const BuBytes orchardSpendAuthSigBasepointBytes = BuBytes.unsafe([
    99,
    201,
    117,
    184,
    132,
    114,
    26,
    141,
    12,
    161,
    112,
    123,
    227,
    12,
    127,
    12,
    95,
    68,
    95,
    62,
    124,
    24,
    141,
    59,
    6,
    214,
    241,
    40,
    179,
    35,
    85,
    183,
  ]);

  /// RedPallas binding basepoint, canonical 32-byte base encoding.
  static const BuBytes orchardBindingSigBasepointBytes = BuBytes.unsafe([
    145,
    90,
    60,
    136,
    104,
    198,
    195,
    14,
    47,
    128,
    144,
    238,
    69,
    215,
    110,
    64,
    72,
    32,
    141,
    234,
    91,
    35,
    102,
    79,
    187,
    9,
    164,
    15,
    85,
    68,
    244,
    7,
  ]);
}
