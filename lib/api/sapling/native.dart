import 'package:blockchain_utils/api/sapling/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [SaplingApi] backed by a native (FFI/platform) implementation.
class NativeSaplingApi implements SaplingApi {
  /// Underlying connector backend (Rust Sapling Groth16 core).
  final BuSaplingApi api;

  /// Creates a native Sapling backend over [api].
  const NativeSaplingApi(this.api);

  /// Loads Spend ceremony [params] and returns the params handle; throws [CryptoException] on native failure.
  @override
  Object setSpendParams(List<int> params) {
    return api
        .setSpendParams(params: params)
        .unwrapOrThrowCryptoError();
  }

  /// Loads Output ceremony [params] and returns the params handle; throws [CryptoException] on native failure.
  @override
  Object setOutputParams(List<int> params) {
    return api
        .setOutputParams(params: params)
        .unwrapOrThrowCryptoError();
  }

  /// Releases params [handle].
  @override
  void paramsFree(Object handle) {
    api.paramsFree(handle);
  }

  /// Proves [kind] circuit from [witness] under [handle]; returns proof and public inputs; throws [CryptoException] on native failure.
  @override
  BuSaplingProof prove({
    required Object handle,
    required int kind,
    required List<int> witness,
  }) {
    return api
        .prove(handle: handle, kind: kind, witness: witness)
        .unwrapOrThrowCryptoError();
  }

  /// Verifies [proof] against [inputs] for [kind] under [handle]; throws [CryptoException] on verification or native failure.
  @override
  void verify({
    required Object handle,
    required int kind,
    required List<int> proof,
    required List<int> inputs,
  }) {
    api
        .verify(
          handle: handle,
          kind: kind,
          proof: BuBytes.from(proof),
          inputs: BuBytes.from(inputs),
        )
        .unwrapOrThrowCryptoError();
  }
}
