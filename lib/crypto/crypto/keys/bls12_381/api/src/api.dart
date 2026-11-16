import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_pubkey_size/types.dart';
import 'package:blockchain_utils/crypto/crypto/keys/bls12_381/minimal_signature_size/types.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Backend interface for BLS12-381 signing/verification/aggregation.
abstract interface class BlsSigningApi {
  /// Derives 48-byte compressed G1 public key from 32-byte big-endian [sk]. Throws on invalid length/scalar.
  BuBytes publicKeyG1(List<int> sk);

  /// Derives 96-byte compressed G2 public key from 32-byte big-endian [sk]. Throws on invalid length/scalar.
  BuBytes publicKeyG2(List<int> sk);

  /// Minimal-pubkey-size sign: 32-byte big-endian [sk], arbitrary [message], optional [dst]. Returns G2 signature. Throws on invalid sk.
  Bls12G1Signature signMinPk({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  });

  /// Minimal-signature-size sign: 32-byte big-endian [sk], arbitrary [message], optional [dst]. Returns G1 signature. Throws on invalid sk.
  Bls12G2Signature signMinSig({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  });

  /// Min-pk verify: G1 [pk], [message], G2 [signature], optional [dst]. Returns true on valid, false on invalid signature, throws on crypto failure.
  bool verifyMinPk({
    required List<int> pk,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  });

  /// Min-sig verify: G2 [pk], [message], G1 [signature], optional [dst]. Returns true on valid, false on invalid signature, throws on crypto failure.
  bool verifyMinSig({
    required List<int> pk,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  });

  /// Sums non-empty [publicKeys] (G1) into 48-byte compressed aggregate. Throws on empty list or crypto failure.
  BuBytes aggregatePublicKeysG1(List<List<int>> publicKeys);

  /// Sums non-empty [publicKeys] (G2) into 96-byte compressed aggregate. Throws on empty list or crypto failure.
  BuBytes aggregatePublicKeysG2(List<List<int>> publicKeys);

  /// Sums non-empty G2 [signatures] into one min-pk aggregate signature. Throws on empty list or crypto failure.
  Bls12G1Signature aggregateSignaturesG1(List<Bls12G1Signature> signatures);

  /// Sums non-empty G1 [signatures] into one min-sig aggregate signature. Throws on empty list or crypto failure.
  Bls12G2Signature aggregateSignaturesG2(List<Bls12G2Signature> signatures);

  /// Same message, many min-pk public keys, one aggregated G2 signature.
  bool fastAggregateVerifyMinPk({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  });

  /// Same message, many min-sig public keys, one aggregated G1 signature.
  bool fastAggregateVerifyMinSig({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  });

  /// Distinct messages, many min-pk keys, one aggregated G2 signature; [publicKeys] and [messages] must share non-zero length. Returns true on valid, false on invalid, throws on length mismatch or crypto failure.
  bool aggregateVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G1Signature signature,
    List<int>? dst,
  });

  /// Distinct messages, many min-sig keys, one aggregated G1 signature; [publicKeys] and [messages] must share non-zero length. Returns true on valid, false on invalid, throws on length mismatch or crypto failure.
  bool aggregateVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G2Signature signature,
    List<int>? dst,
  });

  /// One message/signature per min-pk key; all three lists must share non-zero length. Returns true on all-valid, false otherwise, throws on length mismatch or crypto failure.
  bool batchVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G1Signature> signatures,
    List<int>? dst,
  });

  /// One message/signature per min-sig key; all three lists must share non-zero length. Returns true on all-valid, false otherwise, throws on length mismatch or crypto failure.
  bool batchVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G2Signature> signatures,
    List<int>? dst,
  });

  /// Validates 48/96-byte G1 [publicKey] and returns its canonical 48-byte
  /// compressed base encoding, or null when invalid (bad prefix, range,
  /// curve membership, or identity).
  BuBytes? normalizeG1PublicKey(List<int> publicKey);

  /// Validates 96/192-byte G2 [publicKey] and returns its canonical 96-byte
  /// compressed base encoding, or null when invalid (bad prefix, range,
  /// curve membership, or identity).
  BuBytes? normalizeG2PublicKey(List<int> publicKey);
}

/// Validates argument lengths/emptiness before delegating to the inner backend.
class ValidatedBlsSigningApi implements BlsSigningApi {
  ValidatedBlsSigningApi(this.inner);
  final BlsSigningApi inner;
  static const _tag = 'BlsSigning';

