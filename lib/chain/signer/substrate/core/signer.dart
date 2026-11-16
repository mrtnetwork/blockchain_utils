import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/protocol/substrate/substrate.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_ecdsa.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_eddsa.dart';
import 'package:blockchain_utils/chain/signer/substrate/signers/substrate_sr25519.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';

/// Contract every Substrate key-algorithm signer implements.
abstract class BaseSubstrateSigner<
  SIGNATURE extends ISignature,
  VK extends IVerifiyingKey,
  SK extends ISigningKey
>
    extends ISignatureSigner<VK, SK> {
  const BaseSubstrateSigner(super.signingKey);
  SignedContent<SIGNATURE> sign(List<int> digest);
  SignedContent<SIGNATURE> vrfSign(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
  });

  /// Picks the signer implementation matching [algorithm].
  static BaseSubstrateSigner fromBytes(
    List<int> keyBytes,
    CryptoKeyType algorithm,
  ) {
    switch (algorithm) {
      case CryptoKeyType.ed25519:
        return SubstrateED25519Signer.fromKeyBytes(keyBytes);
      case CryptoKeyType.secp256k1:
        return SubstrateEcdsaSigner.fromKeyBytes(keyBytes);
      case CryptoKeyType.sr25519:
        return SubstrateSr25519Signer.fromKeyBytes(keyBytes);
      default:
        throw CoreErrors.invalidOperationArguments(
          "BaseSubstrateSigner",
          name: "algorithm",
          reason: "Unsupported key algorithm.",
        );
    }
  }

  /// Picks the signer implementation matching [substrate]'s coin config.
  static BaseSubstrateSigner fromSubstrate(Substrate substrate) {
    return substrate.priveKey.toBytes().useValue((k) {
      switch (substrate.coinConf.type) {
        case CryptoKeyType.ed25519:
          return SubstrateED25519Signer.fromKeyBytes(k);
        case CryptoKeyType.secp256k1:
          return SubstrateEcdsaSigner.fromKeyBytes(k);
        default:
          return SubstrateSr25519Signer.fromKeyBytes(k);
      }
    }, zero: true);
  }

  @override
  BaseSubstrateVerifier<VK> toVerifier();
}
