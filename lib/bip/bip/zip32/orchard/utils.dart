import 'package:blockchain_utils/bip/bip/zip32/base/context.dart';
import 'package:blockchain_utils/bip/bip/zip32/orchard/exception.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fq.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/native/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/pasta/point/pallas_native.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

class OrchardKeyUtils {
  static const String commitIvkDomainName = "z.cash:Orchard-CommitIvk";
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
      throw OrchardKeyError.cryptoFailureWith(
        "Diversify Hash",
        reason:
            "Diversification failed: hash-to-curve returned the identity element",
      );
    }
    return point;
  }

  static PallasNativePoint kaOrchardPreparedNative({
    required PallasNativePoint base,
    required VestaNativeFq sk,
  }) {
    final PallasNativePoint p = base * sk;
    if (p.isIdentity()) {
      throw OrchardKeyError.cryptoFailureWith(
        "kaOrchardPrepared",
        reason: "Scalar multiplication resulted in the identity point.",
      );
    }
    return p;
  }

  // static WnafBase<VestaFq, PallasPoint> generator() {
  //   const String orchardSpendAuthSigBasepointMessagePrefix = "z.cash:Orchard";
  //   const String orchardSpendAuthSigBasepointMessage = "G";
  //   return WnafBase<VestaFq, PallasPoint>(
  //     PallasPoint.hashToCurve(
  //       domainPrefix: orchardSpendAuthSigBasepointMessagePrefix,
  //       message: StringUtils.encode(orchardSpendAuthSigBasepointMessage),
  //     ),
  //   );
  // }

  static PallasNativeFp prfNf({
    required PallasNativeFp nk,
    required PallasNativeFp rho,
    required ZCryptoContext context,
  }) {
    return context.getPoseidonHash().hash([nk, rho]);
  }

  static PallasPoint get orchardSpendAuthSigBasepoint =>
      PallasAffinePoint(
        x: PallasFp([
          BigInt.parse("5264466673313547928"),
          BigInt.parse("10333203565794581066"),
          BigInt.parse("9965125688782365053"),
          BigInt.parse("1191378874554977547"),
        ]),
        y: PallasFp([
          BigInt.parse("16613790901992704663"),
          BigInt.parse("2660772978433416708"),
          BigInt.parse("8778179246636635677"),
          BigInt.parse("935550387939465227"),
        ]),
      ).toCurve();
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
  static PallasPoint get orchardBindingSigBasepoint =>
      PallasAffinePoint(
        x: PallasFp([
          BigInt.parse("2845817119958416836"),
          BigInt.parse("9164760055157252168"),
          BigInt.parse("17374653478061863198"),
          BigInt.parse("1858716823038486356"),
        ]),
        y: PallasFp([
          BigInt.parse("5358554816547260529"),
          BigInt.parse("12651796841123479157"),
          BigInt.parse("5360682003649880277"),
          BigInt.parse("3717404296076135847"),
        ]),
      ).toCurve();
}
