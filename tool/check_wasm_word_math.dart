/// WASM word-math backend check (NOT a `package:test` test: it must be
/// compiled with an explicit `-D` flag, which `dart test` cannot forward).
///
/// Verifies that a dart2wasm build compiled with
/// `-DBLOCKCHAIN_UTILS_NATIVE_MATH=true` actually runs the native 64-bit
/// word math (and that the native math is exact on wasm64).
///
/// CI (`dart-web-wasm` job):
/// ```sh
/// dart compile wasm tool/check_wasm_word_math.dart -o /tmp/wasm-math/check.wasm \
///   --define=BLOCKCHAIN_UTILS_NATIVE_MATH=true
/// # serve /tmp/wasm-math over HTTP, load check.html in headless Chrome,
/// # and expect `WASM-WORD-MATH-OK` in the dumped DOM.
/// ```
///
/// Run locally the same way. Without the flag the const check below fails
/// by design (proving the gate discriminates); on dart2js the native math
/// would be wrong, which is why the flag exists at all.
library;

import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/word_math/word_math.dart'
    as word_math;

void main() {
  final failures = <String>[];
  void check(bool ok, String name) {
    if (!ok) failures.add(name);
  }

  // Uint64 stores two 32-bit limbs: fromParts(high32, low32).
  Uint64 u(int hi, int lo) => Uint64.fromParts(hi, lo);
  bool eq(Uint64 v, int hi, int lo) => v.hi == hi && v.lo == lo;

  try {
    // 1. The native backend must actually be switched on by the build flag.
    check(
      word_math.useNativeWordMath == true,
      'useNativeWordMath is enabled '
      '(compile with -DBLOCKCHAIN_UTILS_NATIVE_MATH=true)',
    );

    // 2. Exactness past double precision (2^53): wrong on dart2js-style
    // doubles, exact with real 64-bit ints.
    // (2^64 - 1) * (2^64 - 1) = 2^128 - 2^65 + 1.
    final r1 = word_math.widenMulImpl(
      u(0xFFFFFFFF, 0xFFFFFFFF),
      u(0xFFFFFFFF, 0xFFFFFFFF),
    );
    check(eq(r1.$1, 0xFFFFFFFF, 0xFFFFFFFE), 'max*max hi');
    check(eq(r1.$2, 0x00000000, 0x00000001), 'max*max lo');

    // 0x123456789ABCDEF0 * 0x0FEDCBA987654321
    //   = 0x0121FA00AD77D742_2236D88FE5618CF0.
    final r2 = word_math.widenMulImpl(
      u(0x12345678, 0x9ABCDEF0),
      u(0x0FEDCBA9, 0x87654321),
    );
    check(eq(r2.$1, 0x0121FA00, 0xAD77D742), 'rnd hi');
    check(eq(r2.$2, 0x2236D88F, 0xE5618CF0), 'rnd lo');

    // (2^64 - 1) / 3 = 0x5555...5555 rem 0.
    final d1 = word_math.divModImpl(u(0xFFFFFFFF, 0xFFFFFFFF), u(0, 3));
    check(eq(d1.quotient, 0x55555555, 0x55555555), 'div q');
    check(eq(d1.remainder, 0, 0), 'div r');

    // (2^64 - 2) / 3 = 0x5555...5554 rem 2.
    final d2 = word_math.divModImpl(u(0xFFFFFFFF, 0xFFFFFFFE), u(0, 3));
    check(eq(d2.quotient, 0x55555555, 0x55555554), 'div2 q');
    check(eq(d2.remainder, 0, 2), 'div2 r');

    // 2^63 / 3 = 0x2AAA...AAAA rem 2 (high bit set dividend).
    final d3 = word_math.divModImpl(u(0x80000000, 0), u(0, 3));
    check(eq(d3.quotient, 0x2AAAAAAA, 0xAAAAAAAA), 'div3 q');
    check(eq(d3.remainder, 0, 2), 'div3 r');

    // 3. Division by zero must throw (not crash / return garbage).
    var threw = false;
    try {
      word_math.divModImpl(u(0, 1), u(0, 0));
    } catch (_) {
      threw = true;
    }
    check(threw, 'div-by-zero throws');
  } catch (e) {
    failures.add('unexpected throw: $e');
  }

  final document = globalContext.getProperty('document'.toJS) as JSObject;
  final body = document.getProperty('body'.toJS) as JSObject;
  body.setProperty(
    'textContent'.toJS,
    (failures.isEmpty
            ? 'WASM-WORD-MATH-OK'
            : 'WASM-WORD-MATH-FAIL: ${failures.join('; ')}')
        .toJS,
  );
}
