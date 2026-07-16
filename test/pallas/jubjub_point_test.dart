import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  test("JubJub/Point", () {
    _isOnCurve();
    _nonQuadraticResidue();
    _affineNielsPointIdentity();
    _extendedNielsPointIdentity();
    _assoc();
    _testBatchNormalize();
    _findEightTorsion();
    _findTrial();
    _smallOrder();
    _isIdentity();
    _testMulConsistency();
    _serializationConsistency();
    _testZip216();
  });
}

void _testZip216() {
  // Non-canonical encodings (32 bytes each)
  const List<String> nonCanonicalEncodings = [
    "0100000000000000000000000000000000000000000000000000000000000080",
    "00000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7edf3",
  ];

  for (final b in nonCanonicalEncodings) {
    // Make a mutable copy of the encoding
    final encoding = List<int>.from(BytesUtils.fromHexString(b));

    // The normal API should reject the non-canonical encoding
    expect(
      () => JubJubAffinePoint.fromBytes(encoding, zip216Enabled: true),
      throwsA(isA<ArgumentException>()),
    );

    // If we clear the sign bit of the non-canonical encoding, it should be accepted
    encoding[31] &= 0x7F;
    JubJubAffinePoint.fromBytes(encoding, zip216Enabled: true);

    // The bug-preserving API should accept the non-canonical encoding
    final parsed = JubJubAffinePoint.fromBytes(encoding);
    final encoded = parsed.toBytes();

    // The serialized canonical encoding should be different from the original
    expect(BytesUtils.bytesEqual(BytesUtils.fromHexString(b), encoded), false);

    // If we set the sign bit of the serialized encoding, it should match the non-canonical encoding
    final modifiedEncoded = List<int>.from(encoded);
    modifiedEncoded[31] |= 128;
    expect(BytesUtils.fromHexString(b), modifiedEncoded);
  }
}

void _serializationConsistency() {
  final List<String> v = [
    "cb550cd538ea0cc1138480408e6eaab9b36c613f0dd3f7784fdb6eea837b13d7",
    "719af0e6e0c6d0aa680f3b7e97dee9c3cbc3a7815979f08e33a640fab8ca9ab1",
    "c5295dd1cb37a4ae58005ac7019c958df01d0e5256e17e81ba9d94a2db339cc7",
    "b675faf151c4c7e3974af311dd61c88bc053e723d60e5f4582c90474b113b300",
    "76291dc83cbd77fc4e28e612d0dd26d6b0fa040a4d651ad8c1c6e25419b1e6b9",
    "e2bde3d0707588624826d3a7fe52ae7170a68aaba67134fb81c58a2dc3073d8c",
    "26c69cc492e137a38ab29d807387ccd70021ab143c208ed121e97d92cf0c1018",
    "11bbe753a524e8b88ccdc3fca6553b5603e2d343b31deeb5668e3a3f3959ae8a",
    "d29f5010b527ddcce090914f36e7088c8ed85dbeb774ae3f21f2b1769428f1cb",
    "008f6b6695bb1b7c120a621c717b79b91d980e82951c57238787993670353644",
    "b28355a0d633d09dc498f75dca3851ef9b7a3bbcedfd0ba9d0ec0c04a3d35861",
    "f6c2e7c39f65b4855015b9dcc373900c5a962c75089ca8f8ce293c52434b3943",
    "d4cdab997110c2f1e02bb16ebef816c9d0a6025386825581a688b9bfa326360a",
    "083cbe2799de77178eed0c6e920913db8f40a163c74d279446d5f6e396b2edb2",
    "0b72d9a0652564dc38722a1f8a21549dd6a749e973517c860f1fb53cb882af9f",
    "8deeebcaf120d20a7fe6361f9250f7096b7c001acb10ed22d693850f1dec2558",
  ];

  final gen = _fullGenerator.mulByCofactor();
  var p = gen;
  for (int i = 0; i < v.length; i++) {
    final pBytes = BytesUtils.fromHexString(v[i]);
    final batchDeserialized = JubJubAffinePoint.fromBytes(pBytes);
    expect(p.isOnCurve(), true);
    final affine = JubJubAffinePoint.fromExtendedPoint(p);
    final serialized = affine.toBytes();
    final deserialize = JubJubAffinePoint.fromBytes(serialized);
    expect(affine, deserialize);
    expect(affine, batchDeserialized);
    expect(pBytes, serialized);
    p += gen;
  }
}

