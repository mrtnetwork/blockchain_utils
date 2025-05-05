import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/exception/signing_exception.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Tron Signer class for cryptographic operations, including signing and verification.
///
/// The `TronSigner` class facilitates the creation of Tron signatures and
/// provides methods for signing messages, personal messages, and converting to
/// verification keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class TronSigner {
  const TronSigner._(this._ecdsaSigningKey);

  final Secp256k1SigningKey _ecdsaSigningKey;

  /// Factory method to create a TronSigner from a byte representation of a private key.
  factory TronSigner.fromKeyBytes(List<int> keyBytes) {
    return TronSigner._(Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
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
  //     final recover = ecdsaSign.recoverPublicKeys(
  //         hash, CryptoSignerConst.generatorSecp256k1);
  //     for (int i = 0; i < recover.length; i++) {
  //       if (recover[i].point == verifyKey.edsaVerifyKey.publicKey.point) {
  //         return [...ecdsaSign.toBytes(CryptoSignerConst.digestLength), i + 27];
  //       }
  //     }
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
  //     final recover = ecdsaSign.recoverPublicKeys(
  //         hash, CryptoSignerConst.generatorSecp256k1);
  //     for (int i = 0; i < recover.length; i++) {
  //       if (recover[i].point == verifyKey.edsaVerifyKey.publicKey.point) {
  //         return [...ecdsaSign.toBytes(CryptoSignerConst.digestLength), i + 27];
  //       }
  //     }
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
    final signature =
        _ecdsaSigningKey.sign(digest: hash, extraEntropy: extraEntropy);
    return [
      ...signature.item1.toBytes(CryptoSignerConst.digestLength),
      signature.item2 + 27
    ];
  }

  List<int> signConst(List<int> digest,
      {bool hashMessage = true, List<int>? extraEntropy}) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    final signature =
        _ecdsaSigningKey.signConst(digest: hash, extraEntropy: extraEntropy);

    return [
      ...signature.item1.toBytes(CryptoSignerConst.digestLength),
      signature.item2 + 27
    ];
  }

  /// Signs a personal message digest with an optional payload length.
  ///
  /// The Tron personal sign prefix is applied to the message, and the resulting
  /// signature is returned as a byte list. Optionally, a payload length can be provided.
  ///
  /// Parameters:
  /// - [digest]: The personal message digest to be signed.
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  /// - [useEthPrefix]: Whether to use the Ethereum or Tron personal sign prefix (default is false).
  ///
  /// Returns:
  /// - A byte list representing the signature of the personal message.
  List<int> signProsonalMessage(List<int> digest,
      {int? payloadLength,
      bool useEthPrefix = false,
      List<int>? extraEntropy}) {
    String prefix = useEthPrefix
        ? CryptoSignerConst.ethPersonalSignPrefix
        : CryptoSignerConst.tronSignMessagePrefix;
    prefix = prefix + (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    return sign(QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...digest]),
        hashMessage: false, extraEntropy: extraEntropy);
  }

  List<int> signProsonalMessageConst(List<int> digest,
      {int? payloadLength,
      bool useEthPrefix = false,
      List<int>? extraEntropy}) {
    String prefix = useEthPrefix
        ? CryptoSignerConst.ethPersonalSignPrefix
        : CryptoSignerConst.tronSignMessagePrefix;
    prefix = prefix + (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    return signConst(
        QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...digest]),
        hashMessage: false,
        extraEntropy: extraEntropy);
  }

  /// Converts the TronSigner to a TronVerifier for verification purposes.
  ///
  /// Returns:
  /// - A TronVerifier representing the verification key.
  TronVerifier toVerifyKey() {
    return TronVerifier.fromKeyBytes(
        _ecdsaSigningKey.privateKey.publicKey.toBytes());
  }
}

/// Tron Verifier class for cryptographic operations, including signature verification.
///
/// The `TronVerifier` class allows the verification of Tron signatures and
/// public keys. It uses the ECDSA (Elliptic Curve Digital Signature Algorithm)
/// for cryptographic operations on the secp256k1 elliptic curve.
class TronVerifier {
  final ECDSAVerifyKey edsaVerifyKey;

  TronVerifier._(this.edsaVerifyKey);

  /// Factory method to create a TronVerifier from a byte representation of a public key.
  factory TronVerifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
        curve: CryptoSignerConst.generatorSecp256k1.curve,
        data: keyBytes,
        order: null);
    final verifyingKey =
        ECDSAPublicKey(CryptoSignerConst.generatorSecp256k1, point);
    return TronVerifier._(ECDSAVerifyKey(verifyingKey));
  }
  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature = ECDSASignature.fromBytes(
        sigBytes, CryptoSignerConst.generatorSecp256k1);
    return edsaVerifyKey.verify(signature, digest);
  }

  /// Verifies a Tron signature against a message digest.
  ///
  /// Parameters:
  /// - [message]: The message digest.
  /// - [signature]: The signature bytes.
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verify(List<int> message, List<int> signature) {
    return _verifyEcdsa(message, signature);
  }

  /// Verifies a Tron signature of a personal message against the message digest.
  ///
  /// Parameters:
  /// - [message]: The personal message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  /// - [useEthPrefix]: Whether to use the Ethereum or Tron personal sign prefix (default is false).
  ///
  /// Returns:
  /// - True if the signature is valid, false otherwise.
  bool verifyPersonalMessage(List<int> message, List<int> signature,
      {bool hashMessage = true, int? payloadLength, useEthPrefix = false}) {
    if (hashMessage) {
      String prefix = useEthPrefix
          ? CryptoSignerConst.ethPersonalSignPrefix
          : CryptoSignerConst.tronSignMessagePrefix;
      prefix =
          prefix + (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes =
          StringUtils.encode(prefix, type: StringEncoding.ascii);
      message = QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...message]);
    }
    if (signature.length > CryptoSignerConst.ecdsaSignatureLength) {
      signature = signature.sublist(0, CryptoSignerConst.ecdsaSignatureLength);
    }
    return _verifyEcdsa(message, signature);
  }

  /// Gets the recovered ECDSAPublicKey from a message and signature.
  ///
  /// Parameters:
  /// - [message]: The message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before recovering the public key (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  /// - [useEthPrefix]: Whether to use the Ethereum or Tron personal sign prefix (default is false).
  ///
  /// Returns:
  /// - The recovered ECDSAPublicKey.
  static ECDSAPublicKey getPublicKey(List<int> message, List<int> signature,
      {bool hashMessage = true,
      int? payloadLength,
      bool useEthPrefix = false}) {
    if (hashMessage) {
      String prefix = useEthPrefix
          ? CryptoSignerConst.ethPersonalSignPrefix
          : CryptoSignerConst.tronSignMessagePrefix;
      prefix =
          prefix + (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes =
          StringUtils.encode(prefix, type: StringEncoding.ascii);
      message = QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...message]);
    }

    final ethSignature = ETHSignature.fromBytes(signature);
    final toBytes = ethSignature.toBytes(false);
    final recoverId = toBytes[CryptoSignerConst.ecdsaSignatureLength];
    final signatureBytes = ECDSASignature.fromBytes(
        toBytes.sublist(0, CryptoSignerConst.ecdsaSignatureLength),
        CryptoSignerConst.generatorSecp256k1);

    return signatureBytes.recoverPublicKey(
        message, CryptoSignerConst.generatorSecp256k1, recoverId);
  }
}
