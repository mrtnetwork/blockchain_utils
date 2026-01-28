import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("Vesta-Pasta/FP", () {
    _hashToCurve();
    _swu();
    _isoMapIdentity();
    _isoMap();
    _testSqrtRatioAndAlt();
    _testSqrt();
    _powByMinus1();
    _testZeta();
    _rootOfUnity();
    _rootOfUnityInv();
    _inv2();
    _delta();
  });
}

void _hashToCurve() {
  var p = PallasPoint.hashToCurve(
    domainPrefix: "z.cash:test",
    message: StringUtils.encode("Trans rights now!"),
  );

  expect(
    BytesUtils.toHexString(p.x.toBytes().reversed.toList()),
    "36a6e3a9c50b7b6540cb002c977c82f37f8a875fb51eb35327ee1452e6ce7947",
  );
  expect(
    BytesUtils.toHexString(p.y.toBytes().reversed.toList()),
    "01da3b4403d73252f2d7e9c19bc23dc6a080f2d02f8262fca4f7e3d756ac6a7c",
  );
  expect(
    BytesUtils.toHexString(p.z.toBytes().reversed.toList()),
    "1d48103df8fcbb70d1809c1806c95651dd884a559fec0549658537ce9d94bed9",
  );
  expect(p.isOnCurve(), true);
  final bytes = p.toBytes();
  final from = PallasPoint.fromBytes(bytes);
  expect(from, p);
}

void _swu() {
  var p = PastaUtils.mapToCurveSimpleSwu(
    u: PallasFp.zero(),
    theta: PallasFp.theta(),
    z: PallasFp.z(),
    isogenyParams: PastaCurveParams.isoPallas,
    r: PallasFp.r(),
  );
  expect(
    BytesUtils.toHexString(p.$1.toBytes().reversed.toList()),
    "28c1a6a534f56c52e25295b339129a8af5f42525dea727f485ca3433519b096e",
  );
  expect(
    BytesUtils.toHexString(p.$2.toBytes().reversed.toList()),
    "3bfc658bee6653c63c7d7f0927083fd315d29c270207b7c7084fa1ee6ac5ae8d",
  );
  expect(
    BytesUtils.toHexString(p.$3.toBytes().reversed.toList()),
    "054b3ba10416dc104157b1318534a19d5d115472da7d746f8a5f250cd8cdef36",
  );
  p = PastaUtils.mapToCurveSimpleSwu(
    u: PallasFp.one(),
    theta: PallasFp.theta(),
    z: PallasFp.z(),
    isogenyParams: PastaCurveParams.isoPallas,
    r: PallasFp.r(),
  );
  expect(
    BytesUtils.toHexString(p.$1.toBytes().reversed.toList()),
    "010cba5957e876534af5e967c026a1856d64b071068280837913b9a5a3561505",
  );
  expect(
    BytesUtils.toHexString(p.$2.toBytes().reversed.toList()),
    "062fc61f9cd3118e7d6e65a065ebf46a547514d6b08078e976fa6d515dcc9c81",
  );
  expect(
    BytesUtils.toHexString(p.$3.toBytes().reversed.toList()),
    "3f86cb8c311250c3101c4e523e7793605ccff5623de1753a7c75bc9a29a73688",
  );
}

void _isoMapIdentity() {
  var r = PallasIsoPoint(
    x: PallasFp.fromRaw([
      BigInt.parse("0xc37f111df5c4419e"),
      BigInt.parse("0x593c053e5e2337ad"),
      BigInt.parse("0x9c6cfc47bce1aba6"),
      BigInt.parse("0x0a881e4d556945aa"),
    ]),
    y: PallasFp.fromRaw([
      BigInt.parse("0xf234e04434502b47"),
      BigInt.parse("0x6979f7f2b0acf188"),
      BigInt.parse("0xa62eec46f662cb4e"),
      BigInt.parse("0x035e5c8a06d5cfb4"),
    ]),
    z: PallasFp.fromRaw([
      BigInt.parse("0x11ab791d4fb6f6b4"),
      BigInt.parse("0x575baa717958ef1f"),
      BigInt.parse("0x6ac4e343558dcbf3"),
      BigInt.parse("0x3af37975b0933125"),
    ]),
  );
  print("r ${r.toHex()}");
  print("R mult ${(r * -VestaFq.one()).toHex()}");
  final e = (r * -VestaFq.one()) + r;
  print("e ${e.toHex()}");
  expect(e.isOnCurve(), true);
  expect(e.isIdentity(), true);
  final p = PastaUtils.isoMap(
    p: (e.x, e.y, e.z),
    iso: PallasFPConst.isogenyConstants,
  );
  final pallas = PallasPoint(x: p.$1, y: p.$2, z: p.$3);
  expect(pallas.isOnCurve(), true);
  expect(pallas.isIdentity(), true);
  final from = PallasPoint.fromBytes(pallas.toBytes());
  expect(from, pallas);
}

