import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:test/test.dart';

void main() {
  test("JubJub/FR", () {
    _fromRow();
    _testSqrt();
    _testInvert();
    _testInvert2();
    _square();
    _testMul();
    _subtraction();
    _negation();
    _addition();
    _testZero();
    _fromBytes64();
    _fromBytes642();
    _toBytes();
    _constants();
  });
}

void _fromRow() {
  expect(
    JubJubFr.fromRaw([
      Uint64.parseHex("0x25f80bb3b99607d8"),
      Uint64.parseHex("0xf315d62f66b6e750"),
      Uint64.parseHex("0x932514eeeb8814f4"),
      Uint64.parseHex("0x09a6fc6f479155c6"),
    ]),
    JubJubFr.fromRaw(List.filled(4, Uint64.parseHex("0xffffffffffffffff"))),
  );
  expect(JubJubFr.fromRaw(JubJubFrConst.modulus.limbs), JubJubFr.zero);
  expect(
    JubJubFr.fromRaw([Uint64.one, Uint64.zero, Uint64.zero, Uint64.zero]),
    JubJubFr.r,
  );
}

void _testSqrt() {
  expect(JubJubFr.zero.sqrt().result, JubJubFr.zero);
  JubJubFr square = JubJubFr([
    Uint64.parseHex("0xd0970e5ed6f72cb5"),
    Uint64.parseHex("0xa6682093ccc81082"),
    Uint64.parseHex("0x06673b0101343b00"),
    Uint64.parseHex("0x0e7db4ea6533afa9"),
  ]);

  int noneCount = 0;

  for (int i = 0; i < 100; i++) {
    var squareRoot = square.sqrt();
    if (!squareRoot.isSquare) {
      noneCount += 1;
    } else {
      expect(squareRoot.result * squareRoot.result, square);
    }
    square -= JubJubFr.one;
  }

  expect(47, noneCount);
}

void _testInvert() {
  List<Uint64> m2 = [
    Uint64.parseHex("0xd0970e5ed6f72cb5"),
    Uint64.parseHex("0xa6682093ccc81082"),
    Uint64.parseHex("0x06673b0101343b00"),
    Uint64.parseHex("0x0e7db4ea6533afa9"),
  ];

  JubJubFr r1 = JubJubFr.r;
  JubJubFr r2 = JubJubFr.r;
  JubJubFr r3 = JubJubFr.r;

  for (int i = 0; i < 100; i++) {
    r1 = r1.invert()!;
    r2 = r2.powVartime(m2);
    r3 = r3.pow(m2);
    expect(r1, r2);
    expect(r2, r3);
    // Add r so we check something different next time around
    r1 += JubJubFr.r;
    r2 = r1;
    r3 = r1;
  }
}

void _testInvert2() {
  expect(JubJubFr.zero.invert(), null);
  expect(JubJubFr.one.invert(), JubJubFr.one);
  expect((-JubJubFr.one).invert(), -JubJubFr.one);

  JubJubFr tmp = JubJubFr.r2;

  for (int i = 0; i < 100; i++) {
    JubJubFr tmp2 = tmp.invert()!;
    tmp2 *= tmp;
    expect(tmp2, JubJubFr.one);
    tmp += JubJubFr.r2;
  }
}

void _square() {
  JubJubFr cur = largest;

  for (int i = 0; i < 100; i++) {
    // tmp = cur.square()
    JubJubFr tmp = cur.square();

    // tmp2 = 0
    JubJubFr tmp2 = JubJubFr.zero;

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

void _testMul() {
  final largest = JubJubFr([
    Uint64.parseHex('0xd0970e5ed6f72cb6'),
    Uint64.parseHex('0xa6682093ccc81082'),
    Uint64.parseHex('0x06673b0101343b00'),
    Uint64.parseHex('0x0e7db4ea6533afa9'),
  ]);
  JubJubFr cur = largest;

  // return;
  for (int i = 0; i < 100; i++) {
    JubJubFr tmp = cur.mul(cur); // cur * cur

    JubJubFr tmp2 = JubJubFr.zero;

    // convert cur to bytes and iterate bits MSB -> LSB
    List<int> bytes = cur.toBytes(); // returns List<int> of length 32
    for (int byteIndex = bytes.length - 1; byteIndex >= 0; byteIndex--) {
      int byte = bytes[byteIndex];
      for (int i = 7; i >= 0; i--) {
        bool b = ((byte >> i) & 1) == 1;

        // double tmp2
        JubJubFr tmp3 = tmp2; // clone to avoid overwriting
        tmp2 += tmp3;

        // add cur if bit is set
        if (b) {
          tmp2 += cur;
        }
      }
    }
    expect(tmp, tmp2);

    // increment cur by LARGEST
    cur += largest;
  }
}

void _subtraction() {
  JubJubFr tmp = largest;
  tmp -= largest;

  expect(tmp, JubJubFr.zero);

  tmp = JubJubFr.zero;
  tmp -= largest;

  JubJubFr tmp2 = JubJubFrConst.modulus;
  tmp2 -= largest;

  expect(tmp, tmp2);
}

final largest = JubJubFr([
  Uint64.parseHex('0xd0970e5ed6f72cb6'),
  Uint64.parseHex('0xa6682093ccc81082'),
  Uint64.parseHex('0x06673b0101343b00'),
  Uint64.parseHex('0x0e7db4ea6533afa9'),
]);

void _negation() {
  JubJubFr tmp = -largest;

  expect(tmp, JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList()));

  tmp = -JubJubFr.zero;
  expect(tmp, JubJubFr.zero);
  tmp = -JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList());
  expect(tmp, largest);
}

