import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';
import 'fp_test.dart';

void main() {
  test("BLS12/G1 Native", () {
    _beta();
    _isOnCurve();
    _affinePointEquality();
    _testProjectivePointEquality();
    _testConditionallySelectAffine();
    _testConditionallySelectProjective();
    _testProjectiveToAffine();
    _testAffineToProjective();
    _testDoubling();
    _testProjectiveAddition();
    _testMixedAddition();
    _testProjectiveNegationAndSubtraction();
    _testAffineNegationAndSubtraction();
    _testProjectiveScalarMultiplication();
    _testAffineScalarMultiplication();
    _testIsTorsionFree();
    _testMulByX();
    _testClearCofactor();
  });
}

void _testMulByX() {
  final generator = G1NativeProjective.generator();
  final x = -JubJubNativeFq(BigInt.parse("15132376222941642752"));

  expect(generator.mulByX(), generator * x);

  final point =
      G1NativeProjective.generator() * JubJubNativeFq(BigInt.from(42));
  expect(point.mulByX(), point * x);
}

void _testClearCofactor() {
  // the generator (and the identity) are always on the curve,
  // even after clearing the cofactor
  final generator = G1NativeProjective.generator();
  expect(generator.clearCofactor().isOnCurve(), true);

  final id = G1NativeProjective.identity();
  expect(id.clearCofactor().isOnCurve(), true);

  final z =
      Bls12Fp([
        Uint64.parseHex('0x3d2d1c670671394e'),
        Uint64.parseHex('0x0ee3a800a2f7c1ca'),
        Uint64.parseHex('0x270f4f21da2e5050'),
        Uint64.parseHex('0xe02840a53f1be768'),
        Uint64.parseHex('0x55debeb597512690'),
        Uint64.parseHex('0x08bd25353dc8f791'),
      ]).toNative();

  final point = G1NativeProjective(
    x:
        Bls12Fp([
          Uint64.parseHex('0x48af5ff540c817f0'),
          Uint64.parseHex('0xd73893acaf379d5a'),
          Uint64.parseHex('0xe6c43584e18e023c'),
          Uint64.parseHex('0x1eda39c30f188b3e'),
          Uint64.parseHex('0xf618c6d3ccc0f8d8'),
          Uint64.parseHex('0x0073542cd671e16c'),
        ]).toNative() *
        z,
    y:
        Bls12Fp([
          Uint64.parseHex('0x57bf8be79461d0ba'),
          Uint64.parseHex('0xfc61459cee3547c3'),
          Uint64.parseHex('0x0d23567df1ef147b'),
          Uint64.parseHex('0x0ee187bcce1d9b64'),
          Uint64.parseHex('0xb0c8cfbe9dc8fdc1'),
          Uint64.parseHex('0x1328661767ef368b'),
        ]).toNative(),
    z: z.square() * z,
  );

  expect(point.isOnCurve(), true);
  expect(G1NativeAffinePoint.fromProjective(point).isTorsionFree(), false);

  final clearedPoint = point.clearCofactor();
  expect(clearedPoint.isOnCurve(), true);
  expect(
    G1NativeAffinePoint.fromProjective(clearedPoint).isTorsionFree(),
    true,
  );

  // in BLS12-381 the cofactor in G1 can be
  // cleared multiplying by (1-x)
  final hEff =
      JubJubNativeFq(BigInt.one) +
      JubJubNativeFq(BigInt.parse("15132376222941642752"));
  expect(point.clearCofactor(), point * hEff);
}

void _testProjectiveNegationAndSubtraction() {
  final a = G1NativeProjective.generator().double();
  expect(a + (-a), G1NativeProjective.identity());
  expect(a + (-a), a - a);
}

void _testAffineNegationAndSubtraction() {
  final a = G1NativeAffinePoint.generator();
  expect(
    G1NativeProjective.fromAffine(a) + (-a),
    G1NativeProjective.identity(),
  );
  expect(
    G1NativeProjective.fromAffine(a) + (-a),
    G1NativeProjective.fromAffine(a) - a,
  );
}

void _testProjectiveScalarMultiplication() {
  final g = G1NativeProjective.generator();
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
  final g = G1NativeAffinePoint.generator();
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

  expect(G1NativeAffinePoint.fromProjective(g * a) * b, g * c);
}

