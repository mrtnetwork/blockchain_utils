import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

/// P-256 group order (matches [Secp256r1FrConst.modulusLimbs];
/// pinned by the n*G == identity tests).
final BigInt _r1Order = BigInt.parse(
  'FFFFFFFF00000000FFFFFFFFFFFFFFFFBCE6FAADA7179E84F3B9CAC2FC632551',
  radix: 16,
);

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "Secp256r1", onNative: secp256r1);
}

void secp256r1(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = Secp256r1CurveTest.generate(apis: [api.secp256r1]);
  test.run();
}

class Secp256r1CurveTest extends CurveTest<Secp256r1CurveApi> {
  Secp256r1CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory Secp256r1CurveTest.generate({
    List<Secp256r1CurveApi> apis = const [],
  }) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: _r1Order,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.big,
      validatePoint: (data) {
        try {
          Secp256r1Point.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: WeierstrassSecp256r1CurveApi(),
      pointLengthBytes: 33,
    );
    return Secp256r1CurveTest(
      apis: [WeierstrassSecp256r1CurveApi(), ...apis],
      randomGenerator: generator,
      name: "Secp256r1",
    );
  }

  @override
  BuBytes? get zeroScalar => BuBytes(List.filled(32, 0));

  @override
  BuBytes? get zeroPoint => BuBytes(List.filled(33, 0));
}
