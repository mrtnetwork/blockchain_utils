import 'package:blockchain_utils/crypto/crypto/keys/reddsa/redjubjub/api/src/api.dart';
import 'package:blockchain_utils/exception/exception/core_errors.dart';
import 'package:blockchain_utils/crypto/crypto/keys/reddsa/types/types.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of RedJubjub (Zcash Sapling RedDSA) signing/verification.
class NativeRedJubJubSigningApi implements RedJubJubSigningApi {
  final BuReddsaSigningApi api;
  const NativeRedJubJubSigningApi(this.api);

  static const String _tag = 'RedJubJubSigningApi';

  BuReddsaDomain _domain(RedJubJubVariant v) {
    return switch (v) {
      RedJubJubVariant.spendAuth => BuReddsaDomain.jubjubAuth,
      RedJubJubVariant.binding => BuReddsaDomain.jubjubBinding,
    };
  }

  @override
  BuBytes publicKey({
    required List<int> sk,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    return api
        .publicKey(domain: _domain(variant), sk: sk.asBytes)
        .unwrapOrThrowCryptoError()
        .asBytes;
  }

  @override
  ReddsaSignature sign({
    required List<int> sk,
    required List<int> message,
    List<int>? rand80,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    if (rand80 != null && rand80.length != 80) {
      throw CoreErrors.cryptoFailed(
        '$_tag.sign',
        reason: 'rand80 must be 80 bytes, got ${rand80.length}',
      );
    }
    // Signing randomness is caller-supplied: fill from the platform RNG
    // when omitted so the native backend never depends on Rust-side
    // generation (which is deterministic unless the host seeded it).
    final rand = (rand80 ?? QuickCrypto.generateRandom(length: 80)).asBytes;
    final sig =
        api
            .sign(
              domain: _domain(variant),
              sk: sk.asBytes,
              message: message.asBytes,
              rand80: rand,
            )
            .unwrapOrThrowCryptoError();

    return ReddsaSignature.fromBytes(sig);
  }

  @override
  bool verify({
    required List<int> pk,
    required List<int> message,
    required ReddsaSignature signature,
    RedJubJubVariant variant = RedJubJubVariant.spendAuth,
  }) {
    return api
        .verify(
          domain: _domain(variant),
          pk: pk.asBytes,
          message: message.asBytes,
          signature: signature.toBytes(),
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes? normalizePublicKey(List<int> publicKey) {
    // Pure validation: identical math on every backend (Dart decoders are
    // pinned equal to Rust by the api-comparison tests), so no FFI
    // round-trip and no new Rust exports are needed.
    final r = api.normalizeJubjubPublicKey(publicKey.asBytes);
    if (!r.isOk) return null;
    return r.value;
  }
}
