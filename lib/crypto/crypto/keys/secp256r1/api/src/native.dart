import 'package:blockchain_utils/crypto/crypto/keys/secp256r1/api/src/api.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/helper/helper.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Native (FFI) implementation of secp256r1 signing/verification.
class NativeSecp256r1SigningApi implements Secp256r1SigningApi {
  final BuSecp256r1SigningApi api;
  const NativeSecp256r1SigningApi(this.api);

  @override
  IECDSASignature sign({
    required List<int> sk,
    required List<int> publicKey,
    required List<int> digest,
    List<int>? extraEntropy,
  }) {
    final signature = api
        .signEcdsa(
          BuBytes.unsafe(sk),
          BuSecp256r1SignParams(
            digest: digest.asBytes,
            extraEntropy: extraEntropy?.asBytes,
          ),
        )
        .unwrapOrThrowCryptoError();
    return IECDSASignature(
      r: signature.r,
      s: signature.s,
      recoveryId: signature.recoveryId,
    );
  }

  @override
  bool verify({
    required List<int> digest,
    required IECDSASignature signature,
    required List<int> publicKey,
  }) {
    final result = api
        .verifyEcdsa(
          pk: publicKey.asBytes,
          signature: BuEcdsaSignature(
            r: signature.r,
            s: signature.s,
            recoveryId: signature.recoveryId,
          ),
          digest: digest.asBytes,
        )
        .unwrapOrThrowCryptoError();
    return result;
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
