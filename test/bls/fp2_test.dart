import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/zcrypto/bls12_381/src/fp2.dart';
import 'package:test/test.dart';

import 'fp_test.dart';

void main() {
  test("BLS12/FP2", () {
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
  expect(Bls12Fp2.zero().lexicographicallyLargest(), false);

  // one
  expect(Bls12Fp2.one().lexicographicallyLargest(), false);

  // arbitrary Bls12Fp2 element
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x1128ecad67549455'),
      BigInt.parse('0x9e7a1cff3a4ea1a8'),
      BigInt.parse('0xeb208d51e08bcf27'),
      BigInt.parse('0xe98ad40811f5fc2b'),
      BigInt.parse('0x736c3a59232d511d'),
      BigInt.parse('0x10acd42d29cfcbb6'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0xd328e37cc2f58d41'),
      BigInt.parse('0x948df0858a605869'),
      BigInt.parse('0x6032f9d56f93a573'),
      BigInt.parse('0x2be483ef3fffdc87'),
      BigInt.parse('0x30ef61f88f483c2a'),
      BigInt.parse('0x1333f55a35725be0'),
    ]),
  );
  expect(a.lexicographicallyLargest(), true);

  // negated Bls12Fp2 element
  var negA = Bls12Fp2(
    c0:
        -Bls12Fp([
          BigInt.parse('0x1128ecad67549455'),
          BigInt.parse('0x9e7a1cff3a4ea1a8'),
          BigInt.parse('0xeb208d51e08bcf27'),
          BigInt.parse('0xe98ad40811f5fc2b'),
          BigInt.parse('0x736c3a59232d511d'),
          BigInt.parse('0x10acd42d29cfcbb6'),
        ]),
    c1:
        -Bls12Fp([
          BigInt.parse('0xd328e37cc2f58d41'),
          BigInt.parse('0x948df0858a605869'),
          BigInt.parse('0x6032f9d56f93a573'),
          BigInt.parse('0x2be483ef3fffdc87'),
          BigInt.parse('0x30ef61f88f483c2a'),
          BigInt.parse('0x1333f55a35725be0'),
        ]),
  );
  expect(negA.lexicographicallyLargest(), false);

  // Bls12Fp2 element with c1 = 0
  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x1128ecad67549455'),
      BigInt.parse('0x9e7a1cff3a4ea1a8'),
      BigInt.parse('0xeb208d51e08bcf27'),
      BigInt.parse('0xe98ad40811f5fc2b'),
      BigInt.parse('0x736c3a59232d511d'),
      BigInt.parse('0x10acd42d29cfcbb6'),
    ]),
    c1: Bls12Fp.zero(),
  );
  expect(b.lexicographicallyLargest(), false);

  // negated Bls12Fp2 element with c1 = 0
  var negB = Bls12Fp2(
    c0:
        -Bls12Fp([
          BigInt.parse('0x1128ecad67549455'),
          BigInt.parse('0x9e7a1cff3a4ea1a8'),
          BigInt.parse('0xeb208d51e08bcf27'),
          BigInt.parse('0xe98ad40811f5fc2b'),
          BigInt.parse('0x736c3a59232d511d'),
          BigInt.parse('0x10acd42d29cfcbb6'),
        ]),
    c1: Bls12Fp.zero(),
  );
  expect(negB.lexicographicallyLargest(), true);
}

void _testNegation() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc9a2183163ee70d4'),
      BigInt.parse('0xbc3770a7196b5c91'),
      BigInt.parse('0xa247f8c1304c5f44'),
      BigInt.parse('0xb01fc2a3726c80b5'),
      BigInt.parse('0xe1d293e5bbd919c9'),
      BigInt.parse('0x04b78e80020ef2ca'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x952ea4460462618f'),
      BigInt.parse('0x238d5eddf025c62f'),
      BigInt.parse('0xf6c94b012ea92e72'),
      BigInt.parse('0x03ce24eac1c93808'),
      BigInt.parse('0x055950f945da483c'),
      BigInt.parse('0x010a768d0df4eabc'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xf05ce7ce9c1139d7'),
      BigInt.parse('0x62748f5797e8a36d'),
      BigInt.parse('0xc4e8d9dfc66496df'),
      BigInt.parse('0xb45788e181189209'),
      BigInt.parse('0x694913d08772930d'),
      BigInt.parse('0x1549836a3770f3cf'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x24d05bb9fb9d491c'),
      BigInt.parse('0xfb1ea120c12e39d0'),
      BigInt.parse('0x7067879fc807c7b1'),
      BigInt.parse('0x60a9269a31bbdab6'),
      BigInt.parse('0x45c256bcfd71649b'),
      BigInt.parse('0x18f69b5d2b8afbde'),
    ]),
  );

  expect(-a, b);
}

