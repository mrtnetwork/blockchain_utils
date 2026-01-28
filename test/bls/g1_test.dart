import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("BLS12/G1", () {
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
  final generator = G1Projective.generator();
  final x = -JubJubFq.from(BigInt.parse("15132376222941642752"));

  expect(generator.mulByX(), generator * x);

  final point = G1Projective.generator() * JubJubFq.from(BigInt.from(42));
  expect(point.mulByX(), point * x);
}

void _testClearCofactor() {
  // the generator (and the identity) are always on the curve,
  // even after clearing the cofactor
  final generator = G1Projective.generator();
  expect(generator.clearCofactor().isOnCurve(), true);

  final id = G1Projective.identity();
  expect(id.clearCofactor().isOnCurve(), true);

  final z = Bls12Fp([
    BigInt.parse('0x3d2d1c670671394e'),
    BigInt.parse('0x0ee3a800a2f7c1ca'),
    BigInt.parse('0x270f4f21da2e5050'),
    BigInt.parse('0xe02840a53f1be768'),
    BigInt.parse('0x55debeb597512690'),
    BigInt.parse('0x08bd25353dc8f791'),
  ]);

  final point = G1Projective(
    x:
        Bls12Fp([
          BigInt.parse('0x48af5ff540c817f0'),
          BigInt.parse('0xd73893acaf379d5a'),
          BigInt.parse('0xe6c43584e18e023c'),
          BigInt.parse('0x1eda39c30f188b3e'),
          BigInt.parse('0xf618c6d3ccc0f8d8'),
          BigInt.parse('0x0073542cd671e16c'),
        ]) *
        z,
    y: Bls12Fp([
      BigInt.parse('0x57bf8be79461d0ba'),
      BigInt.parse('0xfc61459cee3547c3'),
      BigInt.parse('0x0d23567df1ef147b'),
      BigInt.parse('0x0ee187bcce1d9b64'),
      BigInt.parse('0xb0c8cfbe9dc8fdc1'),
      BigInt.parse('0x1328661767ef368b'),
    ]),
    z: z.square() * z,
  );

  expect(point.isOnCurve(), true);
  expect(!G1AffinePoint.fromProjective(point).isTorsionFree(), true);

  final clearedPoint = point.clearCofactor();
  expect(clearedPoint.isOnCurve(), true);
  expect(G1AffinePoint.fromProjective(clearedPoint).isTorsionFree(), true);

  // in BLS12-381 the cofactor in G1 can be
  // cleared multiplying by (1-x)
  final hEff =
      JubJubFq.from(BigInt.one) +
      JubJubFq.from(BigInt.parse("15132376222941642752"));
  expect(point.clearCofactor(), point * hEff);
}

void _testProjectiveNegationAndSubtraction() {
  final a = G1Projective.generator().double();
  expect(a + (-a), G1Projective.identity());
  expect(a + (-a), a - a);
}

void _testAffineNegationAndSubtraction() {
  final a = G1AffinePoint.generator();
  expect(G1Projective.fromAffine(a) + (-a), G1Projective.identity());
  expect(G1Projective.fromAffine(a) + (-a), G1Projective.fromAffine(a) - a);
}

void _testProjectiveScalarMultiplication() {
  final g = G1Projective.generator();
  final a = JubJubFq.fromRaw([
    BigInt.parse('0x2b568297a56da71c'),
    BigInt.parse('0xd8c39ecb0ef375d1'),
    BigInt.parse('0x435c38da67bfbf96'),
    BigInt.parse('0x8088a05026b659b2'),
  ]);
  final b = JubJubFq.fromRaw([
    BigInt.parse('0x785fdd9b26ef8b85'),
    BigInt.parse('0xc997f25837695c18'),
    BigInt.parse('0x4c8dbc39e7b756c1'),
    BigInt.parse('0x70d9b6cc6d87df20'),
  ]);
  final c = a * b;

  expect((g * a) * b, g * c);
}

void _testAffineScalarMultiplication() {
  final g = G1AffinePoint.generator();
  final a = JubJubFq.fromRaw([
    BigInt.parse('0x2b568297a56da71c'),
    BigInt.parse('0xd8c39ecb0ef375d1'),
    BigInt.parse('0x435c38da67bfbf96'),
    BigInt.parse('0x8088a05026b659b2'),
  ]);
  final b = JubJubFq.fromRaw([
    BigInt.parse('0x785fdd9b26ef8b85'),
    BigInt.parse('0xc997f25837695c18'),
    BigInt.parse('0x4c8dbc39e7b756c1'),
    BigInt.parse('0x70d9b6cc6d87df20'),
  ]);
  final c = a * b;

  expect(G1AffinePoint.fromProjective(g * a) * b, g * c);
}

void _testIsTorsionFree() {
  final a = G1AffinePoint(
    x: Bls12Fp([
      BigInt.parse('0x0abaf895b97e43c8'),
      BigInt.parse('0xba4c6432eb9b61b0'),
      BigInt.parse('0x12506f52adfe307f'),
      BigInt.parse('0x75028c3439336b72'),
      BigInt.parse('0x84744f05b8e9bd71'),
      BigInt.parse('0x113d554fb09554f7'),
    ]),
    y: Bls12Fp([
      BigInt.parse('0x73e90e88f5cf01c0'),
      BigInt.parse('0x37007b65dd3197e2'),
      BigInt.parse('0x5cf9a1992f0d7c78'),
      BigInt.parse('0x4f83c10b9eb3330d'),
      BigInt.parse('0xf6a63f6f07f60961'),
      BigInt.parse('0x0c53b5b97e634df3'),
    ]),
    infinity: false,
  );

  expect(!a.isTorsionFree(), true);
  expect(G1AffinePoint.identity().isTorsionFree(), true);
  expect(G1AffinePoint.generator().isTorsionFree(), true);
}

void _testMixedAddition() {
  {
    final a = G1AffinePoint.identity();
    final b = G1Projective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  {
    final a = G1AffinePoint.identity();
    var b = G1Projective.generator();

    final z = Bls12Fp([
      BigInt.parse('0xba7afa1f9a6fe250'),
      BigInt.parse('0xfa0f5b595eafe731'),
      BigInt.parse('0x3bdc477694c306e7'),
      BigInt.parse('0x2149be4b3949fa24'),
      BigInt.parse('0x64aa6e0649b2078c'),
      BigInt.parse('0x12b108ac33643c3e'),
    ]);

    b = G1Projective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1Projective.generator());
  }

  {
    final a = G1AffinePoint.identity();
    var b = G1Projective.generator();

    final z = Bls12Fp([
      BigInt.parse('0xba7afa1f9a6fe250'),
      BigInt.parse('0xfa0f5b595eafe731'),
      BigInt.parse('0x3bdc477694c306e7'),
      BigInt.parse('0x2149be4b3949fa24'),
      BigInt.parse('0x64aa6e0649b2078c'),
      BigInt.parse('0x12b108ac33643c3e'),
    ]);

    b = G1Projective(x: b.x * z, y: b.y * z, z: z);

    final c = b + a;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1Projective.generator());
  }

  {
    final a = G1Projective.generator().double().double(); // 4P
    final b = G1Projective.generator().double(); // 2P
    final c = a + b;

    var d = G1Projective.generator();
    for (var i = 0; i < 5; i++) {
      d += G1AffinePoint.generator();
    }

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(d.isIdentity(), false);
    expect(d.isOnCurve(), true);
    expect(c, d);
  }

  // Degenerate case
  {
    var beta = Bls12Fp([
      BigInt.parse('0xcd03c9e48671f071'),
      BigInt.parse('0x5dab22461fcda5d2'),
      BigInt.parse('0x587042afd3851b95'),
      BigInt.parse('0x8eb60ebe01bacb9e'),
      BigInt.parse('0x03f97d6e83d050d2'),
      BigInt.parse('0x18f0206554638741'),
    ]);
    beta = beta.square();

    final aProj = G1Projective.generator().double().double();
    final b = G1Projective(x: aProj.x * beta, y: -aProj.y, z: aProj.z);

    final a = G1AffinePoint.fromProjective(aProj);

    expect(a.isOnCurve(), true);
    expect(b.isOnCurve(), true);

    final c = a + b;

    expect(
      G1AffinePoint.fromProjective(c),
      G1AffinePoint.fromProjective(
        G1Projective(
          x: Bls12Fp([
            BigInt.parse('0x29e1e987ef68f2d0'),
            BigInt.parse('0xc5f3ec531db03233'),
            BigInt.parse('0xacd6c4b6ca19730f'),
            BigInt.parse('0x18ad9e827bc2bab7'),
            BigInt.parse('0x46e3b2c5785cc7a9'),
            BigInt.parse('0x07e571d42d22ddd6'),
          ]),
          y: Bls12Fp([
            BigInt.parse('0x94d117a7e5a539e7'),
            BigInt.parse('0x8e17ef673d4b5d22'),
            BigInt.parse('0x9d746aaf508a33ea'),
            BigInt.parse('0x8c6d883d2516c9a2'),
            BigInt.parse('0x0bc3b8d5fb0447f7'),
            BigInt.parse('0x07bfa4c7210f4f44'),
          ]),
          z: Bls12Fp.one(),
        ),
      ),
    );

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
  }
}

