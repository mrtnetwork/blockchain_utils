import 'dart:typed_data';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/utils.dart';

void _testEqualWithAffinePoint() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generatorSecp256k1);
  final point2 = point1.toAffine();
  assert(point1 == point2 && point2 == point1);
}

void _testInfinityPoint() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curveSecp256k1,
      x: BigInt.zero,
      y: Curves.curveSecp256k1.p,
      z: BigInt.one);
  assert(point1.doublePoint().isInfinity);
}

void _testAffineWithZero() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curveSecp256k1,
      x: BigInt.zero,
      y: BigInt.zero,
      z: BigInt.one);
  final point2 = point1.toAffine();
  assert(point2.isInfinity);
}

void _testWithAffinePoint() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final aff = point1.toAffine();
  final sum = point1 + aff;

  final doublePoint = point1.doublePoint();
  assert(sum == doublePoint);
}

void _testWithAffinePointAndRightAdd() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final aff = point1.toAffine();
  final sum = aff + point1;
  final doublePoint = point1.doublePoint();
  assert(sum == doublePoint);
}

void _testAddWithInfinity() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final p2 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  final sum = p2 + point1;
  assert(sum == point1);
}

void _testMultiplyByZero() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final m = point1 * BigInt.zero;
  assert(m.isInfinity);
}

void _zeroMultyply() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  final m = point1 * BigInt.one;
  assert(m.isInfinity);
}

void _isInfinity() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  assert(point1.isInfinity);
}

void _multyByTwo() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);

  final p2 = Curves.generator256 * BigInt.two;
  final p3 = point1 * BigInt.two;
  assert(p3.x == p2.x);
  assert(p3.y == p2.y);
}

void _doubleWithMul() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final doublePoint = point1.doublePoint();
  final doubleWithMul = point1 * BigInt.two;
  assert(doublePoint == doubleWithMul);
}

void _multiPly() {
  for (int i = 0; i < 5; i++) {
    final mBy = BigInt.from(i + 1) * BigInt.from(i + 1);
    final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
    final point2 = point1.toAffine() * mBy;
    final point3 = point1 * mBy;
    assert(point3.x == point2.x);
    assert(point3.y == point2.y);
    assert(point3 == point2);
  }
}

void _testPreCompute() {
  for (int i = 0; i < 5; i++) {
    final mBy = BigInt.from(i + 1) * BigInt.from(i + 1);
    final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
    final point2 = Curves.generator256 * mBy;
    final point3 = point1 * mBy;
    assert(point3.x == point2.x);
    assert(point3.y == point2.y);
    assert(point3 == point2);
  }
}

void _addScaledPoint() {
  for (int i = 0; i < 5; i++) {
    final mul = BigInt.from(i + 1);
    final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
    final point2 = ProjectiveECCPoint.fromAffine(point1 * mul);
    final point3 = ProjectiveECCPoint.fromAffine(point1 * mul);
    final sum = point2 + point3;
    final m = point1 * (mul * BigInt.two);
    assert(sum == m);
  }
}

void _mullLarge() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final point2 = ProjectiveECCPoint.fromAffine(point1 * BigInt.from(255));
  assert(point1 * BigInt.from(256) == point1 + point2);
}

void _testKeys() {
  final seed = BytesUtils.fromHexString(
      "416ec857ec2501598cdb8b146f764a6be33a23d77ed6d1a01a2b5bae7adc9d2c");
  final secexp = BigintUtils.fromBytes(seed, byteOrder: Endian.big);
  final ECDSAPrivateKey privateKey =
      ECDSAPrivateKey.fromBytes(seed, Curves.generatorSecp256k1);
  assert(privateKey.publicKey.point == Curves.generatorSecp256k1 * secexp);
  final msgDigest = BigInt.zero;
  final sig = privateKey.sign(
      msgDigest,
      RFC6979.generateK(Curves.generatorSecp256k1.order!, secexp,
          () => SHA256(), Uint8List(32)));
  final verify = privateKey.publicKey.verifies(msgDigest, sig);
  assert(verify);
}

void testECDSA() {
  _testKeys();
  _mullLarge();
  _testEqualWithAffinePoint();
  _testInfinityPoint();
  _testAffineWithZero();
  _testWithAffinePoint();
  _testWithAffinePointAndRightAdd();
  _testAddWithInfinity();
  _testMultiplyByZero();
  _zeroMultyply();
  _multyByTwo();
  _isInfinity();
  _doubleWithMul();
  _multiPly();
  _testPreCompute();
  _addScaledPoint();
}