void _isoMap() {
  final PallasIsoPoint r = PallasIsoPoint(
    x: PallasFp.fromRaw([
      BigInt.parse("0xc37f111df5c4419e"),
      BigInt.parse("0x593c053e5e2337ad"),
      BigInt.parse("0x9c6cfc47bce1aba6"),
      BigInt.parse("0x0a881e4d556945aa"),
    ]),
    y: PallasFp.fromRaw([
      BigInt.parse("0xf234e04434502b47"),
      BigInt.parse("0x6979f7f2b0acf188"),
      BigInt.parse("0xa62eec46f662cb4e"),
      BigInt.parse("0x035e5c8a06d5cfb4"),
    ]),
    z: PallasFp.fromRaw([
      BigInt.parse("0x11ab791d4fb6f6b4"),
      BigInt.parse("0x575baa717958ef1f"),
      BigInt.parse("0x6ac4e343558dcbf3"),
      BigInt.parse("0x3af37975b0933125"),
    ]),
  );
  final p = PastaUtils.isoMap(
    p: (r.x, r.y, r.z),
    iso: PallasFPConst.isogenyConstants,
  );
  final point = PallasPoint(x: p.$1, y: p.$2, z: p.$3);
  expect(
    BytesUtils.toHexString(p.$1.toBytes().reversed.toList()),
    "318cc15f281662b3f26d0175cab97b924870c837879cac647e877be51a85e898",
  );
  expect(
    BytesUtils.toHexString(p.$2.toBytes().reversed.toList()),
    "1e91e2fa2a5a6a5bc86ff9564ae9336084470e7119dffcb85ae8c1383a3defd7",
  );
  expect(
    BytesUtils.toHexString(p.$3.toBytes().reversed.toList()),
    "1e049436efa754f5f189aec69c2c3a4a559eca6a12b45c3f2e4a769deeca6187",
  );
  final r2 = r.double();
  expect(r2.isOnCurve(), true);
  final p2 = PastaUtils.isoMap(
    p: (r2.x, r2.y, r2.z),
    iso: PallasFPConst.isogenyConstants,
  );
  final point1 = PallasPoint(x: p2.$1, y: p2.$2, z: p2.$3);

  expect(point1.isOnCurve(), true);
  expect(point1, point.double());
}

void _delta() {
  expect(
    PallasFp.delta(),
    PallasFp.generator().pow([
      BigInt.one << PallasFPConst.S,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
  );
  expect(
    PallasFp.delta(),
    PallasFp.generator().pow([
      BigInt.one << PallasFPConst.S,
      BigInt.zero,
      BigInt.zero,
      BigInt.zero,
    ]),
  );
}

void _inv2() {
  expect(PallasFp.twoInv(), PallasFp.from(BigInt.from(2)).invert());
}

void _rootOfUnity() {
  final v = PallasFp.rootOfUnity().pow([
    BigInt.one << PallasFPConst.S,
    BigInt.zero,
    BigInt.zero,
    BigInt.zero,
  ]);
  expect(v, PallasFp.one());
}

void _rootOfUnityInv() {
  expect(PallasFp.rootOfUnityInv(), PallasFp.rootOfUnity().invert());
}

void _testZeta() {
  final v = BytesUtils.toHexString(PallasFp.zeta().toBytes().reversed.toList());
  expect(v, "12ccca834acdba712caad5dc57aab1b01d1f8bd237ad31491dad5ebdfdfe4ab9");
  final a = PallasFp.zeta();
  expect(a != PallasFp.one(), true);
  final b = a * a;
  expect(b != PallasFp.one(), true);
  final c = b * a;
  expect(c, PallasFp.one());
}

void _testSqrtRatioAndAlt() {
  // (true, sqrt(num/div)), if num and div are nonzero and num/div is a square
  var num = PallasFp.twoInv().square();
  var div = PallasFp.from(BigInt.from(25));
  var divInverse = div.invert();
  var expected = PallasFp.twoInv() * PallasFp.from(BigInt.from(5)).invert()!;

  var result = PallasFp.sqrtRatio(num, div);
  var isSquare = result.isSquare;
  var v = result.result;
  expect(isSquare, true);
  expect(v == expected || (-v) == expected, true);

  var resultAlt = PallasFp.sqrtAlt(num * divInverse!);
  var isSquareAlt = resultAlt.isSquare;
  var vAlt = resultAlt.result;
  expect(isSquareAlt, true);
  expect(vAlt, v);

  // (false, sqrt(rootOfUnity * num/div)), if num/div is nonsquare
  num = num * PallasFp.rootOfUnity();
  expected =
      PallasFp.twoInv() *
      PallasFp.rootOfUnity() *
      PallasFp.from(BigInt.from(5)).invert()!;

  result = PallasFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v == expected || (-v) == expected, true);

  resultAlt = PallasFp.sqrtAlt(num * divInverse);
  isSquareAlt = resultAlt.isSquare;
  vAlt = resultAlt.result;
  expect(isSquareAlt, false);

  // (true, 0), if num is zero
  num = PallasFp.zero();
  expected = PallasFp.zero();

  result = PallasFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, true);
  expect(v, expected);

  resultAlt = PallasFp.sqrtAlt(num * divInverse);
  isSquareAlt = resultAlt.isSquare;
  vAlt = resultAlt.result;
  expect(isSquareAlt, true);
  expect(vAlt, v);

  // (false, 0), if num is nonzero and div is zero
  num = PallasFp.twoInv().square();
  div = PallasFp.zero();
  expected = PallasFp.zero();

  result = PallasFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v, expected);
}

void _testSqrt() {
  final v = PallasFp.twoInv().square().sqrt();
  expect(
    v.result == PallasFp.twoInv() || (-v.result) == PallasFp.twoInv(),
    true,
  );
}

void _powByMinus1() {
  final v = PallasFp.twoInv().powByTMinus1Over2();
  expect(v, PallasFp.twoInv().pow(PallasFPConst.tMinus1Over2));
}
