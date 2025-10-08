import 'dart:typed_data';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/ecdsa/private_key.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/ec_projective_point.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/rfc6979/rfc6979.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:test/test.dart';

void _testEqualWithAffinePoint() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generatorSecp256k1);
  final point2 = point1.toAffine();
  expect(point1.toAffine() == point2 && point2 == point1.toAffine(), true);
}

void _testInfinityPoint() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curveSecp256k1,
      x: BigInt.zero,
      y: Curves.curveSecp256k1.p,
      z: BigInt.one);
  expect(point1.doublePoint().isInfinity, true);
}

void _testAffineWithZero() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curveSecp256k1,
      x: BigInt.zero,
      y: BigInt.zero,
      z: BigInt.one);
  final point2 = point1.toAffine();
  expect(point2.isInfinity, true);
}

void _testWithAffinePoint() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final aff = point1.toAffine();
  final sum = point1 + ProjectiveECCPoint.fromAffine(aff);

  final doublePoint = point1.doublePoint();
  expect(sum, doublePoint);
}

void _testWithAffinePointAndRightAdd() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final aff = point1.toAffine();
  final sum = aff + point1.toAffine();
  final doublePoint = point1.doublePoint();
  expect(sum, doublePoint);
}

void _testAddWithInfinity() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final p2 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  final sum = p2 + point1;
  expect(sum, point1);
}

void _testMultiplyByZero() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final m = point1 * BigInt.zero;
  expect(m.isInfinity, true);
}

void _zeroMultyply() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  final m = point1 * BigInt.one;
  expect(m.isInfinity, true);
}

void _isInfinity() {
  final point1 = ProjectiveECCPoint(
      curve: Curves.curve256, x: BigInt.zero, y: BigInt.zero, z: BigInt.one);
  expect(point1.isInfinity, true);
}

void _multyByTwo() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);

  final p2 = Curves.generator256 * BigInt.two;
  final p3 = point1 * BigInt.two;
  expect(p3.x, p2.x);
  expect(p3.y, p2.y);
}

void _doubleWithMul() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final doublePoint = point1.doublePoint();
  final doubleWithMul = point1 * BigInt.two;
  expect(doublePoint, doubleWithMul);
}

void _multiPly() {
  for (int i = 0; i < 5; i++) {
    final mBy = BigInt.from(i + 1) * BigInt.from(i + 1);
    final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
    final point2 = point1.toAffine() * mBy;
    final point3 = point1 * mBy;
    expect(point3.x, point2.x);
    expect(point3.y, point2.y);
    expect(point3, point2);
  }
}

void _testPreCompute() {
  for (int i = 0; i < 5; i++) {
    final mBy = BigInt.from(i + 1) * BigInt.from(i + 1);
    final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
    final point2 = Curves.generator256 * mBy;
    final point3 = point1 * mBy;
    expect(point3.x, point2.x);
    expect(point3.y, point2.y);
    expect(point3, point2);
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
    expect(sum, m);
  }
}

void _mullLarge() {
  final point1 = ProjectiveECCPoint.fromAffine(Curves.generator256);
  final point2 = ProjectiveECCPoint.fromAffine(point1 * BigInt.from(255));
  expect(point1 * BigInt.from(256), point1 + point2);
}

void _testKeys() {
  final seed = BytesUtils.fromHexString(
      "416ec857ec2501598cdb8b146f764a6be33a23d77ed6d1a01a2b5bae7adc9d2c");
  final secexp = BigintUtils.fromBytes(seed, byteOrder: Endian.big);
  final ECDSAPrivateKey privateKey =
      ECDSAPrivateKey.fromBytes(seed, Curves.generatorSecp256k1);
  expect(privateKey.publicKey.point, Curves.generatorSecp256k1 * secexp);
  final msgDigest = BigInt.zero;
  final sig = privateKey.sign(
      msgDigest,
      RFC6979.generateK(
          order: Curves.generatorSecp256k1.order!,
          secexp: secexp,
          hashFunc: () => SHA256(),
          data: Uint8List(32)));

  final verify = privateKey.publicKey.verifies(msgDigest, sig);
  expect(verify, true);
}

void main() {
  test("ecdsa point", () {
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
  });
}
