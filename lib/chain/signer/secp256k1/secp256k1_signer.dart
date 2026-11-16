import 'package:blockchain_utils/chain/signer/core/core.dart';
import 'package:blockchain_utils/crypto/crypto/keys/keys.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/chain/signer/types/signature.dart';

/// Shared secp256k1 signing logic (SHA-256 digest, raw ECDSA encoding).
///
/// `signHash` signs an already-hashed 32-byte digest; subclasses bind
/// one key family (single-key secp256k1, DKLs23 quorum, ...). Shared
/// `sign` is implemented once here.
abstract class BaseSecp256k1Signer<
  VK extends IVerifiyingKey,
  SK extends ISigningKey
>
    extends ISignatureSigner<VK, SK> {
  const BaseSecp256k1Signer(super.signingKey);

  /// Signs a 32-byte message hash, returning the ECDSA signature.
  IECDSASignature signHash(List<int> hash, {List<int>? extraEntropy});

  /// Signs [message] (SHA-256 hashed unless [hashMessage] is false).
  SignedContent<IECDSASignature> sign(
    List<int> message, {
    bool hashMessage = true,
    List<int>? extraEntropy,
  }) {
    final digest = hashMessage ? QuickCrypto.sha256Hash(message) : message;
    final signature = signHash(digest, extraEntropy: extraEntropy);
    return SignedContent<IECDSASignature>(
      signature: signature,
      content: digest,
      encoded: signature.toBytes(),
    );
  }
}

/// Signs messages with a secp256k1 private key.
class Secp256k1Signer
    extends BaseSecp256k1Signer<ISecp256k1VerificationKey, ISecp256k1SigningKey> {
  const Secp256k1Signer(super.signingKey);
  factory Secp256k1Signer.fromBytes(List<int> keyBytes) {
    return Secp256k1Signer(Secp256k1PrivateKey.fromBytes(keyBytes));
  }

  @override
  IECDSASignature signHash(List<int> hash, {List<int>? extraEntropy}) {
    return signingKey.sign(
      Secp256k1SigningParams(digest: hash, extraEntropy: extraEntropy),
    );
  }

  @override
  Secp256k1Verifier toVerifier() {
    return Secp256k1Verifier(signingKey.verificationKey());
  }
}

/// Signer backed by a DKLs23(secp256k1) quorum: same digest / encoding
/// flow as [Secp256k1Signer] (`subset` defaults to the first `t` held
/// shares, `sid` / `seeds` to fresh randomness — pass them explicitly
/// for deterministic tests or partial quorums).
class Dkls23Secp256k1Signer
    extends BaseSecp256k1Signer<ISecp256k1VerificationKey, IDkls23SigningKey> {
  final Dkls23Secp256k1PrivateKey dklsKey;
  Dkls23Secp256k1Signer(this.dklsKey) : super(dklsKey);

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
    List<int> message, {
    bool hashMessage = true,
    List<int>? extraEntropy,
    List<int>? subset,
    List<int>? sid,
    List<int>? seeds,
  }) {
    final digest = hashMessage ? QuickCrypto.sha256Hash(message) : message;
    final signature = signHash(
      digest,
      extraEntropy: extraEntropy,
      subset: subset,
      sid: sid,
      seeds: seeds,
    );
    return SignedContent<IECDSASignature>(
      signature: signature,
      content: digest,
      encoded: signature.toBytes(),
    );
  }

  /// Verifier over the quorum group key (threshold signatures are
  /// standard ECDSA and verify as plain secp256k1).
  @override
  Secp256k1Verifier toVerifier() {
    return Secp256k1Verifier(
      Secp256k1PublicKey.fromBytes(dklsKey.publicKey.aggKey.toBytes()),
    );
  }
}

/// Verifies signatures made with a secp256k1 public key.
///
/// Unlike [ETHVerifier]/[TronVerifier] (default `hashMessage: true` with
/// their personal-message prefixes), [verify] defaults to
/// `hashMessage: false` and expects the raw digest.
class Secp256k1Verifier extends ISignatureVerifier<ISecp256k1VerificationKey> {
  Secp256k1Verifier(super.verificationKey);

  factory Secp256k1Verifier.fromKeyBytes(List<int> keyBytes) {
    return Secp256k1Verifier(Secp256k1PublicKey.fromBytes(keyBytes));
  }

  bool verify(
    List<int> message,
    IECDSASignature signature, {
    bool hashMessage = false,
  }) {
    final digest = hashMessage ? QuickCrypto.sha256Hash(message) : message;

    return verificationKey.verify(
      Secp256k1VerifyingParams(
        Secp256k1SigningParams(digest: digest),
        signature,
      ),
    );
  }
}
