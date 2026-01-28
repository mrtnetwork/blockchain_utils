import 'package:blockchain_utils/crypto/crypto/ec/cdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';

/// Secp256k1 Signer class for cryptographic operations, including signing and verification.
class Secp256k1Signer {
  const Secp256k1Signer._(this._ecdsaSigningKey);

  final Secp256k1SigningKey _ecdsaSigningKey;

  /// Factory method to create a [Secp256k1Signer] from a byte representation of a private key.
  factory Secp256k1Signer.fromKeyBytes(List<int> keyBytes) {
    return Secp256k1Signer._(Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
  }

  /// Signs a message digest using the ECDSA algorithm on the secp256k1 curve.
  ///
  /// Parameters:
  /// - [digest]: The message digest to be signed.
  /// - [hashMessage]: Whether to hash the message before signing (default is true).
  ///
  /// Throws:
  /// - [ArgumentException] if the digest length is invalid.
  List<int> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    return _ecdsaSigningKey
        .sign(digest: hash, extraEntropy: extraEntropy)
        .$1
        .toBytes(CryptoSignerConst.curveSecp256k1.baselen);
  }

  List<int> signConst(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    return _ecdsaSigningKey
        .signConst(digest: hash, extraEntropy: extraEntropy)
        .$1
        .toBytes(CryptoSignerConst.curveSecp256k1.baselen);
  }

  /// Converts the [Secp256k1Signer] to a [Secp256k1Verifier] for verification purposes.
  Secp256k1Verifier toVerifyKey() {
    return Secp256k1Verifier.fromKeyBytes(
      _ecdsaSigningKey.privateKey.publicKey.toBytes(),
    );
  }
}

/// Secp256k1 Verifier class for cryptographic operations, including signature verification.
class Secp256k1Verifier {
  final ECDSAVerifyKey edsaVerifyKey;

  Secp256k1Verifier._(this.edsaVerifyKey);

  /// Factory method to create a [Secp256k1Verifier] from a byte representation of a public key.
  factory Secp256k1Verifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: CryptoSignerConst.generatorSecp256k1.curve,
      data: keyBytes,
      order: null,
    );
    final verifyingKey = ECDSAPublicKey(
      CryptoSignerConst.generatorSecp256k1,
      point,
    );
    return Secp256k1Verifier._(ECDSAVerifyKey(verifyingKey));
  }

  /// Verifies a Secp256k1 signature against a message digest.
  ///
  /// Parameters:
  /// - [message]: The message digest.
  /// - [signature]: The signature bytes.
  ///
  bool verify(
    List<int> message,
    List<int> signature, {
    bool hashMessage = false,
  }) {
    if (hashMessage) {
      message = QuickCrypto.sha256Hash(message);
    }
    final ecdsaSignature = ECDSASignature.fromBytes(
      signature,
      CryptoSignerConst.generatorSecp256k1,
    );
    return edsaVerifyKey.verify(ecdsaSignature, message);
  }
}
