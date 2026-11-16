import 'package:blockchain_utils/api/rng/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [RngApi] backed by a native (FFI/platform) implementation.
class NativeRngApi implements RngApi {
  /// Underlying connector backend (platform ChaCha20 RNG core).
  final BuRngApi api;

  /// Creates a native RNG backend over [api].
  const NativeRngApi(this.api);

  /// Seeds the global RNG with 32-byte [seed32]; throws [CryptoException] on native failure or if already seeded.
  @override
  void seed({required List<int> seed32}) {
    api.seed(seed32: seed32).unwrapOrThrowCryptoError();
  }

  /// Whether the global RNG was seeded.
  @override
  bool get isSeeded => api.isSeeded;

  /// Fills [length] random bytes and returns them; throws [CryptoException] on native failure.
  @override
  BuBytes fill({required int length}) {
    return api.fill(length: length).unwrapOrThrowCryptoError();
  }
}
