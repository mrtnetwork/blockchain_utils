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
  BlockchainUtilsTestApi.runTest(() {}, "G1", onNative: g1);
}

void g1(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = G1CurveTest.generate(apis: [api.g1]);
  test.run();
}

class G1CurveTest extends CurveTest<G1ProjectiveCurveApi> {
  G1CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory G1CurveTest.generate({List<G1ProjectiveCurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: _blsFrOrder,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.big,
      validatePoint: (data) {
        try {
          G1AffinePoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartG1ProjectiveCurveApi(),
      pointLengthBytes: 48,
    );
    return G1CurveTest(
      apis: [DartG1ProjectiveCurveApi(), ...apis],
      randomGenerator: generator,
      name: "G1",
    );
  }
}
