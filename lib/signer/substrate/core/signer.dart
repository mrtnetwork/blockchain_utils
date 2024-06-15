import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_sr25519.dart';

abstract class BaseSubstrateSigner {
  List<int> sign(List<int> digest);
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra});

  factory BaseSubstrateSigner.fromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm algorithm) {
    switch (algorithm) {
      case SubstrateKeyAlgorithm.ed25519:
        return SubstrateED25519Signer.fromKeyBytes(keyBytes);
      case SubstrateKeyAlgorithm.secp256k1:
        return SubstrateEcdsaSigner.fromKeyBytes(keyBytes);
      default:
        return SubstrateSr25519Signer.fromKeyBytes(keyBytes);
    }
  }
  factory BaseSubstrateSigner.fromSubstrate(Substrate substrate) {
    switch (substrate.publicKey.algorithm) {
      case SubstrateKeyAlgorithm.ed25519:
        return SubstrateED25519Signer.fromKeyBytes(substrate.priveKey.raw);
      case SubstrateKeyAlgorithm.secp256k1:
        return SubstrateEcdsaSigner.fromKeyBytes(substrate.priveKey.raw);
      default:
        return SubstrateSr25519Signer.fromKeyBytes(substrate.priveKey.raw);
    }
  }
}
