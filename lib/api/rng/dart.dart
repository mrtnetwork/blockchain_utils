import 'package:blockchain_utils/api/rng/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [RngApi] pure-Dart backend.
///
/// Every method throws [BuError]: global platform randomness
/// lives behind the native backend. Use [NativeRngApi] via
/// `blockchainUtils.setRustApi()` instead.
class DartRngApi implements RngApi {
  /// Creates a pure-Dart RNG backend; every method throws [BuError].
  const DartRngApi();

  static BuError _un(String op) => BuError(
    DefaultErrorType.unsupported,
    'DartRngApi.$op: pure-Dart backend has no global RNG; '
    'use NativeRngApi via blockchainUtils.setRustApi().',
  );

  /// Seeds the global RNG with 32-byte [seed32]; pure-Dart stub always throws [BuError].
  @override
  void seed({required List<int> seed32}) {
    throw _un('seed');
  }

  /// Whether the global RNG was seeded; pure-Dart stub always throws [BuError].
  @override
  bool get isSeeded {
    throw _un('isSeeded');
  }

  /// Fills [length] random bytes and returns them; pure-Dart stub always throws [BuError].
  @override
  BuBytes fill({required int length}) {
    throw _un('fill');
  }
}
