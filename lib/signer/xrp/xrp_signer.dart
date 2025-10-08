import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/types.dart';

/// Class for signing XRP transactions using either EDDSA or ECDSA algorithm.
class XrpSigner {
  /// Constructs a new XrpSigner instance with the provided signing keys.
  ///
  /// This constructor is marked as private and takes an EDDSA private key [_signingKey]
  /// and an ECDSA signing key [_ecdsaSigningKey] as inputs, creating a new XrpSigner
  /// instance with the provided keys.
  XrpSigner._(this._signingKey, this._ecdsaSigningKey);

  /// The EDDSA private key for signing.
  final EDDSAPrivateKey? _signingKey;

  /// The ECDSA signing key for signing.
  final Secp256k1SigningKey? _ecdsaSigningKey;

  /// Factory method to create an XrpSigner instance from key bytes and curve type.
  ///
  /// This factory method takes a list of key bytes [keyBytes] and an [EllipticCurveTypes] [curve]
  /// as input and returns a new XrpSigner instance based on the specified curve type and key bytes.
  ///
  /// [keyBytes] The bytes representing the private key.
  /// [curve] The elliptic curve type of the private key.
  /// returns An instance of XrpSigner initialized with the provided key bytes and curve type.
  factory XrpSigner.fromKeyBytes(List<int> keyBytes, EllipticCurveTypes curve) {
    switch (curve) {
      case EllipticCurveTypes.ed25519:
        // Create an EDDSA private key from the key bytes using the ED25519 curve.
        final signingKey = EDDSAPrivateKey(
            generator: CryptoSignerConst.generatorED25519,
            privateKey: keyBytes,
            type: EllipticCurveTypes.ed25519);
        return XrpSigner._(signingKey, null);
      case EllipticCurveTypes.secp256k1:
        return XrpSigner._(
            null, Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
      default:
        // Throw an error if the curve type is not supported.
        throw CryptoSignException(
            "xrp signer support ${EllipticCurveTypes.secp256k1.name} or ${EllipticCurveTypes.ed25519} private key");
    }
  }

  // /// Signs the provided digest using the ED25519 algorithm.
  // ///
  // /// This method takes a digest as input and uses the private signing key to generate
  // /// a signature based on the ED25519 algorithm. It then verifies the signature using
  // /// the corresponding verification key and throws an exception if the verification fails.
  // ///
  // /// [digest] The digest to be signed.
  // /// returns A list of bytes representing the generated signature.
  // List<int> _signEdward(List<int> digest) {
  //   final sig = _signingKey!.sign(digest, () => SHA512());
  //   final verifyKey = toVerifyKey();
  //   final verify = verifyKey._verifyEddsa(digest, sig);
  //   if (!verify) {
  //     throw const CryptoSignException(
  //         'The created signature does not pass verification.');
  //   }
  //   return sig;
  // }

  /// Signs the provided digest using the appropriate algorithm based on the available signing key.
  ///
  /// This method takes a digest as input and delegates the signing process to either
  /// the ED25519 or ECDSA algorithm based on the type of available signing key.
  ///
  /// [digest] The digest to be signed.
  /// returns A list of bytes representing the generated signature using the appropriate algorithm.
  /// The [hashMessage] and [extraEntropy] parameters are only applicable for ECDSA signing.
  List<int> sign(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    if (_signingKey != null) {
      return _signingKey.sign(digest, () => SHA512());
    } else {
      // If an ECDSA signing key is available, use the ECDSA algorithm for signing.
      final hash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).item1 : digest;
      return _ecdsaSigningKey!
          .signDer(digest: hash, extraEntropy: extraEntropy);
    }
  }

  /// The [hashMessage] and [extraEntropy] parameters are only applicable for ECDSA signing.
  List<int> signConst(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    if (_signingKey != null) {
      // If an EDDSA private key is available, use the ED25519 algorithm for signing.
      return _signingKey.signConst(digest, () => SHA512());
    } else {
      final hash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).item1 : digest;
      return _ecdsaSigningKey!
          .signConstDer(digest: hash, extraEntropy: extraEntropy);
    }
  }

  /// Returns an XrpVerifier instance based on the available signing key type.
  ///
  /// This method constructs and returns an XrpVerifier instance adapted to the available
  /// signing key type (ED25519 or SECP256K1) for signature verification.
  ///
  /// returns An XrpVerifier instance based on the available signing key type.
  XrpVerifier toVerifyKey() {
    final keyBytes = _ecdsaSigningKey?.privateKey.publicKey.toBytes() ??
        _signingKey!.publicKey.toBytes();
    return XrpVerifier.fromKeyBytes(
        keyBytes,
        _ecdsaSigningKey == null
            ? EllipticCurveTypes.ed25519
            : EllipticCurveTypes.secp256k1);
  }
}

