import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  test("Vesta-Pasta/FP Native", () {
    _hashToCurve();
    _swu();
    _isoMapIdentity();
    _testSqrtRatioAndAlt();
    _testSqrt();
    _testZeta();
    _testRootOfUnity();
    _testRootOfUnityInv();
    _testInv2();
    _testDelta();
  });
}

void _hashToCurve() {
  var p = PallasNativePoint.hashToCurve(
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
  final from = PallasNativePoint.fromBytes(bytes);
  expect(from, p);
}

// /
void _swu() {
  var p = PastaUtils.mapToCurveSimpleSwu(
    u: PallasNativeFp.zero(),
    theta: PallasNativeFp.theta(),
    z: PallasNativeFp.z(),
    isogenyParams: PastaCurveParams.isoPallasNative,
    r: PallasNativeFp.r(),
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
    u: PallasNativeFp.one(),
    theta: PallasNativeFp.theta(),
    z: PallasNativeFp.z(),
    isogenyParams: PastaCurveParams.isoPallasNative,
    r: PallasNativeFp.r(),
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

// r ead1e41cf395165f539008d6a0a41c55fbf51d45d42ddd7ee79df3a34d2d5126
// R mult ead1e41cf395165f539008d6a0a41c55fbf51d45d42ddd7ee79df3a34d2d51a6
// e 0000000000000000000000000000000000000000000000000000000000000000
void _isoMapIdentity() {
  var r = PallasIsoNativePoint(
    x: PallasNativeFp.fromBytes(
      PallasFp.fromRaw([
        Uint64.parseHex("0xc37f111df5c4419e"),
        Uint64.parseHex("0x593c053e5e2337ad"),
        Uint64.parseHex("0x9c6cfc47bce1aba6"),
        Uint64.parseHex("0x0a881e4d556945aa"),
      ]).toBytes(),
    ),
    y: PallasNativeFp.fromBytes(
      PallasFp.fromRaw([
        Uint64.parseHex("0xf234e04434502b47"),
        Uint64.parseHex("0x6979f7f2b0acf188"),
        Uint64.parseHex("0xa62eec46f662cb4e"),
        Uint64.parseHex("0x035e5c8a06d5cfb4"),
      ]).toBytes(),
    ),
    z: PallasNativeFp.fromBytes(
      PallasFp.fromRaw([
        Uint64.parseHex("0x11ab791d4fb6f6b4"),
        Uint64.parseHex("0x575baa717958ef1f"),
        Uint64.parseHex("0x6ac4e343558dcbf3"),
        Uint64.parseHex("0x3af37975b0933125"),
      ]).toBytes(),
    ),
  );
  final e = (r * -VestaNativeFq.one()) + r;
  expect(e.isOnCurve(), true);
  expect(e.isIdentity(), true);
  final p = PastaUtils.isoMap(
    p: (e.x, e.y, e.z),
    iso:
        PallasFPConst.isogenyConstants
            .map((e) => PallasNativeFp.fromBytes(e.toBytes()))
            .toList(),
  );
  final pallas = PallasNativePoint(x: p.$1, y: p.$2, z: p.$3);
  expect(pallas.isOnCurve(), true);
  expect(pallas.isIdentity(), true);
  final from = PallasNativePoint.fromBytes(pallas.toBytes());
  expect(from, pallas);
}

void _testDelta() {
  expect(
    PallasNativeFp.fromBytes(PallasFp.delta.toBytes()),
    PallasNativeFp.fromBytes(
      PallasFp.generator.pow([
        Uint64.one << PallasFPConst.S,
        Uint64.zero,
        Uint64.zero,
        Uint64.zero,
      ]).toBytes(),
    ),
  );
}

void _testInv2() {
  expect(
    PallasNativeFp.fromBytes(PallasFp.twoInv.toBytes()),
    PallasNativeFp(BigInt.from(2)).invert(),
  );
}

void _testRootOfUnity() {
  final v = PallasNativeFp.rootOfUnity().pow(BigInt.one << PallasFPConst.S);
  expect(v, PallasNativeFp.one());
}

void _testRootOfUnityInv() {
  expect(
    PallasNativeFp.fromBytes(PallasFp.rootOfUnityInv.toBytes()),
    PallasNativeFp.rootOfUnity().invert(),
  );
}

void _testZeta() {
  final zeta = PallasNativeFp.fromBytes(PallasFp.zeta.toBytes());
  final v = BytesUtils.toHexString(zeta.toBytes().reversed.toList());
  expect(v, "12ccca834acdba712caad5dc57aab1b01d1f8bd237ad31491dad5ebdfdfe4ab9");
  final a = zeta;
  expect(a != PallasNativeFp.one(), true);
  final b = a * a;
  expect(b != PallasNativeFp.one(), true);
  final c = b * a;
  expect(c, PallasNativeFp.one());
}

void _testSqrtRatioAndAlt() {
  final toInv = PallasNativeFp.fromBytes(PallasFp.twoInv.toBytes());

  // (true, sqrt(num/div)), if num and div are nonzero and num/div is a square
  var num = toInv.square();
  var div = PallasNativeFp(BigInt.from(25));
  var divInverse = div.invert();
  var expected = toInv * PallasNativeFp(BigInt.from(5)).invert()!;

  var result = PallasNativeFp.sqrtRatio(num, div);
  var isSquare = result.isSquare;
  var v = result.result;
  expect(isSquare, true);
  expect(v == expected || (-v) == expected, true);

  var resultAlt = PallasNativeFp.sqrtAlt(num * divInverse!);
  expect(resultAlt.result, v);

  // (false, sqrt(rootOfUnity * num/div)), if num/div is nonsquare
  num = num * PallasNativeFp.rootOfUnity();
  expected =
      toInv *
      PallasNativeFp.rootOfUnity() *
      PallasNativeFp(BigInt.from(5)).invert()!;

  result = PallasNativeFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v == expected || (-v) == expected, true);

  resultAlt = PallasNativeFp.sqrtAlt(num * divInverse);
  expect(resultAlt.isSquare, false);

  // (true, 0), if num is zero
  num = PallasNativeFp.zero();
  expected = PallasNativeFp.zero();

  result = PallasNativeFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, true);
  expect(v, expected);

  resultAlt = PallasNativeFp.sqrtAlt(num * divInverse);
  expect(resultAlt.result, v);

  // (false, 0), if num is nonzero and div is zero
  num = toInv.square();
  div = PallasNativeFp.zero();
  expected = PallasNativeFp.zero();

  result = PallasNativeFp.sqrtRatio(num, div);
  isSquare = result.isSquare;
  v = result.result;
  expect(isSquare, false);
  expect(v, expected);
}

void _testSqrt() {
  final toInv = PallasNativeFp.fromBytes(PallasFp.twoInv.toBytes());

  final v = toInv.square().sqrt();
  expect(v.result == toInv || (-v.result) == toInv, true);
}
