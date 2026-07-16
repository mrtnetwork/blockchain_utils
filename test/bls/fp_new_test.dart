import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  test("BLS12/FP", () {
    _conditionalSelection();
    _equality();
    _squaring();
    _multiplication();
    _addition();
    _subtraction();
    _negation();
    _debug();
    _testFromBytes();
    _testSqrt();
    _testInversion();
    _testLexicographicLargest();
  });
}

extension H on Bls12Fp {
  Bls12NativeFp toNative() => Bls12NativeFp.fromBytes(toBytes());
}

void _testSqrt() {
  // a = 4
  var a = Bls12Fp([
    Uint64.parseHex('0xaa270000000cfff3'),
    Uint64.parseHex('0x53cc0032fc34000a'),
    Uint64.parseHex('0x478fe97a6b0a807f'),
    Uint64.parseHex('0xb1d37ebee6ba24d7'),
    Uint64.parseHex('0x8ec9733bbf78ab2f'),
    Uint64.parseHex('0x09d645513d83de7e'),
  ]);

  expect(
    ((-a).sqrt()).result,
    Bls12Fp([
      Uint64.parseHex('0x321300000006554f'),
      Uint64.parseHex('0xb93c0018d6c40005'),
      Uint64.parseHex('0x57605e0db0ddbb51'),
      Uint64.parseHex('0x8b256521ed1f9bcb'),
      Uint64.parseHex('0x6cf28d7901622c03'),
      Uint64.parseHex('0x11ebab9dbb81e28c'),
    ]),
  );
}

void _testInversion() {
  var a = Bls12Fp([
    Uint64.parseHex('0x43b43a5078ac2076'),
    Uint64.parseHex('0x1ce0763046f8962b'),
    Uint64.parseHex('0x724a5276486d735c'),
    Uint64.parseHex('0x6f05c2a6282d48fd'),
    Uint64.parseHex('0x2095bd5bb4ca9331'),
    Uint64.parseHex('0x03b35b3894b0f7da'),
  ]);

  var b = Bls12Fp([
    Uint64.parseHex('0x69ecd7040952148f'),
    Uint64.parseHex('0x985ccc2022190f55'),
    Uint64.parseHex('0xe19bba36a9ad2f41'),
    Uint64.parseHex('0x19bb16c95219dbd8'),
    Uint64.parseHex('0x14dcacfdfb478693'),
    Uint64.parseHex('0x115ff58afff9a8e1'),
  ]);
  expect(a.invert(), b);
  expect(Bls12Fp.zero.invert(), null);
}

void _testLexicographicLargest() {
  expect(Bls12Fp.zero.lexicographicallyLargest(), false);
  expect(Bls12Fp.one.lexicographicallyLargest(), false);

  expect(
    Bls12Fp([
      Uint64.parseHex('0xa1fafffffffe5557'),
      Uint64.parseHex('0x995bfff976a3fffe'),
      Uint64.parseHex('0x03f41d24d174ceb4'),
      Uint64.parseHex('0xf6547998c1995dbd'),
      Uint64.parseHex('0x778a468f507a6034'),
      Uint64.parseHex('0x020559931f7f8103'),
    ]).lexicographicallyLargest(),
    false,
  );

  expect(
    Bls12Fp([
      Uint64.parseHex('0x1804000000015554'),
      Uint64.parseHex('0x855000053ab00001'),
      Uint64.parseHex('0x633cb57c253c276f'),
      Uint64.parseHex('0x6e22d1ec31ebb502'),
      Uint64.parseHex('0xd3916126f2d14ca2'),
      Uint64.parseHex('0x17fbb8571a006596'),
    ]).lexicographicallyLargest(),
    true,
  );

  expect(
    Bls12Fp([
      Uint64.parseHex('0x43f5fffffffcaaae'),
      Uint64.parseHex('0x32b7fff2ed47fffd'),
      Uint64.parseHex('0x07e83a49a2e99d69'),
      Uint64.parseHex('0xeca8f3318332bb7a'),
      Uint64.parseHex('0xef148d1ea0f4c069'),
      Uint64.parseHex('0x040ab3263eff0206'),
    ]).lexicographicallyLargest(),
    true,
  );
}

