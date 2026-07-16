import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';
import 'fp_test.dart';

void main() {
  test("BLS12/FP2 Native", () {
    _testEquality();
    _testConditionalSelection();
    _testSquaring();
    _testMultiplication();
    _testAddition();
    _testSubtraction();
    _testNegation();
    _testSqrt();
    _testLexicographicLargest();
  });
}

void _testLexicographicLargest() {
  // zero
  expect(Bls12NativeFp2.zero().lexicographicallyLargest(), false);

  // one
  expect(Bls12NativeFp2.one().lexicographicallyLargest(), false);

  // arbitrary Bls12NativeFp2 element
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0x1128ecad67549455'),
          Uint64.parseHex('0x9e7a1cff3a4ea1a8'),
          Uint64.parseHex('0xeb208d51e08bcf27'),
          Uint64.parseHex('0xe98ad40811f5fc2b'),
          Uint64.parseHex('0x736c3a59232d511d'),
          Uint64.parseHex('0x10acd42d29cfcbb6'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0xd328e37cc2f58d41'),
          Uint64.parseHex('0x948df0858a605869'),
          Uint64.parseHex('0x6032f9d56f93a573'),
          Uint64.parseHex('0x2be483ef3fffdc87'),
          Uint64.parseHex('0x30ef61f88f483c2a'),
          Uint64.parseHex('0x1333f55a35725be0'),
        ]).toNative(),
  );
  expect(a.lexicographicallyLargest(), true);

  // negated Bls12NativeFp2 element
  var negA = Bls12NativeFp2(
    c0:
        (-Bls12Fp([
              Uint64.parseHex('0x1128ecad67549455'),
              Uint64.parseHex('0x9e7a1cff3a4ea1a8'),
              Uint64.parseHex('0xeb208d51e08bcf27'),
              Uint64.parseHex('0xe98ad40811f5fc2b'),
              Uint64.parseHex('0x736c3a59232d511d'),
              Uint64.parseHex('0x10acd42d29cfcbb6'),
            ]))
            .toNative(),
    c1:
        (-Bls12Fp([
              Uint64.parseHex('0xd328e37cc2f58d41'),
              Uint64.parseHex('0x948df0858a605869'),
              Uint64.parseHex('0x6032f9d56f93a573'),
              Uint64.parseHex('0x2be483ef3fffdc87'),
              Uint64.parseHex('0x30ef61f88f483c2a'),
              Uint64.parseHex('0x1333f55a35725be0'),
            ]))
            .toNative(),
  );
  expect(negA.lexicographicallyLargest(), false);

  // Bls12NativeFp2 element with c1 = 0
  var b = Bls12NativeFp2(
    c0:
        (Bls12Fp([
          Uint64.parseHex('0x1128ecad67549455'),
          Uint64.parseHex('0x9e7a1cff3a4ea1a8'),
          Uint64.parseHex('0xeb208d51e08bcf27'),
          Uint64.parseHex('0xe98ad40811f5fc2b'),
          Uint64.parseHex('0x736c3a59232d511d'),
          Uint64.parseHex('0x10acd42d29cfcbb6'),
        ])).toNative(),
    c1: Bls12NativeFp.zero(),
  );
  expect(b.lexicographicallyLargest(), false);

  // negated Bls12NativeFp2 element with c1 = 0
  var negB = Bls12NativeFp2(
    c0:
        (-Bls12Fp([
              Uint64.parseHex('0x1128ecad67549455'),
              Uint64.parseHex('0x9e7a1cff3a4ea1a8'),
              Uint64.parseHex('0xeb208d51e08bcf27'),
              Uint64.parseHex('0xe98ad40811f5fc2b'),
              Uint64.parseHex('0x736c3a59232d511d'),
              Uint64.parseHex('0x10acd42d29cfcbb6'),
            ]))
            .toNative(),
    c1: Bls12NativeFp.zero(),
  );
  expect(negB.lexicographicallyLargest(), true);
}

