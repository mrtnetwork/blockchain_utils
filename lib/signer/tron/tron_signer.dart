import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception/exception.dart';
import 'package:blockchain_utils/signer/const/constants.dart';
import 'package:blockchain_utils/signer/signing_key/ecdsa_signing_key.dart';
import 'package:blockchain_utils/signer/types/eth_signature.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Tron Signer class for cryptographic operations, including signing and verification.
class TronSigner {
  const TronSigner._(this._ecdsaSigningKey);

  final Secp256k1SigningKey _ecdsaSigningKey;

  /// Factory method to create a TronSigner from a byte representation of a private key.
  factory TronSigner.fromKeyBytes(List<int> keyBytes) {
    return TronSigner._(Secp256k1SigningKey.fromBytes(keyBytes: keyBytes));
  }

  /// Signs a message digest using the ECDSA algorithm on the secp256k1 curve.
  ///
  /// Parameters:
  /// - [digest]: The message digest to be signed.
  /// - [hashMessage]: Whether to hash the message before signing (default is true).
  ///
  /// Throws:
  /// - [ArgumentException] if the digest length is invalid.
  List<int> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    final signature = _ecdsaSigningKey.sign(
      digest: hash,
      extraEntropy: extraEntropy,
    );
    return [
      ...signature.$1.toBytes(CryptoSignerConst.digestLength),
      signature.$2 + 27,
    ];
  }

  List<int> signConst(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    final signature = _ecdsaSigningKey.signConst(
      digest: hash,
      extraEntropy: extraEntropy,
    );

    return [
      ...signature.$1.toBytes(CryptoSignerConst.digestLength),
      signature.$2 + 27,
    ];
  }

  /// Signs a personal message digest with an optional payload length.
  ///
  /// Parameters:
  /// - [digest]: The personal message digest to be signed.
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  /// - [useEthPrefix]: Whether to use the Ethereum or Tron personal sign prefix (default is false).
  ///
  List<int> signProsonalMessage(
    List<int> digest, {
    int? payloadLength,
    bool useEthPrefix = false,
    List<int>? extraEntropy,
  }) {
    String prefix =
        useEthPrefix
            ? CryptoSignerConst.ethPersonalSignPrefix
            : CryptoSignerConst.tronSignMessagePrefix;
    prefix = prefix + (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    return sign(
      QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...digest]),
      hashMessage: false,
      extraEntropy: extraEntropy,
    );
  }

  List<int> signProsonalMessageConst(
    List<int> digest, {
    int? payloadLength,
    bool useEthPrefix = false,
    List<int>? extraEntropy,
  }) {
    String prefix =
        useEthPrefix
            ? CryptoSignerConst.ethPersonalSignPrefix
            : CryptoSignerConst.tronSignMessagePrefix;
    prefix = prefix + (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(prefix, type: StringEncoding.ascii);
    return signConst(
      QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...digest]),
      hashMessage: false,
      extraEntropy: extraEntropy,
    );
  }

  /// Converts the TronSigner to a TronVerifier for verification purposes.
  TronVerifier toVerifyKey() {
    return TronVerifier.fromKeyBytes(
      _ecdsaSigningKey.privateKey.publicKey.toBytes(),
    );
  }
}

/// Tron Verifier class for cryptographic operations, including signature verification.
class TronVerifier {
  final ECDSAVerifyKey edsaVerifyKey;

  TronVerifier._(this.edsaVerifyKey);

  /// Factory method to create a TronVerifier from a byte representation of a public key.
  factory TronVerifier.fromKeyBytes(List<int> keyBytes) {
    final point = ProjectiveECCPoint.fromBytes(
      curve: CryptoSignerConst.generatorSecp256k1.curve,
      data: keyBytes,
      order: null,
    );
    final verifyingKey = ECDSAPublicKey(
      CryptoSignerConst.generatorSecp256k1,
      point,
    );
    return TronVerifier._(ECDSAVerifyKey(verifyingKey));
  }
  bool _verifyEcdsa(List<int> digest, List<int> sigBytes) {
    final signature = ECDSASignature.fromBytes(
      sigBytes,
      CryptoSignerConst.generatorSecp256k1,
    );
    return edsaVerifyKey.verify(signature, digest);
  }

  /// Verifies a Tron signature against a message digest.
  ///
  /// Parameters:
  /// - [message]: The message digest.
  /// - [signature]: The signature bytes.
  ///
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
  bool verifyPersonalMessage(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    int? payloadLength,
    useEthPrefix = false,
  }) {
    if (hashMessage) {
      String prefix =
          useEthPrefix
              ? CryptoSignerConst.ethPersonalSignPrefix
              : CryptoSignerConst.tronSignMessagePrefix;
      prefix =
          prefix + (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes = StringUtils.encode(
        prefix,
        type: StringEncoding.ascii,
      );
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
  static ECDSAPublicKey getPublicKey(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    int? payloadLength,
    bool useEthPrefix = false,
  }) {
    if (hashMessage) {
      String prefix =
          useEthPrefix
              ? CryptoSignerConst.ethPersonalSignPrefix
              : CryptoSignerConst.tronSignMessagePrefix;
      prefix =
          prefix + (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes = StringUtils.encode(
        prefix,
        type: StringEncoding.ascii,
      );
      message = QuickCrypto.keccack256Hash(<int>[...prefixBytes, ...message]);
    }

    final ethSignature = ETHSignature.fromBytes(signature);
    final toBytes = ethSignature.toBytes(false);
    final recoverId = toBytes[CryptoSignerConst.ecdsaSignatureLength];
    final signatureBytes = ECDSASignature.fromBytes(
      toBytes.sublist(0, CryptoSignerConst.ecdsaSignatureLength),
      CryptoSignerConst.generatorSecp256k1,
    );

    return signatureBytes.recoverPublicKey(
      message,
      CryptoSignerConst.generatorSecp256k1,
      recoverId,
    );
  }
}
