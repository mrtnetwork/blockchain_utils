import 'package:blockchain_utils/crypto/crypto/cdsa/cdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';

/// Secp256k1 Signer class for cryptographic operations, including signing and verification.
///
/// The [Secp256k1Signer] class facilitates the creation of Ecdsa signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class Secp256k1Signer {
  const Secp256k1Signer._(this._ecdsaSigningKey);

  final Secp256k1SigningKey _ecdsaSigningKey;

  /// Factory method to create a [Secp256k1Signer] from a byte representation of a private key.
  factory Secp256k1Signer.fromKeyBytes(List<int> keyBytes) {
    return Secp256k1Signer._(Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
  }

  // List<int> _signEcdsaConst(List<int> digest,
  //     {Secp256k1ECmultGenContext? context,
  //     bool hashMessage = true,
  //     List<int>? extraEntropy}) {
  //   final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
  //   if (hash.length != CryptoSignerConst.digestLength) {
  //     throw CryptoSignException(
  //         "invalid digest. digest length must be ${CryptoSignerConst.digestLength} got ${digest.length}");
  //   }
  //   if (context == null) {
  //     context = Secp256k1ECmultGenContext();
  //     Secp256k1.secp256k1ECmultGenBlind(context, null);
  //     Secp256k1.secp256k1ECmultGenBlind(
  //         context, QuickCrypto.generateRandom());
  //   }
  //   final keyBytes = _ecdsaSigningKey.privateKey.toBytes();
  //   List<int> k = RFC6979.generateSecp256k1KBytes(
  //       secexp: keyBytes,
  //       hashFunc: () => SHA256(),
  //       data: hash,
  //       extraEntropy: extraEntropy);
  //   final ecdsaSign = Secp256k1.signInternal(
  //       kBytes: k, privateKey: keyBytes, messageB: hash, context: context);
  //   final sigBytes =
  //       ecdsaSign.toBytes(CryptoSignerConst.generatorSecp256k1.curve.baselen);
  //   final verifyKey = toVerifyKey();
  //   if (verifyKey.verify(hash, sigBytes)) {
  //     return ecdsaSign.toBytes(CryptoSignerConst.digestLength);
  //   }

  //   throw const CryptoSignException(
  //       'The created signature does not pass verification.');
  // }

  // List<int> _signEcdsa(List<int> digest, {bool hashMessage = true}) {
  //   final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
  //   if (hash.length != CryptoSignerConst.digestLength) {
  //     throw CryptoSignException(
  //         "invalid digest. digest length must be ${CryptoSignerConst.digestLength} got ${digest.length}");
  //   }
  //   ECDSASignature ecdsaSign = _ecdsaSigningKey.signDigestDeterminstic(
  //       digest: hash, hashFunc: () => SHA256());
  //   if (ecdsaSign.s > CryptoSignerConst.orderHalf) {
  //     ecdsaSign = ECDSASignature(
  //         ecdsaSign.r, CryptoSignerConst.secp256k1Order - ecdsaSign.s);
  //   }
  //   final sigBytes =
  //       ecdsaSign.toBytes(CryptoSignerConst.generatorSecp256k1.curve.baselen);
  //   final verifyKey = toVerifyKey();
  //   if (verifyKey.verify(hash, sigBytes)) {
  //     return ecdsaSign.toBytes(CryptoSignerConst.digestLength);
  //   }

  //   throw const CryptoSignException(
  //       'The created signature does not pass verification.');
  // }

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
  /// - [CryptoSignException] if the digest length is invalid.
  List<int> sign(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    return _ecdsaSigningKey
        .sign(digest: hash, extraEntropy: extraEntropy)
        .item1
        .toBytes(CryptoSignerConst.curveSecp256k1.baselen);
  }

  List<int> signConst(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    return _ecdsaSigningKey
        .signConst(digest: hash, extraEntropy: extraEntropy)
        .item1
        .toBytes(CryptoSignerConst.curveSecp256k1.baselen);
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
        curve: CryptoSignerConst.generatorSecp256k1.curve,
        data: keyBytes,
        order: null);
    final verifyingKey =
        ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return Secp256k1Verifier._(ECDSAVerifyKey(verifyingKey));
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
    final ecdsaSignature = ECDSASignature.fromBytes(
        signature, CryptoSignerConst.generatorSecp256k1);
    return edsaVerifyKey.verify(ecdsaSignature, message);
  }
}