void _testSqrt() {
  // a as Bls12Fp2 element
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x2beed14627d7f9e9'),
      BigInt.parse('0xb6614e06660e5dce'),
      BigInt.parse('0x06c4cc7c2f91d42c'),
      BigInt.parse('0x996d78474b7a63cc'),
      BigInt.parse('0xebaebc4c820d574e'),
      BigInt.parse('0x18865e12d93fd845'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x7d828664baf4f566'),
      BigInt.parse('0xd17e663996ec7339'),
      BigInt.parse('0x679ead55cb4078d0'),
      BigInt.parse('0xfe3b2260e001ec28'),
      BigInt.parse('0x305993d043d91b68'),
      BigInt.parse('0x0626f03c0489b72d'),
    ]),
  );
  expect(a.sqrt().result.square(), a);

  // b = 5 in multiplicative subgroup
  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x6631000000105545'),
      BigInt.parse('0x211400400eec000d'),
      BigInt.parse('0x3fa7af30c820e316'),
      BigInt.parse('0xc52a8b8d6387695d'),
      BigInt.parse('0x9fb4e61d1e83eac5'),
      BigInt.parse('0x005cb922afe84dc7'),
    ]),
    c1: Bls12Fp.zero(),
  );
  expect(b.sqrt().result.square(), b);

  // c = 25 in multiplicative subgroup
  var c = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x44f600000051ffae'),
      BigInt.parse('0x86b8014199480043'),
      BigInt.parse('0xd7159952f1f3794a'),
      BigInt.parse('0x755d6e3dfe1ffc12'),
      BigInt.parse('0xd36cd6db5547e905'),
      BigInt.parse('0x02f8c8ecbf1867bb'),
    ]),
    c1: Bls12Fp.zero(),
  );
  expect(c.sqrt().result.square(), c);

  // Non-square element
  var nonsquare = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc5fa1bc8fd00d7f6'),
      BigInt.parse('0x3830ca454606003b'),
      BigInt.parse('0x2b287f1104b102da'),
      BigInt.parse('0xa7fb30f28230f23e'),
      BigInt.parse('0x339cdb9ee953dbf0'),
      BigInt.parse('0x0d78ec51d989fc57'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x27ec4898cf87f613'),
      BigInt.parse('0x9de1394e1abb05a5'),
      BigInt.parse('0x0947f85dc170fc14'),
      BigInt.parse('0x586fbc696b6114b7'),
      BigInt.parse('0x2b3475a4077d7169'),
      BigInt.parse('0x13e1c895cc4b6c22'),
    ]),
  );
  expect(nonsquare.sqrt().isSquare, false);
}

void _testAddition() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc9a2183163ee70d4'),
      BigInt.parse('0xbc3770a7196b5c91'),
      BigInt.parse('0xa247f8c1304c5f44'),
      BigInt.parse('0xb01fc2a3726c80b5'),
      BigInt.parse('0xe1d293e5bbd919c9'),
      BigInt.parse('0x04b78e80020ef2ca'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x952ea4460462618f'),
      BigInt.parse('0x238d5eddf025c62f'),
      BigInt.parse('0xf6c94b012ea92e72'),
      BigInt.parse('0x03ce24eac1c93808'),
      BigInt.parse('0x055950f945da483c'),
      BigInt.parse('0x010a768d0df4eabc'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xa1e09175a4d2c1fe'),
      BigInt.parse('0x8b33acfc204eff12'),
      BigInt.parse('0xe24415a11b456e42'),
      BigInt.parse('0x61d996b1b6ee1936'),
      BigInt.parse('0x1164dbe8667c853c'),
      BigInt.parse('0x0788557acc7d9c79'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0xda6a87cc6f48fa36'),
      BigInt.parse('0x0fc7b488277c1903'),
      BigInt.parse('0x9445ac4adc448187'),
      BigInt.parse('0x02616d5bc9099209'),
      BigInt.parse('0xdbed46772db58d48'),
      BigInt.parse('0x11b94d5076c7b7b1'),
    ]),
  );

  var c = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0x6b82a9a708c132d2'),
      BigInt.parse('0x476b1da339ba5ba4'),
      BigInt.parse('0x848c0e624b91cd87'),
      BigInt.parse('0x11f95955295a99ec'),
      BigInt.parse('0xf3376fce22559f06'),
      BigInt.parse('0x0c3fe3face8c8f43'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x6f992c1273ab5bc5'),
      BigInt.parse('0x3355136617a1df33'),
      BigInt.parse('0x8b0ef74c0aedaff9'),
      BigInt.parse('0x062f92468ad2ca12'),
      BigInt.parse('0xe1469770738fd584'),
      BigInt.parse('0x12c3c3dd84bca26d'),
    ]),
  );

  expect(a + b, c);
}