void _testIsTorsionFree() {
  final a = G1NativeAffinePoint(
    x:
        Bls12Fp([
          Uint64.parseHex('0x0abaf895b97e43c8'),
          Uint64.parseHex('0xba4c6432eb9b61b0'),
          Uint64.parseHex('0x12506f52adfe307f'),
          Uint64.parseHex('0x75028c3439336b72'),
          Uint64.parseHex('0x84744f05b8e9bd71'),
          Uint64.parseHex('0x113d554fb09554f7'),
        ]).toNative(),
    y:
        Bls12Fp([
          Uint64.parseHex('0x73e90e88f5cf01c0'),
          Uint64.parseHex('0x37007b65dd3197e2'),
          Uint64.parseHex('0x5cf9a1992f0d7c78'),
          Uint64.parseHex('0x4f83c10b9eb3330d'),
          Uint64.parseHex('0xf6a63f6f07f60961'),
          Uint64.parseHex('0x0c53b5b97e634df3'),
        ]).toNative(),
    infinity: false,
  );

  expect(a.isTorsionFree(), false);
  expect(G1NativeAffinePoint.identity().isTorsionFree(), true);
  expect(G1NativeAffinePoint.generator().isTorsionFree(), true);
}

void _testMixedAddition() {
  {
    final a = G1NativeAffinePoint.identity();
    final b = G1NativeProjective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  {
    final a = G1NativeAffinePoint.identity();
    var b = G1NativeProjective.generator();

    final z =
        Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]).toNative();

    b = G1NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1NativeProjective.generator());
  }

  {
    final a = G1NativeAffinePoint.identity();
    var b = G1NativeProjective.generator();

    final z =
        Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]).toNative();

    b = G1NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = b + a;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1NativeProjective.generator());
  }

  {
    final a = G1NativeProjective.generator().double().double(); // 4P
    final b = G1NativeProjective.generator().double(); // 2P
    final c = a + b;

    var d = G1NativeProjective.generator();
    for (var i = 0; i < 5; i++) {
      d += G1NativeAffinePoint.generator();
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
        Bls12Fp([
          Uint64.parseHex('0xcd03c9e48671f071'),
          Uint64.parseHex('0x5dab22461fcda5d2'),
          Uint64.parseHex('0x587042afd3851b95'),
          Uint64.parseHex('0x8eb60ebe01bacb9e'),
          Uint64.parseHex('0x03f97d6e83d050d2'),
          Uint64.parseHex('0x18f0206554638741'),
        ]).toNative();
    beta = beta.square();

    final aProj = G1NativeProjective.generator().double().double();
    final b = G1NativeProjective(x: aProj.x * beta, y: -aProj.y, z: aProj.z);

    final a = G1NativeAffinePoint.fromProjective(aProj);

    expect(a.isOnCurve(), true);
    expect(b.isOnCurve(), true);

    final c = a + b;

    expect(
      G1NativeAffinePoint.fromProjective(c),
      G1NativeAffinePoint.fromProjective(
        G1NativeProjective(
          x:
              Bls12Fp([
                Uint64.parseHex('0x29e1e987ef68f2d0'),
                Uint64.parseHex('0xc5f3ec531db03233'),
                Uint64.parseHex('0xacd6c4b6ca19730f'),
                Uint64.parseHex('0x18ad9e827bc2bab7'),
                Uint64.parseHex('0x46e3b2c5785cc7a9'),
                Uint64.parseHex('0x07e571d42d22ddd6'),
              ]).toNative(),
          y:
              Bls12Fp([
                Uint64.parseHex('0x94d117a7e5a539e7'),
                Uint64.parseHex('0x8e17ef673d4b5d22'),
                Uint64.parseHex('0x9d746aaf508a33ea'),
                Uint64.parseHex('0x8c6d883d2516c9a2'),
                Uint64.parseHex('0x0bc3b8d5fb0447f7'),
                Uint64.parseHex('0x07bfa4c7210f4f44'),
              ]).toNative(),
          z: Bls12NativeFp.one(),
        ),
      ),
    );

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
  }
}

void _testAffineToProjective() {
  final a = G1NativeAffinePoint.generator();
  final b = G1NativeAffinePoint.identity();

  expect(G1NativeProjective.fromAffine(a).isOnCurve(), true);
  expect(G1NativeProjective.fromAffine(a).isIdentity(), false);
  expect(G1NativeProjective.fromAffine(b).isOnCurve(), true);
  expect(G1NativeProjective.fromAffine(b).isIdentity(), true);
}

