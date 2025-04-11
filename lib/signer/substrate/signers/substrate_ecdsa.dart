import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';

class _SubstrateEcdsaSignerCons {
  static const int vrfLength =
      CryptoSignerConst.ecdsaSignatureWithRecoveryIdLength +
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

  final ECDSASigningKey _ecdsaSigningKey;

  /// Factory method to create an ETHSigner from a byte representation of a private key.
  factory SubstrateEcdsaSigner.fromKeyBytes(List<int> keyBytes) {
    final signingKey = ECDSAPrivateKey.fromBytes(
        keyBytes, CryptoSignerConst.generatorSecp256k1);
    return SubstrateEcdsaSigner._(ECDSASigningKey(signingKey));
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
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return vrfResult;
  }

  List<int> signProsonalMessage(List<int> digest, {int? payloadLength}) {
    final prefix = CryptoSignerConst.ethPersonalSignPrefix +
        (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    final sign = _signEcdsa(<int>[...prefixBytes, ...digest]);
    return sign.toBytes(true);
  }

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
        curve: CryptoSignerConst.generatorSecp256k1.curve,
        data: keyBytes,
        order: null);
    final verifyingKey =
        ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return SubstrateEcdsaVerifier._(ECDSAVerifyKey(verifyingKey));
  }

  /// Verifies an signature against a message digest.
  ///
  /// Parameters:
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  @override
  bool verify(List<int> message, List<int> signature,
      {bool hashMessage = true}) {
    final sigBytes =
        signature.sublist(0, CryptoSignerConst.ecdsaSignatureLength);
    final digest = hashMessage ? QuickCrypto.blake2b256Hash(message) : message;
    final ecdsaSignature = ECDSASignature.fromBytes(
        sigBytes, CryptoSignerConst.generatorSecp256k1);
    return edsaVerifyKey.verify(ecdsaSignature, digest);
  }

  @override
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    if (vrfSign.length != _SubstrateEcdsaSignerCons.vrfLength) {
      throw CryptoSignException(
          "Invalid vrf length. expected: ${_SubstrateEcdsaSignerCons.vrfLength} got: ${vrfSign.length}");
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