void _addition() {
  JubJubFr tmp = largest;
  tmp += largest;

  expect(
    tmp,
    JubJubFr([
      Uint64.parseHex('0xd0970e5ed6f72cb5'),
      Uint64.parseHex('0xa6682093ccc81082'),
      Uint64.parseHex('0x06673b0101343b00'),
      Uint64.parseHex('0x0e7db4ea6533afa9'),
    ]),
  );

  tmp = largest;
  tmp += JubJubFr([1, 0, 0, 0].map((e) => Uint64(e)).toList());

  expect(tmp, JubJubFr.zero);
}

void _testZero() {
  expect(JubJubFr.zero, -JubJubFr.zero);
  expect(JubJubFr.zero, JubJubFr.zero + JubJubFr.zero);
  expect(JubJubFr.zero, JubJubFr.zero - JubJubFr.zero);
  expect(JubJubFr.zero, JubJubFr.zero * JubJubFr.zero);
}

void _fromBytes64() {
  expect(
    JubJubFr([
      Uint64.parseHex('0x8b75c9015ae42a22'),
      Uint64.parseHex('0xe59082e7bf9e38b8'),
      Uint64.parseHex('0x6440c91261da51b3'),
      Uint64.parseHex('0x0a5e07ffb20991cf'),
    ]),
    JubJubFr.fromBytes64(List<int>.filled(64, 0xff)),
  );
}

void _fromBytes642() {
  expect(
    (-JubJubFr.one),
    JubJubFr.fromBytes64(
      BytesUtils.fromHexString(
        "b62cf7d65e0e97d08210c8cc932068a6003b3401013b6706a9af3365eab47d0e0000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
  expect(
    JubJubFr.r2,
    JubJubFr.fromBytes64(
      BytesUtils.fromHexString(
        "d90796b9b30bf82550e7b6662fd615f3f41488ebee142593c65591476ffca6090000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
}

void _toBytes() {
  final r2Bytes = BytesUtils.fromHexString(
    "d90796b9b30bf82550e7b6662fd615f3f41488ebee142593c65591476ffca609",
  );
  expect(BytesUtils.bytesEqual(JubJubFr.r2.toBytes(), r2Bytes), true);
  expect(JubJubFr.r2, JubJubFr.fromBytes(r2Bytes));
  expect(
    (-JubJubFr.one).toBytes(),
    BytesUtils.fromHexString(
      "b62cf7d65e0e97d08210c8cc932068a6003b3401013b6706a9af3365eab47d0e",
    ),
  );
}

void _constants() {
  expect((JubJubFr.from(Uint64(2)) * JubJubFr.twoInv), JubJubFr.one);
  expect((JubJubFr.rootOfUnity * JubJubFr.rootOfUnityInv), JubJubFr.one);
  expect(
    JubJubFr.rootOfUnity.pow([
      Uint64.one << JubJubFrConst.s,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]),
    JubJubFr.one,
  );
  expect(
    JubJubFr.delta.pow([
      Uint64.parseHex('0x684b872f6b7b965b'),
      Uint64.parseHex('0x53341049e6640841'),
      Uint64.parseHex('0x83339d80809a1d80'),
      Uint64.parseHex('0x073eda753299d7d4'),
    ]),
    JubJubFr.one,
  );
}
