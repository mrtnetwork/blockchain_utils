import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Signs Substrate transactions with an SR25519 key.
class SubstrateSr25519Signer
    extends
        BaseSubstrateSigner<
          BaseSR25519Signature,
          ISR25519VerificationKey,
          ISR25519SigningKey
        > {
  static const int vrfProofLength = 64;

  /// Constructs a [SubstrateSr25519Signer] with the provided signing key.
  SubstrateSr25519Signer(super.signingKey);

  /// Creates a [SubstrateSr25519Signer] from raw private key bytes.
  factory SubstrateSr25519Signer.fromKeyBytes(List<int> keyBytes) {
    return SubstrateSr25519Signer(SR25519PrivateKey.fromBytes(keyBytes));
  }

  @override
  SignedContent<SR25519Signature> sign(List<int> message, {List<int>? nonce}) {
    final signature = signingKey.sign(
      SR25519SigningParams(
        context: StringUtils.encode("substrate"),
        message: message,
        nonce: nonce,
      ),
    );
    return SignedContent<SR25519Signature>(
      signature: signature,
      content: null,
      encoded: signature.toBytes(),
    );
  }

  @override
  SignedContent<SR25519VRFSignature> vrfSign(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
    List<int>? nonce,
  }) {
    final sign = signingKey.vrfSign(
      SR25519VrfSigningParams(
        context: context ?? [],
        message: message,
        vrfScriptadditionalData: extra,
        kusamaVRF: true,
        nonce: nonce,
      ),
    );
    final List<int> vrfResult = sign.toBytes();
    return SignedContent<SR25519VRFSignature>(
      signature: sign,
      content: message,
      encoded: vrfResult,
    );
  }

  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  }) {
    return signingKey.verificationKey().vrfVerify(
      SR25519VRFVerifyingParams(
        signingParams: SR25519VrfSigningParams(
          context: context ?? [],
          message: message,
          kusamaVRF: true,
          vrfScriptadditionalData: extra,
        ),
        signature: SR25519VRFSignature.fromBytes(vrfSign),
      ),
    );
  }

  /// Returns the [SubstrateSr25519Verifier] matching this signer's key.
  @override
  SubstrateSr25519Verifier toVerifier() {
    return SubstrateSr25519Verifier(signingKey.verificationKey());
  }
}

/// Verifies Substrate signatures made with an SR25519 key.
class SubstrateSr25519Verifier
    extends BaseSubstrateVerifier<ISR25519VerificationKey> {
  /// Constructs a [SubstrateSr25519Verifier] from an [ISR25519VerificationKey].
  const SubstrateSr25519Verifier(super.verificationKey);

  /// Creates a [SubstrateSr25519Verifier] from raw public key bytes.
  factory SubstrateSr25519Verifier.fromKeyBytes(List<int> keyBytes) {
    final verifier = SR25519PublicKey(keyBytes);
    return SubstrateSr25519Verifier(verifier);
  }

  /// Verifies the signature for the provided digest using the available key.
  @override
  bool verify(List<int> message, List<int> signature) {
    return verificationKey.verify(
      SR25519VerifyingParams(
        signingParams: SR25519SigningParams(
          context: StringUtils.encode("substrate"),
          message: message,
        ),
        signature: SR25519Signature.fromBytes(signature),
      ),
    );
  }

  @override
  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  }) {
    return verificationKey.vrfVerify(
      SR25519VRFVerifyingParams(
        signingParams: SR25519VrfSigningParams(
          context: context ?? [],
          message: message,
          kusamaVRF: true,
          vrfScriptadditionalData: extra,
        ),
        signature: SR25519VRFSignature.fromBytes(vrfSign),
      ),
    );
  }
}
