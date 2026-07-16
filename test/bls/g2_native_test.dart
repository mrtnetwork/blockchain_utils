import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';
import 'fp2_test.dart';
import 'g1_native_test.dart';

void main() {
  test("BLS12/G2 Native", () {
    _testIsOnCurve();
    _testProjectivePointEquality();
    _testAffinePointEquality();
    _testConditionallySelectAffine();
    _testConditionallySelectProjective();
    _testProjectiveToAffine();
    _testAffineToProjective();
    _testDoubling();
    _testProjectiveAddition();
    _testMixedAddition();
    _testAffineNegationAndSubtraction();
    _testProjectiveScalarMultiplication();
    _testAffineScalarMultiplication();
    _testIsTorsionFree();
    _testMulByX();
    _testPsi();
    _testClearCofactor();
    _testCommutativeScalarSubgroupMultiplication();
  });
}

void _testCommutativeScalarSubgroupMultiplication() {
  var a =
      JubJubFq.fromRaw([
        Uint64.parseHex("0x1fff3231233ffffd"),
        Uint64.parseHex("0x4884b7fa00034802"),
        Uint64.parseHex("0x998c4fefecbc4ff3"),
        Uint64.parseHex("0x1824b159acc50562"),
      ]).toNative();

  var g2A = G2NativeAffinePoint.generator();
  var g2P = G2NativeProjective.generator();

  // By reference. In subfunction to avoid unnecessary copies.
  void byRef(
    G2NativeAffinePoint g2A,
    G2NativeProjective g2P,
    JubJubNativeFq a,
  ) {
    expect(g2A * a, g2A * a);
    expect(g2P * a, g2P * a);
  }

  byRef(g2A, g2P, a);

  // Mixed
  void groupRef(
    G2NativeAffinePoint g2A,
    G2NativeProjective g2P,
    JubJubNativeFq a,
  ) {
    expect(g2A * a, g2A * a);
    expect(g2P * a, g2P * a);
  }

  void scalarRef(
    G2NativeAffinePoint g2A,
    G2NativeProjective g2P,
    JubJubNativeFq a,
  ) {
    expect(g2A * a, g2A * a);
    expect(g2P * a, g2P * a);
  }

  groupRef(g2A, g2P, a);
  scalarRef(g2A, g2P, a);

  // By value
  expect(g2P * a, g2P * a);
  expect(g2A * a, g2A * a);
}

void _testMulByX() {
  // multiplying by `x` a point in G2 is the same as multiplying by
  // the equivalent scalar.
  var generator = G2NativeProjective.generator();
  var x = -JubJubNativeFq(BigInt.parse("15132376222941642752"));

  expect(generator.mulByX(), generator * x);

  var point = G2NativeProjective.generator() * JubJubNativeFq(BigInt.from(42));
  expect(point.mulByX(), point * x);
}

