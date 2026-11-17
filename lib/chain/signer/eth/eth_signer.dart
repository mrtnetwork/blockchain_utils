import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/crypto/keys/utils/ecdsa.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/chain/signer/secp256k1/secp256k1_signer.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';
import 'package:blockchain_utils/utils/string/string.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Shared Ethereum signing logic (keccak digest, EIP-191 personal
/// messages, `ethereumLegacy` encoding).
///
/// `signHash` signs an already-hashed 32-byte digest; subclasses bind
/// one key family (single-key secp256k1, DKLs23 quorum, ...). Shared
/// `sign` / `signPersonalMessage` are implemented once here.
abstract class BaseETHSigner<VK extends IVerifiyingKey, SK extends ISigningKey>
    extends ISignatureSigner<VK, SK> {
  const BaseETHSigner(super.signingKey);

  /// Signs a 32-byte message hash, returning the ECDSA signature.
  IECDSASignature signHash(List<int> hash, {List<int>? extraEntropy});

  /// Signs [digest] as an Ethereum transaction hash.
  SignedContent<IECDSASignature> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.keccak256Hash(digest) : digest;
    final signature = signHash(hash, extraEntropy: extraEntropy);
    return SignedContent(
      signature: signature,
      content: hash,
      encoded: signature.toBytes(
        encoding: ECDSASignatureEncoding.ethereumLegacy,
      ),
    );
  }

  /// Signs [digest] as an EIP-191 personal message (adds the
  /// `"\x19Ethereum Signed Message:\n<length>"` prefix before signing).
  SignedContent<IECDSASignature> signPersonalMessage(
    List<int> digest, {
    int? payloadLength,
    List<int>? extraEntropy,
  }) {
    final prefix =
        CryptoSignerConst.ethPersonalSignPrefix +
        (payloadLength?.toString() ?? digest.length.toString());
    final prefixBytes = StringUtils.encode(
      prefix,
      encoding: StringEncoding.ascii,
    );
    return sign([...prefixBytes, ...digest], extraEntropy: extraEntropy);
  }
}

/// Ethereum signer: signs raw digests and EIP-191 personal messages.
class ETHSigner
    extends BaseETHSigner<ISecp256k1VerificationKey, ISecp256k1SigningKey> {
  final Secp256k1Signer signer;
  ETHSigner(this.signer) : super(signer.signingKey);
  factory ETHSigner.fromSigningKey(ISecp256k1SigningKey key) {
    return ETHSigner(Secp256k1Signer(key));
  }
  factory ETHSigner.fromBytes(List<int> bytes) =>
      ETHSigner(Secp256k1Signer.fromBytes(bytes));

  @override
  IECDSASignature signHash(List<int> hash, {List<int>? extraEntropy}) {
    return signer
        .sign(hash, extraEntropy: extraEntropy, hashMessage: false)
        .signature;
  }

  /// Converts the ETHSigner to an ETHVerifier for verification purposes.
  @override
  ETHVerifier toVerifier() {
    return ETHVerifier(signer.toVerifier());
  }
}