void _testDoubling() {
  {
    final tmp = G1NativeProjective.identity().double();
    expect(tmp.isIdentity(), true);
    expect(tmp.isOnCurve(), true);
  }

  {
    final tmp = G1NativeProjective.generator().double();
    expect(tmp.isIdentity(), false);
    expect(tmp.isOnCurve(), true);

    expect(
      G1NativeAffinePoint.fromProjective(tmp),
      G1NativeAffinePoint(
        x:
            Bls12Fp([
              Uint64.parseHex('0x53e978ce58a9ba3c'),
              Uint64.parseHex('0x3ea0583c4f3d65f9'),
              Uint64.parseHex('0x4d20bb47f0012960'),
              Uint64.parseHex('0xa54c664ae5b2b5d9'),
              Uint64.parseHex('0x26b552a39d7eb21f'),
              Uint64.parseHex('0x0008895d26e68785'),
            ]).toNative(),
        y:
            Bls12Fp([
              Uint64.parseHex('0x70110b3298293940'),
              Uint64.parseHex('0xda33c5393f1f6afc'),
              Uint64.parseHex('0xb86edfd16a5aa785'),
              Uint64.parseHex('0xaec6d1c9e7b1c895'),
              Uint64.parseHex('0x25cfc2b522d11720'),
              Uint64.parseHex('0x06361c83f8d09b15'),
            ]).toNative(),
        infinity: false,
      ),
    );
  }
}

void _testProjectiveAddition() {
  {
    final a = G1NativeProjective.identity();
    final b = G1NativeProjective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  {
    final a = G1NativeProjective.identity();
    var b = G1NativeProjective.generator();

    final z =
        Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]).toNative();

    b = G1NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1NativeProjective.generator());
  }

  {
    final a = G1NativeProjective.identity();
    var b = G1NativeProjective.generator();

    final z =
        Bls12Fp([
          Uint64.parseHex('0xba7afa1f9a6fe250'),
          Uint64.parseHex('0xfa0f5b595eafe731'),
          Uint64.parseHex('0x3bdc477694c306e7'),
          Uint64.parseHex('0x2149be4b3949fa24'),
          Uint64.parseHex('0x64aa6e0649b2078c'),
          Uint64.parseHex('0x12b108ac33643c3e'),
        ]).toNative();

    b = G1NativeProjective(x: b.x * z, y: b.y * z, z: z);

    final c = b + a;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1NativeProjective.generator());
  }

  {
    final a = G1NativeProjective.generator().double().double(); // 4P
    final b = G1NativeProjective.generator().double(); // 2P
    final c = a + b;

    var d = G1NativeProjective.generator();
    for (var i = 0; i < 5; i++) {
      d += G1NativeProjective.generator();
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
        Bls12Fp([
          Uint64.parseHex('0xcd03c9e48671f071'),
          Uint64.parseHex('0x5dab22461fcda5d2'),
          Uint64.parseHex('0x587042afd3851b95'),
          Uint64.parseHex('0x8eb60ebe01bacb9e'),
          Uint64.parseHex('0x03f97d6e83d050d2'),
          Uint64.parseHex('0x18f0206554638741'),
        ]).toNative();
    beta = beta.square();

    final a = G1NativeProjective.generator().double().double();
    final b = G1NativeProjective(x: a.x * beta, y: -a.y, z: a.z);

    expect(a.isOnCurve(), true);
    expect(b.isOnCurve(), true);

    final c = a + b;

    expect(
      G1NativeAffinePoint.fromProjective(c),
      G1NativeAffinePoint.fromProjective(
        G1NativeProjective(
          x:
              Bls12Fp([
                Uint64.parseHex('0x29e1e987ef68f2d0'),
                Uint64.parseHex('0xc5f3ec531db03233'),
                Uint64.parseHex('0xacd6c4b6ca19730f'),
                Uint64.parseHex('0x18ad9e827bc2bab7'),
                Uint64.parseHex('0x46e3b2c5785cc7a9'),
                Uint64.parseHex('0x07e571d42d22ddd6'),
              ]).toNative(),
          y:
              Bls12Fp([
                Uint64.parseHex('0x94d117a7e5a539e7'),
                Uint64.parseHex('0x8e17ef673d4b5d22'),
                Uint64.parseHex('0x9d746aaf508a33ea'),
                Uint64.parseHex('0x8c6d883d2516c9a2'),
                Uint64.parseHex('0x0bc3b8d5fb0447f7'),
                Uint64.parseHex('0x07bfa4c7210f4f44'),
              ]).toNative(),
          z: Bls12NativeFp.one(),
        ),
      ),
    );

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
  }
}

void _testConditionallySelectAffine() {
  final a = G1NativeAffinePoint.generator();
  final b = G1NativeAffinePoint.identity();

  expect(G1NativeAffinePoint.conditionalSelect(a, b, false), a);
  expect(G1NativeAffinePoint.conditionalSelect(a, b, true), b);
}

void _testConditionallySelectProjective() {
  final a = G1NativeProjective.generator();
  final b = G1NativeProjective.identity();

  expect(G1NativeProjective.conditionalSelect(a, b, false), a);
  expect(G1NativeProjective.conditionalSelect(a, b, true), b);
}