void _testPsi() {
  var generator = G2NativeProjective.generator();

  var z =
      Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x0ef2ddffab187c0a'),
          Uint64.parseHex('0x2424522b7d5ecbfc'),
          Uint64.parseHex('0xc6f341a3398054f4'),
          Uint64.parseHex('0x5523ddf409502df0'),
          Uint64.parseHex('0xd55c0b5a88e0dd97'),
          Uint64.parseHex('0x066428d704923e52'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x538bbe0c95b4878d'),
          Uint64.parseHex('0xad04a50379522881'),
          Uint64.parseHex('0x6d5c05bf5c12fb64'),
          Uint64.parseHex('0x4ce4a069a2d34787'),
          Uint64.parseHex('0x59ea6c8d0dffaeaf'),
          Uint64.parseHex('0x0d42a083a75bd6f3'),
        ]),
      ).toNative();

  var point = G2NativeProjective(
    x:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0xee4c8cb7c047eaf2'),
            Uint64.parseHex('0x44ca22eee036b604'),
            Uint64.parseHex('0x33b3affb2aefe101'),
            Uint64.parseHex('0x15d3e45bbafaeb02'),
            Uint64.parseHex('0x7bfc2154cd7419a4'),
            Uint64.parseHex('0x0a2d0c2b756e5edc'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0xfc224361029a8777'),
            Uint64.parseHex('0x4cbf2baab8740924'),
            Uint64.parseHex('0xc5008c6ec6592c89'),
            Uint64.parseHex('0xecc2c57b472a9c2d'),
            Uint64.parseHex('0x8613eafd9d81ffb1'),
            Uint64.parseHex('0x10fe54daa2d3d495'),
          ]),
        ).toNative() *
        z,
    y:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0x7de7edc43953b75c'),
            Uint64.parseHex('0x58be1d2de35e87dc'),
            Uint64.parseHex('0x5731d30b0e337b40'),
            Uint64.parseHex('0xbe93b60cfeaae4c9'),
            Uint64.parseHex('0x8b22c203764bedca'),
            Uint64.parseHex('0x01616c8d1033b771'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0xea126fe476b5733b'),
            Uint64.parseHex('0x85cee68b5dae1652'),
            Uint64.parseHex('0x98247779f7272b04'),
            Uint64.parseHex('0xa649c8b468c6e808'),
            Uint64.parseHex('0xb5b9a62dff0c4e45'),
            Uint64.parseHex('0x1555b67fc7bbe73d'),
          ]),
        ).toNative(),
    z: z.square() * z,
  );

  expect(point.isOnCurve(), true);

  // psi2(P) = psi(psi(P))
  expect(generator.psi2(), generator.psi().psi());
  expect(point.psi2(), point.psi().psi());
  // psi(P) is a morphism
  expect(generator.double().psi(), generator.psi().double());
  expect(point.psi() + generator.psi(), (point + generator).psi());
}

void _testClearCofactor() {
  var z =
      Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0x0ef2ddffab187c0a'),
          Uint64.parseHex('0x2424522b7d5ecbfc'),
          Uint64.parseHex('0xc6f341a3398054f4'),
          Uint64.parseHex('0x5523ddf409502df0'),
          Uint64.parseHex('0xd55c0b5a88e0dd97'),
          Uint64.parseHex('0x066428d704923e52'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x538bbe0c95b4878d'),
          Uint64.parseHex('0xad04a50379522881'),
          Uint64.parseHex('0x6d5c05bf5c12fb64'),
          Uint64.parseHex('0x4ce4a069a2d34787'),
          Uint64.parseHex('0x59ea6c8d0dffaeaf'),
          Uint64.parseHex('0x0d42a083a75bd6f3'),
        ]),
      ).toNative();

  var point = G2NativeProjective(
    x:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0xee4c8cb7c047eaf2'),
            Uint64.parseHex('0x44ca22eee036b604'),
            Uint64.parseHex('0x33b3affb2aefe101'),
            Uint64.parseHex('0x15d3e45bbafaeb02'),
            Uint64.parseHex('0x7bfc2154cd7419a4'),
            Uint64.parseHex('0x0a2d0c2b756e5edc'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0xfc224361029a8777'),
            Uint64.parseHex('0x4cbf2baab8740924'),
            Uint64.parseHex('0xc5008c6ec6592c89'),
            Uint64.parseHex('0xecc2c57b472a9c2d'),
            Uint64.parseHex('0x8613eafd9d81ffb1'),
            Uint64.parseHex('0x10fe54daa2d3d495'),
          ]),
        ).toNative() *
        z,
    y:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0x7de7edc43953b75c'),
            Uint64.parseHex('0x58be1d2de35e87dc'),
            Uint64.parseHex('0x5731d30b0e337b40'),
            Uint64.parseHex('0xbe93b60cfeaae4c9'),
            Uint64.parseHex('0x8b22c203764bedca'),
            Uint64.parseHex('0x01616c8d1033b771'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0xea126fe476b5733b'),
            Uint64.parseHex('0x85cee68b5dae1652'),
            Uint64.parseHex('0x98247779f7272b04'),
            Uint64.parseHex('0xa649c8b468c6e808'),
            Uint64.parseHex('0xb5b9a62dff0c4e45'),
            Uint64.parseHex('0x1555b67fc7bbe73d'),
          ]),
        ).toNative(),
    z: z.square() * z,
  );

  expect(point.isOnCurve(), true);
  expect(G2NativeAffinePoint.fromProjective(point).isTorsionFree(), false);
  var clearedPoint = point.clearCofactor();

  expect(clearedPoint.isOnCurve(), true);
  expect(
    G2NativeAffinePoint.fromProjective(clearedPoint).isTorsionFree(),
    true,
  );

  var generator = G2NativeProjective.generator();
  expect(generator.clearCofactor().isOnCurve(), true);
  var id = G2NativeProjective.identity();
  expect(id.clearCofactor().isOnCurve(), true);

  var hEffModQ = [
    0xff,
    0xff,
    0x01,
    0x00,
    0x04,
    0x00,
    0x02,
    0xa4,
    0x09,
    0x90,
    0x06,
    0x00,
    0x04,
    0x90,
    0x16,
    0xb1,
    0x02,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ];
  expect(generator.clearCofactor(), generator.multiply(hEffModQ));
  expect(clearedPoint.clearCofactor(), clearedPoint.multiply(hEffModQ));
}

