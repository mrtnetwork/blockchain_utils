import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/constants/ecdsa.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';

/// Backend interface for secp256r1 signing/verification operations.
abstract interface class Secp256r1SigningApi {
  /// Signs [digest] with 32-byte big-endian [sk] using ECDSA on P-256.
  /// [publicKey] is 33/65 bytes; [extraEntropy] is optional RFC6979 entropy. Throws on invalid input.
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  });

  /// Verifies ECDSA [signature] over [digest] with 33/65-byte [publicKey].
  /// Returns false if invalid; throws on malformed input.
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  });

  /// Validates 33/65-byte [publicKey] and returns its canonical base
  /// (compressed) encoding, or null when invalid (bad length, prefix,
  /// range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths before delegating to the inner backend.
class ValidatedSecp256r1SigningApi implements Secp256r1SigningApi {
  ValidatedSecp256r1SigningApi(this.inner);
  final Secp256r1SigningApi inner;
  static const _tag = 'Secp256r1Signing';

  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    final op = "$_tag.sign";
    ApiValidate.length(
      sk,
      EcdsaKeysConst.privKeyByteLen,
      operation: op,
      name: "sk",
    );
    ApiValidate.oneOfLengths(
      publicKey,
      [
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyUncompressedByteLen,
      ],
      operation: op,
      name: "publicKey",
    );
    return ApiValidate.call(
      op,
      () => inner.sign(
        sk: sk,
        publicKey: publicKey,
        digest: digest,
        extraEntropy: extraEntropy,
      ),
    );
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final op = "$_tag.verify";
    ApiValidate.oneOfLengths(
      publicKey,
      [
        EcdsaKeysConst.pubKeyCompressedByteLen,
        EcdsaKeysConst.pubKeyUncompressedByteLen,
      ],
      operation: op,
      name: "publicKey",
    );
    return ApiValidate.call(
      op,
      () => inner.verify(
        publicKey: publicKey,
        digest: digest,
        signature: signature,
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
