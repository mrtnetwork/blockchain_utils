import 'package:blockchain_utils/crypto/crypto/keys/ml_dsa/api/src/api.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of ML-DSA key generation/signing/verification.
class NativeMLDSASigningApi implements MLDSASigningApi {
  final BuMlDsaSigningApi api;
  const NativeMLDSASigningApi(this.api);

  @override
  (BuBytes, BuBytes) keygen({required int level, List<int>? seed}) {
    // Key material is caller-supplied: fill from the platform RNG when
    // omitted so the native backend never depends on Rust-side generation.
    final s = (seed ?? QuickCrypto.generateRandom(length: 32)).asBytes;
    final (pk, sk) =
        api.keygen(level: level, seed: s).unwrapOrThrowCryptoError();
    return (pk.asBytes, sk.asBytes);
  }

  @override
  BuBytes publicKeyFromSecret({int? level, required List<int> sk}) {
    final pk =
        api
            .publicKeyFromSecret(level: level, sk: sk.asBytes)
            .unwrapOrThrowCryptoError();
    return pk.asBytes;
  }

  @override
  BuBytes sign({
    int? level,
    required List<int> sk,
    required List<int> message,
    List<int>? context,
    List<int>? rnd,
  }) {
    // FIPS `rnd` is caller-supplied: fill from the platform RNG when
    // omitted so the native backend never depends on Rust-side generation.
    final r = (rnd ?? QuickCrypto.generateRandom(length: 32)).asBytes;
    final pk =
        api
            .sign(
              level: level,
              sk: sk.asBytes,
              message: message.asBytes,
              rnd: r,
              context: context?.asBytes,
            )
            .unwrapOrThrowCryptoError();
    return pk.asBytes;
  }

  @override
  bool verify({
    int? level,
    required List<int> pk,
    required List<int> message,
    required List<int> signature,
    List<int>? context,
  }) {
    return api
        .verify(
          level: level,
          pk: pk.asBytes,
          message: message.asBytes,
          signature: signature.asBytes,
          context: context?.asBytes,
        )
        .unwrapOrThrowCryptoError();
  }
}
