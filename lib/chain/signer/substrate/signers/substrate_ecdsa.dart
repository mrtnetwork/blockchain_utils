import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/signer/secp256k1/secp256k1_signer.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class _SubstrateEcdsaSignerConstants {
  static const int vrfLength =
      CryptoSignerConst.ecdsaSignatureWithRecoveryIdLength +
      QuickCrypto.blake2b256DigestSize;
}

/// Signs Substrate transactions with a secp256k1 (ECDSA) key.
class SubstrateEcdsaSigner
    extends
        BaseSubstrateSigner<
          IECDSASignature,
          ISecp256k1VerificationKey,
          ISecp256k1SigningKey
        > {
  SubstrateEcdsaSigner(this.signer) : super(signer.signingKey);

  final Secp256k1Signer signer;

  factory SubstrateEcdsaSigner.fromKeyBytes(List<int> keyBytes) {
    return SubstrateEcdsaSigner(Secp256k1Signer.fromBytes(keyBytes));
  }

  @override
  SignedContent<IECDSASignature> sign(
    List<int> digest, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final hash = hashMessage ? QuickCrypto.blake2b256Hash(digest) : digest;
    final signature = signer.sign(
      hash,
      extraEntropy: extraEntropy,
      hashMessage: false,
    );
    return SignedContent(
      signature: signature.signature,
      content: signature.content,
      encoded: signature.signature.toBytes(
        encoding: ECDSASignatureEncoding.suffixRecoveryId,
      ),
    );
  }

  SignedContent<IECDSASignature> _vrfSign(
    List<int> message,
    SignedContent<IECDSASignature> signature, {
    List<int>? context,
    List<int>? extra,
  }) {
    final vrf = QuickCrypto.blake2b256Hash([
      ...context?.asBytes ?? [],
      ...extra?.asBytes ?? [],
      ...signature.encoded,
    ]);
    return SignedContent<IECDSASignature>(
      signature: signature.signature,
      content: message,
      encoded: BuBytes.concat([vrf, signature.encoded]),
    );
  }

  @override
  SignedContent<IECDSASignature> vrfSign(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
  }) {
    final msg = message.asImmutableBytes;
    final signature = sign(msg);
    return _vrfSign(msg, signature, context: context, extra: extra);
  }

  @override
  SubstrateEcdsaVerifier toVerifier() {
    return SubstrateEcdsaVerifier(signer.toVerifier());
  }
}

/// Verifies Substrate signatures made with a secp256k1 (ECDSA) key.
class SubstrateEcdsaVerifier
    extends BaseSubstrateVerifier<ISecp256k1VerificationKey> {
  final Secp256k1Verifier verifier;

  SubstrateEcdsaVerifier(this.verifier) : super(verifier.verificationKey);

  factory SubstrateEcdsaVerifier.fromKeyBytes(List<int> keyBytes) {
    final verificationKey = Secp256k1Verifier.fromKeyBytes(keyBytes);
    return SubstrateEcdsaVerifier(verificationKey);
  }

  /// Verifies a signature against a message digest.
  ///
  /// - [signature]: The signature bytes.
  /// - [hashMessage]: Whether to hash the message before verification (default is true).
  @override
  bool verify(
    List<int> message,
    List<int> signature, {
    bool hashMessage = true,
  }) {
    final digest = hashMessage ? QuickCrypto.blake2b256Hash(message) : message;
    return verifier.verify(
      digest,
      IECDSASignature.fromBytes(
        signature,
        encoding: ECDSASignatureEncoding.suffixRecoveryId,
      ),
      hashMessage: false,
    );
  }

  @override
  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  }) {
    if (vrfSign.length != _SubstrateEcdsaSignerConstants.vrfLength) {
      throw CoreErrors.invalidOperationArguments(
        "vrfVerify",
        name: "vrfSign",
        reason: "Invalid vrf signature bytes length.",
      );
    }
    final List<int> signature = vrfSign.sublist(
      QuickCrypto.blake2b256DigestSize,
    );
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
