import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/exception.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas_native.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';

class OrchardKeyUtils {
  static PallasNativePoint diversifyHashNative(List<int> bytes) {
    const String keyDiversificationPersonalization = "z.cash:Orchard-gd";
    final point = PallasNativePoint.hashToCurve(
      domainPrefix: keyDiversificationPersonalization,
      message: bytes.exc(
        length: 11,
        operation: "Diversify Hash",
        reason: "Invalid diversify key bytes length.",
      ),
    );
    if (point.isIdentity()) {
      throw OrchardKeyError.failed(
        "Diversify Hash",
        reason: "Hash-to-curve returned the identity element",
      );
    }
    return point;
  }

  static PallasNativePoint kaOrchardNative({
    required PallasNativePoint base,
    required VestaNativeFq sk,
  }) {
    final PallasNativePoint p = base * sk;
    if (p.isIdentity()) {
      throw OrchardKeyError.failed(
        "kaOrchard",
        reason: "Scalar multiplication resulted in the identity point.",
      );
    }
    return p;
  }

  static PallasNativeFp prfNf({
    required PallasNativeFp nk,
    required PallasNativeFp rho,
    required ZCryptoContext context,
  }) {
    return context.pseudoRando(nk: nk, rho: rho);
  }

  static const PallasPoint orchardSpendAuthSigBasepoint = PallasPoint(
    x: PallasFp.unsafe([
      Uint64.unsafe(1225729164, 180127384),
      Uint64.unsafe(2405886437, 989616714),
      Uint64.unsafe(2320186628, 905847165),
      Uint64.unsafe(277389510, 851512587),
    ]),
    y: PallasFp.unsafe([
      Uint64.unsafe(3868199629, 1038371479),
      Uint64.unsafe(619509485, 796614148),
      Uint64.unsafe(2043829124, 444306973),
      Uint64.unsafe(217824798, 4271659019),
    ]),
    z: PallasFp.unsafe([
      Uint64.unsafe(880307512, 4294967293),
      Uint64.unsafe(2569811211, 3826848941),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
  );

  static PallasNativePoint get orchardSpendAuthSigBasepointNative =>
      PallasAffineNativePoint(
        x: PallasNativeFp.nP(
          BigInt.parse(
            "25027635063850382358429654596649554085117301901282348152423547104939793041763",
          ),
        ),
        y: PallasNativeFp.nP(
          BigInt.parse(
            "12128007492603938773365931378340937928001494939630793217712875072231079427017",
          ),
        ),
      ).toCurve();
  static PallasNativePoint get orchardBindingSigBasepointNative =>
      PallasAffineNativePoint(
        x: PallasNativeFp.nP(
          BigInt.parse(
            "3597772235883004661259329170144280297379687592370687591147658848249887611537",
          ),
        ),
        y: PallasNativeFp.nP(
          BigInt.parse(
            "16317546749781193797530044795837656238506071957562073482938086095508632426954",
          ),
        ),
      ).toCurve();
  static const PallasPoint orchardBindingSigBasepoint = PallasPoint(
    x: PallasFp.unsafe([
      Uint64.unsafe(662593431, 3268984260),
      Uint64.unsafe(2133836982, 2471911496),
      Uint64.unsafe(4045351752, 2405560606),
      Uint64.unsafe(432766234, 1195403092),
    ]),
    y: PallasFp.unsafe([
      Uint64.unsafe(1247635766, 4257351793),
      Uint64.unsafe(2945726001, 3851615861),
      Uint64.unsafe(1248131041, 1432445141),
      Uint64.unsafe(865525634, 4196470183),
    ]),
    z: PallasFp.unsafe([
      Uint64.unsafe(880307512, 4294967293),
      Uint64.unsafe(2569811211, 3826848941),
      Uint64.unsafe(4294967295, 4294967295),
      Uint64.unsafe(1073741823, 4294967295),
    ]),
  );
}
