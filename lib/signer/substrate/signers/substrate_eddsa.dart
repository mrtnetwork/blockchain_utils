import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/exception/exception.dart';
import 'package:blockchain_utils/signer/solana/solana_signer.dart';
import 'package:blockchain_utils/signer/substrate/core/signer.dart';
import 'package:blockchain_utils/signer/substrate/core/verifier.dart';
import 'package:blockchain_utils/utils/utils.dart';

class _SubstrateED25519SignerConstant {
  static final int vrfLength =
      SolanaSignerConst.signatureLen + QuickCrypto.blake2b256DigestSize;
}

/// Class for signing Substrate transactions using either EDDSA algorithm.
class SubstrateED25519Signer implements BaseSubstrateSigner {
  /// Constructs a new SubstrateED25519Signer instance with the provided signing keys.
  const SubstrateED25519Signer._(this._signer);

  /// The EDDSA private key for signing.
  final SolanaSigner _signer;

  /// Factory method to create an SubstrateED25519Signer instance from key bytes.
  factory SubstrateED25519Signer.fromKeyBytes(List<int> keyBytes) {
    return SubstrateED25519Signer._(SolanaSigner.fromKeyBytes(keyBytes));
  }

  /// Returns an SubstrateED25519Signer instance based on the available signing key type.
  ///
  /// This method constructs and returns an SubstrateED25519Verifier instance for signature verification.
  ///
  /// returns An SubstrateED25519Verifier instance based on the available signing key type.
  SubstrateED25519Verifier toVerifyKey() {
    final keyBytes = _signer.toVerifyKey();
    return SubstrateED25519Verifier._(keyBytes);
  }

  @override
  List<int> sign(List<int> digest) {
    return _signer.sign(digest);
  }

  @override
  List<int> vrfSign(List<int> message, {List<int>? context, List<int>? extra}) {
    final msg = BytesUtils.toBytes(message, unmodifiable: true);
    final signature = _signer.sign(message);
    final vrf = QuickCrypto.blake2b256Hash([
      ...BytesUtils.tryToBytes(context) ?? [],
      ...BytesUtils.tryToBytes(extra) ?? [],
      ...signature,
    ]);
    final List<int> vrfResult = [...vrf, ...signature];
    final verify = toVerifyKey()
        .vrfVerify(List.from(vrfResult), msg, context: context, extra: extra);
    if (!verify) {
      throw const MessageException(
          'The created signature does not pass verification.');
    }
    return vrfResult;
  }
}

/// Class representing an Substrate ED25519 Verifier for signature verification.
class SubstrateED25519Verifier implements BaseSubstrateVerifier {
  final SolanaVerifier _verifier;

  /// Private constructor to create an SolanaVerifier instance.
  SubstrateED25519Verifier._(this._verifier);

  /// Factory method to create an SolanaVerifier instance from key bytes.
  factory SubstrateED25519Verifier.fromKeyBytes(List<int> keyBytes) {
    final verifier = SolanaVerifier.fromKeyBytes(keyBytes);
    return SubstrateED25519Verifier._(verifier);
  }

  /// Verifies the signature for the provided digest using the available key.
  ///
  /// This method verifies the signature of the provided digest using either EDDSA algorithms,
  ///
  /// [message] The digest to be verified.
  /// [signature] The signature to be verified.
  @override
  bool verify(List<int> message, List<int> signature) {
    return _verifier.verify(message, signature);
  }

  @override
  bool vrfVerify(List<int> message, List<int> vrfSign,
      {List<int>? context, List<int>? extra}) {
    if (vrfSign.length != _SubstrateED25519SignerConstant.vrfLength) {
      throw ArgumentException(
          "Invalid vrf length. excepted: ${_SubstrateED25519SignerConstant.vrfLength} got: ${vrfSign.length}");
    }
    final List<int> signature =
        vrfSign.sublist(QuickCrypto.blake2b256DigestSize);
    final verifySignature = _verifier.verify(message, signature);

    if (verifySignature) {
      final vrfHash = vrfSign.sublist(0, QuickCrypto.blake2b256DigestSize);
      final vrf = QuickCrypto.blake2b256Hash([
        ...BytesUtils.tryToBytes(context) ?? [],
        ...BytesUtils.tryToBytes(extra) ?? [],
        ...signature,
      ]);
      return BytesUtils.bytesEqual(vrf, vrfHash);
    }
    return false;
  }
}