void _testAffineToProjective() {
  final a = G1AffinePoint.generator();
  final b = G1AffinePoint.identity();

  expect(G1Projective.fromAffine(a).isOnCurve(), true);
  expect(!G1Projective.fromAffine(a).isIdentity(), true);
  expect(G1Projective.fromAffine(b).isOnCurve(), true);
  expect(G1Projective.fromAffine(b).isIdentity(), true);
}

void _testDoubling() {
  {
    final tmp = G1Projective.identity().double();
    expect(tmp.isIdentity(), true);
    expect(tmp.isOnCurve(), true);
  }

  {
    final tmp = G1Projective.generator().double();
    expect(!tmp.isIdentity(), true);
    expect(tmp.isOnCurve(), true);

    expect(
      G1AffinePoint.fromProjective(tmp),
      G1AffinePoint(
        x: Bls12Fp([
          BigInt.parse('0x53e978ce58a9ba3c'),
          BigInt.parse('0x3ea0583c4f3d65f9'),
          BigInt.parse('0x4d20bb47f0012960'),
          BigInt.parse('0xa54c664ae5b2b5d9'),
          BigInt.parse('0x26b552a39d7eb21f'),
          BigInt.parse('0x0008895d26e68785'),
        ]),
        y: Bls12Fp([
          BigInt.parse('0x70110b3298293940'),
          BigInt.parse('0xda33c5393f1f6afc'),
          BigInt.parse('0xb86edfd16a5aa785'),
          BigInt.parse('0xaec6d1c9e7b1c895'),
          BigInt.parse('0x25cfc2b522d11720'),
          BigInt.parse('0x06361c83f8d09b15'),
        ]),
        infinity: false,
      ),
    );
  }
}