void _testNegation() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc9a2183163ee70d4'),
          Uint64.parseHex('0xbc3770a7196b5c91'),
          Uint64.parseHex('0xa247f8c1304c5f44'),
          Uint64.parseHex('0xb01fc2a3726c80b5'),
          Uint64.parseHex('0xe1d293e5bbd919c9'),
          Uint64.parseHex('0x04b78e80020ef2ca'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x952ea4460462618f'),
          Uint64.parseHex('0x238d5eddf025c62f'),
          Uint64.parseHex('0xf6c94b012ea92e72'),
          Uint64.parseHex('0x03ce24eac1c93808'),
          Uint64.parseHex('0x055950f945da483c'),
          Uint64.parseHex('0x010a768d0df4eabc'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xf05ce7ce9c1139d7'),
          Uint64.parseHex('0x62748f5797e8a36d'),
          Uint64.parseHex('0xc4e8d9dfc66496df'),
          Uint64.parseHex('0xb45788e181189209'),
          Uint64.parseHex('0x694913d08772930d'),
          Uint64.parseHex('0x1549836a3770f3cf'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x24d05bb9fb9d491c'),
          Uint64.parseHex('0xfb1ea120c12e39d0'),
          Uint64.parseHex('0x7067879fc807c7b1'),
          Uint64.parseHex('0x60a9269a31bbdab6'),
          Uint64.parseHex('0x45c256bcfd71649b'),
          Uint64.parseHex('0x18f69b5d2b8afbde'),
        ]).toNative(),
  );

  expect(-a, b);
}

void _testSqrt() {
  // a as Bls12NativeFp2 element
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0x2beed14627d7f9e9'),
          Uint64.parseHex('0xb6614e06660e5dce'),
          Uint64.parseHex('0x06c4cc7c2f91d42c'),
          Uint64.parseHex('0x996d78474b7a63cc'),
          Uint64.parseHex('0xebaebc4c820d574e'),
          Uint64.parseHex('0x18865e12d93fd845'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x7d828664baf4f566'),
          Uint64.parseHex('0xd17e663996ec7339'),
          Uint64.parseHex('0x679ead55cb4078d0'),
          Uint64.parseHex('0xfe3b2260e001ec28'),
          Uint64.parseHex('0x305993d043d91b68'),
          Uint64.parseHex('0x0626f03c0489b72d'),
        ]).toNative(),
  );
  expect(a.sqrt().result.square(), a);

  // b = 5 in multiplicative subgroup
  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0x6631000000105545'),
          Uint64.parseHex('0x211400400eec000d'),
          Uint64.parseHex('0x3fa7af30c820e316'),
          Uint64.parseHex('0xc52a8b8d6387695d'),
          Uint64.parseHex('0x9fb4e61d1e83eac5'),
          Uint64.parseHex('0x005cb922afe84dc7'),
        ]).toNative(),
    c1: Bls12NativeFp.zero(),
  );
  expect(b.sqrt().result.square(), b);

  // c = 25 in multiplicative subgroup
  var c = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0x44f600000051ffae'),
          Uint64.parseHex('0x86b8014199480043'),
          Uint64.parseHex('0xd7159952f1f3794a'),
          Uint64.parseHex('0x755d6e3dfe1ffc12'),
          Uint64.parseHex('0xd36cd6db5547e905'),
          Uint64.parseHex('0x02f8c8ecbf1867bb'),
        ]).toNative(),
    c1: Bls12NativeFp.zero(),
  );
  expect(c.sqrt().result.square(), c);

  // Non-square element
  var nonsquare = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc5fa1bc8fd00d7f6'),
          Uint64.parseHex('0x3830ca454606003b'),
          Uint64.parseHex('0x2b287f1104b102da'),
          Uint64.parseHex('0xa7fb30f28230f23e'),
          Uint64.parseHex('0x339cdb9ee953dbf0'),
          Uint64.parseHex('0x0d78ec51d989fc57'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x27ec4898cf87f613'),
          Uint64.parseHex('0x9de1394e1abb05a5'),
          Uint64.parseHex('0x0947f85dc170fc14'),
          Uint64.parseHex('0x586fbc696b6114b7'),
          Uint64.parseHex('0x2b3475a4077d7169'),
          Uint64.parseHex('0x13e1c895cc4b6c22'),
        ]).toNative(),
  );
  expect(nonsquare.sqrt().isSquare, false);
}

