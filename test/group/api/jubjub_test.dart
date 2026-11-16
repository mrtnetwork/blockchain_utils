import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "jubjubTest", onNative: jubjub);
}

void jubjub(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = JubJubCurveTest.generate(apis: [api.jubjub]);
  test.run();
}

class JubJubCurveTest extends CurveTest<JubJubCurveApi> {
  JubJubCurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });

  @override
  List<BuBytes> buildPoints() {
    // The official generator has full-curve order 8r, so raw multBase
    // outputs carry a low-order component on which scalar laws fail.
    // (x8 is a permutation of prime-order groups, so this is a no-op in
    // effect for curves that don't need it.)
    final api = DartJubJubCurveApi();
    return super.buildPoints().map((p) {
      return api.clearCofactor(p) ?? api.identity();
    }).toList();
  }
  factory JubJubCurveTest.generate({List<JubJubCurveApi> apis = const []}) {
    assert(apis.isNotEmpty);

    final generator = RandomScalarGeneratorGenerator(
      n: BigInt.parse(
        "6554484396890773809930967563523245729705921265872317281365359162392183254199",
      ),
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),

      endian: Endian.little,
      validatePoint: (data) {
        try {
          JubJubPoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartJubJubCurveApi(),
      pointLengthBytes: 32,
    );
    return JubJubCurveTest(
      apis: [DartJubJubCurveApi(), ...apis],
      randomGenerator: generator,

      name: "JubJub",
    );
  }
}
