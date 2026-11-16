import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// Global ChaCha20 RNG backend interface (seed-once, process-wide).
///
/// Backs proving randomness and any other caller needing platform randomness
/// through `blockchainUtils.api` instead of reaching into the connector.
abstract interface class RngApi {
  /// Seed the global RNG with exactly 32 bytes. Throws if already seeded.
  void seed({required List<int> seed32});

  /// True when the global RNG was seeded.
  bool get isSeeded;

  /// Fill [length] bytes from the global RNG.
  BuBytes fill({required int length});
}
