import 'package:blockchain_utils/api/validation/validate.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Backend interface for secp256k1 signing/verification operations.
abstract interface class Secp256k1SigningApi {
  /// Signs 32-byte [digest] with 32-byte [sk] using BCH Schnorr (RFC6979 k, SHA-256).
  /// [publicKey] is 33/65 bytes; [extraEntropy] defaults to BCH extra data. Throws on invalid input.
  IECDSASignature signSchnorr({
    required List<int> digest,
    required List<int> sk,
    required List<int> publicKey,
    List<int>? extraEntropy,
  });

  /// Signs 32-byte [digest] with 32-byte [sk] using ECDSA (RFC6979 k, low-S).
  /// [publicKey] is 33/65 bytes; returns signature with recovery id. Throws on invalid input.
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  });

  /// Signs 32-byte [digest] with 32-byte [sk] using BIP-340 Schnorr.
  /// [publicKey] is 33/65 bytes; [aux] and [tapTweakHash] are optional 32 bytes. Throws on invalid input.
  IECDSASignature signBip340({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    final List<int>? aux,
    final List<int>? tapTweakHash,
  });

  /// Verifies BIP-340 signature against 32-byte [xOnly] key and 32-byte [digest].
  /// Optional 32-byte [tapTweakHash] tweaks the key first. Returns false if invalid; throws on malformed lengths.
  bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required IECDSASignature signature,
    List<int>? tapTweakHash,
  });

  /// Verifies BCH Schnorr [signature] over 32-byte [digest] with 33/65-byte [publicKey].
  /// Returns false if invalid; throws on malformed input.
  bool verifySchnorr({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  });

  /// Verifies ECDSA [signature] over 32-byte [digest] with 33/65-byte [publicKey].
  /// Returns false if invalid; throws on malformed input.
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  });

  /// Verifies Bitcoin signed-message [signature] over arbitrary [message] with 33/65-byte [publicKey].
  /// [messagePrefix] is the network magic prefix. Returns false if invalid; throws on malformed input.
  bool verifyMessageSignature({
    required List<int> message,
    required IECDSASignature signature,
    required List<int> publicKey,
    required String messagePrefix,
  });

  /// Validates 33/65-byte [publicKey] and returns its canonical base
  /// (compressed) encoding, or null when invalid (bad length, prefix,
  /// range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths before delegating to the inner backend.
class ValidatedSecp256k1SigningApi implements Secp256k1SigningApi {
  ValidatedSecp256k1SigningApi(this.inner);
  final Secp256k1SigningApi inner;
  static const _tag = 'Secp256k1Signing';

  void _digest32(List<int> d, String op) {
    ApiValidate.length(d, 32, operation: '$_tag.$op', name: 'digest');
  }

  void _publicKey(List<int> d, String op) {
    ApiValidate.oneOfLengths(
      d,
      [
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyUncompressedByteLen,
      ],
      operation: '$_tag.$op',
      name: 'publicKey',
    );
  }

  void _sk32(List<int> sk, String op) {
    if (sk.length != 32) {
      throw CoreErrors.invalidOperationArguments(
        '$_tag.$op',
        name: 'sk',
        reason: 'expected 32 bytes',
      );
    }
  }

  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    _sk32(sk, 'sign');
    _digest32(digest, 'sign');
    _publicKey(publicKey, 'sign');
    return ApiValidate.call(
      '$_tag.sign',
      () => inner.sign(
        sk: sk,
        publicKey: publicKey,
        digest: digest,
        extraEntropy: extraEntropy,
      ),
    );
  }

  @override
  IECDSASignature signSchnorr({
    required List<int> digest,
    required List<int> sk,
    required List<int> publicKey,
    List<int>? extraEntropy,
  }) {
    _sk32(sk, 'signSchnorr');
    _digest32(digest, 'signSchnorr');
    _publicKey(publicKey, 'signSchnorr');
    return ApiValidate.call(
      '$_tag.signSchnorr',
      () => inner.signSchnorr(
        digest: digest,
        sk: sk,
        publicKey: publicKey,
        extraEntropy: extraEntropy,
      ),
    );
  }

  @override
  IECDSASignature signBip340({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? aux,
    List<int>? tapTweakHash,
  }) {
    _sk32(sk, 'signBip340');
    _digest32(digest, 'signBip340');
    _publicKey(publicKey, 'signBip340');
    if (aux != null) {
      ApiValidate.length(aux, 32, operation: '$_tag.signBip340', name: 'aux');
    }
    if (tapTweakHash != null) {
      ApiValidate.length(
        tapTweakHash,
        32,
        operation: '$_tag.signBip340',
        name: 'tapTweakHash',
      );
    }
    return ApiValidate.call(
      '$_tag.signBip340',
      () => inner.signBip340(
        sk: sk,
        publicKey: publicKey,
        digest: digest,
        aux: aux,
        tapTweakHash: tapTweakHash,
      ),
    );
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    _digest32(digest, 'verify');
    _publicKey(publicKey, 'verify');
    return ApiValidate.call(
      '$_tag.verify',
      () => inner.verify(
        digest: digest,
        signature: signature,
        publicKey: publicKey,
      ),
    );
  }

  @override
  bool verifySchnorr({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    _digest32(digest, 'verifySchnorr');
    _publicKey(publicKey, 'verifySchnorr');
    return ApiValidate.call(
      '$_tag.verifySchnorr',
      () => inner.verifySchnorr(
        digest: digest,
        signature: signature,
        publicKey: publicKey,
      ),
    );
  }

  @override
  bool verifyBip340SignatureUsingXOnly({
    required List<int> xOnly,
    required List<int> digest,
    required IECDSASignature signature,
    List<int>? tapTweakHash,
  }) {
    ApiValidate.length(
      xOnly,
      32,
      operation: '$_tag.verifyBip340',
      name: 'xOnly',
    );
    _digest32(digest, 'verifyBip340');

    if (tapTweakHash != null) {
      ApiValidate.length(
        tapTweakHash,
        32,
        operation: '$_tag.verifyBip340',
        name: 'tapTweakHash',
      );
    }
    return ApiValidate.call(
      '$_tag.verifyBip340',
      () => inner.verifyBip340SignatureUsingXOnly(
        xOnly: xOnly,
        digest: digest,
        signature: signature,
        tapTweakHash: tapTweakHash,
      ),
    );
  }

  @override
  bool verifyMessageSignature({
    required List<int> message,
    required IECDSASignature signature,
    required List<int> publicKey,
    required String messagePrefix,
  }) {
    _publicKey(publicKey, 'verifyMessageSignature');

    return ApiValidate.call(
      '$_tag.verifyMessage',
      () => inner.verifyMessageSignature(
        message: message,
        signature: signature,
        publicKey: publicKey,
        messagePrefix: messagePrefix,
      ),
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    // Null covers every invalid input; no length pre-check (both 33/65-byte
    // encodings are accepted, anything else normalizes to null).
    return inner.normalizePublicKey(publicKey);
  }
}
