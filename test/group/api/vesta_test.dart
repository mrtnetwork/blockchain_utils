import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "Vesta", onNative: vesta);
}

void vesta(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = VestaCurveTest.generate(apis: [api.vesta]);
  test.run();
}

class VestaCurveTest extends CurveTest<VestaCurveApi> {
  VestaCurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory VestaCurveTest.generate({List<VestaCurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: BigInt.parse(
        "0x40000000000000000000000000000000224698fc094cf91b992d30ed00000001",
      ),
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),

      endian: Endian.little,
      validatePoint: (data) {
        try {
          VestaPoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartVestaCurveApi(),
      pointLengthBytes: 32,
    );
    return VestaCurveTest(
      apis: [DartVestaCurveApi(), ...apis],
      randomGenerator: generator,

      name: "Vesta",
    );
  }
}
