import 'package:blockchain_utils/crypto/crypto/keys/sr25519/api/src/api.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of sr25519 (Schnorrkel) key derivation/
/// signing/verification/VRF operations.
class NativeSr25519SigningApi implements Sr25519SigningApi {
  final BuSr25519SigningApi api;
  const NativeSr25519SigningApi(this.api);

  @override
  (BuBytes, BuBytes) derivePublic({
    required List<int> publicKey,
    required List<int> chainCode32,
    List<int>? message,
  }) {
    final (pk, chainCode) = api
        .derivePublic(
          publicKey: publicKey,
          chainCode32: chainCode32,
          message: message,
        )
        .unwrapOrThrowCryptoError();
    return (pk, chainCode);
  }

  @override
  (BuBytes, BuBytes) hardDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (sk, chainCode) = api
        .hardDerive(
          seedOrSk: seedOrSk,
          chainCode32: chainCode32,
          message: message,
          fromSeed: fromSeed,
          uniform: uniform,
        )
        .unwrapOrThrowCryptoError();
    return (sk, chainCode);
  }

  @override
  bool isValidPublicKey(List<int> pk32) {
    return api.isValidPublicKey(pk32);
  }

  @override
  bool isValidSecretKey(List<int> sk) {
    return api.isValidSecretKey(sk);
  }

  @override
  BuBytes publicKeyFromSecret(List<int> sk64) {
    return api
        .publicKeyFromSecret(sk64)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes publicKeyFromSeed(List<int> seed32, {bool uniform = false}) {
    return api
        .publicKeyFromSeed(seed32, uniform: uniform)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes sign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    return api
        .sign(
          seedOrSk: seedOrSk,
          message: message,
          fromSeed: fromSeed,
          uniform: uniform,
          nonce64: nonce64,
          context: context,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  (BuBytes, BuBytes) softDerive({
    required List<int> seedOrSk,
    required List<int> chainCode32,
    required List<int> newNonce32,
    List<int>? message,
    bool fromSeed = true,
    bool uniform = false,
  }) {
    final (sk, chainCode) = api
        .softDerive(
          seedOrSk: seedOrSk,
          chainCode32: chainCode32,
          message: message,
          fromSeed: fromSeed,
          uniform: uniform,
          newNonce32: newNonce32,
        )
        .unwrapOrThrowCryptoError();
    return (sk, chainCode);
  }

  @override
  BuBytes toEd25519Bytes(List<int> sk64) {
    return api
        .toEd25519Bytes(sk64)
        .unwrapOrThrowCryptoError();
  }

  @override
  bool verify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    return api
        .verify(
          message: message,
          publicKey: publicKey,
          signature: signature,
          context: context,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes vrfSign({
    required List<int> seedOrSk,
    required List<int> message,
    required List<int> nonce64,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    return api
        .vrfSign(
          message: message,
          context: context,
          nonce64: nonce64,
          seedOrSk: seedOrSk,
          fromSeed: fromSeed,
          kusamaVrf: kusamaVrf,
          uniform: uniform,
          extra: extra,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  bool vrfVerify({
    required List<int> publicKey,
    required List<int> message,
    required List<int> preOut32,
    required List<int> proof64,
    List<int>? context,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    return api
        .vrfVerify(
          message: message,
          publicKey: publicKey,
          context: context,
          extra: extra,
          preOut32: preOut32,
          proof64: proof64,
          kusamaVrf: kusamaVrf,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes dleqProve({
    required List<int> seedOrSk,
    required List<int> inout64,
    required List<int> nonce64,
    List<int>? extra,
    bool fromSeed = true,
    bool uniform = false,
    bool kusamaVrf = true,
  }) {
    return api
        .dleqProve(
          seedOrSk: seedOrSk,
          inout64: inout64,
          nonce64: nonce64,
          fromSeed: fromSeed,
          uniform: uniform,
          kusamaVrf: kusamaVrf,
          extra: extra,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  bool dleqVerify({
    required List<int> publicKey,
    required List<int> inout64,
    required List<int> proof64,
    List<int>? extra,
    bool kusamaVrf = true,
  }) {
    return api
        .dleqVerify(
          publicKey: publicKey,
          inout64: inout64,
          proof64: proof64,
          kusamaVrf: kusamaVrf,
          extra: extra,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes vrfHash({
    required List<int> publicKey,
    required List<int> message,
    List<int>? context,
  }) {
    return api
        .vrfHash(publicKey: publicKey, message: message, context: context)
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes vrfInOut({
    required List<int> seedOrSk,
    required List<int> message,
    bool fromSeed = true,
    bool uniform = false,
    List<int>? context,
  }) {
    return api
        .vrfInOut(
          seedOrSk: seedOrSk,
          message: message,
          context: context,
          fromSeed: fromSeed,
          uniform: uniform,
        )
        .unwrapOrThrowCryptoError();
  }

  @override
  BuBytes secretFromSeed(List<int> seed, {bool uniform = false}) {
    return api
        .secretFromSeed(seed, uniform: uniform)
        .unwrapOrThrowCryptoError();
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
