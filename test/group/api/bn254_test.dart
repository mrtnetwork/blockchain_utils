import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';
import 'utils.dart';

// py_ecc oracle vectors (see blockchain-utils/tests/vectors/bn254_*.hex,
// generated from py_ecc.bn128).
const _orderR =
    '30644e72e131a029b85045b68181585d2833e84879b9709143e1f593f0000001';
const _s1 = '000123456789abcdef0123456789abcdef0123456789abcdef0123456789abcd';

void main() {
  BlockchainUtilsTestApi.runTest(() {}, 'Bn254', onNative: bn254);
}

void bn254(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 2));
  QuickCrypto.setupPRNG(rng);
  // Dart-vs-Rust: every CurveTest op runs on both backends and must agree.
  Bn254G1CurveTest.generate(apis: [DartBn254G1CurveApi(), api.bn254G1]).run();
  Bn254G2CurveTest.generate(apis: [DartBn254G2CurveApi(), api.bn254G2]).run();

  group('Bn254 vectors (py_ecc)', () {
    // Both backends must match the py_ecc oracle vectors.
    final dartG1 = DartBn254G1CurveApi();
    final dartG2 = DartBn254G2CurveApi();
    test('G1 generator == py_ecc', () {
      expect(api.bn254G1.generator().toHex(), _g1);
      expect(dartG1.generator().toHex(), _g1);
    });
    test('G2 generator == py_ecc', () {
      expect(api.bn254G2.generator().toHex(), _g2);
      expect(dartG2.generator().toHex(), _g2);
    });
    test('G1 s1*G == py_ecc', () {
      final s = BytesUtils.fromHexString(_s1);
      expect(api.bn254G1.multBase(s).toHex(), _s1g1);
      expect(dartG1.multBase(s).toHex(), _s1g1);
    });
    test('G2 s1*G == py_ecc', () {
      final s = BytesUtils.fromHexString(_s1);
      expect(api.bn254G2.multBase(s).toHex(), _s1g2);
      expect(dartG2.multBase(s).toHex(), _s1g2);
    });
  });
}

class Bn254G1CurveTest extends CurveTest<Bn254G1CurveApi> {
  Bn254G1CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory Bn254G1CurveTest.generate({List<Bn254G1CurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final ref = apis.first;
    final one = BigInt.one.toBytes(length: 32, byteOrder: Endian.big);
    final generator = RandomScalarGeneratorGenerator(
      n: BigInt.parse('0x$_orderR'),
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.big,
      validatePoint: (data) {
        try {
          ref.mult(one, data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: ref,
      pointLengthBytes: 64,
    );
    return Bn254G1CurveTest(
      apis: apis,
      randomGenerator: generator,
      name: 'Bn254G1',
    );
  }
}

class Bn254G2CurveTest extends CurveTest<Bn254G2CurveApi> {
  Bn254G2CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  factory Bn254G2CurveTest.generate({List<Bn254G2CurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final ref = apis.first;
    final one = BigInt.one.toBytes(length: 32, byteOrder: Endian.big);
    final generator = RandomScalarGeneratorGenerator(
      n: BigInt.parse('0x$_orderR'),
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.big,
      validatePoint: (data) {
        try {
          ref.mult(one, data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: ref,
      pointLengthBytes: 128,
    );
    return Bn254G2CurveTest(
      apis: apis,
      randomGenerator: generator,
      name: 'Bn254G2',
    );
  }
}

const _g1 =
    '0000000000000000000000000000000000000000000000000000000000000001'
    '0000000000000000000000000000000000000000000000000000000000000002';
const _g2 =
    '198e9393920d483a7260bfb731fb5d25f1aa493335a9e71297e485b7aef312c2'
    '1800deef121f1e76426a00665e5c4479674322d4f75edadd46debd5cd992f6ed'
    '090689d0585ff075ec9e99ad690c3395bc4b313370b38ef355acdadcd122975b'
    '12c85ea5db8c6deb4aab71808dcb408fe3d1e7690c43d37b4ce6cc0166fa7daa';
const _s1g1 =
    '06ac4ca13cda48220b0efc93816ff826ab7232ce292a5661fa73d067be0756b7'
    '2ba7df81ab4a129aa7dc74d9f038d3c297c4b832c45fa6a796954607f0fd3f32';
const _s1g2 =
    '160223dfca8d574b151d294df83ac3026d084c7613eb8fa3a058c3d15e9d2088'
    '256e1910f583945b7ddd3779344b43be52c460b669adc51149811f2aa925afd1'
    '223118d8edecd8c6e83bb57cd836821d1e7b71542d6002101cd9f907e41cddaf'
    '237c3f79ed797b98f2a3646ebb0ef0054fc619a1097c795a85d0c4fcad231a72';
