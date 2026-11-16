import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';
import 'secp256r1_test.dart';

void main() {
  BlockchainUtilsTestApi.runTest(
    () {},
    "Secp256r1Weierstrass",
    onNative: secp256r1Weierstrass,
  );
}

List<int> _be(BigInt v, int length) {
  final out = List<int>.filled(length, 0);
  var x = v;
  for (var i = length - 1; i >= 0; i--) {
    out[i] = (x & BigInt.from(0xff)).toInt();
    x >>= 8;
  }
  return out;
}

void secp256r1Weierstrass(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final suite = Secp256r1CurveTest.generate(
    apis: [api.secp256r1, WeierstrassSecp256r1CurveApi()],
  );
  suite.run();

  test("scReduce 32 bytes only, field-internal (no BigInt)", () {
    final w = WeierstrassSecp256r1CurveApi();
    final n = BigInt.parse(
      'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
      radix: 16,
    );
    // 32-byte values reduce mod n, including oversized ones.
    expect(w.scReduce(_be(n, 32)).toList(), List.filled(32, 0));
    expect(
      w.scReduce(_be(n + BigInt.from(5), 32)).toList(),
      _be(BigInt.from(5), 32),
    );
    // Anything else besides 32 bytes throws: empty, short, overlong.
    for (final len in [0, 1, 31, 33, 64, 100]) {
      expect(
        () => w.scReduce(List.filled(len, 1)),
        throwsA(anything),
        reason: 'len=$len',
      );
    }
  });
}