void _testAddition() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc9a2183163ee70d4'),
          Uint64.parseHex('0xbc3770a7196b5c91'),
          Uint64.parseHex('0xa247f8c1304c5f44'),
          Uint64.parseHex('0xb01fc2a3726c80b5'),
          Uint64.parseHex('0xe1d293e5bbd919c9'),
          Uint64.parseHex('0x04b78e80020ef2ca'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x952ea4460462618f'),
          Uint64.parseHex('0x238d5eddf025c62f'),
          Uint64.parseHex('0xf6c94b012ea92e72'),
          Uint64.parseHex('0x03ce24eac1c93808'),
          Uint64.parseHex('0x055950f945da483c'),
          Uint64.parseHex('0x010a768d0df4eabc'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xa1e09175a4d2c1fe'),
          Uint64.parseHex('0x8b33acfc204eff12'),
          Uint64.parseHex('0xe24415a11b456e42'),
          Uint64.parseHex('0x61d996b1b6ee1936'),
          Uint64.parseHex('0x1164dbe8667c853c'),
          Uint64.parseHex('0x0788557acc7d9c79'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0xda6a87cc6f48fa36'),
          Uint64.parseHex('0x0fc7b488277c1903'),
          Uint64.parseHex('0x9445ac4adc448187'),
          Uint64.parseHex('0x02616d5bc9099209'),
          Uint64.parseHex('0xdbed46772db58d48'),
          Uint64.parseHex('0x11b94d5076c7b7b1'),
        ]).toNative(),
  );

  var c = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0x6b82a9a708c132d2'),
          Uint64.parseHex('0x476b1da339ba5ba4'),
          Uint64.parseHex('0x848c0e624b91cd87'),
          Uint64.parseHex('0x11f95955295a99ec'),
          Uint64.parseHex('0xf3376fce22559f06'),
          Uint64.parseHex('0x0c3fe3face8c8f43'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x6f992c1273ab5bc5'),
          Uint64.parseHex('0x3355136617a1df33'),
          Uint64.parseHex('0x8b0ef74c0aedaff9'),
          Uint64.parseHex('0x062f92468ad2ca12'),
          Uint64.parseHex('0xe1469770738fd584'),
          Uint64.parseHex('0x12c3c3dd84bca26d'),
        ]).toNative(),
  );

  expect(a + b, c);
}