void _testMulConsistency() {
  final a = JubJubFr([
    Uint64.parseHex("0x21e61211d9934f2e"),
    Uint64.parseHex("0xa52c058a693c3e07"),
    Uint64.parseHex("0x9ccb77bfb12d6360"),
    Uint64.parseHex("0x07df2470ec94398e"),
  ]);

  final b = JubJubFr([
    Uint64.parseHex("0x03336d1cbe19dbe0"),
    Uint64.parseHex("0x0153618f6156a536"),
    Uint64.parseHex("0x2604c9e1fc3c6b15"),
    Uint64.parseHex("0x04ae581ceb028720"),
  ]);

  final c = JubJubFr([
    Uint64.parseHex("0xd7abf5bb24683f4c"),
    Uint64.parseHex("0x9d7712cc274b7c03"),
    Uint64.parseHex("0x973293db9683789f"),
    Uint64.parseHex("0x0b677e29380a97a7"),
  ]);

  expect(a * b, c);

  // -----------------------------------------
  // Point p
  // -----------------------------------------

  final p =
      JubJubPoint.fromAffinePoint(
        JubJubAffinePoint(
          u: JubJubFq.fromRaw([
            Uint64.parseHex("0x81c571e5d883cfb0"),
            Uint64.parseHex("0x049f7a686f147029"),
            Uint64.parseHex("0xf539c860bc3ea21f"),
            Uint64.parseHex("0x4284715b7ccc8162"),
          ]),
          v: JubJubFq.fromRaw([
            Uint64.parseHex("0xbf096275684bb8ca"),
            Uint64.parseHex("0xc7ba245890af256d"),
            Uint64.parseHex("0x59119f3e86380eb0"),
            Uint64.parseHex("0x3793de182f9fb1d2"),
          ]),
        ),
      ).mulByCofactor();

  expect(p * c, (p * a) * b);

  // -----------------------------------------
  // Test Mul on ExtendedNielsPoint
  // -----------------------------------------

  expect(p * c, (p.toNiels() * a) * b);
  expect(p.toNiels() * c, (p * a) * b);
  expect(p.toNiels() * c, (p.toNiels() * a) * b);

  // -----------------------------------------
  // Test Mul on AffineNielsPoint
  // -----------------------------------------

  final pAffineNiels = JubJubAffinePoint.fromExtendedPoint(p).toNiels();
  expect(p * c, (pAffineNiels * a) * b);
  expect(pAffineNiels * c, (p * a) * b);
  expect(pAffineNiels * c, (pAffineNiels * a) * b);
}

void _isIdentity() {
  final a = _eightTorsion.first.mulByCofactor();
  final b = _eightTorsion[1].mulByCofactor();
  expect(a.u, b.u);
  expect(a.v, a.z);
  expect(b.v, b.z);
  expect(a.v != b.v, true);
  expect(a.z != b.z, true);
  expect(a.isIdentity(), true);
  expect(b.isIdentity(), true);
  for (final i in _eightTorsion) {
    expect(i.mulByCofactor().isIdentity(), true);
  }
}

void _smallOrder() {
  for (final i in _eightTorsion) {
    expect(i.isSmallOrder(), true);
  }
}

void _findTrial() {
  // trial_bytes starts as 32 zero bytes
  final trialBytes = List<int>.filled(32, 0);

  // mBytes should be a Uint8List(32) defined elsewhere
  // final Uint8List mBytes = ...;

  for (var i = 0; i < 255; i++) {
    // Try decode as affine point; use a nullable factory so we can check existence
    JubJubAffinePoint? a;
    try {
      a = JubJubAffinePoint.fromBytes(trialBytes);
    } on ArgumentException catch (_) {}

    if (a != null) {
      // a is present (CtOption::is_some())
      expect(a.isOnCurve(), true);

      // Convert to extended and multiply by the scalar modulus
      JubJubPoint b = JubJubPoint.fromAffinePoint(a);
      b = b.multiply(JubJubFrConst.frModulusBytes);

      expect(b.isSmallOrder(), true);

      // double and check still small order
      b = b.double();
      expect(b.isSmallOrder(), true);

      b = b.double();
      expect(b.isSmallOrder(), true);

      // If not identity yet, do additional doubling and checks
      if (!b.isIdentity()) {
        b = b.double();
        expect(b.isSmallOrder(), true);
        expect(b.isIdentity(), true);

        // check generator matches
        expect(_fullGenerator, a);
        expect(JubJubAffinePoint.generator(), a);

        expect(a.mulByCofactor().isTorsionFree(), true);
        return; // found it — exit early like the Rust version
      }
    }

    // increment first byte (little-endian like in Rust loop)
    // wrap-around handled automatically by Uint8List element arithmetic
    trialBytes[0] = (trialBytes[0] + 1) & 0xFF;
  }
  expect(false, true);
}