void _testFromBytes() {
  var a = Bls12Fp([
    Uint64.parseHex('0xdc906d9be3f95dc8'),
    Uint64.parseHex('0x8755caf7459691a1'),
    Uint64.parseHex('0xcff1a7f4e9583ab3'),
    Uint64.parseHex('0x9b43821f849e2284'),
    Uint64.parseHex('0xf57554f3a2974f3f'),
    Uint64.parseHex('0x085dbea84ed47f79'),
  ]);

  for (var i = 0; i < 100; i++) {
    a = a.square();
    var tmp = a.toBytes();
    var b = Bls12Fp.fromBytes(tmp);

    expect(a, b);
  }

  expect(
    -Bls12Fp.one,
    Bls12Fp.fromBytes(
      BytesUtils.fromHexString(
        "1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      ),
    ),
  );

  expect(
    () => Bls12Fp.fromBytes(
      BytesUtils.fromHexString(
        "1b0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      ),
    ),
    throwsA(isA<ArgumentException>()),
  );
  expect(
    () => Bls12Fp.fromBytes(List.filled(48, 0xff)),
    throwsA(isA<ArgumentException>()),
  );
}

void _debug() {
  final r = Bls12Fp([
    Uint64.parseHex('0x5360bb5978678032'),
    Uint64.parseHex('0x7dd275ae799e128e'),
    Uint64.parseHex('0x5c5b5071ce4f4dcf'),
    Uint64.parseHex('0xcdb21f93078dbb3e'),
    Uint64.parseHex('0xc32365c5e73f474a'),
    Uint64.parseHex('0x115a2a5489babe5b'),
  ]);
  expect(
    BytesUtils.toHexString(r.toBytes()),
    "104bf052ad3bc99bcb176c24a06a6c3aad4eaf2308fc4d282e106c84a757d061052630515305e59bdddf8111bfdeb704",
  );
}

void _subtraction() {
  final a = Bls12Fp([
    Uint64.parseHex('0x5360bb5978678032'),
    Uint64.parseHex('0x7dd275ae799e128e'),
    Uint64.parseHex('0x5c5b5071ce4f4dcf'),
    Uint64.parseHex('0xcdb21f93078dbb3e'),
    Uint64.parseHex('0xc32365c5e73f474a'),
    Uint64.parseHex('0x115a2a5489babe5b'),
  ]);
  final b = Bls12Fp([
    Uint64.parseHex('0x9fd287733d23dda0'),
    Uint64.parseHex('0xb16bf2af738b3554'),
    Uint64.parseHex('0x3e57a75bd3cc6d1d'),
    Uint64.parseHex('0x900bc0bd627fd6d6'),
    Uint64.parseHex('0xd319a080efb245fe'),
    Uint64.parseHex('0x15fdcaa4e4bb2091'),
  ]);
  final c = Bls12Fp([
    Uint64.parseHex('0x6d8d33e63b434d3d'),
    Uint64.parseHex('0xeb1282fdb766dd39'),
    Uint64.parseHex('0x85347bb6f133d6d5'),
    Uint64.parseHex('0xa21daa5a9892f727'),
    Uint64.parseHex('0x3b256cfb3ad8ae23'),
    Uint64.parseHex('0x155d7199de7f8464'),
  ]);

  expect(a - b, c);
}

void _negation() {
  final a = Bls12Fp([
    Uint64.parseHex('0x5360bb5978678032'),
    Uint64.parseHex('0x7dd275ae799e128e'),
    Uint64.parseHex('0x5c5b5071ce4f4dcf'),
    Uint64.parseHex('0xcdb21f93078dbb3e'),
    Uint64.parseHex('0xc32365c5e73f474a'),
    Uint64.parseHex('0x115a2a5489babe5b'),
  ]);
  final b = Bls12Fp([
    Uint64.parseHex('0x669e44a687982a79'),
    Uint64.parseHex('0xa0d98a5037b5ed71'),
    Uint64.parseHex('0x0ad5822f2861a854'),
    Uint64.parseHex('0x96c52bf1ebf75781'),
    Uint64.parseHex('0x87f841f05c0c658c'),
    Uint64.parseHex('0x08a6e795afc5283e'),
  ]);

  expect(-a, b);
}

void _addition() {
  final a = Bls12Fp([
    Uint64.parseHex('0x5360bb5978678032'),
    Uint64.parseHex('0x7dd275ae799e128e'),
    Uint64.parseHex('0x5c5b5071ce4f4dcf'),
    Uint64.parseHex('0xcdb21f93078dbb3e'),
    Uint64.parseHex('0xc32365c5e73f474a'),
    Uint64.parseHex('0x115a2a5489babe5b'),
  ]);
  final b = Bls12Fp([
    Uint64.parseHex('0x9fd287733d23dda0'),
    Uint64.parseHex('0xb16bf2af738b3554'),
    Uint64.parseHex('0x3e57a75bd3cc6d1d'),
    Uint64.parseHex('0x900bc0bd627fd6d6'),
    Uint64.parseHex('0xd319a080efb245fe'),
    Uint64.parseHex('0x15fdcaa4e4bb2091'),
  ]);
  final c = Bls12Fp([
    Uint64.parseHex('0x393442ccb58bb327'),
    Uint64.parseHex('0x1092685f3bd547e3'),
    Uint64.parseHex('0x3382252cab6ac4c9'),
    Uint64.parseHex('0xf94694cb76887f55'),
    Uint64.parseHex('0x4b215e9093a5e071'),
    Uint64.parseHex('0x0d56e30f34f5f853'),
  ]);

  expect(a + b, c);
}

void _multiplication() {
  final a = Bls12Fp([
    Uint64.parseHex('0x0397a38320170cd4'),
    Uint64.parseHex('0x734c1b2c9e761d30'),
    Uint64.parseHex('0x5ed255ad9a48beb5'),
    Uint64.parseHex('0x095a3c6b22a7fcfc'),
    Uint64.parseHex('0x2294ce75d4e26a27'),
    Uint64.parseHex('0x13338bd870011ebb'),
  ]);
  final b = Bls12Fp([
    Uint64.parseHex('0xb9c3c7c5b1196af7'),
    Uint64.parseHex('0x2580e2086ce335c1'),
    Uint64.parseHex('0xf49aed3d8a57ef42'),
    Uint64.parseHex('0x41f281e49846e878'),
    Uint64.parseHex('0xe0762346c38452ce'),
    Uint64.parseHex('0x0652e89326e57dc0'),
  ]);
  final c = Bls12Fp([
    Uint64.parseHex('0xf96ef3d711ab5355'),
    Uint64.parseHex('0xe8d459ea00f148dd'),
    Uint64.parseHex('0x53f7354a5f00fa78'),
    Uint64.parseHex('0x9e34a4f3125c5f83'),
    Uint64.parseHex('0x3fbe0c47ca74c19e'),
    Uint64.parseHex('0x01b06a8bbd4adfe4'),
  ]);
  expect(a * b, c);
}

void _squaring() {
  final a = Bls12Fp([
    Uint64.parseHex('0xd215d2768e83191b'),
    Uint64.parseHex('0x5085d80f8fb28261'),
    Uint64.parseHex('0xce9a032ddf393a56'),
    Uint64.parseHex('0x3e9c4fff2ca0c4bb'),
    Uint64.parseHex('0x6436b6f7f4d95dfb'),
    Uint64.parseHex('0x10606628ad4a4d90'),
  ]);
  final b = Bls12Fp([
    Uint64.parseHex('0x33d9c42a3cb3e235'),
    Uint64.parseHex('0xdad11a094c4cd455'),
    Uint64.parseHex('0xa2f144bd729aaeba'),
    Uint64.parseHex('0xd4150932be9ffeac'),
    Uint64.parseHex('0xe27bc7c47d44ee50'),
    Uint64.parseHex('0x14b6a78d3ec7a560'),
  ]);

  expect(a.square(), b);
}

void _equality() {
  bool isEqual(Bls12Fp a, Bls12Fp b) {
    return a == b;
  }

  expect(
    isEqual(
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    true,
  );

  expect(
    isEqual(
      Bls12Fp([7, 2, 3, 4, 5, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12Fp([1, 7, 3, 4, 5, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12Fp([1, 2, 7, 4, 5, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12Fp([1, 2, 3, 7, 5, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12Fp([1, 2, 3, 4, 7, 6].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12Fp([1, 2, 3, 4, 5, 7].toBigInt()),
      Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt()),
    ),
    false,
  );
}

void _conditionalSelection() {
  final a = Bls12Fp([1, 2, 3, 4, 5, 6].toBigInt());
  final b = Bls12Fp([7, 8, 9, 10, 11, 12].toBigInt());

  expect(Bls12Fp.conditionalSelect(a, b, false), a);
  expect(Bls12Fp.conditionalSelect(a, b, true), b);
}

extension _TOBIG on List<int> {
  List<Uint64> toBigInt() => map((e) => Uint64(e)).toList();
}