void _testAffineNegationAndSubtraction() {
  final a = G2NativeAffinePoint.generator();
  expect(
    G2NativeProjective.fromAffine(a) + (-a),
    G2NativeProjective.identity(),
  );
  expect(
    G2NativeProjective.fromAffine(a) + (-a),
    G2NativeProjective.fromAffine(a) - a,
  );
}

void _testProjectiveScalarMultiplication() {
  final g = G2NativeProjective.generator();
  final a =
      JubJubFq.fromRaw([
        Uint64.parseHex('0x2b568297a56da71c'),
        Uint64.parseHex('0xd8c39ecb0ef375d1'),
        Uint64.parseHex('0x435c38da67bfbf96'),
        Uint64.parseHex('0x8088a05026b659b2'),
      ]).toNative();
  final b =
      JubJubFq.fromRaw([
        Uint64.parseHex('0x785fdd9b26ef8b85'),
        Uint64.parseHex('0xc997f25837695c18'),
        Uint64.parseHex('0x4c8dbc39e7b756c1'),
        Uint64.parseHex('0x70d9b6cc6d87df20'),
      ]).toNative();

  final c = a * b;
  expect((g * a) * b, g * c);
}

void _testAffineScalarMultiplication() {
  final g = G2NativeAffinePoint.generator();
  final a =
      JubJubFq.fromRaw([
        Uint64.parseHex('0x2b568297a56da71c'),
        Uint64.parseHex('0xd8c39ecb0ef375d1'),
        Uint64.parseHex('0x435c38da67bfbf96'),
        Uint64.parseHex('0x8088a05026b659b2'),
      ]).toNative();
  final b =
      JubJubFq.fromRaw([
        Uint64.parseHex('0x785fdd9b26ef8b85'),
        Uint64.parseHex('0xc997f25837695c18'),
        Uint64.parseHex('0x4c8dbc39e7b756c1'),
        Uint64.parseHex('0x70d9b6cc6d87df20'),
      ]).toNative();

  final c = a * b;
  expect(G2NativeAffinePoint.fromProjective(g * a) * b, g * c);
}

