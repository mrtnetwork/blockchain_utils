import 'package:blockchain_utils/crypto/crypto/keys/ed25519/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of ed25519-family signing/verification.
class NativeED25519SigningApi implements ED25519SigningApi {
  final BuEd25519SigningApi api;
  const NativeED25519SigningApi(this.api);

  BuEd25519Variant _toBuKeyType(CryptoKeyType type) {
    return switch (type) {
      CryptoKeyType.ed25519 => BuEd25519Variant.ed25519,
      CryptoKeyType.ed25519Blake2b => BuEd25519Variant.ed25519Blake2b,
      CryptoKeyType.ed25519Kholaw => BuEd25519Variant.ed25519Kholaw,
      CryptoKeyType.ed25519Monero => BuEd25519Variant.ed25519Monero,
      _ =>
        throw CoreErrors.cryptoFailed(
          "ED25519SigningApi",
          reason: "Invalid ED25519 key type.",
        ),
    };
  }

  @override
  BuBytes sign({
    required List<int> sk,
    required List<int> message,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    final signature = api.sign(
      secret: sk.asBytes,
      message: message.asBytes,
      variant: _toBuKeyType(type),
    );

    return signature
        .map((s) => s.bytes)
        .unwrapOrThrowCryptoError();
  }

  @override
  bool verify({
    required List<int> message,
    required List<int> signature,
    required List<int> publicKey,
    CryptoKeyType type = CryptoKeyType.ed25519,
  }) {
    final verify = api.verify(
      publicKey: publicKey.asBytes,
      message: message.asBytes,
      variant: _toBuKeyType(type),
      signature: BuEd25519Signature(signature.asBytes),
    );
    return verify.unwrapOrThrowCryptoError();
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    // Pure validation: identical math on every backend (Dart decoders are
    // pinned equal to Rust by the api-comparison tests), so no FFI
    // round-trip and no new Rust exports are needed.
    final r = api.normalizePublicKey(publicKey.asBytes);
    if (!r.isOk) return null;
    return r.value;
  }
}
