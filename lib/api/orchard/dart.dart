import 'package:blockchain_utils/api/orchard/api.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// [OrchardApi] pure-Dart backend.
///
/// Every method throws [BuError]: Halo2 proving needs the native
/// backend. Use [NativeOrchardApi] via `blockchainUtils.setRustApi()`
/// instead.
class DartOrchardApi implements OrchardApi {
  /// Creates a pure-Dart Orchard backend; every method throws [BuError].
  const DartOrchardApi();

  static BuError _un(String op) => BuError(DefaultErrorType.unsupported, 'DartOrchardApi.$op: pure-Dart backend has no Orchard prover; '
    'use NativeOrchardApi via blockchainUtils.setRustApi().',
  );

  /// Builds a proving key for [version]; pure-Dart stub always throws [BuError].
  @override
  Object pkNew({required int version}) {
    throw _un('pkNew');
  }

  /// Releases proving-key handle [pk]; pure-Dart stub always throws [BuError].
  @override
  void pkFree(Object pk) {
    throw _un('pkFree');
  }

  /// Proves actions from packed [inputs]/[instances]/[seed] with key [pk],
  /// [version] and [disableCrossAddress]; pure-Dart stub always throws [BuError].
  @override
  BuBytes createProof({
    required Object pk,
    required List<int> inputs,
    required List<int> instances,
    required List<int> seed,
    required int version,
    bool disableCrossAddress = false,
  }) {
    throw _un('createProof');
  }

  /// Verifies [proof] against [instances] with key [pk], [version] and [disableCrossAddress]; pure-Dart stub always throws [BuError].
  @override
  void verifyProof({
    required Object pk,
    required List<int> proof,
    required List<int> instances,
    required int version,
    bool disableCrossAddress = false,
  }) {
    throw _un('verifyProof');
  }
}