void _testIsTorsionFree() {
  final a = G2NativeAffinePoint(
    x:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0x89f550c813db6431'),
            Uint64.parseHex('0xa50be8c456cd8a1a'),
            Uint64.parseHex('0xa45b374114cae851'),
            Uint64.parseHex('0xbb6190f5bf7fff63'),
            Uint64.parseHex('0x970ca02c3ba80bc7'),
            Uint64.parseHex('0x02b85d24e840fbac'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0x6888bc53d70716dc'),
            Uint64.parseHex('0x3dea6b4117682d70'),
            Uint64.parseHex('0xd8f5f930500ca354'),
            Uint64.parseHex('0x6b5ecb6556f5c155'),
            Uint64.parseHex('0xc96bef0434778ab0'),
            Uint64.parseHex('0x05081505515006ad'),
          ]),
        ).toNative(),
    y:
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0x3cf1ea0d434b0f40'),
            Uint64.parseHex('0x1a0dc610e603e333'),
            Uint64.parseHex('0x7f89956160c72fa0'),
            Uint64.parseHex('0x25ee03decf6431c5'),
            Uint64.parseHex('0xeee8e206ec0fe137'),
            Uint64.parseHex('0x097592b226dfef28'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0x71e8bb5f29247367'),
            Uint64.parseHex('0xa5fe049e211831ce'),
            Uint64.parseHex('0x0ce6b354502a3896'),
            Uint64.parseHex('0x93b012000997314e'),
            Uint64.parseHex('0x6759f3b6aa5b42ac'),
            Uint64.parseHex('0x156944c4dfe92bbb'),
          ]),
        ).toNative(),
    infinity: false,
  );

  expect(a.isTorsionFree(), false);
  expect(G2NativeAffinePoint.identity().isTorsionFree(), true);
  expect(G2NativeAffinePoint.generator().isTorsionFree(), true);
}

void _testAffineToProjective() {
  final a = G2NativeAffinePoint.generator();
  final b = G2NativeAffinePoint.identity();

  final aProj = G2NativeProjective.fromAffine(a);
  final bProj = G2NativeProjective.fromAffine(b);

  expect(aProj.isOnCurve(), true);
  expect(aProj.isIdentity(), false);
  expect(bProj.isOnCurve(), true);
  expect(bProj.isIdentity(), true);
}

void _testDoubling() {
  {
    final tmp = G2NativeProjective.identity().double();
    expect(tmp.isIdentity(), true);
    expect(tmp.isOnCurve(), true);
  }
  {
    final tmp = G2NativeProjective.generator().double();
    expect(tmp.isIdentity(), false);
    expect(tmp.isOnCurve(), true);

    final expected = G2NativeAffinePoint(
      x:
          Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0xe9d9e2da9620f98b'),
              Uint64.parseHex('0x54f1199346b97f36'),
              Uint64.parseHex('0x3db3b820376bed27'),
              Uint64.parseHex('0xcfdb31c9b0b64f4c'),
              Uint64.parseHex('0x41d7c12786354493'),
              Uint64.parseHex('0x05710794c255c064'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0xd6c1d3ca6ea0d06e'),
              Uint64.parseHex('0xda0cbd905595489f'),
              Uint64.parseHex('0x4f5352d43479221d'),
              Uint64.parseHex('0x8ade5d736f8c97e0'),
              Uint64.parseHex('0x48cc8433925ef70e'),
              Uint64.parseHex('0x08d7ea71ea91ef81'),
            ]),
          ).toNative(),
      y:
          Bls12Fp2(
            c0: Bls12Fp([
              Uint64.parseHex('0x15ba26eb4b0d186f'),
              Uint64.parseHex('0x0d086d64b7e9e01e'),
              Uint64.parseHex('0xc8b848dd652f4c78'),
              Uint64.parseHex('0xeecf46a6123bae4f'),
              Uint64.parseHex('0x255e8dd8b6dc812a'),
              Uint64.parseHex('0x164142af21dcf93f'),
            ]),
            c1: Bls12Fp([
              Uint64.parseHex('0xf9b4a1a895984db4'),
              Uint64.parseHex('0xd417b114cccff748'),
              Uint64.parseHex('0x6856301fc89f086e'),
              Uint64.parseHex('0x41c777878931e3da'),
              Uint64.parseHex('0x3556b155066a2105'),
              Uint64.parseHex('0x00acf7d325cb89cf'),
            ]),
          ).toNative(),
      infinity: false,
    );

    expect(G2NativeAffinePoint.fromProjective(tmp), expected);
  }
}

