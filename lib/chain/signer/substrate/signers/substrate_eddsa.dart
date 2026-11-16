import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:blockchain_utils/helper/helper.dart';
import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/chain/signer/ed25519/ed25519.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/chain/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';
import 'package:blockchain_utils/utils/binary/src/utils.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

class _SubstrateED25519SignerConstants {
  static const int vrfLength =
      CryptoSignerConst.ed25519SignatureLength +
      QuickCrypto.blake2b256DigestSize;
}

/// Signs Substrate transactions with an Ed25519 key.
class SubstrateED25519Signer
    extends
        BaseSubstrateSigner<
          ED25519Signature,
          IEd25519VerificationKey,
          IEd25519SigningKey
        > {
  /// Constructs a [SubstrateED25519Signer] with the provided signing key.
  SubstrateED25519Signer(this.signer) : super(signer.signingKey);

  /// The Ed25519 private key used for signing.
  final ED25519Signer signer;

  /// Creates a [SubstrateED25519Signer] from raw private key bytes.
  factory SubstrateED25519Signer.fromKeyBytes(List<int> keyBytes) {
    return SubstrateED25519Signer(
      ED25519Signer.fromKeyBytes(
        keyBytes: keyBytes,
        type: CryptoKeyType.ed25519,
      ),
    );
  }

  @override
  SignedContent<ED25519Signature> sign(List<int> digest) {
    return signer.sign(digest);
  }

  SignedContent<ED25519Signature> _vrfSign(
    List<int> message,
    SignedContent<ED25519Signature> signature, {
    List<int>? context,
    List<int>? extra,
  }) {
    final vrf = QuickCrypto.blake2b256Hash([
      ...context?.asBytes ?? [],
      ...extra?.asBytes ?? [],
      ...signature.encoded,
    ]);
    return SignedContent<ED25519Signature>(
      signature: signature.signature,
      content: message,
      encoded: BuBytes.concat([vrf, signature.encoded]),
    );
  }

  @override
  SignedContent<ED25519Signature> vrfSign(
    List<int> message, {
    List<int>? context,
    List<int>? extra,
  }) {
    final msg = message.asImmutableBytes;
    final signature = signer.sign(msg);
    return _vrfSign(msg, signature, extra: extra, context: context);
  }

  @override
  SubstrateED25519Verifier toVerifier() {
    return SubstrateED25519Verifier(signer.toVerifyKey());
  }
}

/// Verifies Substrate signatures made with an Ed25519 key.
class SubstrateED25519Verifier
    extends BaseSubstrateVerifier<IEd25519VerificationKey> {
  final ED25519Verifier verifier;

  /// Constructs a [SubstrateED25519Verifier] from an [ED25519Verifier].
  SubstrateED25519Verifier(this.verifier) : super(verifier.verificationKey);

  /// Creates a [SubstrateED25519Verifier] from raw public key bytes.
  factory SubstrateED25519Verifier.fromKeyBytes(List<int> keyBytes) {
    final verifier = ED25519Verifier.fromKeyBytes(
      keyBytes: keyBytes,
      type: CryptoKeyType.ed25519,
    );
    return SubstrateED25519Verifier(verifier);
  }

  /// Verifies the signature for the provided digest using the available key.
  ///
  /// [message] The digest to be verified.
  /// [signature] The signature to be verified.
  @override
  bool verify(List<int> message, List<int> signature) {
    return verifier.verify(message, ED25519Signature.fromBytes(signature));
  }

  @override
  bool vrfVerify(
    List<int> message,
    List<int> vrfSign, {
    List<int>? context,
    List<int>? extra,
  }) {
    if (vrfSign.length != _SubstrateED25519SignerConstants.vrfLength) {
      throw CoreErrors.invalidOperationArguments(
        "vrfVerify",
        name: "vrfSign",
        reason: "Invalid vrf signature bytes length.",
      );
    }
    final List<int> signature = vrfSign.sublist(
      QuickCrypto.blake2b256DigestSize,
    );
    final verifySignature = verifier.verify(
      message,
      ED25519Signature.fromBytes(signature),
    );

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
