import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_sr25519.dart';

abstract class BaseSubstrateSigner {
  List<int> sign(List<int> digest);
  List<int> signConst(List<int> digest);
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra});
  List<int> vrfSignConst(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
  });

  factory BaseSubstrateSigner.fromBytes(
    List<int> keyBytes,
    EllipticCurveTypes algorithm,
  ) {
    switch (algorithm) {
      case EllipticCurveTypes.ed25519:
        return SubstrateED25519Signer.fromKeyBytes(keyBytes);
      case EllipticCurveTypes.secp256k1:
        return SubstrateEcdsaSigner.fromKeyBytes(keyBytes);
      case EllipticCurveTypes.sr25519:
        return SubstrateSr25519Signer.fromKeyBytes(keyBytes);
      default:
        throw ArgumentException.invalidOperationArguments(
          "BaseSubstrateSigner",
          name: "algorithm",
          reason: "Unsupported key algorithm.",
        );
    }
  }
  factory BaseSubstrateSigner.fromSubstrate(Substrate substrate) {
    switch (substrate.coinConf.type) {
      case EllipticCurveTypes.ed25519:
        return SubstrateED25519Signer.fromKeyBytes(substrate.priveKey.raw);
      case EllipticCurveTypes.secp256k1:
        return SubstrateEcdsaSigner.fromKeyBytes(substrate.priveKey.raw);
      default:
        return SubstrateSr25519Signer.fromKeyBytes(substrate.priveKey.raw);
    }
  }
}
