import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/utils/utils.dart';

/// Ethereum Signer class for cryptographic operations, including signing and verification.
///
/// The `ETHSigner` class facilitates the creation of Ethereum signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class ETHSigner {
  const ETHSigner._(this._ecdsaSigningKey);

  final ECDSASigningKey _ecdsaSigningKey;

  /// Factory method to create an ETHSigner from a byte representation of a private key.
  factory ETHSigner.fromKeyBytes(List<int> keyBytes) {
    final signingKey = ECDSAPrivateKey.fromBytes(
        keyBytes, CryptoSignerConst.generatorSecp256k1);
    return ETHSigner._(ECDSASigningKey(signingKey));
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
    if (hash.length != CryptoSignerConst.digestLength) {
      throw CryptoSignException(
          "invalid digest. digest length must be ${CryptoSignerConst.digestLength} got ${digest.length}");
    }
    ECDSASignature ecdsaSign = _ecdsaSigningKey.signDigestDeterminstic(
        digest: hash, hashFunc: () => SHA256());
    if (ecdsaSign.s > CryptoSignerConst.orderHalf) {
      ecdsaSign = ECDSASignature(
          ecdsaSign.r, CryptoSignerConst.secp256k1Order - ecdsaSign.s);
    }
    final sigBytes =
        ecdsaSign.toBytes(CryptoSignerConst.generatorSecp256k1.curve.baselen);
    final verifyKey = toVerifyKey();
    if (verifyKey.verify(hash, sigBytes, hashMessage: false)) {
      final recover = ecdsaSign.recoverPublicKeys(
          hash, CryptoSignerConst.generatorSecp256k1);
      for (int i = 0; i < recover.length; i++) {
        if (recover[i].point == verifyKey.edsaVerifyKey.publicKey.point) {
          return ETHSignature(ecdsaSign.r, ecdsaSign.s, i + 27);
        }
      }
    }

    throw const CryptoSignException(
        'The created signature does not pass verification.');
  }

  ETHSignature sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage);
  }

  List<int> signProsonalMessage(List<int> digest, {int? payloadLength}) {
    final prefix = CryptoSignerConst.ethPersonalSignPrefix +
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
        curve: CryptoSignerConst.generatorSecp256k1.curve,
        data: keyBytes,
        order: null);
    final verifyingKey =
        ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return ETHVerifier._(ECDSAVerifyKey(verifyingKey));
  }

  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature = ECDSASignature.fromBytes(
        sigBytes, CryptoSignerConst.generatorSecp256k1);
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
    final sigBytes =
        signature.sublist(0, CryptoSignerConst.ecdsaSignatureLength);
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
    return _verifyEcdsa(messagaeHash,
        signature.sublist(0, CryptoSignerConst.ecdsaSignatureLength));
  }

  static List<int> _hashMessage(List<int> message,
      {bool hashMessage = true, int? payloadLength}) {
    if (hashMessage) {
      final prefix = CryptoSignerConst.ethPersonalSignPrefix +
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
    final recoverId = toBytes[CryptoSignerConst.ecdsaSignatureLength];
    final signatureBytes = ECDSASignature.fromBytes(
        toBytes.sublist(0, CryptoSignerConst.ecdsaSignatureLength),
        CryptoSignerConst.generatorSecp256k1);
    return signatureBytes.recoverPublicKey(
        messagaeHash, CryptoSignerConst.generatorSecp256k1, recoverId);
  }
}