/// Ethereum signer backed by a DKLs23(secp256k1) quorum: same digest /
/// personal-message / encoding flow as [ETHSigner], threshold signing
/// underneath (`subset` defaults to the first `t` held shares, `sid` /
/// `seeds` to fresh randomness — pass them explicitly for
/// deterministic tests or partial quorums).
class Dkls23ETHSigner
    extends BaseETHSigner<ISecp256k1VerificationKey, IDkls23SigningKey> {
  final Dkls23Secp256k1PrivateKey dklsKey;
  Dkls23ETHSigner(this.dklsKey) : super(dklsKey);

  /// Signs an already-hashed digest with the quorum (defaults mirror
  /// single-key UX; [subset]/[sid]/[seeds] expose the threshold path).
  @override
  IECDSASignature signHash(
    List<int> hash, {
    List<int>? extraEntropy,
    List<int>? subset,
    List<int>? sid,
    List<int>? seeds,
  }) {
    return dklsKey.sign(
      Dkls23SignParams(
        msgHash: hash,
        subset: subset,
        sid: sid,
        seeds: seeds ?? extraEntropy,
      ),
    );
  }

  @override
  SignedContent<IECDSASignature> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
    List<int>? subset,
    List<int>? sid,
    List<int>? seeds,
  }) {
    final hash = hashMessage ? QuickCrypto.keccak256Hash(digest) : digest;
    final signature = signHash(
      hash,
      extraEntropy: extraEntropy,
      subset: subset,
      sid: sid,
      seeds: seeds,
    );
    return SignedContent(
      signature: signature,
      content: hash,
      encoded: signature.toBytes(
        encoding: ECDSASignatureEncoding.ethereumLegacy,
      ),
    );
  }

  /// Verifier over the quorum group key (threshold signatures are
  /// standard ECDSA and verify as plain secp256k1).
  @override
  ETHVerifier toVerifier() {
    return ETHVerifier(
      Secp256k1Verifier(
        Secp256k1PublicKey.fromBytes(dklsKey.publicKey.aggKey.toBytes()),
      ),
    );
  }
}

/// Verifies Ethereum ECDSA signatures, including EIP-191 personal messages.
class ETHVerifier extends ISignatureVerifier<ISecp256k1VerificationKey> {
  final Secp256k1Verifier verifyKey;

  ETHVerifier(this.verifyKey) : super(verifyKey.verificationKey);

  /// Verifies an Ethereum signature against a message digest.
  ///
  /// - [digest]: The message digest.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  bool verify(
    List<int> digest,
    List<int> signature, {
    bool hashMessage = true,
  }) {
    if (signature.length != CryptoSignerConst.ecdsaSignatureLength &&
        signature.length !=
            CryptoSignerConst.ecdsaSignatureWithRecoveryIdLength) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid signature bytes length.",
      );
    }
    final hashDigest = hashMessage ? QuickCrypto.keccak256Hash(digest) : digest;
    return verifyKey.verify(
      hashDigest,
      IECDSASignature.fromBytes(
        signature,
        encoding:
            signature.length == CryptoSignerConst.ecdsaSignatureLength
                ? ECDSASignatureEncoding.raw
                : ECDSASignatureEncoding.ethereumLegacy,
      ),
      hashMessage: false,
    );
  }

  /// Verifies an Ethereum signature of a personal message against the message digest.
  ///
  /// - [message]: The personal message.
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  bool verifyPersonalMessage(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    int? payloadLength,
  }) {
    final List<int> messageHash = _hashMessage(
      message,
      hashMessage: hashMessage,
      payloadLength: payloadLength,
    );
    return verify(messageHash, signature, hashMessage: false);
  }

  static List<int> _hashMessage(
    List<int> message, {
    bool hashMessage = true,
    int? payloadLength,
  }) {
    if (hashMessage) {
      final prefix =
          CryptoSignerConst.ethPersonalSignPrefix +
          (payloadLength?.toString() ?? message.length.toString());
      final prefixBytes = StringUtils.encode(
        prefix,
        encoding: StringEncoding.ascii,
      );
      return QuickCrypto.keccak256Hash(<int>[...prefixBytes, ...message]);
    }
    return message;
  }

  /// Gets the recovered ECDSAPublicKey from a message and signature.
  ///
  /// - [message]: The message.
  /// - [signature]: The 65-byte signature bytes (raw `r || s || v`).
  /// - [hashMessage]: Whether to hash the message before recovering the public key (default is true).
  /// - [payloadLength]: An optional payload length to include in the message prefix.
  static Secp256k1PublicKey getPublicKey(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
    int? payloadLength,
  }) {
    final List<int> messageHash = _hashMessage(
      message,
      hashMessage: hashMessage,
      payloadLength: payloadLength,
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
