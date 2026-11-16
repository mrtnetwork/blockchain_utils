import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/substrate/substrate.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_sr25519.dart';

/// Contract every Substrate key-algorithm verifier implements.
abstract class BaseSubstrateVerifier<VK extends IVerifiyingKey>
    extends ISignatureVerifier<VK> {
  const BaseSubstrateVerifier(super.verificationKey);
  bool verify(List<int> message, List<int> signature);
  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  });

  /// Picks the verifier implementation matching [algorithm].
  static BaseSubstrateVerifier fromBytes(
    List<int> keyBytes,
    CryptoKeyType algorithm,
  ) {
    switch (algorithm) {
      case CryptoKeyType.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(keyBytes);
      case CryptoKeyType.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(keyBytes);
      case CryptoKeyType.sr25519:
        return SubstrateSr25519Verifier.fromKeyBytes(keyBytes);
      default:
        throw CoreErrors.invalidOperationArguments(
          "BaseSubstrateVerifier",
          name: "algorithm",
          reason: "Unsupported key algorithm.",
        );
    }
  }

  /// Picks the verifier implementation matching [substrate]'s coin config.
  static BaseSubstrateVerifier fromSubstrate(Substrate substrate) {
    final publicKey = substrate.publicKey.toBytes();
    switch (substrate.coinConf.type) {
      case CryptoKeyType.ed25519:
        return SubstrateED25519Verifier.fromKeyBytes(publicKey);
      case CryptoKeyType.secp256k1:
        return SubstrateEcdsaVerifier.fromKeyBytes(publicKey);
      default:
        return SubstrateSr25519Verifier.fromKeyBytes(publicKey);
    }
  }
}