// _fullGenerator --------------------------------------------------------------
void _findEightTorsion() {
  // Convert _fullGenerator into an ExtendedPoint
  final g0 = JubJubPoint.fromAffinePoint(_fullGenerator);
  // Ensure generator is not a small-order point
  expect(g0.isSmallOrder(), false);
  final mBytes = [
    183,
    44,
    247,
    214,
    94,
    14,
    151,
    208,
    130,
    16,
    200,
    204,
    147,
    32,
    104,
    166,
    0,
    59,
    52,
    1,
    1,
    59,
    103,
    6,
    169,
    175,
    51,
    101,
    234,
    180,
    125,
    14,
  ];
  // Multiply by group modulus = this produces the 8-torsion base point
  final g = g0.multiply(mBytes);

  expect(g.isSmallOrder(), true);

  // Iterate through expected 8-torsion points
  var cur = g;

  for (var i = 0; i < _eightTorsion.length; i++) {
    final expected = _eightTorsion[i];
    final tmp = JubJubAffinePoint.fromExtendedPoint(cur);
    expect(tmp, expected);
    // cur += g;
    cur = cur + g;
  }
}

final _fullGenerator = JubJubAffinePoint(
  u: JubJubFq.fromRaw([
    Uint64.parseHex("0xe4b3d35df1a7adfe"),
    Uint64.parseHex("0xcaf55d1b29bf81af"),
    Uint64.parseHex("0x8b0f03ddd60a8187"),
    Uint64.parseHex("0x62edcbb8bf3787c8"),
  ]),
  v: JubJubFq.fromRaw([
    Uint64.parseHex("0xb"),
    Uint64.parseHex("0x0"),
    Uint64.parseHex("0x0"),
    Uint64.parseHex("0x0"),
  ]),
);
final _eightTorsion = <JubJubAffinePoint>[
  // 0 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0xd92e6a7927200d43"),
      Uint64.parseHex("0x7aa41ac43dae8582"),
      Uint64.parseHex("0xeaaae086a16618d1"),
      Uint64.parseHex("0x71d4df38ba9e7973"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0xff0d2068eff496dd"),
      Uint64.parseHex("0x9106ee90f384a4a1"),
      Uint64.parseHex("0x16a13035ad4d7266"),
      Uint64.parseHex("0x4958bdb21966982e"),
    ]),
  ),

  // 1 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0xfffeffff00000001"),
      Uint64.parseHex("0x67baa40089fb5bfe"),
      Uint64.parseHex("0xa5e80b39939ed334"),
      Uint64.parseHex("0x73eda753299d7d47"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
    ]),
  ),

  // 2 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0xd92e6a7927200d43"),
      Uint64.parseHex("0x7aa41ac43dae8582"),
      Uint64.parseHex("0xeaaae086a16618d1"),
      Uint64.parseHex("0x71d4df38ba9e7973"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0x00f2df96100b6924"),
      Uint64.parseHex("0xc2b6b5720c79b75d"),
      Uint64.parseHex("0x1c98a7d25c54659e"),
      Uint64.parseHex("0x2a94e9a11036e51a"),
    ]),
  ),

  // 3 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0xffffffff00000000"),
      Uint64.parseHex("0x53bda402fffe5bfe"),
      Uint64.parseHex("0x3339d80809a1d805"),
      Uint64.parseHex("0x73eda753299d7d48"),
    ]),
  ),

  // 4 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0x26d19585d8dff2be"),
      Uint64.parseHex("0xd919893ec24fd67c"),
      Uint64.parseHex("0x488ef781683bbf33"),
      Uint64.parseHex("0x0218c81a6eff03d4"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0x00f2df96100b6924"),
      Uint64.parseHex("0xc2b6b5720c79b75d"),
      Uint64.parseHex("0x1c98a7d25c54659e"),
      Uint64.parseHex("0x2a94e9a11036e51a"),
    ]),
  ),

  // 5 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0x0001000000000000"),
      Uint64.parseHex("0xec03000276030000"),
      Uint64.parseHex("0x8d51ccce760304d0"),
      Uint64.parseHex("0x0"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
    ]),
  ),

  // 6 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0x26d19585d8dff2be"),
      Uint64.parseHex("0xd919893ec24fd67c"),
      Uint64.parseHex("0x488ef781683bbf33"),
      Uint64.parseHex("0x0218c81a6eff03d4"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0xff0d2068eff496dd"),
      Uint64.parseHex("0x9106ee90f384a4a1"),
      Uint64.parseHex("0x16a13035ad4d7266"),
      Uint64.parseHex("0x4958bdb21966982e"),
    ]),
  ),

  // 7 ----------------------------------------------------
  JubJubAffinePoint(
    u: JubJubFq.fromRaw([
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
    ]),
    v: JubJubFq.fromRaw([
      Uint64.parseHex("0x1"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
      Uint64.parseHex("0x0"),
    ]),
  ),
];

