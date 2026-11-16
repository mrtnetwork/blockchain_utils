import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "Pallas", onNative: pallas);
}

void pallas(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = PallasCurveTest.generate(apis: [api.pallas]);
  test.run();
}

class PallasCurveTest extends CurveTest<PallasCurveApi> {
  PallasCurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory PallasCurveTest.generate({List<PallasCurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: BigInt.parse(
        "0x40000000000000000000000000000000224698fc0994a8dd8c46eb2100000001",
      ),
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),

      endian: Endian.little,
      validatePoint: (data) {
        try {
          PallasPoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartPallasCurveApi(),
      pointLengthBytes: 32,
    );
    return PallasCurveTest(
      apis: [DartPallasCurveApi(), ...apis],
      randomGenerator: generator,

      name: "Pallas",
    );
  }
}
