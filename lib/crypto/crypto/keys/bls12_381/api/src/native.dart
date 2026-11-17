import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of BLS12-381 signing/verification/aggregation.
class NativeBlsSigningApi implements BlsSigningApi {
  final BuBlsSigningApi api;
  const NativeBlsSigningApi(this.api);
  BuBytes buBlsPackMessages(List<List<int>> messages) {
    final out = <int>[];
    for (final m in messages) {
      final len = m.length;
      out.add((len >> 24) & 0xff);
      out.add((len >> 16) & 0xff);
      out.add((len >> 8) & 0xff);
      out.add(len & 0xff);
      out.addAll(m);
    }
    return BuBytes(out);
  }

  @override
  BuBytes aggregatePublicKeysG1(List<List<int>> publicKeys) {
    final result = api.aggregatePublicKeysG1(BuBytes.concat(publicKeys));
    return result.map((e) => e.asBytes).unwrapOrThrowCryptoError();
  }

  @override
  BuBytes aggregatePublicKeysG2(List<List<int>> publicKeys) {
    final result = api.aggregatePublicKeysG2(BuBytes.concat(publicKeys));
    return result.map((e) => e.asBytes).unwrapOrThrowCryptoError();
  }

  @override
  Bls12G1Signature aggregateSignaturesG1(List<Bls12G1Signature> signatures) {
    final result = api.aggregateSignaturesG2(
      BuBytes.concat(signatures.map((e) => e.toBytes())),
    );
    return result
        .map((e) => Bls12G1Signature.fromBytes(e))
        .unwrapOrThrowCryptoError();
  }

  @override
  Bls12G2Signature aggregateSignaturesG2(List<Bls12G2Signature> signatures) {
    final result = api.aggregateSignaturesG1(
      BuBytes.concat(signatures.map((e) => e.toBytes())),
    );
    return result
        .map((e) => Bls12G2Signature.fromBytes(e))
        .unwrapOrThrowCryptoError();
  }

  @override
  bool aggregateVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    final result = api.aggregateVerifyMinPk(
      pksConcat: BuBytes.concat(publicKeys),
      signature: signature.toBytes(),
      messageCount: messages.length,
      dst: dst?.asBytes,
      messagesBlob: buBlsPackMessages(messages),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool aggregateVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    final result = api.aggregateVerifyMinSig(
      pksConcat: BuBytes.concat(publicKeys),
      signature: signature.toBytes(),
      messageCount: messages.length,
      dst: dst?.asBytes,
      messagesBlob: buBlsPackMessages(messages),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool batchVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G1Signature> signatures,
    List<int>? dst,
  }) {
    final result = api.batchVerifyMinPk(
      pksConcat: BuBytes.concat(publicKeys),
      messageCount: messages.length,
      dst: dst?.asBytes,
      messagesBlob: buBlsPackMessages(messages),
      sigsConcat: BuBytes.concat(signatures.map((e) => e.toBytes())),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool batchVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G2Signature> signatures,
    List<int>? dst,
  }) {
    final result = api.batchVerifyMinSig(
      pksConcat: BuBytes.concat(publicKeys),
      messageCount: messages.length,
      dst: dst?.asBytes,
      messagesBlob: buBlsPackMessages(messages),
      sigsConcat: BuBytes.concat(signatures.map((e) => e.toBytes())),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool fastAggregateVerifyMinPk({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    final result = api.fastAggregateVerifyMinPk(
      aggregatePublicKey: aggregatePublicKey.asBytes,
      message: message.asBytes,
      signature: signature.toBytes(),
      dst: dst?.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool fastAggregateVerifyMinSig({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    final result = api.fastAggregateVerifyMinSig(
      aggregatePublicKey: aggregatePublicKey.asBytes,
      message: message.asBytes,
      signature: signature.toBytes(),
      dst: dst?.asBytes,
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes publicKeyG1(List<int> sk) {
    return api.publicKeyG1(BuBytes.unsafe(sk)).unwrapOrThrowCryptoError();
  }

  @override
  BuBytes publicKeyG2(List<int> sk) {
    return api.publicKeyG2(BuBytes.unsafe(sk)).unwrapOrThrowCryptoError();
  }

  @override
  Bls12G1Signature signMinPk({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    final result = api
        .signMinPk(message: message.asBytes, dst: dst?.asBytes, sk: sk.asBytes)
        .map((e) => e.asBytes);
    return Bls12G1Signature.fromBytes(result.unwrapOrThrowCryptoError());
  }

  @override
  Bls12G2Signature signMinSig({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    final result = api
        .signMinSig(message: message.asBytes, dst: dst?.asBytes, sk: sk.asBytes)
        .map((e) => e.asBytes);
    return Bls12G2Signature.fromBytes(result.unwrapOrThrowCryptoError());
  }

  @override
  bool verifyMinPk({
    required List<int> pk,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    final result = api.verifyMinPk(
      pk: pk.asBytes,
      message: message.asBytes,
      dst: dst?.asBytes,
      signature: signature.toBytes(),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  bool verifyMinSig({
    required List<int> pk,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    final result = api.verifyMinSig(
      pk: pk.asBytes,
      message: message.asBytes,
      dst: dst?.asBytes,
      signature: signature.toBytes(),
    );
    return result.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes? normalizeG1PublicKey(List<int> publicKey) {
    // Pure validation: identical math on every backend (Dart decoders are
    // pinned equal to Rust by the api-comparison tests), so no FFI
    // round-trip and no new Rust exports are needed.
    final r = api.normalizeG1PublicKey(publicKey.asBytes);
    if (!r.isOk) return null;
    return r.value;
  }

  @override
  BuBytes? normalizeG2PublicKey(List<int> publicKey) {
    final r = api.normalizeG2PublicKey(publicKey.asBytes);
    if (!r.isOk) return null;
    return r.value;
  }
}