void _testProjectiveAddition() {
  {
    final a = G1Projective.identity();
    final b = G1Projective.identity();
    final c = a + b;
    expect(c.isIdentity(), true);
    expect(c.isOnCurve(), true);
  }

  {
    final a = G1Projective.identity();
    var b = G1Projective.generator();

    final z = Bls12Fp([
      BigInt.parse('0xba7afa1f9a6fe250'),
      BigInt.parse('0xfa0f5b595eafe731'),
      BigInt.parse('0x3bdc477694c306e7'),
      BigInt.parse('0x2149be4b3949fa24'),
      BigInt.parse('0x64aa6e0649b2078c'),
      BigInt.parse('0x12b108ac33643c3e'),
    ]);

    b = G1Projective(x: b.x * z, y: b.y * z, z: z);

    final c = a + b;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1Projective.generator());
  }

  {
    final a = G1Projective.identity();
    var b = G1Projective.generator();

    final z = Bls12Fp([
      BigInt.parse('0xba7afa1f9a6fe250'),
      BigInt.parse('0xfa0f5b595eafe731'),
      BigInt.parse('0x3bdc477694c306e7'),
      BigInt.parse('0x2149be4b3949fa24'),
      BigInt.parse('0x64aa6e0649b2078c'),
      BigInt.parse('0x12b108ac33643c3e'),
    ]);

    b = G1Projective(x: b.x * z, y: b.y * z, z: z);

    final c = b + a;
    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(c, G1Projective.generator());
  }

  {
    final a = G1Projective.generator().double().double(); // 4P
    final b = G1Projective.generator().double(); // 2P
    final c = a + b;

    var d = G1Projective.generator();
    for (var i = 0; i < 5; i++) {
      d += G1Projective.generator();
    }

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
    expect(!d.isIdentity(), true);
    expect(d.isOnCurve(), true);
    expect(c, d);
  }

  // Degenerate case
  {
    var beta = Bls12Fp([
      BigInt.parse('0xcd03c9e48671f071'),
      BigInt.parse('0x5dab22461fcda5d2'),
      BigInt.parse('0x587042afd3851b95'),
      BigInt.parse('0x8eb60ebe01bacb9e'),
      BigInt.parse('0x03f97d6e83d050d2'),
      BigInt.parse('0x18f0206554638741'),
    ]);
    beta = beta.square();

    final a = G1Projective.generator().double().double();
    final b = G1Projective(x: a.x * beta, y: -a.y, z: a.z);

    expect(a.isOnCurve(), true);
    expect(b.isOnCurve(), true);

    final c = a + b;

    expect(
      G1AffinePoint.fromProjective(c),
      G1AffinePoint.fromProjective(
        G1Projective(
          x: Bls12Fp([
            BigInt.parse('0x29e1e987ef68f2d0'),
            BigInt.parse('0xc5f3ec531db03233'),
            BigInt.parse('0xacd6c4b6ca19730f'),
            BigInt.parse('0x18ad9e827bc2bab7'),
            BigInt.parse('0x46e3b2c5785cc7a9'),
            BigInt.parse('0x07e571d42d22ddd6'),
          ]),
          y: Bls12Fp([
            BigInt.parse('0x94d117a7e5a539e7'),
            BigInt.parse('0x8e17ef673d4b5d22'),
            BigInt.parse('0x9d746aaf508a33ea'),
            BigInt.parse('0x8c6d883d2516c9a2'),
            BigInt.parse('0x0bc3b8d5fb0447f7'),
            BigInt.parse('0x07bfa4c7210f4f44'),
          ]),
          z: Bls12Fp.one(),
        ),
      ),
    );

    expect(c.isIdentity(), false);
    expect(c.isOnCurve(), true);
  }
}

