import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/chain/signer/secp256k1/secp256k1_signer.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/utils/string/string.dart';

/// Tron signer: signs raw digests and Tron/Ethereum-prefixed personal messages.
class TronSigner
    extends ISignatureSigner<ISecp256k1VerificationKey, ISecp256k1SigningKey> {
  final Secp256k1Signer signer;
  TronSigner(this.signer) : super(signer.signingKey);
  factory TronSigner.fromBytes(List<int> bytes) =>
      TronSigner(Secp256k1Signer.fromBytes(bytes));

  SignedContent<IECDSASignature> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    final signature = signer.sign(
      hash,
      extraEntropy: extraEntropy,
      hashMessage: false,
    );
    return SignedContent<IECDSASignature>(
      content: hash,
      signature: signature.signature,
      encoded: signature.signature.toBytes(
        encoding: ECDSASignatureEncoding.ethereumLegacy,
      ),
    );
  }

  /// Hashes [digest] with the Tron (or, if [useEthPrefix], Ethereum) personal
  /// message prefix.
  static BuBytes createPersonalMessageDigest({
    required bool useEthPrefix,
    required List<int> digest,
    int? payloadLength,
  }) {
    String prefix =
        useEthPrefix
            ? CryptoSignerConst.ethPersonalSignPrefix
            : CryptoSignerConst.tronSignMessagePrefix;
    prefix = prefix + (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(
      prefix,
      encoding: StringEncoding.ascii,
    );
    return QuickCrypto.keccak256Hash(<int>[...prefixBytes, ...digest]);
  }

  /// Signs [digest] as a personal message (see [createPersonalMessageDigest]).
  SignedContent<IECDSASignature> signPersonalMessage(
    List<int> digest, {
    int? payloadLength,
    List<int>? extraEntropy,
    bool useEthPrefix = false,
  }) {
    digest = createPersonalMessageDigest(
      useEthPrefix: useEthPrefix,
      digest: digest,
      payloadLength: payloadLength,
    );
    return sign(digest, extraEntropy: extraEntropy, hashMessage: false);
  }

  @override
  TronVerifier toVerifier() {
    return TronVerifier(signer.toVerifier());
  }
}

/// Verifies Tron ECDSA signatures, including personal messages.
class TronVerifier extends ISignatureVerifier<ISecp256k1VerificationKey> {
  final Secp256k1Verifier verifier;

  TronVerifier(this.verifier) : super(verifier.verificationKey);

  bool verify(
    List<int> digest,
    List<int> signature, {
    bool hashMessage = true,
  }) {
    final hashDigest = hashMessage ? QuickCrypto.sha256Hash(digest) : digest;
    return verifier.verify(
      hashDigest,
      IECDSASignature.fromBytes(
        signature,
        encoding: ECDSASignatureEncoding.ethereumLegacy,
      ),
      hashMessage: false,
    );
  }

  bool verifyPersonalMessage(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    int? payloadLength,
    bool useEthPrefix = false,
  }) {
    final List<int> messageHash = _hashMessage(
      message,
      hashMessage: hashMessage,
      payloadLength: payloadLength,
      useEthPrefix: useEthPrefix,
    );
    return verify(messageHash, signature, hashMessage: false);
  }

  static List<int> _hashMessage(
    List<int> digest, {
    bool hashMessage = true,
    bool useEthPrefix = false,
    int? payloadLength,
  }) {
    if (hashMessage) {
      return TronSigner.createPersonalMessageDigest(
        useEthPrefix: useEthPrefix,
        digest: digest,
        payloadLength: payloadLength,
      );
    }
    return digest;
  }

  /// Gets the recovered ECDSAPublicKey from a message and signature.
  ///
  /// - [message]: The message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before recovering the public key (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  static Secp256k1PublicKey getPublicKey(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    bool useEthPrefix = false,
    int? payloadLength,
  }) {
    final List<int> messageHash = _hashMessage(
      message,
      hashMessage: hashMessage,
      payloadLength: payloadLength,
      useEthPrefix: useEthPrefix,
    );
    final point = Secp256k1EcdsaUtils.recoverPublicKey(
      hash: messageHash,
      signature: IECDSASignature.fromBytes(
        signature,
        encoding: ECDSASignatureEncoding.ethereumLegacy,
      ),
    );
    return Secp256k1PublicKey.fromBytes(point.toBytes());
  }
}
