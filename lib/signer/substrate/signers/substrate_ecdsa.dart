import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/utils/binary/utils.dart' show BytesUtils;
import 'package:blockchain_utils/utils/string/string.dart';

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

  final Secp256k1SigningKey _ecdsaSigningKey;

  /// Factory method to create an ETHSigner from a byte representation of a private key.
  factory SubstrateEcdsaSigner.fromKeyBytes(List<int> keyBytes) {
    return SubstrateEcdsaSigner._(
        Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
  }

  @override
  List<int> sign(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    final hash = hashMessage ? QuickCrypto.blake2b256Hash(digest) : digest;
    final signature =
        _ecdsaSigningKey.sign(digest: hash, extraEntropy: extraEntropy);
    return [
      ...signature.item1.toBytes(CryptoSignerConst.curveSecp256k1.baselen),
      signature.item2
    ];
  }

  @override
  List<int> signConst(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    final hash = hashMessage ? QuickCrypto.blake2b256Hash(digest) : digest;
    final signature =
        _ecdsaSigningKey.signConst(digest: hash, extraEntropy: extraEntropy);
    return [
      ...signature.item1.toBytes(CryptoSignerConst.curveSecp256k1.baselen),
      signature.item2
    ];
  }

  List<int> _vrfSign(List<int> message, List<int> signature,
      {List<int>? context, List<int>? extra}) {
    final vrf = QuickCrypto.blake2b256Hash(
        [...context?.asBytes ?? [], ...extra?.asBytes ?? [], ...signature]);
    final List<int> vrfResult = [...vrf, ...signature];
    final verify = toVerifyKey().vrfVerify(List.from(vrfResult), message,
        context: context, extra: extra);
    if (!verify) {
      throw const CryptoSignException(
          'The created signature does not pass verification.');
    }
    return vrfResult;
  }

  @override
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    final msg = message.asImmutableBytes;
    final signature = sign(msg);
    return _vrfSign(msg, signature, context: context, extra: extra);
  }

  @override
  List<int> vrfSignConst(List<int> message,
      {List<int>? context, List<int>? extra}) {
    final msg = message.asImmutableBytes;
    final signature = signConst(msg);
    return _vrfSign(msg, signature, context: context, extra: extra);
  }

  List<int> signProsonalMessage(List<int> digest, {int? payloadLength}) {
    final prefix = CryptoSignerConst.ethPersonalSignPrefix +
        (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    final signature = sign(<int>[...prefixBytes, ...digest]);
    signature.last += 27;
    return signature;
  }

  List<int> signProsonalMessageConst(List<int> digest, {int? payloadLength}) {
    final prefix = CryptoSignerConst.ethPersonalSignPrefix +
        (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    final signature = signConst(<int>[...prefixBytes, ...digest]);
    signature.last += 27;
    return signature;
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
        ...context?.asBytes ?? [],
        ...extra?.asBytes ?? [],
        ...signature,
      ]);
      return BytesUtils.bytesEqual(vrf, vrfHash);
    }
    return false;
  }
}
