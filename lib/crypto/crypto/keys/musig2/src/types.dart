import 'package:blockchain_utils/chain/signer/const/constants.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/constants/const.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Parameters for producing one participant's partial signature.
class MuSig2PartialSigningParams implements ISigningParams {
  final MuSig2Session session;
  final MuSig2Nonce nonce;
  MuSig2PartialSigningParams({required this.session, required this.nonce});
}

/// A single participant's partial signature, carrying along the pubnonce
/// that produced it (needed later for `partialSigVerify` / aggregation).
class MuSig2PartialSignature extends ISignature {
  final BuBytes signature;
  final BuBytes pubnonce;

  /// Signer public key, stored as bytes.
  final BuBytes publicKey;
  MuSig2PartialSignature({
    required List<int> signature,
    required List<int> pubnonce,
    required List<int> publicKey,
  }) : publicKey = publicKey.asImmutableBytes,
       signature =
           signature
               .exc(
                 length: MuSig2Constants.partialSignatureLength,
                 operation: "MuSig2PartialSignature",
                 reason: "Invalid signature bytes length.",
               )
               .asImmutableBytes,
       pubnonce = pubnonce.asImmutableBytes;

  @override
  BuBytes toBytes() => signature.cloneBytes();

  @override
  List<dynamic> get variables => [signature, pubnonce, publicKey];
}

class MuSig2Signature extends ISignature {
  final List<MuSig2PartialSignature> signatures;
  final List<MuSig2PartialSigningParams> sessions;
  final BuBytes aggSignature;
  MuSig2Signature({
    required List<MuSig2PartialSignature> signatures,
    required List<MuSig2PartialSigningParams> signingParams,
    required List<int> aggSignature,
  }) : signatures = signatures.immutable,
       sessions = signingParams.immutable,
       aggSignature =
           aggSignature
               .exc(
                 length: CryptoSignerConst.ecdsaSignatureLength,
                 operation: "MuSig2Signature",
                 reason: "Invalid agg signature bytes length.",
               )
               .asImmutableBytes;

  @override
  BuBytes toBytes() => aggSignature.cloneBytes();

  @override
  List<dynamic> get variables => [aggSignature];
}

/// Params to verify one participant's partial signature against a session
/// (mirrors the exact args your `sign()` already passes to `partialSigVerify`).
class MuSig2PartialVerifiyingParams implements IVerifiyingParams {
  final MuSig2PartialSignature signature;
  final MuSig2Session session;
  MuSig2PartialVerifiyingParams({
    required this.signature,
    required this.session,
  });
}

/// Parameters for verifying a final aggregated MuSig2 signature.
class MuSig2AggregateVerifiyingParams implements IVerifiyingParams {
  final BuBytes signature; // 64-byte final (R || s) signature
  final BuBytes message;
  final List<MuSig2Tweak> tweaks;

  MuSig2AggregateVerifiyingParams({
    required List<int> signature,
    required List<int> message,
    List<MuSig2Tweak> tweaks = const [],
  }) : signature =
           signature
               .exc(
                 length: CryptoSignerConst.ecdsaSignatureLength,
                 operation: "MuSig2AggregateVerifiyingParams",
                 reason: "Invalid signature bytes length.",
               )
               .asImmutableBytes,
       message = message.asImmutableBytes,
       tweaks = tweaks.immutable;
}

/// Inputs for generating a MuSig2 nonce pair.
class MuSig2GenerateNoncesParams with SecretState {
  final BuBytes? rand;
  final SecretBytes? sk;
  final BuBytes? aggPubKey;
  final BuBytes? msg;
  final BuBytes? extra;

  MuSig2GenerateNoncesParams({
    List<int>? rand,
    List<int>? sk,
    List<int>? aggPubKey,
    List<int>? msg,
    List<int>? extra,
  }) : rand = rand?.asImmutableBytes,
       sk = sk == null ? null : SecretBytes(sk),
       aggPubKey = aggPubKey?.asImmutableBytes,
       msg = msg?.asImmutableBytes,
       extra = extra?.asImmutableBytes;

  @override
  void dispose() {
    sk?.zero();
  }
}

/// Inputs for starting a MuSig2 signing session.
class MuSig2GenerateSessionParams implements ISigningParams {
  final MuSig2GenerateNoncesParams? nonceGenerationParams;
  final BuBytes message;
  final List<MuSig2Tweak> tweaks;

  MuSig2GenerateSessionParams({
    this.nonceGenerationParams,
    required List<int> message,
    List<MuSig2Tweak> tweaks = const [],
  }) : message = message.asImmutableBytes,
       tweaks = tweaks.immutable;
}
