import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

/// BLS12-381 scalar field order (Fr), big-endian 32-byte scalars.
final BigInt _blsFrOrder = BigInt.parse(
  '73eda753299d7d483339d80809a1d80553bda402fffe5bfeffffffff00000001',
  radix: 16,
);

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "G2", onNative: g2);
}

void g2(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = G2CurveTest.generate(apis: [api.g2]);
  test.run();
}

class G2CurveTest extends CurveTest<G2ProjectiveCurveApi> {
  G2CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory G2CurveTest.generate({List<G2ProjectiveCurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: _blsFrOrder,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.big,
      validatePoint: (data) {
        try {
          G2AffinePoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartG2ProjectiveCurveApi(),
      pointLengthBytes: 96,
    );
    return G2CurveTest(
      apis: [DartG2ProjectiveCurveApi(), ...apis],
      randomGenerator: generator,
      name: "G2",
    );
  }
}