void _testProjectiveAddition() {
  // Identity + Identity
  {
    final a = G2NativeProjective.identity();
    final b = G2NativeProjective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  // Identity + Generator * z
  {
    final a = G2NativeProjective.identity();
    var b = G2NativeProjective.generator();

    final z =
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0xba7afa1f9a6fe250'),
            Uint64.parseHex('0xfa0f5b595eafe731'),
            Uint64.parseHex('0x3bdc477694c306e7'),
            Uint64.parseHex('0x2149be4b3949fa24'),
            Uint64.parseHex('0x64aa6e0649b2078c'),
            Uint64.parseHex('0x12b108ac33643c3e'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0x125325df3d35b5a8'),
            Uint64.parseHex('0xdc469ef5555d7fe3'),
            Uint64.parseHex('0x02d716d2443106a9'),
            Uint64.parseHex('0x05a1db59a6ff37d0'),
            Uint64.parseHex('0x7cf7784e5300bb8f'),
            Uint64.parseHex('0x16a88922c7a5e844'),
          ]),
        ).toNative();

    b = G2NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G2NativeProjective.generator());
  }

  // Generator doubling + doubling
  {
    final a = G2NativeProjective.generator().double().double(); // 4P
    final b = G2NativeProjective.generator().double(); // 2P
    final c = a + b;

    var d = G2NativeProjective.generator();
    for (int i = 0; i < 5; i++) {
      d += G2NativeProjective.generator();
    }

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(d.isIdentity(), false);
    expect(d.isOnCurve(), true);
    expect(c, d);
  }

  // Degenerate case
  {
    var beta =
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0xcd03c9e48671f071'),
            Uint64.parseHex('0x5dab22461fcda5d2'),
            Uint64.parseHex('0x587042afd3851b95'),
            Uint64.parseHex('0x8eb60ebe01bacb9e'),
            Uint64.parseHex('0x03f97d6e83d050d2'),
            Uint64.parseHex('0x18f0206554638741'),
          ]),
          c1: Bls12Fp.zero,
        ).toNative();
    beta = beta.square();

    final a = G2NativeProjective.generator().double().double();
    final b = G2NativeProjective(x: a.x * beta, y: -a.y, z: a.z);

    expect(a.isOnCurve(), true);
    expect(b.isOnCurve(), true);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
  }
}

void _testMixedAddition() {
  // Affine identity + projective identity
  {
    final a = G2NativeAffinePoint.identity();
    final b = G2NativeProjective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  // Affine identity + projective generator * z
  {
    final a = G2NativeAffinePoint.identity();
    var b = G2NativeProjective.generator();

    final z =
        Bls12Fp2(
          c0: Bls12Fp([
            Uint64.parseHex('0xba7afa1f9a6fe250'),
            Uint64.parseHex('0xfa0f5b595eafe731'),
            Uint64.parseHex('0x3bdc477694c306e7'),
            Uint64.parseHex('0x2149be4b3949fa24'),
            Uint64.parseHex('0x64aa6e0649b2078c'),
            Uint64.parseHex('0x12b108ac33643c3e'),
          ]),
          c1: Bls12Fp([
            Uint64.parseHex('0x125325df3d35b5a8'),
            Uint64.parseHex('0xdc469ef5555d7fe3'),
            Uint64.parseHex('0x02d716d2443106a9'),
            Uint64.parseHex('0x05a1db59a6ff37d0'),
            Uint64.parseHex('0x7cf7784e5300bb8f'),
            Uint64.parseHex('0x16a88922c7a5e844'),
          ]),
        ).toNative();

    b = G2NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G2NativeProjective.generator());
  }
}

void _testConditionallySelectAffine() {
  final a = G2NativeAffinePoint.generator();
  final b = G2NativeAffinePoint.identity();

  expect(G2NativeAffinePoint.conditionalSelect(a, b, false), a);
  expect(G2NativeAffinePoint.conditionalSelect(a, b, true), b);
}

