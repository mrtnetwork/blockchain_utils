import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/signer/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/eth/eth_signature.dart';
import 'package:blockchain_utils/signer/eth/evm_signer.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';

class _SubstrateEcdsaSignerCons {
  static const int vrfLength = ETHSignerConst.ethSignatureLength +
      ETHSignerConst.ethSignatureRecoveryIdLength +
      QuickCrypto.blake2b256DigestSize;
}

/// Ethereum Signer class for cryptographic operations, including signing and verification.
///
/// The `ETHSigner` class facilitates the creation of Ethereum signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class SubstrateEcdsaSigner implements BaseSubstrateSigner {
  const SubstrateEcdsaSigner._(this._ecdsaSigningKey);

  final EcdsaSigningKey _ecdsaSigningKey;

  /// Factory method to create an ETHSigner from a byte representation of a private key.
  factory SubstrateEcdsaSigner.fromKeyBytes(List<int> keyBytes) {
    final signingKey =
        ECDSAPrivateKey.fromBytes(keyBytes, ETHSignerConst.secp256);
    return SubstrateEcdsaSigner._(EcdsaSigningKey(signingKey));
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
    final hash = hashMessage ? QuickCrypto.blake2b256Hash(digest) : digest;
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
  @override
  List<int> sign(List<int> digest, {bool hashMessage = true}) {
    return _signEcdsa(digest, hashMessage: hashMessage).toBytes(false);
  }

  @override
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    final msg = BytesUtils.toBytes(message, unmodifiable: true);
    final signature = sign(message);
    final vrf = QuickCrypto.blake2b256Hash([
      ...BytesUtils.tryToBytes(context) ?? [],
      ...BytesUtils.tryToBytes(extra) ?? [],
      ...signature,
    ]);
    final List<int> vrfResult = [...vrf, ...signature];
    final verify = toVerifyKey()
        .vrfVerify(List.from(vrfResult), msg, context: context, extra: extra);
    if (!verify) {
      throw const MessageException(
          'The created signature does not pass verification.');
    }
    return vrfResult;
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
  SubstrateEcdsaVerifier toVerifyKey() {
    return SubstrateEcdsaVerifier.fromKeyBytes(
        _ecdsaSigningKey.privateKey.publicKey.toBytes());
  }
}

/// Ethereum Verifier class for cryptographic operations, including signature verification.
///
/// The `ETHVerifier` class allows the verification of Ethereum signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class SubstrateEcdsaVerifier implements BaseSubstrateVerifier {
  final ECDSAVerifyKey edsaVerifyKey;

  SubstrateEcdsaVerifier._(this.edsaVerifyKey);

  /// Factory method to create an ETHVerifier from a byte representation of a public key.
  factory SubstrateEcdsaVerifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: ETHSignerConst.secp256.curve, data: keyBytes, order: null);
    final verifyingKey = ECDSAPublicKey(ETHSignerConst.secp256, point);
    return SubstrateEcdsaVerifier._(ECDSAVerifyKey(verifyingKey));
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
  @override
  bool verify(List<int> message, List<int> signature,
      {bool hashMessage = true}) {
    final sigBytes = signature.sublist(0, ETHSignerConst.ethSignatureLength);
    final hashDigest =
        hashMessage ? QuickCrypto.blake2b256Hash(message) : message;
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
    List<int> messagaeHash = _hashMessage(message,
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
      return QuickCrypto.blake2b256Hash(<int>[...prefixBytes, ...message]);
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
    List<int> messagaeHash = _hashMessage(message,
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

  @override
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    if (vrfSign.length != _SubstrateEcdsaSignerCons.vrfLength) {
      throw ArgumentException(
          "Invalid vrf length. excepted: ${_SubstrateEcdsaSignerCons.vrfLength} got: ${vrfSign.length}");
    }
    final List<int> signature =
        vrfSign.sublist(QuickCrypto.blake2b256DigestSize);
    final verifySignature = verify(message, signature);

    if (verifySignature) {
      final vrfHash = vrfSign.sublist(0, QuickCrypto.blake2b256DigestSize);
      final vrf = QuickCrypto.blake2b256Hash([
        ...BytesUtils.tryToBytes(context) ?? [],
        ...BytesUtils.tryToBytes(extra) ?? [],
        ...signature,
      ]);
      return BytesUtils.bytesEqual(vrf, vrfHash);
    }
    return false;
  }
}
