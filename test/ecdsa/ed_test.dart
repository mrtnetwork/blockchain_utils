import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/eddsa/keys/privatekey.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/point/edwards.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import '../quick_hex.dart';

void _testDouble() {
  final a = Curves.generatorED25519;
  final z = a.doublePoint();
  final x2 = BigInt.parse(
      "24727413235106541002554574571675588834622768167397638456726423682521233608206");
  final y2 = BigInt.parse(
      "15549675580280190176352668710449542251549572066445060580507079593062643049417");
  final b = EDPoint(
      curve: Curves.curveEd25519, x: x2, y: y2, z: BigInt.one, t: x2 * y2);
  expect(z, b);
}

void _addDouble() {
  final a = Curves.generatorED25519;
  final d = a + a;
  final dDouble = a.doublePoint();
  expect(d, dDouble);
}

void _infinity() {
  final p = EDPoint(
      curve: Curves.curveEd25519,
      x: BigInt.zero,
      y: BigInt.one,
      z: BigInt.one,
      t: BigInt.zero);
  expect(p.doublePoint().isInfinity, true);
  final p2 = EDPoint(
      curve: Curves.curveEd25519,
      x: BigInt.one,
      y: BigInt.one,
      z: BigInt.one,
      t: BigInt.zero);
  expect(p2.doublePoint().isInfinity, true);
}

void _equal() {
  final x = Curves.generatorED25519.x;
  final y = Curves.generatorED25519.y;
  final p = Curves.generatorED25519.curve.p;
  final p1 = EDPoint(
      curve: Curves.generatorED25519.curve,
      x: x * BigInt.two % p,
      y: y * BigInt.two % p,
      z: BigInt.two,
      t: x * y * BigInt.two % p);
  final p2 = EDPoint(
      curve: Curves.generatorED25519.curve,
      x: x * BigInt.from(3) % p,
      y: y * BigInt.from(3) % p,
      z: BigInt.from(3),
      t: x * y * BigInt.from(3) % p);
  expect(p1, p2);
}

void _scaling() {
  final x = Curves.generatorED25519.x;
  final y = Curves.generatorED25519.y;
  final p = Curves.generatorED25519.curve.p;
  final p1 = EDPoint(
      curve: Curves.generatorED25519.curve,
      x: x * BigInt.from(11) % p,
      y: y * BigInt.from(11) % p,
      z: BigInt.from(11),
      t: x * y * BigInt.from(11) % p);

  expect(p1.x, x);
  expect(p1.y, y);
  p1.scale();
  expect(p1.x, x);
  expect(p1.y, y);
  p1.scale();
  expect(p1.x, x);
  expect(p1.y, y);
}

void _add3Time() {
  final a = Curves.generatorED25519;
  final z = a + a + a;
  final x3 = BigInt.parse(
      "46896733464454938657123544595386787789046198280132665686241321779790909858396");
  final y3 = BigInt.parse(
      "8324843778533443976490377120369201138301417226297555316741202210403726505172");
  final ed = EDPoint(
      curve: Curves.curveEd25519, x: x3, y: y3, z: BigInt.one, t: x3 * y3);
  assert(ed == z);
}

void _addInfinity() {
  final x = BigInt.parse(
      "42783823269122696939284341094755422415180979639778424813682678720006717057747");
  final y = BigInt.parse(
      "46316835694926478169428394003475163141307993866256225615783033603165251855960");
  final p1 =
      EDPoint(curve: Curves.curveEd25519, x: x, y: y, z: BigInt.one, t: x * y);
  final p2 = p1 + Curves.generatorED25519;
  assert(p2.isInfinity);
}

void _addAndMull() {
  assert(Curves.generatorED25519 + Curves.generatorED25519 ==
      Curves.generatorED25519 * BigInt.two);
  assert((Curves.generatorED25519 +
          Curves.generatorED25519 +
          Curves.generatorED25519) ==
      Curves.generatorED25519 * BigInt.from(3));
}

void _infinityMul() {
  expect((Curves.generatorED25519 * Curves.generatorED25519.order!).isInfinity,
      true);
}

void _infinityMulAddOne() {
  expect(
      (Curves.generatorED25519 *
              (Curves.generatorED25519.order! + BigInt.one)) ==
          Curves.generatorED25519,
      true);
}

void _mulByZero() {
  expect((Curves.generatorED25519 * BigInt.zero).isInfinity, true);
}

void _testEncoding() {
  const generatorBytes =
      "5866666666666666666666666666666666666666666666666666666666666666";
  expect(Curves.generatorED25519.toBytes().toHex(), generatorBytes);
  final gn = EDPoint.fromBytes(
      curve: Curves.curveEd25519,
      data: BytesUtils.fromHexString(generatorBytes));
  expect(gn, Curves.generatorED25519);
}

void _testKeys() {
  final pr =
      EDDSAPrivateKey(Curves.generatorED25519, Uint8List(32), () => SHA512());
  expect(pr.publicKey.point.toBytes().toHex(),
      "3b6a27bcceb6a42d62a3a8d02a6f0d73653215771de243a63ac048a18b59da29");
  final sig = pr.sign(Uint8List(32), () => SHA512());
  final verify = pr.publicKey.verify(Uint8List(32), sig, () => SHA512());
  expect(verify, true);
}

void _testEDBlake2bKeys() {
  final pr =
      EDDSAPrivateKey(Curves.generatorED25519, Uint8List(32), () => BLAKE2b());
  final sig = pr.sign(Uint8List(32), () => BLAKE2b());
  final verify = pr.publicKey.verify(Uint8List(32), sig, () => BLAKE2b());
  expect(verify, true);
}

void main() {
  test("EDDSA points", () {
    _testKeys();
    _testEDBlake2bKeys();
    _testEncoding();
    _mulByZero();
    _infinityMul();
    _addInfinity();
    _add3Time();
    _scaling();
    _equal();
    _testDouble();
    _addDouble();
    _infinity();
    _addAndMull();
    _infinityMulAddOne();
  });
}
