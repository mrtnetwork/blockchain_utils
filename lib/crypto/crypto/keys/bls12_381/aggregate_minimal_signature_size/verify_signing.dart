import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';

abstract class IBlsAggregateMinSigSigningKey<
  P extends IBlsAggregateMinSigVerificationKey
>
    implements
        ISigningKey<Bls12G2BatchSignature, Bls12AggregateSigningParams, P> {
  List<Bls12G2PrivateKey> get secretKeys;

  @override
  Bls12G2BatchSignature sign(Bls12AggregateSigningParams params) {
    List<Bls12G2Signature> signatures = [];
    if (params.messages.length != secretKeys.length) {
      throw CoreErrors.cryptoFailed(
        "sign",
        reason: "Mismatch between messages and secret keys length.",
      );
    }
    for (final i in secretKeys.indexed) {
      final signMessage = Bls12SigningParams(
        message: params.messages.elementAt(i.$1),
        dst: params.dst,
      );
      final signature = i.$2.sign(signMessage);
      signatures.add(signature);
    }
    final aggSig = blockchainUtils.api.signing.bls.aggregateSignaturesG2(
      signatures,
    );
    return Bls12G2BatchSignature(
      aggregateSignature: aggSig,
      signatures: signatures,
    );
  }

  Bls12G2Signature signFast(Bls12FastAggregateSigningParams params) {
    List<Bls12G2Signature> signatures = [];
    final signMessage = Bls12SigningParams(
      message: params.message,
      dst: params.dst,
    );
    for (final i in secretKeys.indexed) {
      final signature = i.$2.sign(signMessage);
      signatures.add(signature);
    }
    return blockchainUtils.api.signing.bls.aggregateSignaturesG2(signatures);
  }
}

abstract class IBlsAggregateMinSigVerificationKey
    implements IVerifiyingKey<Bls12G2AggregateVerifiyingParams> {
  List<Bls12G2PublicKey>? get publicKeys;
  Bls12G2PublicKey get aggregateKey;
  @override
  bool verify(Bls12G2AggregateVerifiyingParams params) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed("verify", reason: "Missing public keys.");
    }
    return blockchainUtils.api.signing.bls.aggregateVerifyMinSig(
      messages: params.messages,
      publicKeys: publicKeys.map((e) => e.keyBytes).toList(),
      signature: params.signature,
      dst: params.dst,
    );
  }

  bool verifyFast(Bls12G2AggregateFastVerifiyingParams params) {
    return blockchainUtils.api.signing.bls.fastAggregateVerifyMinSig(
      aggregatePublicKey: aggregateKey.keyBytes,
      message: params.signingParams.message,
      signature: params.signature,
      dst: params.signingParams.dst,
    );
  }

  bool batchVerify(Bls12G2AggregateBatchVerifiyingParams params) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed(
        "batchVerify",
        reason: "Missing public keys.",
      );
    }
    return blockchainUtils.api.signing.bls.batchVerifyMinSig(
      messages: params.messages,
      publicKeys: publicKeys.map((e) => e.keyBytes).toList(),
      signatures: params.signatures,
      dst: params.dst,
    );
  }
}
