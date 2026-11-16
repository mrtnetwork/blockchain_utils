import 'package:blockchain_utils/api/orchard/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [OrchardApi] backed by a native (FFI/platform) implementation.
class NativeOrchardApi implements OrchardApi {
  /// Underlying connector backend (Rust Orchard Halo2 core).
  final BuOrchardApi api;

  /// Creates a native Orchard backend over [api].
  const NativeOrchardApi(this.api);

  static BuBytes _as(List<int> x) => x is BuBytes ? x : BuBytes.from(x);

  /// Builds a proving key for [version] and returns its handle; throws [CryptoException] on native failure.
  @override
  Object pkNew({required int version}) {
    return api.pkNew(version: version).unwrapOrThrowCryptoError();
  }

  /// Releases proving-key handle [pk].
  @override
  void pkFree(Object pk) {
    api.pkFree(pk);
  }

  /// Proves actions from packed [inputs] with key [pk], [version] and [disableCrossAddress]; returns proof bytes; throws [CryptoException] on native failure.
  @override
  BuBytes createProof({
    required Object pk,
    required List<int> inputs,
    required List<int> instances,
    required List<int> seed,
    required int version,
    bool disableCrossAddress = false,
  }) {
    return api
        .createProof(
          pk: pk,
          inputs: inputs,
          instances: instances,
          seed: seed,
          version: version,
          disableCrossAddress: disableCrossAddress,
        )
        .unwrapOrThrowCryptoError();
  }

  /// Verifies [proof] against [instances] with key [pk], [version] and [disableCrossAddress]; throws [CryptoException] on verification or native failure.
  @override
  void verifyProof({
    required Object pk,
    required List<int> proof,
    required List<int> instances,
    required int version,
    bool disableCrossAddress = false,
  }) {
    api
        .verifyProof(
          pk: pk,
          proof: _as(proof),
          instances: _as(instances),
          version: version,
          disableCrossAddress: disableCrossAddress,
        )
        .unwrapOrThrowCryptoError();
  }
}