void _testConditionallySelectAffine() {
  final a = G1AffinePoint.generator();
  final b = G1AffinePoint.identity();

  expect(G1AffinePoint.conditionalSelect(a, b, false), a);
  expect(G1AffinePoint.conditionalSelect(a, b, true), b);
}

void _testConditionallySelectProjective() {
  final a = G1Projective.generator();
  final b = G1Projective.identity();

  expect(G1Projective.conditionalSelect(a, b, false), a);
  expect(G1Projective.conditionalSelect(a, b, true), b);
}

void _testProjectiveToAffine() {
  final a = G1Projective.generator();
  final b = G1Projective.identity();

  expect(G1AffinePoint.fromProjective(a).isOnCurve(), true);
  expect(!G1AffinePoint.fromProjective(a).isIdentity(), true);
  expect(G1AffinePoint.fromProjective(b).isOnCurve(), true);
  expect(G1AffinePoint.fromProjective(b).isIdentity(), true);

  final z = Bls12Fp([
    BigInt.parse('0xba7afa1f9a6fe250'),
    BigInt.parse('0xfa0f5b595eafe731'),
    BigInt.parse('0x3bdc477694c306e7'),
    BigInt.parse('0x2149be4b3949fa24'),
    BigInt.parse('0x64aa6e0649b2078c'),
    BigInt.parse('0x12b108ac33643c3e'),
  ]);

  final c = G1Projective(x: a.x * z, y: a.y * z, z: z);

  expect(G1AffinePoint.fromProjective(c), G1AffinePoint.generator());
}

void _testProjectivePointEquality() {
  final a = G1Projective.generator();
  final b = G1Projective.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);

  final z = Bls12Fp([
    BigInt.parse('0xba7afa1f9a6fe250'),
    BigInt.parse('0xfa0f5b595eafe731'),
    BigInt.parse('0x3bdc477694c306e7'),
    BigInt.parse('0x2149be4b3949fa24'),
    BigInt.parse('0x64aa6e0649b2078c'),
    BigInt.parse('0x12b108ac33643c3e'),
  ]);

  var c = G1Projective(x: a.x * z, y: a.y * z, z: z);

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
  expect(!c.isOnCurve(), true);
  expect(a != b, true);
  expect(a != c, true);
  expect(b != c, true);
}

void _affinePointEquality() {
  final a = G1AffinePoint.generator();
  final b = G1AffinePoint.identity();

  expect(a, a);
  expect(b, b);
  expect(a != b, true);
  expect(b != a, true);
}

void _isOnCurve() {
  expect(G1AffinePoint.identity().isOnCurve(), true);
  expect(G1AffinePoint.generator().isOnCurve(), true);
  expect(G1Projective.identity().isOnCurve(), true);
  expect(G1Projective.generator().isOnCurve(), true);

  final z = Bls12Fp([
    BigInt.parse('0xba7afa1f9a6fe250'),
    BigInt.parse('0xfa0f5b595eafe731'),
    BigInt.parse('0x3bdc477694c306e7'),
    BigInt.parse('0x2149be4b3949fa24'),
    BigInt.parse('0x64aa6e0649b2078c'),
    BigInt.parse('0x12b108ac33643c3e'),
  ]);

  final gen = G1AffinePoint.generator();
  G1Projective test = G1Projective(x: gen.x * z, y: gen.y * z, z: z);

  expect(test.isOnCurve(), true);

  test = G1Projective(x: z, y: test.y, z: test.z);
  expect(test.isOnCurve(), false);
}

void _beta() {
  expect(
    Bls12Fp.beta(),
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
  expect(Bls12Fp.beta() != Bls12Fp.one(), true);
  expect(Bls12Fp.beta() * Bls12Fp.beta() != Bls12Fp.one(), true);
  expect(Bls12Fp.beta() * Bls12Fp.beta() * Bls12Fp.beta(), Bls12Fp.one());
}
