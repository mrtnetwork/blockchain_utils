import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:test/test.dart';

void main() {
  test("JubJub/FR", () {
    _toBytes();
    _bytes64();
    _fromBytesMax();
    _testZero();
    _addition();
    _negation();
    _subtraction();
    _square();
    _inversion();
    _invert();
  });
}

void _invert() {
  final m2 = BigInt.parse(
    "6554484396890773809930967563523245729705921265872317281365359162392183254197",
  );
  final r = JubJubNativeFr.fromBytes(JubJubFr.r.toBytes());
  JubJubNativeFr r1 = r;
  JubJubNativeFr r2 = r;
  JubJubNativeFr r3 = r;

  for (int i = 0; i < 100; i++) {
    r1 = r1.invert() ?? JubJubNativeFr.zero();
    r2 = r2.pow(m2);
    r3 = r3.pow(m2);
    expect(r2, r3);
    r1 += r;
    r2 = r1;
    r3 = r1;
  }
}

void _inversion() {
  expect(JubJubNativeFr.zero().invert(), null);
  // return;
  expect(JubJubNativeFr.one().invert(), JubJubNativeFr.one());
  expect((-JubJubNativeFr.one()).invert(), -JubJubNativeFr.one());

  JubJubNativeFr tmp = JubJubNativeFr.fromBytes(JubJubFr.r2.toBytes());

  for (int i = 0; i < 100; i++) {
    JubJubNativeFr tmp2 = tmp.invert() ?? JubJubNativeFr.zero();
    tmp2 *= tmp;
    expect(tmp2, JubJubNativeFr.one());
    tmp += JubJubNativeFr.fromBytes(JubJubFr.r2.toBytes());
  }
}

void _square() {
  JubJubNativeFr cur = largest;

  for (int i = 0; i < 100; i++) {
    // tmp = cur.square()
    JubJubNativeFr tmp = cur.square();

    // tmp2 = 0
    JubJubNativeFr tmp2 = JubJubNativeFr.zero();

    // Iterate bits MSB -> LSB
    List<int> bytes = cur.toBytes();
    for (int byteIndex = bytes.length - 1; byteIndex >= 0; byteIndex--) {
      int byte = bytes[byteIndex];
      for (int i = 7; i >= 0; i--) {
        bool b = ((byte >> i) & 1) == 1;

        // tmp2 = tmp2 + tmp2 (double)
        tmp2 += tmp2;

        // If bit is set, add cur
        if (b) {
          tmp2 += cur;
        }
      }
    }

    expect(tmp, tmp2);

    // cur += LARGEST
    cur += largest;
  }
}

void _subtraction() {
  JubJubNativeFr tmp = largest;
  tmp -= largest;

  expect(tmp, JubJubNativeFr.zero());

  tmp = JubJubNativeFr.zero();
  tmp -= largest;

  JubJubNativeFr tmp2 = JubJubNativeFr.fromBytes(JubJubFrConst.modulus.toBytes());
  tmp2 -= largest;

  expect(tmp, tmp2);
}

void _negation() {
  JubJubNativeFr tmp = -largest;

  expect(tmp.toBytes(), JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes());

  tmp = -JubJubNativeFr.zero();
  expect(tmp, JubJubNativeFr.zero());
  tmp =
      -JubJubNativeFr.fromBytes(
        JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes(),
      );
  expect(tmp, largest);
}

void _addition() {
  JubJubNativeFr tmp = largest;
  tmp += largest;

  expect(
    tmp.toBytes(),
    JubJubFr([
      Uint64.parseHex('0xd0970e5ed6f72cb5'),
      Uint64.parseHex('0xa6682093ccc81082'),
      Uint64.parseHex('0x06673b0101343b00'),
      Uint64.parseHex('0x0e7db4ea6533afa9'),
    ]).toBytes(),
  );

  tmp = largest;
  tmp += JubJubNativeFr.fromBytes(
    JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes(),
  );

  expect(tmp, JubJubNativeFr.zero());
}

void _testZero() {
  expect(JubJubNativeFr.zero(), -JubJubNativeFr.zero());
  expect(JubJubNativeFr.zero(), JubJubNativeFr.zero() + JubJubNativeFr.zero());
  expect(JubJubNativeFr.zero(), JubJubNativeFr.zero() - JubJubNativeFr.zero());
  expect(JubJubNativeFr.zero(), JubJubNativeFr.zero() * JubJubNativeFr.zero());
}

void _fromBytesMax() {
  expect(
    JubJubFr([
      Uint64.parseHex('0x8b75c9015ae42a22'),
      Uint64.parseHex('0xe59082e7bf9e38b8'),
      Uint64.parseHex('0x6440c91261da51b3'),
      Uint64.parseHex('0x0a5e07ffb20991cf'),
    ]).toBytes(),
    JubJubNativeFr.fromBytes64(List<int>.filled(64, 0xff)).toBytes(),
  );
}

void _bytes64() {
  expect(
    (-JubJubNativeFr.one()),
    JubJubNativeFr.fromBytes64(
      BytesUtils.fromHexString(
        "b62cf7d65e0e97d08210c8cc932068a6003b3401013b6706a9af3365eab47d0e0000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
  expect(
    JubJubFr.r2.toBytes(),
    JubJubNativeFr.fromBytes64(
      BytesUtils.fromHexString(
        "d90796b9b30bf82550e7b6662fd615f3f41488ebee142593c65591476ffca6090000000000000000000000000000000000000000000000000000000000000000",
      ),
    ).toBytes(),
  );
}

final largest = JubJubNativeFr.fromBytes(
  BytesUtils.fromHexString(
    "a6fad3f64642201a72915e7aa7bbe3d4d149c48837390b0a3781a0677ba9060b",
  ),
);
void testMul() {
  JubJubNativeFr cur = largest;

  for (int i = 0; i < 100; i++) {
    JubJubNativeFr tmp = cur * cur; // cur * cur

    JubJubNativeFr tmp2 = JubJubNativeFr.zero();

    // convert cur to bytes and iterate bits MSB -> LSB
    List<int> bytes = cur.toBytes(); // returns List<int> of length 32
    for (int byteIndex = bytes.length - 1; byteIndex >= 0; byteIndex--) {
      int byte = bytes[byteIndex];
      for (int i = 7; i >= 0; i--) {
        bool b = ((byte >> i) & 1) == 1;

        // double tmp2
        JubJubNativeFr tmp3 = tmp2; // clone to avoid overwriting
        tmp2 += tmp3;

        // add cur if bit is set
        if (b) {
          tmp2 += cur;
        }
      }
    }
    // check equality
    expect(tmp, tmp2);
    // increment cur by LARGEST
    cur += largest;
  }
}

void _toBytes() {
  expect(
    (-JubJubNativeFr.one()).toBytes(),
    BytesUtils.fromHexString(
      "b62cf7d65e0e97d08210c8cc932068a6003b3401013b6706a9af3365eab47d0e",
    ),
  );
}
