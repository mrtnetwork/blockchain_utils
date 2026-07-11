import 'package:blockchain_utils/crypto/crypto/ec/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';

/// Nist256p1Signer Signer class for cryptographic operations, including signing and verification.
class Nist256p1Signer {
  const Nist256p1Signer._(this._ecdsaSigningKey);

  final ECDSASigningKey _ecdsaSigningKey;

  /// Factory method to create a [Nist256p1Signer] from a byte representation of a private key.
  factory Nist256p1Signer.fromKeyBytes(List<int> keyBytes) {
    final signingKey = ECDSAPrivateKey.fromBytes(
      keyBytes,
      CryptoSignerConst.nist256,
    );
    return Nist256p1Signer._(ECDSASigningKey(signingKey));
  }

  List<int> _signEcdsa(List<int> digest, {bool hashMessage = true}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    if (hash.length != CryptoSignerConst.nist256DigestLength) {
      throw ArgumentException.invalidOperationArguments(
        "signing",
        name: "digest",
        reason: "Invalid digest bytes length.",
      );
    }
    ECDSASignature ecdsaSign = _ecdsaSigningKey.signDigestDeterminstic(
      digest: hash,
      hashFunc: () => SHA256(),
    );
    if (ecdsaSign.s > CryptoSignerConst.orderHalf) {
      ecdsaSign = ECDSASignature(
        ecdsaSign.r,
        CryptoSignerConst.nist256256Order - ecdsaSign.s,
      );
    }
    final sigBytes = ecdsaSign.toBytes(CryptoSignerConst.nist256.curve.baselen);
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(hash, sigBytes)) {
      return ecdsaSign.toBytes(CryptoSignerConst.nist256DigestLength);
    }

    throw CryptoSignException.signatureVerificationFailed;
  }

  /// Signs a message digest using the ECDSA algorithm on the secp256R1 curve.
  ///
  /// Parameters:
  /// - [digest]: The message digest to be signed.
  /// - [hashMessage]: Whether to hash the message before signing (default is true).
  ///
  /// Throws:
  /// - [ArgumentException] if the digest length is invalid.
  List<int> sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage);
  }

  /// Converts the [Nist256p1Signer] to a [Nist256p1Verifier] for verification purposes.
  Nist256p1Verifier toVerifyKey() {
    return Nist256p1Verifier.fromKeyBytes(
      _ecdsaSigningKey.privateKey.publicKey.toBytes(),
    );
  }
}

/// [Nist256p1Verifier] class for cryptographic operations, including signature verification.
class Nist256p1Verifier {
  final ECDSAVerifyKey edsaVerifyKey;

  Nist256p1Verifier._(this.edsaVerifyKey);

  /// Factory method to create a [Nist256p1Verifier] from a byte representation of a public key.
  factory Nist256p1Verifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: CryptoSignerConst.nist256.curve,
      data: keyBytes,
      order: null,
    );
    final verifyingKey = ECDSAPublicKey(CryptoSignerConst.nist256, point);
    return Nist256p1Verifier._(ECDSAVerifyKey(verifyingKey));
  }

  /// Verifies a Nist256p1 signature against a message digest.
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
      CryptoSignerConst.nist256,
    );
    return edsaVerifyKey.verify(ecdsaSignature, message);
  }
}