void _testSubtraction() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc9a2183163ee70d4'),
      BigInt.parse('0xbc3770a7196b5c91'),
      BigInt.parse('0xa247f8c1304c5f44'),
      BigInt.parse('0xb01fc2a3726c80b5'),
      BigInt.parse('0xe1d293e5bbd919c9'),
      BigInt.parse('0x04b78e80020ef2ca'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x952ea4460462618f'),
      BigInt.parse('0x238d5eddf025c62f'),
      BigInt.parse('0xf6c94b012ea92e72'),
      BigInt.parse('0x03ce24eac1c93808'),
      BigInt.parse('0x055950f945da483c'),
      BigInt.parse('0x010a768d0df4eabc'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xa1e09175a4d2c1fe'),
      BigInt.parse('0x8b33acfc204eff12'),
      BigInt.parse('0xe24415a11b456e42'),
      BigInt.parse('0x61d996b1b6ee1936'),
      BigInt.parse('0x1164dbe8667c853c'),
      BigInt.parse('0x0788557acc7d9c79'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0xda6a87cc6f48fa36'),
      BigInt.parse('0x0fc7b488277c1903'),
      BigInt.parse('0x9445ac4adc448187'),
      BigInt.parse('0x02616d5bc9099209'),
      BigInt.parse('0xdbed46772db58d48'),
      BigInt.parse('0x11b94d5076c7b7b1'),
    ]),
  );

  var c = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xe1c086bbbf1b5981'),
      BigInt.parse('0x4fafc3a9aa705d7e'),
      BigInt.parse('0x2734b5c10bb7e726'),
      BigInt.parse('0xb2bd7776af037a3e'),
      BigInt.parse('0x1b895fb398a84164'),
      BigInt.parse('0x17304aef6f113cec'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x74c31c7995191204'),
      BigInt.parse('0x3271aa5479fdad2b'),
      BigInt.parse('0xc9b471574915a30f'),
      BigInt.parse('0x65e40313ec44b8be'),
      BigInt.parse('0x7487b2385b7067cb'),
      BigInt.parse('0x09523b26d0ad19a4'),
    ]),
  );

  expect(a - b, c);
}

void _testSquaring() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc9a2183163ee70d4'),
      BigInt.parse('0xbc3770a7196b5c91'),
      BigInt.parse('0xa247f8c1304c5f44'),
      BigInt.parse('0xb01fc2a3726c80b5'),
      BigInt.parse('0xe1d293e5bbd919c9'),
      BigInt.parse('0x04b78e80020ef2ca'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x952ea4460462618f'),
      BigInt.parse('0x238d5eddf025c62f'),
      BigInt.parse('0xf6c94b012ea92e72'),
      BigInt.parse('0x03ce24eac1c93808'),
      BigInt.parse('0x055950f945da483c'),
      BigInt.parse('0x010a768d0df4eabc'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xa1e09175a4d2c1fe'),
      BigInt.parse('0x8b33acfc204eff12'),
      BigInt.parse('0xe24415a11b456e42'),
      BigInt.parse('0x61d996b1b6ee1936'),
      BigInt.parse('0x1164dbe8667c853c'),
      BigInt.parse('0x0788557acc7d9c79'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0xda6a87cc6f48fa36'),
      BigInt.parse('0x0fc7b488277c1903'),
      BigInt.parse('0x9445ac4adc448187'),
      BigInt.parse('0x02616d5bc9099209'),
      BigInt.parse('0xdbed46772db58d48'),
      BigInt.parse('0x11b94d5076c7b7b1'),
    ]),
  );

  expect(a.square(), b);
}

