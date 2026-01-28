import 'package:blockchain_utils/bip/ecc/bip_ecc.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/types.dart';

/// Class for signing XRP transactions using either EDDSA or ECDSA algorithm.
class XrpSigner {
  /// Constructs a new XrpSigner instance with the provided signing keys.
  XrpSigner._(this._signingKey, this._ecdsaSigningKey);

  /// The EDDSA private key for signing.
  final EDDSAPrivateKey? _signingKey;

  /// The ECDSA signing key for signing.
  final Secp256k1SigningKey? _ecdsaSigningKey;

  /// Factory method to create an XrpSigner instance from key bytes and algorithm type.
  ///
  /// [keyBytes] The bytes representing the private key.
  /// [algorithm] The elliptic curve type of the private key.
  ///
  factory XrpSigner.fromKeyBytes(
    List<int> keyBytes,
    EllipticCurveTypes algorithm,
  ) {
    switch (algorithm) {
      case EllipticCurveTypes.ed25519:
        // Create an EDDSA private key from the key bytes using the ED25519 curve.
        final signingKey = EDDSAPrivateKey(
          generator: CryptoSignerConst.generatorED25519,
          secretKey: keyBytes,
          type: EllipticCurveTypes.ed25519,
        );
        return XrpSigner._(signingKey, null);
      case EllipticCurveTypes.secp256k1:
        return XrpSigner._(
          null,
          Secp256k1SigningKey.fromBytes(keyBytes: keyBytes),
        );
      default:
        throw ArgumentException.invalidOperationArguments(
          "XrpSigner",
          name: "algorithm",
          reason: "Unsupported secret key algorithm.",
        );
    }
  }

  /// Signs the provided digest using the appropriate algorithm based on the available signing key.
  ///
  /// [digest] The digest to be signed.
  ///
  List<int> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    if (_signingKey != null) {
      return _signingKey.sign(digest, () => SHA512());
    } else {
      // If an ECDSA signing key is available, use the ECDSA algorithm for signing.
      final hash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).$1 : digest;
      return _ecdsaSigningKey!.signDer(
        digest: hash,
        extraEntropy: extraEntropy,
      );
    }
  }

  /// The [hashMessage] and [extraEntropy] parameters are only applicable for ECDSA signing.
  List<int> signConst(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    if (_signingKey != null) {
      // If an EDDSA private key is available, use the ED25519 algorithm for signing.
      return _signingKey.signConst(digest, () => SHA512());
    } else {
      final hash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).$1 : digest;
      return _ecdsaSigningKey!.signConstDer(
        digest: hash,
        extraEntropy: extraEntropy,
      );
    }
  }

  /// Returns an XrpVerifier instance based on the available signing key type.
  XrpVerifier toVerifyKey() {
    final keyBytes =
        _ecdsaSigningKey?.privateKey.publicKey.toBytes() ??
        _signingKey!.publicKey.toBytes();
    return XrpVerifier.fromKeyBytes(
      keyBytes,
      _ecdsaSigningKey == null
          ? EllipticCurveTypes.ed25519
          : EllipticCurveTypes.secp256k1,
    );
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
  /// [keyBytes] The bytes representing the public key.
  /// [algorithm] The elliptic curve type of the public key.
  ///
  factory XrpVerifier.fromKeyBytes(
    List<int> keyBytes,
    EllipticCurveTypes algorithm,
  ) {
    switch (algorithm) {
      case EllipticCurveTypes.ed25519:
        final pub = Ed25519PublicKey.fromBytes(keyBytes);
        final verifyingKey = EDDSAPublicKey(
          CryptoSignerConst.generatorED25519,
          pub.compressed.sublist(1),
        );
        return XrpVerifier._(verifyingKey, null);
      case EllipticCurveTypes.secp256k1:
        final point = ProjectiveECCPoint.fromBytes(
          curve: CryptoSignerConst.generatorSecp256k1.curve,
          data: keyBytes,
          order: null,
        );
        final verifyingKey = ECDSAPublicKey(
          CryptoSignerConst.generatorSecp256k1,
          point,
        );
        return XrpVerifier._(null, ECDSAVerifyKey(verifyingKey));
      default:
        throw ArgumentException.invalidOperationArguments(
          "XrpVerifier",
          name: "algorithm",
          reason: "Unsupported key algorithm.",
        );
    }
  }

  /// Verifies the ECDSA signature for the provided digest.
  ///
  /// [digest] The digest used for verification.
  /// [derSignature] The DER-encoded ECDSA signature as a list of bytes.
  ///
  bool _verifyEcdsa(List<int> digest, List<int> derSignature) {
    final signature =
        Secp256k1EcdsaSignature.fromDer(derSignature).toEcdsaSignature();
    return _edsaVerifyKey!.verify(signature, digest);
  }

  /// Verifies the EDDSA signature for the provided digest.
  ///
  /// [digest] The digest used for verification.
  /// [signature] The EDDSA signature as a list of bytes.
  ///
  bool _verifyEddsa(List<int> digest, List<int> signature) {
    return _eddsaPublicKey!.verify(digest, signature, () => SHA512());
  }

  /// Verifies the signature for the provided digest using the available key and hashing option.
  ///
  /// [digest] The digest to be verified.
  /// [signature] The signature to be verified.
  /// [hashMessage] Whether to hash the message before verification, defaults to true.
  ///
  bool verify(
    List<int> digest,
    List<int> signature, {
    bool hashMessage = true,
  }) {
    if (_edsaVerifyKey != null) {
      final messagaeHash =
          hashMessage ? QuickCrypto.sha512HashHalves(digest).$1 : digest;
      return _verifyEcdsa(messagaeHash, signature);
    }
    return _verifyEddsa(digest, signature);
  }
}
