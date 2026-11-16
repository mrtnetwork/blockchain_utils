import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/musig2/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/weierstrass.dart';
import 'package:blockchain_utils/crypto/crypto/keys/secp256k1/src/secp256k1.dart';
import 'package:blockchain_utils/crypto/crypto/keys/musig2/src/types.dart';

/// Common interface for a MuSig2 co-signer holding one or more of the
/// group's private keys.
abstract class IMuSig2SigningKey<P extends IMuSig2VerificationKey>
    implements ISigningKey<MuSig2Signature, MuSig2GenerateSessionParams, P> {
  List<Secp256k1PrivateKey> get secretKeys;

  List<MuSig2Nonce> generateNonces(MuSig2GenerateNoncesParams params) =>
      verificationKey().generateNonces(params);

  List<MuSig2PartialSigningParams> generateSession(
    MuSig2GenerateSessionParams params,
  ) => verificationKey().generateSession(params);

  MuSig2PartialSignature partialSign(MuSig2PartialSigningParams params) {
    final sk = secretKeys.firstWhere(
      (e) => e.publicKey.keyBytes == params.nonce.publicKey,
      orElse:
          () =>
              throw CoreErrors.cryptoFailed(
                "IMuSig2SigningKey.partialSign",
                reason: "Missing nonce signer.",
              ),
    );
    final sigBytes = sk.takeSecretKey().useValue(
      (k) => blockchainUtils.api.muSig2.sign(
        secnonce: params.nonce.secnonce,
        sk: k,
        session: params.session,
      ),
    );
    return MuSig2PartialSignature(
      signature: sigBytes,
      pubnonce: params.nonce.pubnonce,
      publicKey: params.nonce.publicKey,
    );
  }

  @override
  MuSig2Signature sign(MuSig2GenerateSessionParams params) {
    final sessions = generateSession(params);
    final List<MuSig2PartialSignature> signatures = [];
    for (final i in sessions) {
      final sign = partialSign(i);
      signatures.add(sign);
    }
    return MuSig2Signature(
      signingParams: sessions,
      aggSignature: blockchainUtils.api.muSig2.partialSigAgg(
        signatures: signatures.map((e) => e.signature).toList(),
        session: sessions.first.session,
      ),
      signatures: signatures,
    );
  }
}

/// Analogue of `IBlsAggregateVerificationKey`: verifies one participant's
/// partial signature via `partialSigVerify` (see [verify]).
abstract class IMuSig2VerificationKey
    implements IVerifiyingKey<MuSig2PartialVerifiyingParams> {
  BuBytes xOnly();
  Secp256k1Point tweakedPoint(List<MuSig2Tweak> tweaks);
  List<Secp256k1PublicKey>? get publicKeys;

  List<MuSig2PartialSigningParams> generateSession(
    MuSig2GenerateSessionParams params,
  ) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed(
        "IMuSig2VerificationKey.generateSession",
        reason: "Missing public keys.",
      );
    }
    final nonces = generateNonces(
      params.nonceGenerationParams ?? MuSig2GenerateNoncesParams(),
    );
    final aggNonce = blockchainUtils.api.muSig2.nonceAgg(
      nonces.map((e) => e.pubnonce).toList(),
    );
    final session = MuSig2Session(
      aggnonce: aggNonce,
      publicKeys: publicKeys.map((e) => e.toBytes()).toList(),
      msg: params.message,
      tweaks: params.tweaks,
    );
    return publicKeys.indexed
        .map(
          (e) => MuSig2PartialSigningParams(
            session: session,
            nonce: nonces.elementAt(e.$1),
          ),
        )
        .toList();
  }

  List<MuSig2Nonce> generateNonces(MuSig2GenerateNoncesParams params) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed(
        "generateNonces",
        reason: "Missing public keys.",
      );
    }
    final sk = params.sk;
    final rand = params.rand;
    if (sk == null && rand == null) {
      throw CoreErrors.invalidOperationArguments(
        "generateNonces",
        reason: "At least one of sk or rand must be provided.",
      );
    }
    return publicKeys
        .map(
          (e) => blockchainUtils.api.muSig2.nonceGenerate(
            publicKey: e.toBytes(mode: CryptoKeyEncoding.base),
            aggPubKey: params.aggPubKey,
            extra: params.extra,
            msg: params.msg,
            rand: rand?.cloneBytes(),
            sk: sk?.cloneBytes(),
          ),
        )
        .toList();
  }

  /// Verifies the final aggregated (tweaked) MuSig2 signature.
  bool verifyAggregate(MuSig2AggregateVerifiyingParams params) {
    BuBytes xOnly = tweakedPoint(params.tweaks).toXOnly();
    return blockchainUtils.api.muSig2.verifyAggregate(
      message: params.message,
      signature: params.signature,
      aggXOnly: xOnly,
    );
  }

  @override
  bool verify(MuSig2PartialVerifiyingParams params) {
    return blockchainUtils.api.muSig2.partialSigVerify(
      signature: params.signature.toBytes(),
      pubnonce: params.signature.pubnonce,
      pk: params.signature.publicKey,
      session: params.session,
    );
  }
}