void _testMultiplication() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xc9a2183163ee70d4'),
      BigInt.parse('0xbc3770a7196b5c91'),
      BigInt.parse('0xa247f8c1304c5f44'),
      BigInt.parse('0xb01fc2a3726c80b5'),
      BigInt.parse('0xe1d293e5bbd919c9'),
      BigInt.parse('0x04b78e80020ef2ca'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x952ea4460462618f'),
      BigInt.parse('0x238d5eddf025c62f'),
      BigInt.parse('0xf6c94b012ea92e72'),
      BigInt.parse('0x03ce24eac1c93808'),
      BigInt.parse('0x055950f945da483c'),
      BigInt.parse('0x010a768d0df4eabc'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xa1e09175a4d2c1fe'),
      BigInt.parse('0x8b33acfc204eff12'),
      BigInt.parse('0xe24415a11b456e42'),
      BigInt.parse('0x61d996b1b6ee1936'),
      BigInt.parse('0x1164dbe8667c853c'),
      BigInt.parse('0x0788557acc7d9c79'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0xda6a87cc6f48fa36'),
      BigInt.parse('0x0fc7b488277c1903'),
      BigInt.parse('0x9445ac4adc448187'),
      BigInt.parse('0x02616d5bc9099209'),
      BigInt.parse('0xdbed46772db58d48'),
      BigInt.parse('0x11b94d5076c7b7b1'),
    ]),
  );

  var c = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('0xf597483e27b4e0f7'),
      BigInt.parse('0x610fbadf811dae5f'),
      BigInt.parse('0x8432af917714327a'),
      BigInt.parse('0x6a9a9603cf88f09e'),
      BigInt.parse('0xf05a7bf8bad0eb01'),
      BigInt.parse('0x09549131c003ffae'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('0x963b02d0f93d37cd'),
      BigInt.parse('0xc95ce1cdb30a73d4'),
      BigInt.parse('0x308725fa3126f9b8'),
      BigInt.parse('0x56da3c167fab0d50'),
      BigInt.parse('0x6b5086b5f4b6d6af'),
      BigInt.parse('0x09c39f062f18e9f2'),
    ]),
  );

  expect(a * b, c);
}

void _testConditionalSelection() {
  var a = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('1'),
      BigInt.parse('2'),
      BigInt.parse('3'),
      BigInt.parse('4'),
      BigInt.parse('5'),
      BigInt.parse('6'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('7'),
      BigInt.parse('8'),
      BigInt.parse('9'),
      BigInt.parse('10'),
      BigInt.parse('11'),
      BigInt.parse('12'),
    ]),
  );

  var b = Bls12Fp2(
    c0: Bls12Fp([
      BigInt.parse('13'),
      BigInt.parse('14'),
      BigInt.parse('15'),
      BigInt.parse('16'),
      BigInt.parse('17'),
      BigInt.parse('18'),
    ]),
    c1: Bls12Fp([
      BigInt.parse('19'),
      BigInt.parse('20'),
      BigInt.parse('21'),
      BigInt.parse('22'),
      BigInt.parse('23'),
      BigInt.parse('24'),
    ]),
  );

  expect(Bls12Fp2.conditionalSelect(a, b, false), a);
  expect(Bls12Fp2.conditionalSelect(a, b, true), b);
}

void _testEquality() {
  bool isEqual(Bls12Fp2 a, Bls12Fp2 b) {
    return a == b;
  }

  expect(
    isEqual(
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('1'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('7'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('1'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('7'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
    ),

    true,
  );

  expect(
    isEqual(
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('2'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('7'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('1'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('7'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
    ),
    false,
  );

  expect(
    isEqual(
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('1'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('2'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
      Bls12Fp2(
        c0: Bls12Fp([
          BigInt.parse('1'),
          BigInt.parse('2'),
          BigInt.parse('3'),
          BigInt.parse('4'),
          BigInt.parse('5'),
          BigInt.parse('6'),
        ]),
        c1: Bls12Fp([
          BigInt.parse('7'),
          BigInt.parse('8'),
          BigInt.parse('9'),
          BigInt.parse('10'),
          BigInt.parse('11'),
          BigInt.parse('12'),
        ]),
      ),
    ),
    false,
  );
}

extension Bls12FpToNative on Bls12Fp2 {
  Bls12NativeFp2 toNative() =>
      Bls12NativeFp2(c0: c0.toNative(), c1: c1.toNative());
}
