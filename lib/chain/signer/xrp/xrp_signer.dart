import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';

/// XRP Ledger signer: supports both Ed25519 and secp256k1 keys.
class XrpSigner extends ISignatureSigner<IVerifiyingKey, ISigningKey> {
  XrpSigner._(super.signingKey);
  factory XrpSigner.from(ISigningKey key) {
    switch (key.type) {
      case CryptoKeyType.ed25519:
      case CryptoKeyType.secp256k1:
        return XrpSigner._(key);
      default:
        throw CoreErrors.unsupportedKeyType(key.type.name);
    }
  }

  factory XrpSigner.fromKeyBytes(List<int> keyBytes, CryptoKeyType algorithm) {
    final signingKey = IPrivateKey.fromBytes(keyBytes, algorithm);
    return XrpSigner.from(signingKey);
  }

  SignedContent<ISignature> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    switch (signingKey) {
      case IEd25519SigningKey signingKey:
        final signature = signingKey.sign(
          Ed25519SigningParams(message: digest),
        );
        return SignedContent<ISignature>(
          content: digest,
          signature: signature,
          encoded: signature.toBytes(),
        );
      case ISecp256k1SigningKey signingKey:
        final signature = signingKey.sign(
          Secp256k1SigningParams(
            digest:
                hashMessage ? QuickCrypto.sha512HashHalves(digest).$1 : digest,
            extraEntropy: extraEntropy,
          ),
        );
        return SignedContent<ISignature>(
          content: digest,
          signature: signature,
          encoded: signature.toBytes(encoding: ECDSASignatureEncoding.der),
        );
      default:
        throw CoreErrors.unknownKey(signingKey.type.name);
    }
  }

  @override
  XrpVerifier toVerifier() {
    return XrpVerifier._(signingKey.verificationKey());
  }
}

/// XRP Ledger signature verifier: supports both Ed25519 and secp256k1 keys.
class XrpVerifier extends ISignatureVerifier<IVerifiyingKey> {
  XrpVerifier._(super.verificationKey);

  factory XrpVerifier.from(IVerifiyingKey key) {
    switch (key.type) {
      case CryptoKeyType.ed25519:
      case CryptoKeyType.secp256k1:
        return XrpVerifier._(key);
      default:
        throw CoreErrors.unsupportedKeyType(key.type.name);
    }
  }

  factory XrpVerifier.fromKeyBytes(
    List<int> keyBytes,
    CryptoKeyType algorithm,
  ) {
    final signingKey = IPublicKey.fromBytes(keyBytes, algorithm);
    return XrpVerifier.from(signingKey);
  }

  bool verify(
    List<int> digest,
    List<int> signature, {
    bool hashMessage = true,
  }) {
    switch (verificationKey) {
      case IEd25519VerificationKey verifyKey:
        return verifyKey.verify(
          Ed25519VerifyingParams(
            Ed25519SigningParams(message: digest),
            ED25519Signature.fromBytes(signature),
          ),
        );
      case ISecp256k1VerificationKey verifyKey:
        return verifyKey.verify(
          Secp256k1VerifyingParams(
            Secp256k1SigningParams(
              digest:
                  hashMessage
                      ? QuickCrypto.sha512HashHalves(digest).$1
                      : digest,
            ),
            IECDSASignature.fromBytes(signature),
          ),
        );
      default:
        throw CoreErrors.unknownKey(verificationKey.type.name);
    }
  }
}
