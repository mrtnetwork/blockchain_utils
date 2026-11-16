import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate_minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/keys.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/types/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';

abstract class IBlsAggregateSigningKey<P extends IBlsAggregateVerificationKey>
    implements
        ISigningKey<Bls12G1BatchSignature, Bls12AggregateSigningParams, P> {
  List<Bls12G1PrivateKey> get secretKeys;

  @override
  Bls12G1BatchSignature sign(Bls12AggregateSigningParams params) {
    if (params.messages.length != secretKeys.length) {
      throw CoreErrors.cryptoFailed(
        "sign",
        reason: "Mismatch between messages and secret keys length.",
      );
    }

    List<Bls12G1Signature> signatures = [];
    for (final i in secretKeys.indexed) {
      final signMessage = Bls12SigningParams(
        message: params.messages.elementAt(i.$1),
        dst: params.dst,
      );
      final signature = i.$2.sign(signMessage);
      signatures.add(signature);
    }
    final aggSig = blockchainUtils.api.signing.bls.aggregateSignaturesG1(
      signatures,
    );
    return Bls12G1BatchSignature(
      aggregateSignature: aggSig,
      signatures: signatures,
    );
  }

  Bls12G1Signature signFast(Bls12FastAggregateSigningParams params) {
    List<Bls12G1Signature> signatures = [];
    final signMessage = Bls12SigningParams(
      message: params.message,
      dst: params.dst,
    );
    for (final i in secretKeys.indexed) {
      final signature = i.$2.sign(signMessage);
      signatures.add(signature);
    }
    final aggSig = blockchainUtils.api.signing.bls.aggregateSignaturesG1(
      signatures,
    );
    return aggSig;
  }
}

abstract class IBlsAggregateVerificationKey
    implements IVerifiyingKey<Bls12G1AggregateVerifiyingParams> {
  List<Bls12G1PublicKey>? get publicKeys;
  Bls12G1PublicKey get aggregateKey;
  @override
  bool verify(Bls12G1AggregateVerifiyingParams params) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed("verify", reason: "Missing public keys.");
    }
    return blockchainUtils.api.signing.bls.aggregateVerifyMinPk(
      messages: params.messages,
      publicKeys: publicKeys.map((e) => e.keyBytes).toList(),
      signature: params.signature,
      dst: params.dst,
    );
  }

  bool verifyFast(Bls12G1AggregateFastVerifiyingParams params) {
    return blockchainUtils.api.signing.bls.fastAggregateVerifyMinPk(
      aggregatePublicKey: aggregateKey.keyBytes,
      message: params.signingParams.message,
      signature: params.signature,
      dst: params.signingParams.dst,
    );
  }

  bool batchVerify(Bls12G1AggregateBatchVerifiyingParams params) {
    final publicKeys = this.publicKeys;
    if (publicKeys == null) {
      throw CoreErrors.cryptoFailed(
        "batchVerify",
        reason: "Missing public keys.",
      );
    }
    return blockchainUtils.api.signing.bls.batchVerifyMinPk(
      messages: params.messages,
      publicKeys: publicKeys.map((e) => e.keyBytes).toList(),
      signatures: params.signatures,
      dst: params.dst,
    );
  }
}