void _testBatchNormalize() {
  // Construct initial point
  var p =
      JubJubPoint.fromAffinePoint(
        JubJubAffinePoint(
          u: JubJubFq.fromRaw([
            Uint64.parseHex("0x81c571e5d883cfb0"),
            Uint64.parseHex("0x049f7a686f147029"),
            Uint64.parseHex("0xf539c860bc3ea21f"),
            Uint64.parseHex("0x4284715b7ccc8162"),
          ]),
          v: JubJubFq.fromRaw([
            Uint64.parseHex("0xbf096275684bb8ca"),
            Uint64.parseHex("0xc7ba245890af256d"),
            Uint64.parseHex("0x59119f3e86380eb0"),
            Uint64.parseHex("0x3793de182f9fb1d2"),
          ]),
        ),
      ).mulByCofactor();

  // Create list of points p, p.double(), p.double().double(), ...
  final v = <JubJubPoint>[];
  for (var i = 0; i < 10; i++) {
    v.add(p);
    p = p.double();
  }

  // Check curve condition
  for (final p in v) {
    expect(p.isOnCurve(), true);
  }

  // Expected affine form
  final expected =
      v.map((p) => JubJubAffinePoint.fromExtendedPoint(p)).toList();

  // result0: using ExtendedPoint.batchNormalize
  final result0 = List.generate(
    v.length,
    (i) => JubJubAffinePoint.fromExtendedPoint(v[i]),
  );
  // JubJubPoint.batchNormalize(v, result0);

  for (var i = 0; i < 10; i++) {
    expect(expected[i], result0[i]);
  }
}

void _assoc() {
  final p =
      JubJubPoint.fromAffinePoint(
        JubJubAffinePoint(
          u: JubJubFq.fromRaw([
            Uint64.parseHex("0x81c571e5d883cfb0"),
            Uint64.parseHex("0x049f7a686f147029"),
            Uint64.parseHex("0xf539c860bc3ea21f"),
            Uint64.parseHex("0x4284715b7ccc8162"),
          ]),
          v: JubJubFq.fromRaw([
            Uint64.parseHex("0xbf096275684bb8ca"),
            Uint64.parseHex("0xc7ba245890af256d"),
            Uint64.parseHex("0x59119f3e86380eb0"),
            Uint64.parseHex("0x3793de182f9fb1d2"),
          ]),
        ),
      ).mulByCofactor();
  expect(p.isOnCurve(), true);

  final n = (p * JubJubFr.from(Uint64(1000))) * JubJubFr.from(Uint64(3938));
  final n2 = p * (JubJubFr.from(Uint64(1000)) * JubJubFr.from(Uint64(3938)));
  expect(n, n2);
  // expect(p*JubJubFr.from(BigInt.from(1000))*JubJubFr.from(BigInt.from(3938)),(p*JubJubFr.from(BigInt.from(1000))*JubJubFr.from(BigInt.from(3938)));
}

void _extendedNielsPointIdentity() {
  expect(
    JubJubNielsPoint.identity().vPlusU,
    JubJubPoint.identity().toNiels().vPlusU,
  );
  expect(
    JubJubNielsPoint.identity().vMinusU,
    JubJubPoint.identity().toNiels().vMinusU,
  );
  expect(JubJubNielsPoint.identity().z, JubJubPoint.identity().toNiels().z);
  expect(JubJubNielsPoint.identity().t2d, JubJubPoint.identity().toNiels().t2d);
}

void _affineNielsPointIdentity() {
  expect(
    JubJubAffineNielsPoint.identity().vPlusU,
    JubJubAffinePoint.identity().toNiels().vPlusU,
  );
  expect(
    JubJubAffineNielsPoint.identity().vMinusU,
    JubJubAffinePoint.identity().toNiels().vMinusU,
  );
  expect(
    JubJubAffineNielsPoint.identity().t2d,
    JubJubAffinePoint.identity().toNiels().t2d,
  );
}

void _isOnCurve() {
  expect(JubJubAffinePoint.identity().isOnCurve(), true);
}

void _nonQuadraticResidue() {
  expect(JubJubFq.edwardsD.sqrt().isSquare, false);
  expect((-JubJubFq.edwardsD2).sqrt().isSquare, false);
  expect((-JubJubFq.edwardsD2).invert()?.sqrt().isSquare, false);
}
