import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';

/// Shared Ed25519 signing logic: one `sign` producing a plain
/// [ED25519Signature] `SignedContent`.
///
/// `signToEd` binds one key family (single-key Ed25519, FROST-Ed25519
/// quorum, ...). FROST-Ed25519 threshold signatures are plain Ed25519
/// compatible (`R || z`, same equation), so both fit here — unlike
/// FROST-secp256k1 (Schnorr), which cannot back an ECDSA signer.
abstract class BaseED25519Signer<
  VK extends IVerifiyingKey,
  SK extends ISigningKey
>
    extends ISignatureSigner<VK, SK> {
  BaseED25519Signer(super.signingKey);

  /// Signs [digest] (signed as-is, no pre-hash), returning a plain
  /// Ed25519 signature.
  ED25519Signature signToEd(List<int> digest);

  /// Signs [digest] as-is, returning the signature content pair.
  SignedContent<ED25519Signature> sign(List<int> digest) {
    final signature = signToEd(digest);
    return SignedContent(
      signature: signature,
      content: digest,
      encoded: signature.toBytes(),
    );
  }
}

/// Signs digests with an Ed25519 private key.
class ED25519Signer
    extends BaseED25519Signer<IEd25519VerificationKey, IEd25519SigningKey> {
  ED25519Signer(super.signingKey);
  factory ED25519Signer.fromKeyBytes({
    required List<int> keyBytes,
    required CryptoKeyType type,
  }) {
    final signingKey = BaseEd25519PrivateKey.fromBytes(
      bytes: keyBytes,
      type: type,
    );
    return ED25519Signer(signingKey);
  }

  @override
  ED25519Signature signToEd(List<int> digest) {
    return signingKey.sign(Ed25519SigningParams(message: digest));
  }

  ED25519Verifier toVerifyKey() {
    return ED25519Verifier(signingKey.verificationKey());
  }

  @override
  ED25519Verifier toVerifier() {
    return ED25519Verifier(signingKey.verificationKey());
  }
}

/// Signer backed by a FROST(Ed25519) quorum: same plain-Ed25519 output
/// as [ED25519Signer] (`subset` defaults to the first `t` held shares,
/// `randomness` to fresh backend randomness — pass them explicitly for
/// deterministic tests or partial quorums).
class FrostEd25519Signer
    extends BaseED25519Signer<IEd25519VerificationKey, IFrostSigningKey> {
  final FrostEd25519PrivateKey frostKey;
  FrostEd25519Signer(this.frostKey) : super(frostKey);

  @override
  ED25519Signature signToEd(
    List<int> digest, {
    List<int>? subset,
    List<int>? randomness,
  }) {
    final sig = frostKey.sign(
      FrostSigningParams(
        message: digest,
        subset: subset,
        randomness: randomness,
      ),
    );
    return ED25519Signature.fromBytes(sig.toBytes());
  }

  @override
  SignedContent<ED25519Signature> sign(
    List<int> digest, {
    List<int>? subset,
    List<int>? randomness,
  }) {
    final signature = signToEd(
      digest,
      subset: subset,
      randomness: randomness,
    );
    return SignedContent(
      signature: signature,
      content: digest,
      encoded: signature.toBytes(),
    );
  }

  /// Verifier over the quorum group key (threshold signatures verify
  /// as plain Ed25519 against it).
  @override
  ED25519Verifier toVerifier() {
    return ED25519Verifier(frostKey.publicKey.aggKey);
  }
}

/// Verifies signatures made with an Ed25519 public key.
class ED25519Verifier extends ISignatureVerifier<IEd25519VerificationKey> {
  ED25519Verifier(super.verificationKey);

  factory ED25519Verifier.fromKeyBytes({
    required List<int> keyBytes,
    required CryptoKeyType type,
  }) {
    final verifyingKey = BaseEd25519PublicKey.fromBytes(
      bytes: keyBytes,
      type: type,
    );
    return ED25519Verifier(verifyingKey);
  }

  bool verify(List<int> digest, ED25519Signature signature) {
    return verificationKey.verify(
      Ed25519VerifyingParams(Ed25519SigningParams(message: digest), signature),
    );
  }
}
