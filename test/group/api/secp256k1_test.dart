import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import '../../utils.dart';
import 'utils.dart';

/// secp256k1 group order (matches [Secp256k1FrConst.modulusLimbs];
/// pinned by the n*G == identity tests).
final BigInt _k1Order = BigInt.parse(
  'FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFEBAAEDCE6AF48A03BBFD25E8CD0364141',
  radix: 16,
);

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "Secp256k1", onNative: secp256k1);
}

void secp256k1(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = Secp256k1CurveTest.generate(apis: [api.secp256k1]);
  test.run();
}

class Secp256k1CurveTest extends CurveTest<Secp256k1CurveApi> {
  Secp256k1CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory Secp256k1CurveTest.generate({
    List<Secp256k1CurveApi> apis = const [],
  }) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: _k1Order,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),

      endian: Endian.big,
      validatePoint: (data) {
        try {
          Secp256k1Point.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: WeierstrassSecp256k1CurveApi(),
      pointLengthBytes: 33,
    );
    return Secp256k1CurveTest(
      apis: [WeierstrassSecp256k1CurveApi(), ...apis],
      randomGenerator: generator,

      name: "Secp256k1",
    );
  }

  @override
  BuBytes? get zeroScalar => BuBytes(List.filled(32, 0));

  @override
  BuBytes? get zeroPoint => BuBytes(List.filled(33, 0));
}
