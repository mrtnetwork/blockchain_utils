// Full suite in Chrome (dart2wasm only) against the pure-Dart backend with
// the native 64-bit word-math path forced on (`useNativeWordMath = true`
// semantics). `dart test` cannot forward `--define` to browser
// compilations, so the compile-time BLOCKCHAIN_UTILS_NATIVE_MATH flag is
// unreachable here; the native path is forced at runtime instead via
// `debugForceNativeWordMath`. Small vectors for speed.
//
//   CHROME_EXECUTABLE=<wrapper> dart test -p chrome -c dart2wasm test/one_shot_browser_dart_native_math_test.dart
@TestOn('browser')
@Tags(['wasm'])
library;

import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/word_math/word_math.dart'
    as word_math;
import 'package:test/test.dart';

import 'one_shot_suite.dart';
import 'utils.dart';

void main() async {
  word_math.debugForceNativeWordMath = true;
  test('native word math forced on and exact (dart2wasm only)', () {
    // Guard: proves the override took effect AND the platform math is
    // exact. Fails loudly on dart2js (doubles), where the native path is
    // wrong — this entry must only run under `-c dart2wasm`.
    // (2^64 - 1) * (2^64 - 1) = 2^128 - 2^65 + 1.
    final r = word_math.widenMulImpl(
      Uint64.fromParts(0xFFFFFFFF, 0xFFFFFFFF),
      Uint64.fromParts(0xFFFFFFFF, 0xFFFFFFFF),
    );
    expect(r.$1.hi, 0xFFFFFFFF);
    expect(r.$1.lo, 0xFFFFFFFE);
    expect(r.$2.hi, 0x00000000);
    expect(r.$2.lo, 0x00000001);
  });
  BlockchainUtilsTestApi.configure(
    const BuTestConfig(
      backend: BuTestBackend.dart,
      vectorTake: 3,
      fuzzIterations: 200,
      generatorTotal: 2,
    ),
  );
  await runOneShotSuite(rustOnly: false);
}
