import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("BLS12/Native FP", () {
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
  var a = Bls12NativeFp(
    [
      BigInt.parse('0xaa270000000cfff3'),
      BigInt.parse('0x53cc0032fc34000a'),
      BigInt.parse('0x478fe97a6b0a807f'),
      BigInt.parse('0xb1d37ebee6ba24d7'),
      BigInt.parse('0x8ec9733bbf78ab2f'),
      BigInt.parse('0x09d645513d83de7e'),
    ].toBigInt(),
  );

  expect(
    ((-a).sqrt()).result,
    Bls12NativeFp(
      [
        BigInt.parse('0x321300000006554f'),
        BigInt.parse('0xb93c0018d6c40005'),
        BigInt.parse('0x57605e0db0ddbb51'),
        BigInt.parse('0x8b256521ed1f9bcb'),
        BigInt.parse('0x6cf28d7901622c03'),
        BigInt.parse('0x11ebab9dbb81e28c'),
      ].toBigInt(),
    ),
  );
}

void _testInversion() {
  var a = Bls12NativeFp(
    [
      BigInt.parse('0x43b43a5078ac2076'),
      BigInt.parse('0x1ce0763046f8962b'),
      BigInt.parse('0x724a5276486d735c'),
      BigInt.parse('0x6f05c2a6282d48fd'),
      BigInt.parse('0x2095bd5bb4ca9331'),
      BigInt.parse('0x03b35b3894b0f7da'),
    ].toBigInt(),
  );

  var b = Bls12NativeFp(
    [
      BigInt.parse('0x69ecd7040952148f'),
      BigInt.parse('0x985ccc2022190f55'),
      BigInt.parse('0xe19bba36a9ad2f41'),
      BigInt.parse('0x19bb16c95219dbd8'),
      BigInt.parse('0x14dcacfdfb478693'),
      BigInt.parse('0x115ff58afff9a8e1'),
    ].toBigInt(),
  );
  expect(a.invert(), b);
  expect(Bls12NativeFp.zero().invert(), null);
}

void _testLexicographicLargest() {
  expect(Bls12NativeFp.zero().lexicographicallyLargest(), false);
  expect(Bls12NativeFp.one().lexicographicallyLargest(), false);

  expect(
    Bls12NativeFp(
      [
        BigInt.parse('0xa1fafffffffe5557'),
        BigInt.parse('0x995bfff976a3fffe'),
        BigInt.parse('0x03f41d24d174ceb4'),
        BigInt.parse('0xf6547998c1995dbd'),
        BigInt.parse('0x778a468f507a6034'),
        BigInt.parse('0x020559931f7f8103'),
      ].toBigInt(),
    ).lexicographicallyLargest(),
    false,
  );

  expect(
    Bls12NativeFp(
      [
        BigInt.parse('0x1804000000015554'),
        BigInt.parse('0x855000053ab00001'),
        BigInt.parse('0x633cb57c253c276f'),
        BigInt.parse('0x6e22d1ec31ebb502'),
        BigInt.parse('0xd3916126f2d14ca2'),
        BigInt.parse('0x17fbb8571a006596'),
      ].toBigInt(),
    ).lexicographicallyLargest(),
    true,
  );

  expect(
    Bls12NativeFp(
      [
        BigInt.parse('0x43f5fffffffcaaae'),
        BigInt.parse('0x32b7fff2ed47fffd'),
        BigInt.parse('0x07e83a49a2e99d69'),
        BigInt.parse('0xeca8f3318332bb7a'),
        BigInt.parse('0xef148d1ea0f4c069'),
        BigInt.parse('0x040ab3263eff0206'),
      ].toBigInt(),
    ).lexicographicallyLargest(),
    true,
  );
}

void _testFromBytes() {
  var a = Bls12NativeFp(
    [
      BigInt.parse('0xdc906d9be3f95dc8'),
      BigInt.parse('0x8755caf7459691a1'),
      BigInt.parse('0xcff1a7f4e9583ab3'),
      BigInt.parse('0x9b43821f849e2284'),
      BigInt.parse('0xf57554f3a2974f3f'),
      BigInt.parse('0x085dbea84ed47f79'),
    ].toBigInt(),
  );

  for (var i = 0; i < 100; i++) {
    a = a.square();
    var tmp = a.toBytes();
    var b = Bls12NativeFp.fromBytes(tmp);

    expect(a, b);
  }

  expect(
    -Bls12NativeFp.one(),
    Bls12NativeFp.fromBytes(
      BytesUtils.fromHexString(
        "1a0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      ),
    ),
  );
  expect(
    () => Bls12NativeFp.fromBytes(
      BytesUtils.fromHexString(
        "1b0111ea397fe69a4b1ba7b6434bacd764774b84f38512bf6730d2a0f6b0f6241eabfffeb153ffffb9feffffffffaaaa",
      ),
    ),
    throwsA(isA<ArgumentException>()),
  );
  expect(
    () => Bls12NativeFp.fromBytes(List.filled(48, 0xff)),
    throwsA(isA<ArgumentException>()),
  );
}

void _debug() {
  final r = Bls12NativeFp(
    [
      BigInt.parse('0x5360bb5978678032'),
      BigInt.parse('0x7dd275ae799e128e'),
      BigInt.parse('0x5c5b5071ce4f4dcf'),
      BigInt.parse('0xcdb21f93078dbb3e'),
      BigInt.parse('0xc32365c5e73f474a'),
      BigInt.parse('0x115a2a5489babe5b'),
    ].toBigInt(),
  );
  expect(
    BytesUtils.toHexString(r.toBytes()),
    "104bf052ad3bc99bcb176c24a06a6c3aad4eaf2308fc4d282e106c84a757d061052630515305e59bdddf8111bfdeb704",
  );
}

void _subtraction() {
  final a = Bls12NativeFp(
    [
      BigInt.parse('0x5360bb5978678032'),
      BigInt.parse('0x7dd275ae799e128e'),
      BigInt.parse('0x5c5b5071ce4f4dcf'),
      BigInt.parse('0xcdb21f93078dbb3e'),
      BigInt.parse('0xc32365c5e73f474a'),
      BigInt.parse('0x115a2a5489babe5b'),
    ].toBigInt(),
  );
  final b = Bls12NativeFp(
    [
      BigInt.parse('0x9fd287733d23dda0'),
      BigInt.parse('0xb16bf2af738b3554'),
      BigInt.parse('0x3e57a75bd3cc6d1d'),
      BigInt.parse('0x900bc0bd627fd6d6'),
      BigInt.parse('0xd319a080efb245fe'),
      BigInt.parse('0x15fdcaa4e4bb2091'),
    ].toBigInt(),
  );
  final c = Bls12NativeFp(
    [
      BigInt.parse('0x6d8d33e63b434d3d'),
      BigInt.parse('0xeb1282fdb766dd39'),
      BigInt.parse('0x85347bb6f133d6d5'),
      BigInt.parse('0xa21daa5a9892f727'),
      BigInt.parse('0x3b256cfb3ad8ae23'),
      BigInt.parse('0x155d7199de7f8464'),
    ].toBigInt(),
  );

  expect(a - b, c);
}

void _negation() {
  final a = Bls12NativeFp(
    [
      BigInt.parse('0x5360bb5978678032'),
      BigInt.parse('0x7dd275ae799e128e'),
      BigInt.parse('0x5c5b5071ce4f4dcf'),
      BigInt.parse('0xcdb21f93078dbb3e'),
      BigInt.parse('0xc32365c5e73f474a'),
      BigInt.parse('0x115a2a5489babe5b'),
    ].toBigInt(),
  );
  final b = Bls12NativeFp(
    [
      BigInt.parse('0x669e44a687982a79'),
      BigInt.parse('0xa0d98a5037b5ed71'),
      BigInt.parse('0x0ad5822f2861a854'),
      BigInt.parse('0x96c52bf1ebf75781'),
      BigInt.parse('0x87f841f05c0c658c'),
      BigInt.parse('0x08a6e795afc5283e'),
    ].toBigInt(),
  );

  expect(-a, b);
}

void _addition() {
  final a = Bls12NativeFp(
    [
      BigInt.parse('0x5360bb5978678032'),
      BigInt.parse('0x7dd275ae799e128e'),
      BigInt.parse('0x5c5b5071ce4f4dcf'),
      BigInt.parse('0xcdb21f93078dbb3e'),
      BigInt.parse('0xc32365c5e73f474a'),
      BigInt.parse('0x115a2a5489babe5b'),
    ].toBigInt(),
  );
  final b = Bls12NativeFp(
    [
      BigInt.parse('0x9fd287733d23dda0'),
      BigInt.parse('0xb16bf2af738b3554'),
      BigInt.parse('0x3e57a75bd3cc6d1d'),
      BigInt.parse('0x900bc0bd627fd6d6'),
      BigInt.parse('0xd319a080efb245fe'),
      BigInt.parse('0x15fdcaa4e4bb2091'),
    ].toBigInt(),
  );
  final c = Bls12NativeFp(
    [
      BigInt.parse('0x393442ccb58bb327'),
      BigInt.parse('0x1092685f3bd547e3'),
      BigInt.parse('0x3382252cab6ac4c9'),
      BigInt.parse('0xf94694cb76887f55'),
      BigInt.parse('0x4b215e9093a5e071'),
      BigInt.parse('0x0d56e30f34f5f853'),
    ].toBigInt(),
  );

  expect(a + b, c);
}

void _multiplication() {
  final a = Bls12NativeFp(
    [
      BigInt.parse('0x0397a38320170cd4'),
      BigInt.parse('0x734c1b2c9e761d30'),
      BigInt.parse('0x5ed255ad9a48beb5'),
      BigInt.parse('0x095a3c6b22a7fcfc'),
      BigInt.parse('0x2294ce75d4e26a27'),
      BigInt.parse('0x13338bd870011ebb'),
    ].toBigInt(),
  );
  final b = Bls12NativeFp(
    [
      BigInt.parse('0xb9c3c7c5b1196af7'),
      BigInt.parse('0x2580e2086ce335c1'),
      BigInt.parse('0xf49aed3d8a57ef42'),
      BigInt.parse('0x41f281e49846e878'),
      BigInt.parse('0xe0762346c38452ce'),
      BigInt.parse('0x0652e89326e57dc0'),
    ].toBigInt(),
  );
  final c = Bls12NativeFp(
    [
      BigInt.parse('0xf96ef3d711ab5355'),
      BigInt.parse('0xe8d459ea00f148dd'),
      BigInt.parse('0x53f7354a5f00fa78'),
      BigInt.parse('0x9e34a4f3125c5f83'),
      BigInt.parse('0x3fbe0c47ca74c19e'),
      BigInt.parse('0x01b06a8bbd4adfe4'),
    ].toBigInt(),
  );
  expect(a * b, c);
}

void _squaring() {
  final a = Bls12NativeFp(
    [
      BigInt.parse('0xd215d2768e83191b'),
      BigInt.parse('0x5085d80f8fb28261'),
      BigInt.parse('0xce9a032ddf393a56'),
      BigInt.parse('0x3e9c4fff2ca0c4bb'),
      BigInt.parse('0x6436b6f7f4d95dfb'),
      BigInt.parse('0x10606628ad4a4d90'),
    ].toBigInt(),
  );

  final b = Bls12NativeFp(
    [
      BigInt.parse('0x33d9c42a3cb3e235'),
      BigInt.parse('0xdad11a094c4cd455'),
      BigInt.parse('0xa2f144bd729aaeba'),
      BigInt.parse('0xd4150932be9ffeac'),
      BigInt.parse('0xe27bc7c47d44ee50'),
      BigInt.parse('0x14b6a78d3ec7a560'),
    ].toBigInt(),
  );
  expect(a.square(), b);
}

void _equality() {
  bool isEqual(Bls12NativeFp a, Bls12NativeFp b) {
    return a == b;
  }

  expect(
    isEqual(
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    true,
  );

  expect(
    isEqual(
      Bls12NativeFp([7, 2, 3, 4, 5, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12NativeFp([1, 7, 3, 4, 5, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12NativeFp([1, 2, 7, 4, 5, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12NativeFp([1, 2, 3, 7, 5, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12NativeFp([1, 2, 3, 4, 7, 6].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
  expect(
    isEqual(
      Bls12NativeFp([1, 2, 3, 4, 5, 7].toSigneBigint()),
      Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint()),
    ),
    false,
  );
}

void _conditionalSelection() {
  final a = Bls12NativeFp([1, 2, 3, 4, 5, 6].toSigneBigint());
  final b = Bls12NativeFp([7, 8, 9, 10, 11, 12].toSigneBigint());

  expect(Bls12NativeFp.conditionalSelect(a, b, false), a);
  expect(Bls12NativeFp.conditionalSelect(a, b, true), b);
}

extension _TOBIG on List<int> {
  BigInt toSigneBigint() => map((e) => BigInt.from(e)).toList().toBigInt();
}

extension _TOSINGLEBIG on List<BigInt> {
  BigInt toBigInt() {
    return BigintUtils.fromBytes(Bls12Fp(this).toBytes());
  }
}
