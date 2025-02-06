import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/eth/evm_signer.dart';

/// Secp256k1 Signer class for cryptographic operations, including signing and verification.
///
/// The [Secp256k1Signer] class facilitates the creation of Ecdsa signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class Secp256k1Signer {
  const Secp256k1Signer._(this._ecdsaSigningKey);

  final EcdsaSigningKey _ecdsaSigningKey;

  /// Factory method to create a [Secp256k1Signer] from a byte representation of a private key.
  factory Secp256k1Signer.fromKeyBytes(List<int> keyBytes) {
    final signingKey =
        ECDSAPrivateKey.fromBytes(keyBytes, ETHSignerConst.secp256);
    return Secp256k1Signer._(EcdsaSigningKey(signingKey));
  }

  List<int> _signEcdsa(List<int> digest, {bool hashMessage = true}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    if (hash.length != ETHSignerConst.digestLength) {
      throw ArgumentException(
          "invalid digest. digest length must be ${ETHSignerConst.digestLength} got ${digest.length}");
    }
    ECDSASignature ecdsaSign = _ecdsaSigningKey.signDigestDeterminstic(
        digest: hash, hashFunc: () => SHA256());
    if (ecdsaSign.s > ETHSignerConst.orderHalf) {
      ecdsaSign =
          ECDSASignature(ecdsaSign.r, ETHSignerConst.curveOrder - ecdsaSign.s);
    }
    final sigBytes = ecdsaSign.toBytes(ETHSignerConst.secp256.curve.baselen);
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(hash, sigBytes)) {
      return ecdsaSign.toBytes(ETHSignerConst.digestLength);
    }

    throw const MessageException(
        'The created signature does not pass verification.');
  }

  /// Signs a message digest using the ECDSA algorithm on the secp256k1 curve.
  ///
  /// Optionally, the message can be hashed before signing.
  ///
  /// Parameters:
  /// - [digest]: The message digest to be signed.
  /// - [hashMessage]: Whether to hash the message before signing (default is true).
  ///
  /// Returns:
  /// - A byte list representing the signature of the message digest.
  ///
  /// Throws:
  /// - [ArgumentException] if the digest length is invalid.
  List<int> sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage);
  }

  /// Converts the [Secp256k1Signer] to a [Secp256k1Verifier] for verification purposes.
  ///
  /// Returns:
  /// - A [Secp256k1Verifier] representing the verification key.
  Secp256k1Verifier toVerifyKey() {
    return Secp256k1Verifier.fromKeyBytes(
        _ecdsaSigningKey.privateKey.publicKey.toBytes());
  }
}

/// Secp256k1 Verifier class for cryptographic operations, including signature verification.
///
/// The [Secp256k1Verifier] class allows the verification of Secp256k1 signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class Secp256k1Verifier {
  final ECDSAVerifyKey edsaVerifyKey;

  Secp256k1Verifier._(this.edsaVerifyKey);

  /// Factory method to create a [Secp256k1Verifier] from a byte representation of a public key.
  factory Secp256k1Verifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: ETHSignerConst.secp256.curve, data: keyBytes, order: null);
    final verifyingKey = ECDSAPublicKey(ETHSignerConst.secp256, point);
    return Secp256k1Verifier._(ECDSAVerifyKey(verifyingKey));
  }
  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature =
        ECDSASignature.fromBytes(sigBytes, ETHSignerConst.secp256);
    return edsaVerifyKey.verify(signature, digest);
  }

  /// Verifies a Secp256k1 signature against a message digest.
  ///
  /// Parameters:
  /// - [message]: The message digest.
  /// - [signature]: The signature bytes.
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verify(List<int> message, List<int> signature,
      {bool hashMessage = false}) {
    if (hashMessage) {
      message = QuickCrypto.sha256Hash(message);
    }
    return _verifyEcdsa(message, signature);
  }
}