void _testSubtraction() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc9a2183163ee70d4'),
          Uint64.parseHex('0xbc3770a7196b5c91'),
          Uint64.parseHex('0xa247f8c1304c5f44'),
          Uint64.parseHex('0xb01fc2a3726c80b5'),
          Uint64.parseHex('0xe1d293e5bbd919c9'),
          Uint64.parseHex('0x04b78e80020ef2ca'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x952ea4460462618f'),
          Uint64.parseHex('0x238d5eddf025c62f'),
          Uint64.parseHex('0xf6c94b012ea92e72'),
          Uint64.parseHex('0x03ce24eac1c93808'),
          Uint64.parseHex('0x055950f945da483c'),
          Uint64.parseHex('0x010a768d0df4eabc'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xa1e09175a4d2c1fe'),
          Uint64.parseHex('0x8b33acfc204eff12'),
          Uint64.parseHex('0xe24415a11b456e42'),
          Uint64.parseHex('0x61d996b1b6ee1936'),
          Uint64.parseHex('0x1164dbe8667c853c'),
          Uint64.parseHex('0x0788557acc7d9c79'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0xda6a87cc6f48fa36'),
          Uint64.parseHex('0x0fc7b488277c1903'),
          Uint64.parseHex('0x9445ac4adc448187'),
          Uint64.parseHex('0x02616d5bc9099209'),
          Uint64.parseHex('0xdbed46772db58d48'),
          Uint64.parseHex('0x11b94d5076c7b7b1'),
        ]).toNative(),
  );

  var c = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xe1c086bbbf1b5981'),
          Uint64.parseHex('0x4fafc3a9aa705d7e'),
          Uint64.parseHex('0x2734b5c10bb7e726'),
          Uint64.parseHex('0xb2bd7776af037a3e'),
          Uint64.parseHex('0x1b895fb398a84164'),
          Uint64.parseHex('0x17304aef6f113cec'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x74c31c7995191204'),
          Uint64.parseHex('0x3271aa5479fdad2b'),
          Uint64.parseHex('0xc9b471574915a30f'),
          Uint64.parseHex('0x65e40313ec44b8be'),
          Uint64.parseHex('0x7487b2385b7067cb'),
          Uint64.parseHex('0x09523b26d0ad19a4'),
        ]).toNative(),
  );

  expect(a - b, c);
}

void _testSquaring() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc9a2183163ee70d4'),
          Uint64.parseHex('0xbc3770a7196b5c91'),
          Uint64.parseHex('0xa247f8c1304c5f44'),
          Uint64.parseHex('0xb01fc2a3726c80b5'),
          Uint64.parseHex('0xe1d293e5bbd919c9'),
          Uint64.parseHex('0x04b78e80020ef2ca'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x952ea4460462618f'),
          Uint64.parseHex('0x238d5eddf025c62f'),
          Uint64.parseHex('0xf6c94b012ea92e72'),
          Uint64.parseHex('0x03ce24eac1c93808'),
          Uint64.parseHex('0x055950f945da483c'),
          Uint64.parseHex('0x010a768d0df4eabc'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xa1e09175a4d2c1fe'),
          Uint64.parseHex('0x8b33acfc204eff12'),
          Uint64.parseHex('0xe24415a11b456e42'),
          Uint64.parseHex('0x61d996b1b6ee1936'),
          Uint64.parseHex('0x1164dbe8667c853c'),
          Uint64.parseHex('0x0788557acc7d9c79'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0xda6a87cc6f48fa36'),
          Uint64.parseHex('0x0fc7b488277c1903'),
          Uint64.parseHex('0x9445ac4adc448187'),
          Uint64.parseHex('0x02616d5bc9099209'),
          Uint64.parseHex('0xdbed46772db58d48'),
          Uint64.parseHex('0x11b94d5076c7b7b1'),
        ]).toNative(),
  );

  expect(a.square(), b);
}

