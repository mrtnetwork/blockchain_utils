import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("Vesta-Pasta/FQ Native", () {
    _swu();
    _hashToCurve();
    _testSqrtRatioAndAlt();
    _testSqrt();
    _sqrtOverflow();
    _testZeta();
    _testRootOfUnity();
    _testRootOfUnityInv();
    _testInv2();
    _testDelta();
    _endo();
  });
}

void _endo() {
  final pallasGenerator = PallasNativePoint.generator();
  expect((pallasGenerator * VestaNativeFq.zeta()), pallasGenerator.endo());
  final generatior = VestaPoint.generator();
  expect((generatior * PallasFp.zeta()), generatior.endo());
}

void _hashToCurve() {
  var p = VestaNativePoint.hashToCurve(
    domainPrefix: "z.cash:test",
    message: StringUtils.encode("hello"),
  );
  expect(
    BytesUtils.toHexString(p.x.toBytes().reversed.toList()),
    "12763505036e0e1a6684b7a7d8d5afb7378cc2b191a95e34f44824a06fcbd08e",
  );
  expect(
    BytesUtils.toHexString(p.y.toBytes().reversed.toList()),
    "0256eafc0188b79bfa7c4b2b393893ddc298e90da500fa4a9aee17c2ea4240e6",
  );
  expect(
    BytesUtils.toHexString(p.z.toBytes().reversed.toList()),
    "1b58d4aa4d68c3f4d9916b77c79ff9911597a27f2ee46244e98eb9615172d2ad",
  );
  final bytes = p.toBytes();
  final r = VestaNativePoint.fromBytes(bytes);
  expect(r, p);
}

void _swu() {
  var p = PastaUtils.mapToCurveSimpleSwu(
    u: VestaNativeFq.zero(),
    theta: VestaNativeFq.theta(),
    z: VestaNativeFq.z(),
    isogenyParams: PastaCurveParams.isoVestaNative,
    r: VestaNativeFq.one(),
  );
  // print("X ${p.x.toHex()}");
  expect(
    BytesUtils.toHexString(p.$1.toBytes().reversed.toList()),
    "2ccc4c6ec2660e5644305bc52527d904d408f92407f599df8f158d50646a2e78",
  );
  expect(
    BytesUtils.toHexString(p.$2.toBytes().reversed.toList()),
    "29a34381321d13d72d50b6b462bb4ea6a9e47393fa28a47227bf35bc0ee7aa59",
  );
  expect(
    BytesUtils.toHexString(p.$3.toBytes().reversed.toList()),
    "0b851e9e579403a76df1100f556e1f226e5656bdf38f3bf8601d8a3a9a15890b",
  );
  p = PastaUtils.mapToCurveSimpleSwu(
    u: VestaNativeFq.one(),
    theta: VestaNativeFq.theta(),
    z: VestaNativeFq.z(),
    isogenyParams: PastaCurveParams.isoVestaNative,
    r: VestaNativeFq.one(),
  );
  expect(
    BytesUtils.toHexString(p.$1.toBytes().reversed.toList()),
    "165f8b71841c5abc3d742ec13fb16f099d596b781e6f5c7d0b6682b1216a8258",
  );
  expect(
    BytesUtils.toHexString(p.$2.toBytes().reversed.toList()),
    "0dadef21de74ed7337a37dd74f126a92e4df73c3a704da501e36eaf59cf03120",
  );
  expect(
    BytesUtils.toHexString(p.$3.toBytes().reversed.toList()),
    "0a3d6f6c1af02bd9274cc0b80129759ce77edeef578d7de968d4a47d39026c82",
  );
}

void _testDelta() {
  expect(
    VestaFq.delta(),
    VestaFq.generator().pow([
      BigInt.one << VestaFQConst.S,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
  );
  expect(
    VestaNativeFq.fromBytes(VestaFq.delta().toBytes()),
    VestaNativeFq.fromBytes(
      VestaFq.generator().toBytes(),
    ).pow(BigInt.one << VestaFQConst.S),
  );
}

void _testInv2() {
  expect(VestaNativeFq.twoInv(), VestaNativeFq(BigInt.from(2)).invert());
}

void _testRootOfUnity() {
  final v = VestaNativeFq.rootOfUnity().pow(BigInt.one << VestaFQConst.S);
  expect(v, VestaNativeFq.one());
}

void _testRootOfUnityInv() {
  expect(
    VestaNativeFq.fromBytes(VestaFq.rootOfUnityInv().toBytes()),
    VestaNativeFq.rootOfUnity().invert(),
  );
}

void _testZeta() {
  final a = VestaNativeFq.fromBytes(VestaFq.zeta().toBytes());
  final v = BytesUtils.toHexString(a.toBytes().reversed.toList());
  expect(v, "06819a58283e528e511db4d81cf70f5a0fed467d47c033af2aa9d2e050aa0e4f");
  expect(a != VestaNativeFq.one(), true);
  final b = a * a;
  expect(b != VestaNativeFq.one(), true);
  final c = b * a;
  expect(c, VestaNativeFq.one());
}

void _testSqrtRatioAndAlt() {
  // (true, sqrt(num/div)), if num and div are nonzero and num/div is a square
  var num = VestaNativeFq.twoInv().square();
  var div = VestaNativeFq(BigInt.from(25));
  var divInverse = div.invert();
  var expected =
      VestaNativeFq.twoInv() * VestaNativeFq(BigInt.from(5)).invert()!;

  var result = VestaNativeFq.sqrtRatio(num, div);
  var isSquare = result.isSquare;
  var v = result.result;
  expect(isSquare, true);
  expect(v == expected || (-v) == expected, true);

  var resultAlt = VestaNativeFq.sqrtAlt(num * divInverse!);
  var isSquareAlt = resultAlt.isSquare;
  var vAlt = resultAlt.result;
  expect(isSquareAlt, true);
  expect(vAlt, v);

  // (false, sqrt(ROOT_OF_UNITY * num/div)), if num/div is nonsquare
  num = num * VestaNativeFq.rootOfUnity();
  expected =
      VestaNativeFq.twoInv() *
      VestaNativeFq.rootOfUnity() *
      VestaNativeFq(BigInt.from(5)).invert()!;

  result = VestaNativeFq.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v == expected || (-v) == expected, true);

  resultAlt = VestaNativeFq.sqrtAlt(num * divInverse);
  isSquareAlt = resultAlt.isSquare;
  vAlt = resultAlt.result;
  expect(isSquareAlt, false);
  // expect(vAlt, v);

  // (true, 0), if num is zero
  num = VestaNativeFq.zero();
  expected = VestaNativeFq.zero();

  result = VestaNativeFq.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, true);
  expect(v, expected);

  resultAlt = VestaNativeFq.sqrtAlt(num * divInverse);
  isSquareAlt = resultAlt.isSquare;
  vAlt = resultAlt.result;
  expect(isSquareAlt, true);
  expect(vAlt, v);

  // (false, 0), if num is nonzero and div is zero
  num = VestaNativeFq.twoInv().square();
  div = VestaNativeFq.zero();
  expected = VestaNativeFq.zero();

  result = VestaNativeFq.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v, expected);
}

void _testSqrt() {
  final v = VestaNativeFq.twoInv().square().sqrt();
  expect(
    v.result == VestaNativeFq.twoInv() || (-v.result) == VestaNativeFq.twoInv(),
    true,
  );
}

void _sqrtOverflow() {
  final v = VestaNativeFq(BigInt.from(5)).sqrt();
  expect(v.isSquare, false);
}
