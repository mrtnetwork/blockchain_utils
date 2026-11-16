import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/ristretto/api/src/dart.dart';
import 'ed25519_test.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(
    () {},
    "RistrettoCurveTest",
    onNative: ristretto,
  );
}

void ristretto(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = RistrettoCurveTest.generate(apis: [api.ristretto]);
  test.run();
}

class RistrettoCurveTest extends CurveTest<RistrettoCurveApi> {
  RistrettoCurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory RistrettoCurveTest.generate({
    List<RistrettoCurveApi> apis = const [],
  }) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: ED25519CurveTest.edOrder,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),

      endian: Endian.little,
      validatePoint: (data) {
        try {
          RistrettoPoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartRistrettoCurveApi(),
      pointLengthBytes: 32,
    );
    return RistrettoCurveTest(
      apis: [DartRistrettoCurveApi(), ...apis],
      randomGenerator: generator,

      name: "Ristretto",
    );
  }
}