/// Class representing an XRP (Ripple) Verifier for signature verification.
class XrpVerifier {
  final ECDSAVerifyKey? _edsaVerifyKey;
  final EDDSAPublicKey? _eddsaPublicKey;

  /// Private constructor to create an XrpVerifier instance with the provided EDDSA public key and ECDSA verify key.
  XrpVerifier._(this._eddsaPublicKey, this._edsaVerifyKey);

  /// Factory method to create an XrpVerifier instance from key bytes and curve type.
  ///
  /// This factory method takes a list of key bytes [keyBytes] and an [EllipticCurveTypes] [curve]
  /// as input, and returns a new XrpVerifier instance based on the specified curve type and key bytes.
  ///
  /// [keyBytes] The bytes representing the public key.
  /// [curve] The elliptic curve type of the public key.
  factory XrpVerifier.fromKeyBytes(
      List<int> keyBytes, EllipticCurveTypes curve) {
    switch (curve) {
      case EllipticCurveTypes.ed25519:
        final pub = Ed25519PublicKey.fromBytes(keyBytes);
        final verifyingKey = EDDSAPublicKey(
            CryptoSignerConst.generatorED25519, pub.compressed.sublist(1));
        return XrpVerifier._(verifyingKey, null);
      case EllipticCurveTypes.secp256k1:
        final point = ProjectiveECCPoint.fromBytes(
            curve: CryptoSignerConst.generatorSecp256k1.curve,
            data: keyBytes,
            order: null);
        final verifyingKey =
            ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
        return XrpVerifier._(null, ECDSAVerifyKey(verifyingKey));
      default:
        throw CryptoSignException(
            "xrp signer support ${EllipticCurveTypes.secp256k1.name} or ${EllipticCurveTypes.ed25519} private key");
    }
  }

  /// Verifies the ECDSA signature for the provided digest.
  ///
  /// This method verifies the ECDSA signature by extracting the 'r' and 's'
  /// components from the DER-encoded signature and then using the ECDSA public
  /// key to verify the signature against the given digest.
  ///
  /// [digest] The digest used for verification.
  /// [derSignature] The DER-encoded ECDSA signature as a list of bytes.
  /// returns True if the signature is verified, false otherwise.
  bool _verifyEcdsa(List<int> digest, List<int> derSignature) {
    final signature =
        Secp256k1EcdsaSignature.fromDer(derSignature).toEcdsaSignature();
    return _edsaVerifyKey!.verify(signature, digest);
  }

  /// Verifies the EDDSA signature for the provided digest.
  ///
  /// This method verifies the EDDSA signature by using the EDDSA public key to
  /// verify the signature against the given digest using the SHA512 hashing
  /// function.
  ///
  /// [digest] The digest used for verification.
  /// [signature] The EDDSA signature as a list of bytes.
  /// returns True if the signature is verified, false otherwise.
  bool _verifyEddsa(List<int> digest, List<int> signature) {
    return _eddsaPublicKey!.verify(digest, signature, () => SHA512());
  }

  /// Verifies the signature for the provided digest using the available key and hashing option.
  ///
  /// This method verifies the signature of the provided digest using either ECDSA or EDDSA algorithms,
  /// based on the availability of the corresponding verification key. If [hashMessage] is true, the digest
  /// is hashed before verification. The method delegates to the appropriate verification algorithm
  /// and returns the result of the signature verification.
  ///
  /// [digest] The digest to be verified.
  /// [signature] The signature to be verified.
  /// [hashMessage] Whether to hash the message before verification, defaults to true.
  /// returns True if the signature is verified, false otherwise.
  /// The [hashMessage] parameter is only applicable for ECDSA signature.
  bool verify(List<int> digest, List<int> signature,
      {bool hashMessage = true}) {
    if (_edsaVerifyKey != null) {
      final messagaeHash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).item1 : digest;
      return _verifyEcdsa(messagaeHash, signature);
    }
    return _verifyEddsa(digest, signature);
  }
}