void _testProjectiveToAffine() {
  final a = G1NativeProjective.generator();
  final b = G1NativeProjective.identity();

  expect(G1NativeAffinePoint.fromProjective(a).isOnCurve(), true);
  expect(G1NativeAffinePoint.fromProjective(a).isIdentity(), false);
  expect(G1NativeAffinePoint.fromProjective(b).isOnCurve(), true);
  expect(G1NativeAffinePoint.fromProjective(b).isIdentity(), true);

  final z =
      Bls12Fp([
        Uint64.parseHex('0xba7afa1f9a6fe250'),
        Uint64.parseHex('0xfa0f5b595eafe731'),
        Uint64.parseHex('0x3bdc477694c306e7'),
        Uint64.parseHex('0x2149be4b3949fa24'),
        Uint64.parseHex('0x64aa6e0649b2078c'),
        Uint64.parseHex('0x12b108ac33643c3e'),
      ]).toNative();

  final c = G1NativeProjective(x: a.x * z, y: a.y * z, z: z);

  expect(
    G1NativeAffinePoint.fromProjective(c),
    G1NativeAffinePoint.generator(),
  );
}

void _testProjectivePointEquality() {
  final a = G1NativeProjective.generator();
  final b = G1NativeProjective.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);

  final z =
      Bls12Fp([
        Uint64.parseHex('0xba7afa1f9a6fe250'),
        Uint64.parseHex('0xfa0f5b595eafe731'),
        Uint64.parseHex('0x3bdc477694c306e7'),
        Uint64.parseHex('0x2149be4b3949fa24'),
        Uint64.parseHex('0x64aa6e0649b2078c'),
        Uint64.parseHex('0x12b108ac33643c3e'),
      ]).toNative();

  var c = G1NativeProjective(x: a.x * z, y: a.y * z, z: z);

  expect(c.isOnCurve(), true);

  expect(a, c);
  expect(b != c, true);
  expect(c, a);
  expect(c != b, true);

  c = c.copyWith(y: -c.y);
  expect(c.isOnCurve(), true);

  expect(a != c, true);
  expect(b != c, true);
  expect(c != a, true);
  expect(c != b, true);

  c = c.copyWith(y: -c.y);
  c = c.copyWith(x: z);
  expect(c.isOnCurve(), false);
  expect(a != b, true);
  expect(a != c, true);
  expect(b != c, true);
}

void _affinePointEquality() {
  final a = G1NativeAffinePoint.generator();
  final b = G1NativeAffinePoint.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);
}

void _isOnCurve() {
  expect((G1NativeAffinePoint.identity().isOnCurve()), true);
  expect((G1NativeAffinePoint.generator().isOnCurve()), true);
  expect((G1NativeProjective.identity().isOnCurve()), true);
  expect((G1NativeProjective.generator().isOnCurve()), true);

  final z =
      Bls12Fp([
        Uint64.parseHex('0xba7afa1f9a6fe250'),
        Uint64.parseHex('0xfa0f5b595eafe731'),
        Uint64.parseHex('0x3bdc477694c306e7'),
        Uint64.parseHex('0x2149be4b3949fa24'),
        Uint64.parseHex('0x64aa6e0649b2078c'),
        Uint64.parseHex('0x12b108ac33643c3e'),
      ]).toNative();

  final gen = G1NativeAffinePoint.generator();
  G1NativeProjective test = G1NativeProjective(
    x: gen.x * z,
    y: gen.y * z,
    z: z,
  );

  expect((test.isOnCurve()), true);

  test = G1NativeProjective(x: z, y: test.y, z: test.z);
  expect(!(test.isOnCurve()), true);
}

void _beta() {
  expect(
    Bls12Fp.beta,
    Bls12Fp.fromBytes([
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x00,
      0x5f,
      0x19,
      0x67,
      0x2f,
      0xdf,
      0x76,
      0xce,
      0x51,
      0xba,
      0x69,
      0xc6,
      0x07,
      0x6a,
      0x0f,
      0x77,
      0xea,
      0xdd,
      0xb3,
      0xa9,
      0x3b,
      0xe6,
      0xf8,
      0x96,
      0x88,
      0xde,
      0x17,
      0xd8,
      0x13,
      0x62,
      0x0a,
      0x00,
      0x02,
      0x2e,
      0x01,
      0xff,
      0xff,
      0xff,
      0xfe,
      0xff,
      0xfe,
    ]),
  );
  expect(Bls12Fp.beta != Bls12Fp.one, true);
  expect(Bls12Fp.beta * Bls12Fp.beta != Bls12Fp.one, true);
  expect(Bls12Fp.beta * Bls12Fp.beta * Bls12Fp.beta, Bls12Fp.one);
}

extension JubJubFqToNative on JubJubFq {
  JubJubNativeFq toNative() => JubJubNativeFq.fromBytes(toBytes());
}
