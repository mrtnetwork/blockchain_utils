// L1 (BU_BACKEND=dart) + L3 (BU_BACKEND=ffi, default) entry: full suite on
// the Dart VM. Backend via environment (see test/test_backend.dart):
//   BU_BACKEND=dart dart test test/one_shot_test.dart
//   BU_BACKEND=ffi [BU_LIB_PATH=...] [BU_BUILD=ffi] dart test test/one_shot_test.dart
import 'one_shot_suite.dart';
import 'utils.dart';

void main() async {
  final backend = BuTestBackend.parse(testEnvVar('BU_BACKEND'));
  // Builds the FFI library with cargo first when BU_BUILD=ffi|all|1.
  await BlockchainUtilsTestApi.ensureBackend();
  await runOneShotSuite(rustOnly: backend != BuTestBackend.dart);
}
