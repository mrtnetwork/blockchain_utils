import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/eth/eth_signature.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Constants used by the Ethereum Signer for cryptographic operations.
///
/// This class provides essential constants related to the Ethereum Signer,
/// including curve parameters, signature lengths, and the Ethereum personal
/// sign prefix. These constants are used in cryptographic operations for
/// signing and verifying Ethereum transactions and messages.
class ETHSignerConst {
  /// The projective ECC point representing the secp256k1 elliptic curve.
  static final ProjectiveECCPoint secp256 = Curves.generatorSecp256k1;

  /// The length of the digest (or component) in bytes for the secp256k1 curve.
  static final int digestLength = secp256.curve.baselen;

  /// The order of the secp256k1 elliptic curve.
  static final curveOrder = secp256.order!;

  /// Half of the order of the secp256k1 elliptic curve.
  static final BigInt orderHalf = curveOrder >> 1;

  /// The length of an Ethereum signature (r + s) in bytes.
  static const int ethSignatureLength = 64;

  /// The length of the recovery id in an Ethereum signature in bytes.
  static const int ethSignatureRecoveryIdLength = 1;

  /// The Ethereum personal sign prefix used in message signing.+
  static const ethPersonalSignPrefix = '\u0019Ethereum Signed Message:\n';
}

/// Ethereum Signer class for cryptographic operations, including signing and verification.
///
/// The `ETHSigner` class facilitates the creation of Ethereum signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class ETHSigner {
  const ETHSigner._(this._ecdsaSigningKey);

  final EcdsaSigningKey _ecdsaSigningKey;

  /// Factory method to create an ETHSigner from a byte representation of a private key.
  factory ETHSigner.fromKeyBytes(List<int> keyBytes) {
    final signingKey =
        ECDSAPrivateKey.fromBytes(keyBytes, ETHSignerConst.secp256);
    return ETHSigner._(EcdsaSigningKey(signingKey));
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
  /// - An ETHSignature representing the signature of the message digest.
  ETHSignature _signEcdsa(List<int> digest, {bool hashMessage = true}) {
    final hash = hashMessage ? QuickCrypto.keccack256Hash(digest) : digest;
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
    if (verifyKey.verify(hash, sigBytes, hashMessage: false)) {
      final recover = ecdsaSign.recoverPublicKeys(hash, ETHSignerConst.secp256);
      for (int i = 0; i < recover.length; i++) {
        if (recover[i].point == verifyKey.edsaVerifyKey.publicKey.point) {
          return ETHSignature(ecdsaSign.r, ecdsaSign.s, i + 27);
        }
      }
    }

    throw const MessageException(
        'The created signature does not pass verification.');
  }

  /// Signs a personal message digest with an optional payload length.
  ///
  /// The Ethereum personal sign prefix is applied to the message, and the resulting
  /// signature is returned as a byte list. Optionally, a payload length can be provided.
  ///
  /// Parameters:
  /// - [digest]: The personal message digest to be signed.
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  ///
  /// Returns:
  /// - A byte list representing the signature of the personal message.
  ETHSignature sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage);
  }

  List<int> signProsonalMessage(List<int> digest, {int? payloadLength}) {
    final prefix = ETHSignerConst.ethPersonalSignPrefix +
        (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    final sign = _signEcdsa(<int>[...prefixBytes, ...digest]);
    return sign.toBytes(true);
  }

  /// Converts the ETHSigner to an ETHVerifier for verification purposes.
  ///
  /// Returns:
  /// - An ETHVerifier representing the verification key.
  ETHVerifier toVerifyKey() {
    return ETHVerifier.fromKeyBytes(
        _ecdsaSigningKey.privateKey.publicKey.toBytes());
  }
}

/// Ethereum Verifier class for cryptographic operations, including signature verification.
///
/// The `ETHVerifier` class allows the verification of Ethereum signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class ETHVerifier {
  final ECDSAVerifyKey edsaVerifyKey;

  ETHVerifier._(this.edsaVerifyKey);

  /// Factory method to create an ETHVerifier from a byte representation of a public key.
  factory ETHVerifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: ETHSignerConst.secp256.curve, data: keyBytes, order: null);
    final verifyingKey = ECDSAPublicKey(ETHSignerConst.secp256, point);
    return ETHVerifier._(ECDSAVerifyKey(verifyingKey));
  }

  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature =
        ECDSASignature.fromBytes(sigBytes, ETHSignerConst.secp256);
    return edsaVerifyKey.verify(signature, digest);
  }

  /// Verifies an Ethereum signature against a message digest.
  ///
  /// Parameters:
  /// - [digest]: The message digest.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verify(List<int> digest, List<int> signature,
      {bool hashMessage = true}) {
    final sigBytes = signature.sublist(0, ETHSignerConst.ethSignatureLength);
    final hashDigest =
        hashMessage ? QuickCrypto.keccack256Hash(digest) : digest;
    return _verifyEcdsa(hashDigest, sigBytes);
  }

  /// Verifies an Ethereum signature of a personal message against the message digest.
  ///
  /// Parameters:
  /// - [message]: The personal message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verifyPersonalMessage(List<int> message, List<int> signature,
      {bool hashMessage = true, int? payloadLength}) {
    final List<int> messagaeHash = _hashMessage(message,
        hashMessage: hashMessage, payloadLength: payloadLength);
    return _verifyEcdsa(
        messagaeHash, signature.sublist(0, ETHSignerConst.ethSignatureLength));
  }

  static List<int> _hashMessage(List<int> message,
      {bool hashMessage = true, int? payloadLength}) {
    if (hashMessage) {
      final prefix = ETHSignerConst.ethPersonalSignPrefix +
          (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes =
          StringUtils.encode(prefix, type: StringEncoding.ascii);
      return QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...message]);
    }
    return message;
  }

  /// Gets the recovered ECDSAPublicKey from a message and signature.
  ///
  /// Parameters:
  /// - [message]: The message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before recovering the public key (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  ///
  /// Returns:
  /// - The recovered ECDSAPublicKey.
  static ECDSAPublicKey? getPublicKey(List<int> message, List<int> signature,
      {bool hashMessage = true, int? payloadLength}) {
    final List<int> messagaeHash = _hashMessage(message,
        hashMessage: hashMessage, payloadLength: payloadLength);
    final ethSignature = ETHSignature.fromBytes(signature);
    final toBytes = ethSignature.toBytes(false);
    final recoverId = toBytes[ETHSignerConst.ethSignatureLength];
    final signatureBytes = ECDSASignature.fromBytes(
        toBytes.sublist(0, ETHSignerConst.ethSignatureLength),
        ETHSignerConst.secp256);
    return signatureBytes.recoverPublicKey(
        messagaeHash, ETHSignerConst.secp256, recoverId);
  }
}
