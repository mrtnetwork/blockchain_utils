import 'package:blockchain_utils/api/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';

/// Backend interface for ed25519-family signing/verification.
abstract interface class ED25519SigningApi {
  /// Signs [message] (arbitrary bytes) with [sk] and 32-byte [publicKey].
  /// [sk] is 32 bytes for [CryptoKeyType.ed25519]/[CryptoKeyType.ed25519Blake2b]
  /// and 64 bytes for [CryptoKeyType.ed25519Monero]/[CryptoKeyType.ed25519Kholaw].
  /// [type] selects the ed25519 domain; returns 64-byte `R || s`. Throws on invalid type or lengths.
  BuBytes sign({
    required List<int> sk,
    required List<int> message,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  });

  /// Verifies 64-byte [signature] over [message] with 32-byte [publicKey].
  /// Returns false if invalid; throws on malformed input or invalid [type].
  bool verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  });

  /// Validates 32-byte [publicKey] (33-byte `0xed`-prefixed form accepted)
  /// and returns its canonical 32-byte base encoding, or null when invalid
  /// (bad length, prefix, range, curve membership, or identity).
  BuBytes? normalizePublicKey(List<int> publicKey);
}

/// Validates argument lengths/key types before delegating to the inner backend.
class ValidatedED25519SigningApi implements ED25519SigningApi {
  final ED25519SigningApi inner;
  const ValidatedED25519SigningApi(this.inner);
  static const String _tag = "ED25519SigningApi";
  void _ensureIsED25519(String name, CryptoKeyType type) {
    if (!type.isED25519()) {
      throw CoreErrors.invalidOperationArguments(
        "$_tag.$name",
        reason: "Invalid ED25519 key type.",
      );
    }
  }

  @override
  BuBytes sign({
    required List<int> sk,
    required List<int> message,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    _ensureIsED25519("sign", type);
    final expectedSkLen =
        type == CryptoKeyType.ed25519Monero ||
                type == CryptoKeyType.ed25519Kholaw
            ? 64
            : 32;
    ApiValidate.length(sk, expectedSkLen, operation: "$_tag.sign", name: "sk");
    ApiValidate.length(
      publicKey,
      32,
      operation: "$_tag.sign",
      name: "publicKey",
    );
    return ApiValidate.call(
      "$_tag.sign",
      () => inner.sign(
        sk: sk,
        message: message,
        publicKey: publicKey,
        type: type,
      ),
    );
  }

  @override
  bool verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    _ensureIsED25519("verify", type);
    ApiValidate.length(
      signature,
      64,
      operation: "$_tag.verify",
      name: "signature",
    );
    ApiValidate.length(
      publicKey,
      32,
      operation: "$_tag.verify",
      name: "publicKey",
    );

    return ApiValidate.call(
      "$_tag.verify",
      () => inner.verify(
        message: message,
        publicKey: publicKey,
        type: type,
        signature: signature,
      ),
    );
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    return inner.normalizePublicKey(publicKey);
  }
}