void _testConditionallySelectProjective() {
  final a = G2NativeProjective.generator();
  final b = G2NativeProjective.identity();

  expect(G2NativeProjective.conditionalSelect(a, b, false), a);
  expect(G2NativeProjective.conditionalSelect(a, b, true), b);
}

void _testProjectiveToAffine() {
  final a = G2NativeProjective.generator();
  final b = G2NativeProjective.identity();

  final aAffine = G2NativeAffinePoint.fromProjective(a);
  final bAffine = G2NativeAffinePoint.fromProjective(b);

  expect(aAffine.isOnCurve(), true);
  expect(aAffine.isIdentity(), false);
  expect(bAffine.isOnCurve(), true);
  expect(bAffine.isIdentity(), true);

  final z =
      Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x125325df3d35b5a8'),
          Uint64.parseHex('0xdc469ef5555d7fe3'),
          Uint64.parseHex('0x02d716d2443106a9'),
          Uint64.parseHex('0x05a1db59a6ff37d0'),
          Uint64.parseHex('0x7cf7784e5300bb8f'),
          Uint64.parseHex('0x16a88922c7a5e844'),
        ]),
      ).toNative();

  final c = G2NativeProjective(x: a.x * z, y: a.y * z, z: z);

  expect(
    G2NativeAffinePoint.fromProjective(c),
    G2NativeAffinePoint.generator(),
  );
}

void _testAffinePointEquality() {
  final a = G2NativeAffinePoint.generator();
  final b = G2NativeAffinePoint.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);
}

void _testProjectivePointEquality() {
  final a = G2NativeProjective.generator();
  final b = G2NativeProjective.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);

  final z =
      Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x125325df3d35b5a8'),
          Uint64.parseHex('0xdc469ef5555d7fe3'),
          Uint64.parseHex('0x02d716d2443106a9'),
          Uint64.parseHex('0x05a1db59a6ff37d0'),
          Uint64.parseHex('0x7cf7784e5300bb8f'),
          Uint64.parseHex('0x16a88922c7a5e844'),
        ]),
      ).toNative();

  var c = G2NativeProjective(x: a.x * z, y: a.y * z, z: z);
  expect(c.isOnCurve(), true);

  expect(a, c);
  expect(b != c, true);
  expect(c, a);
  expect(c != b, true);

  c = G2NativeProjective(x: c.x, y: -c.y, z: c.z);
  expect(c.isOnCurve(), true);

  expect(a != c, true);
  expect(b != c, true);
  expect(c != a, true);
  expect(c != b, true);

  c = G2NativeProjective(x: z, y: -c.y, z: c.z);
  expect(c.isOnCurve(), false);
  expect(a != b, true);
  expect(a != c, true);
  expect(b != c, true);
}

void _testIsOnCurve() {
  expect(G2NativeAffinePoint.identity().isOnCurve(), true);
  expect(G2NativeAffinePoint.generator().isOnCurve(), true);
  expect(G2NativeProjective.identity().isOnCurve(), true);
  expect(G2NativeProjective.generator().isOnCurve(), true);

  final z =
      Bls12Fp2(
        c0: Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]),
        c1: Bls12Fp([
          Uint64.parseHex('0x125325df3d35b5a8'),
          Uint64.parseHex('0xdc469ef5555d7fe3'),
          Uint64.parseHex('0x02d716d2443106a9'),
          Uint64.parseHex('0x05a1db59a6ff37d0'),
          Uint64.parseHex('0x7cf7784e5300bb8f'),
          Uint64.parseHex('0x16a88922c7a5e844'),
        ]),
      ).toNative();

  final gen = G2NativeAffinePoint.generator();
  var test = G2NativeProjective(x: gen.x * z, y: gen.y * z, z: z);

  expect(test.isOnCurve(), true);

  test = G2NativeProjective(x: z, y: test.y, z: test.z);

  expect(test.isOnCurve(), false);
}