  void _sk(List<int> sk, String op) {
    if (sk.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.$op',
        name: 'sk',
        reason: 'Invalid secret key bytes length.',
      );
    }
  }

  @override
  BuBytes publicKeyG1(List<int> sk) {
    _sk(sk, 'publicKeyG1');
    return ApiValidate.call('$_tag.publicKeyG1', () => inner.publicKeyG1(sk));
  }

  @override
  BuBytes publicKeyG2(List<int> sk) {
    _sk(sk, 'publicKeyG2');
    return ApiValidate.call('$_tag.publicKeyG2', () => inner.publicKeyG2(sk));
  }

  @override
  Bls12G1Signature signMinPk({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    _sk(sk, 'signMinPk');
    return ApiValidate.call(
      '$_tag.signMinPk',
      () => inner.signMinPk(sk: sk, message: message, dst: dst),
    );
  }

  @override
  Bls12G2Signature signMinSig({
    required List<int> sk,
    required List<int> message,
    List<int>? dst,
  }) {
    _sk(sk, 'signMinSig');
    return ApiValidate.call(
      '$_tag.signMinSig',
      () => inner.signMinSig(sk: sk, message: message, dst: dst),
    );
  }

  @override
  bool verifyMinPk({
    required List<int> pk,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    return ApiValidate.call(
      '$_tag.verifyMinPk',
      () => inner.verifyMinPk(
        pk: pk,
        message: message,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  bool verifyMinSig({
    required List<int> pk,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    return ApiValidate.call(
      '$_tag.verifyMinSig',
      () => inner.verifyMinSig(
        pk: pk,
        message: message,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  BuBytes aggregatePublicKeysG1(List<List<int>> publicKeys) {
    if (publicKeys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregatePublicKeysG1',
        name: 'publicKeys',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregatePublicKeysG1',
      () => inner.aggregatePublicKeysG1(publicKeys),
    );
  }

  @override
  BuBytes aggregatePublicKeysG2(List<List<int>> publicKeys) {
    if (publicKeys.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregatePublicKeysG2',
        name: 'publicKeys',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregatePublicKeysG2',
      () => inner.aggregatePublicKeysG2(publicKeys),
    );
  }

  @override
  Bls12G1Signature aggregateSignaturesG1(List<Bls12G1Signature> signatures) {
    if (signatures.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregateSignaturesG1',
        name: 'signatures',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregateSignaturesG1',
      () => inner.aggregateSignaturesG1(signatures),
    );
  }

  @override
  Bls12G2Signature aggregateSignaturesG2(List<Bls12G2Signature> signatures) {
    if (signatures.isEmpty) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregateSignaturesG2',
        name: 'signatures',
        reason: 'must not be empty',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregateSignaturesG2',
      () => inner.aggregateSignaturesG2(signatures),
    );
  }

  @override
  bool fastAggregateVerifyMinPk({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    return ApiValidate.call(
      '$_tag.fastAggregateVerifyMinPk',
      () => inner.fastAggregateVerifyMinPk(
        aggregatePublicKey: aggregatePublicKey,
        message: message,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  bool fastAggregateVerifyMinSig({
    required List<int> aggregatePublicKey,
    required List<int> message,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    return ApiValidate.call(
      '$_tag.fastAggregateVerifyMinSig',
      () => inner.fastAggregateVerifyMinSig(
        aggregatePublicKey: aggregatePublicKey,
        message: message,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  bool aggregateVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G1Signature signature,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty || publicKeys.length != messages.length) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregateVerifyMinPk',
        name: 'publicKeys/messages',
        reason: 'non-empty equal lengths required',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregateVerifyMinPk',
      () => inner.aggregateVerifyMinPk(
        publicKeys: publicKeys,
        messages: messages,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  bool aggregateVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required Bls12G2Signature signature,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty || publicKeys.length != messages.length) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.aggregateVerifyMinSig',
        name: 'publicKeys/messages',
        reason: 'non-empty equal lengths required',
      );
    }
    return ApiValidate.call(
      '$_tag.aggregateVerifyMinSig',
      () => inner.aggregateVerifyMinSig(
        publicKeys: publicKeys,
        messages: messages,
        signature: signature,
        dst: dst,
      ),
    );
  }

  @override
  bool batchVerifyMinPk({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G1Signature> signatures,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty ||
        publicKeys.length != messages.length ||
        publicKeys.length != signatures.length) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.batchVerifyMinPk',
        name: 'lists',
        reason: 'publicKeys, messages, signatures must share non-zero length',
      );
    }
    return ApiValidate.call(
      '$_tag.batchVerifyMinPk',
      () => inner.batchVerifyMinPk(
        publicKeys: publicKeys,
        messages: messages,
        signatures: signatures,
        dst: dst,
      ),
    );
  }

  @override
  bool batchVerifyMinSig({
    required List<List<int>> publicKeys,
    required List<List<int>> messages,
    required List<Bls12G2Signature> signatures,
    List<int>? dst,
  }) {
    if (publicKeys.isEmpty ||
        publicKeys.length != messages.length ||
        publicKeys.length != signatures.length) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.batchVerifyMinSig',
        name: 'lists',
        reason: 'publicKeys, messages, signatures must share non-zero length',
      );
    }
    return ApiValidate.call(
      '$_tag.batchVerifyMinSig',
      () => inner.batchVerifyMinSig(
        publicKeys: publicKeys,
        messages: messages,
        signatures: signatures,
        dst: dst,
      ),
    );
  }

  @override
  BuBytes? normalizeG1PublicKey(List<int> publicKey) {
    return inner.normalizeG1PublicKey(publicKey);
  }

  @override
  BuBytes? normalizeG2PublicKey(List<int> publicKey) {
    return inner.normalizeG2PublicKey(publicKey);
  }
}
