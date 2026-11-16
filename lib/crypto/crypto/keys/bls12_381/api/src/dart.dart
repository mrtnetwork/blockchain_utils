import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/group/group.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/api/src/api.dart';

import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/aggregate/aggregate.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Pure-Dart implementation of BLS12-381 signing/verification/aggregation.
class DartBlsSigningApi implements BlsSigningApi {
  const DartBlsSigningApi();
  @override
  BuBytes aggregatePublicKeysG1(List<List<int>> publicKeys) {
    return BlsMinPubkeyAggregateUtils.aggregatePublicKeys(publicKeys).toBytes();
  }

  @override
  BuBytes aggregatePublicKeysG2(List<List<int>> publicKeys) {
    return BlsMinSigAggregateUtils.aggregatePublicKeys(publicKeys).toBytes();
  }

  @override
  Bls12G1Signature aggregateSignaturesG1(List<Bls12G1Signature> signatures) {
    return BlsMinPubkeyAggregateUtils.aggregateSignatures(signatures);
  }

  @override
  Bls12G2Signature aggregateSignaturesG2(List<Bls12G2Signature> signatures) {
    return BlsMinSigAggregateUtils.aggregateSignatures(signatures);
  }

  @override
  bool aggregateVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    return BlsMinPubkeyAggregateUtils.aggregateVerify(
      messages: messages,
      aggregateSignature: signature,
      publicKeys: publicKeys,
      dst: dst,
    );
  }

  @override
  bool aggregateVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    return BlsMinSigAggregateUtils.aggregateVerify(
      messages: messages,
      aggregateSignature: signature,
      publicKeys: publicKeys,
      dst: dst,
    );
  }

  @override
  bool batchVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G1Signature> signatures,
    List<int>? dst,
  }) {
    return BlsMinPubkeyAggregateUtils.batchVerify(
      messages: messages,
      signatures: signatures,
      publicKeys: publicKeys,
      dst: dst,
    );
  }

  @override
  bool batchVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G2Signature> signatures,
    List<int>? dst,
  }) {
    return BlsMinSigAggregateUtils.batchVerify(
      messages: messages,
      signatures: signatures,
      publicKeys: publicKeys,
      dst: dst,
    );
  }

  @override
  BuBytes publicKeyG1(List<int> sk) {
    JubJubFq? sc = JubJubFq.fromBytes(sk, endian: Endian.big);
    final pk = G1Projective.generator * sc;
    sc = null;
    return pk.toBytes();
  }

  @override
  BuBytes publicKeyG2(List<int> sk) {
    JubJubFq? sc = JubJubFq.fromBytes(sk, endian: Endian.big);
    final pk = G2Projective.generator * sc;
    sc = null;
    return pk.toBytes();
  }

  @override
  Bls12G1Signature signMinPk({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    JubJubFq? scalar = JubJubFq.fromBytes(sk, endian: Endian.big);
    final h = BlsHashToG2.hashToG2(message, dst: dst);
    final signature = h * scalar;
    scalar = null;
    return Bls12G1Signature(
      G2Projective.fromBytesUnchecked(signature.toBytes()),
    );
  }

  @override
  Bls12G2Signature signMinSig({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    JubJubFq? scalar = JubJubFq.fromBytes(sk, endian: Endian.big);
    final h = BlsHashToG1.hashToG1(message, dst: dst);
    final signature = h * scalar;
    scalar = null;
    return Bls12G2Signature(
      G1Projective.fromBytesUnchecked(signature.toBytes()),
    );
  }

  @override
  bool fastAggregateVerifyMinPk({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    return BlsMinPubkeyAggregateUtils.fastAggregateVerify(
      aggregatePublicKey: aggregatePublicKey,
      message: message,
      aggregateSignature: signature,
      dst: dst,
    );
  }

  @override
  bool fastAggregateVerifyMinSig({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    return BlsMinSigAggregateUtils.fastAggregateVerify(
      aggregatePublicKey: aggregatePublicKey,
      message: message,
      aggregateSignature: signature,
      dst: dst,
    );
  }

  @override
  bool verifyMinPk({
    required List<int> pk,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    final h = BlsHashToG2.hashToG2(message, dst: dst).toAffine();
    final sig = signature.signature.toAffine();
    final lhs = Bls12PairingUtils.pairing(
      G1Projective.fromBytes(pk).toAffine(),
      h,
    );
    final rhs = Bls12PairingUtils.pairing(G1AffinePoint.generator, sig);
    return lhs == rhs;
  }

  @override
  bool verifyMinSig({
    required List<int> pk,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    final h = BlsHashToG1.hashToG1(message, dst: dst).toAffine();
    final sig = signature.signature.toAffine();

    final lhs = Bls12PairingUtils.pairing(
      h,
      G2Projective.fromBytes(pk).toAffine(),
    );
    final rhs = Bls12PairingUtils.pairing(sig, G2AffinePoint.generator);
    return lhs == rhs;
  }

  @override
  BuBytes? normalizeG1PublicKey(List<int> publicKey) {
    try {
      final point = G1Projective.fromBytes(publicKey);
      if (point.isIdentity()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }

  @override
  BuBytes? normalizeG2PublicKey(List<int> publicKey) {
    try {
      final point = G2Projective.fromBytes(publicKey);
      if (point.isIdentity()) return null;
      return BuBytes.immutable(point.toBytes());
    } catch (_) {
      return null;
    }
  }
}
