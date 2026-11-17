import 'package:blockchain_utils/api/sapling/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [SaplingApi] pure-Dart backend.
///
/// Every method throws [BuError]: Groth16 proving needs the
/// ceremony parameters and native prover. Use [NativeSaplingApi] via
/// `blockchainUtils.setRustApi()` instead.
class DartSaplingApi implements SaplingApi {
  /// Creates a pure-Dart Sapling backend; every method throws [BuError].
  const DartSaplingApi();

  static BuError _un(String op) => BuError(
    DefaultErrorType.unsupported,
    'DartSaplingApi.$op: pure-Dart backend has no Sapling prover; '
    'use NativeSaplingApi via blockchainUtils.setRustApi().',
  );

  /// Loads Spend ceremony [params] and returns a handle; pure-Dart stub always throws [BuError].
  @override
  Object setSpendParams(List<int> params) {
    throw _un('setSpendParams');
  }

  /// Loads Output ceremony [params] and returns a handle; pure-Dart stub always throws [BuError].
  @override
  Object setOutputParams(List<int> params) {
    throw _un('setOutputParams');
  }

  /// Releases params [handle]; pure-Dart stub always throws [BuError].
  @override
  void paramsFree(Object handle) {
    throw _un('paramsFree');
  }

  /// Proves [kind] circuit from [witness] under [handle]; pure-Dart stub always throws [BuError].
  @override
  BuSaplingProof prove({
    required Object handle,
    required int kind,
    required List<int> witness,
  }) {
    throw _un('prove');
  }

  /// Verifies [proof] against [inputs] for [kind] under [handle]; pure-Dart stub always throws [BuError].
  @override
  void verify({
    required Object handle,
    required int kind,
    required List<int> proof,
    required List<int> inputs,
  }) {
    throw _un('verify');
  }
}