void _testMultiplication() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xc9a2183163ee70d4'),
          Uint64.parseHex('0xbc3770a7196b5c91'),
          Uint64.parseHex('0xa247f8c1304c5f44'),
          Uint64.parseHex('0xb01fc2a3726c80b5'),
          Uint64.parseHex('0xe1d293e5bbd919c9'),
          Uint64.parseHex('0x04b78e80020ef2ca'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x952ea4460462618f'),
          Uint64.parseHex('0x238d5eddf025c62f'),
          Uint64.parseHex('0xf6c94b012ea92e72'),
          Uint64.parseHex('0x03ce24eac1c93808'),
          Uint64.parseHex('0x055950f945da483c'),
          Uint64.parseHex('0x010a768d0df4eabc'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xa1e09175a4d2c1fe'),
          Uint64.parseHex('0x8b33acfc204eff12'),
          Uint64.parseHex('0xe24415a11b456e42'),
          Uint64.parseHex('0x61d996b1b6ee1936'),
          Uint64.parseHex('0x1164dbe8667c853c'),
          Uint64.parseHex('0x0788557acc7d9c79'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0xda6a87cc6f48fa36'),
          Uint64.parseHex('0x0fc7b488277c1903'),
          Uint64.parseHex('0x9445ac4adc448187'),
          Uint64.parseHex('0x02616d5bc9099209'),
          Uint64.parseHex('0xdbed46772db58d48'),
          Uint64.parseHex('0x11b94d5076c7b7b1'),
        ]).toNative(),
  );

  var c = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseHex('0xf597483e27b4e0f7'),
          Uint64.parseHex('0x610fbadf811dae5f'),
          Uint64.parseHex('0x8432af917714327a'),
          Uint64.parseHex('0x6a9a9603cf88f09e'),
          Uint64.parseHex('0xf05a7bf8bad0eb01'),
          Uint64.parseHex('0x09549131c003ffae'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseHex('0x963b02d0f93d37cd'),
          Uint64.parseHex('0xc95ce1cdb30a73d4'),
          Uint64.parseHex('0x308725fa3126f9b8'),
          Uint64.parseHex('0x56da3c167fab0d50'),
          Uint64.parseHex('0x6b5086b5f4b6d6af'),
          Uint64.parseHex('0x09c39f062f18e9f2'),
        ]).toNative(),
  );

  expect(a * b, c);
}

void _testConditionalSelection() {
  var a = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseDecimal('1'),
          Uint64.parseDecimal('2'),
          Uint64.parseDecimal('3'),
          Uint64.parseDecimal('4'),
          Uint64.parseDecimal('5'),
          Uint64.parseDecimal('6'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseDecimal('7'),
          Uint64.parseDecimal('8'),
          Uint64.parseDecimal('9'),
          Uint64.parseDecimal('10'),
          Uint64.parseDecimal('11'),
          Uint64.parseDecimal('12'),
        ]).toNative(),
  );

  var b = Bls12NativeFp2(
    c0:
        Bls12Fp([
          Uint64.parseDecimal('13'),
          Uint64.parseDecimal('14'),
          Uint64.parseDecimal('15'),
          Uint64.parseDecimal('16'),
          Uint64.parseDecimal('17'),
          Uint64.parseDecimal('18'),
        ]).toNative(),
    c1:
        Bls12Fp([
          Uint64.parseDecimal('19'),
          Uint64.parseDecimal('20'),
          Uint64.parseDecimal('21'),
          Uint64.parseDecimal('22'),
          Uint64.parseDecimal('23'),
          Uint64.parseDecimal('24'),
        ]).toNative(),
  );

  expect(Bls12NativeFp2.conditionalSelect(a, b, false), a);
  expect(Bls12NativeFp2.conditionalSelect(a, b, true), b);
}

void _testEquality() {
  bool isEqual(Bls12NativeFp2 a, Bls12NativeFp2 b) {
    return a == b;
  }

  expect(
    isEqual(
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('1'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('7'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('1'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('7'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
    ),
    true,
  );

  expect(
    isEqual(
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('7'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('1'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('7'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
    ),
    false,
  );

  expect(
    isEqual(
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('1'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
      Bls12NativeFp2(
        c0:
            Bls12Fp([
              Uint64.parseDecimal('1'),
              Uint64.parseDecimal('2'),
              Uint64.parseDecimal('3'),
              Uint64.parseDecimal('4'),
              Uint64.parseDecimal('5'),
              Uint64.parseDecimal('6'),
            ]).toNative(),
        c1:
            Bls12Fp([
              Uint64.parseDecimal('7'),
              Uint64.parseDecimal('8'),
              Uint64.parseDecimal('9'),
              Uint64.parseDecimal('10'),
              Uint64.parseDecimal('11'),
              Uint64.parseDecimal('12'),
            ]).toNative(),
      ),
    ),
    false,
  );
}
