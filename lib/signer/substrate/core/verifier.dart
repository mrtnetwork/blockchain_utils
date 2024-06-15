import 'package:blockchain_utils/bip/substrate/substrate.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/signer/substrate/signers/substrate_sr25519.dart';

abstract class BaseSubstrateVerifier {
  bool verify(List<int> message, List<int> signature);
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra});

  factory BaseSubstrateVerifier.fromBytes(
      List<int> keyBytes, SubstrateKeyAlgorithm algorithm) {
    switch (algorithm) {
      case SubstrateKeyAlgorithm.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(keyBytes);
      case SubstrateKeyAlgorithm.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(keyBytes);
      default:
        return SubstrateSr25519Verifier.fromKeyBytes(keyBytes);
    }
  }
  factory BaseSubstrateVerifier.fromSubstrate(Substrate substrate) {
    switch (substrate.publicKey.algorithm) {
      case SubstrateKeyAlgorithm.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(
            substrate.publicKey.compressed);
      case SubstrateKeyAlgorithm.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(
            substrate.publicKey.compressed);
      default:
        return SubstrateSr25519Verifier.fromKeyBytes(
            substrate.publicKey.compressed);
    }
  }
}
