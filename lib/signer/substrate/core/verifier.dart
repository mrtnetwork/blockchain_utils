import 'package:blockchain_utils/bip/ecc/curve/elliptic_curve_types.dart';
import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_sr25519.dart';

abstract class BaseSubstrateVerifier {
  bool verify(List<int> message, List<int> signature);
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra});

  factory BaseSubstrateVerifier.fromBytes(
      List<int> keyBytes, EllipticCurveTypes algorithm) {
    switch (algorithm) {
      case EllipticCurveTypes.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(keyBytes);
      case EllipticCurveTypes.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(keyBytes);
      case EllipticCurveTypes.sr25519:
        return SubstrateSr25519Verifier.fromKeyBytes(keyBytes);
      default:
        throw ArgumentException(
            "Invalid substrate signing key algorithm. Excepted: ed25519, secp256k1, or sr25519. Got: ${algorithm.name}");
    }
  }
  factory BaseSubstrateVerifier.fromSubstrate(Substrate substrate) {
    switch (substrate.coinConf.type) {
      case EllipticCurveTypes.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(substrate.priveKey.raw);
      case EllipticCurveTypes.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(substrate.priveKey.raw);
      default:
        return SubstrateSr25519Verifier.fromKeyBytes(substrate.priveKey.raw);
    }
  }
}
