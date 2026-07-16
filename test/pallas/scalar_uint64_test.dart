import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

void main() {
  // return;
  test("JubJub/FQ", () {
    _sqrt();
    _invert();
    _invert2();
    _square();
    _testMul();
    _subtraction();
    _negation();
    _addition();
    _testZero();
    _toBytes();
    _constants();
    _fromBytes64();
    _fromBytesMax();
  });
}

void _sqrt() {
  expect(JubJubFq.zero.sqrt().result, JubJubFq.zero);
  JubJubFq square = JubJubFq([
    Uint64.parseHex("0x46cd85a5f273077e"),
    Uint64.parseHex("0x1d30c47dd68fc735"),
    Uint64.parseHex("0x77f656f60beca0eb"),
    Uint64.parseHex("0x494aa01bdf32468d"),
  ]);

  int noneCount = 0;

  for (int i = 0; i < 100; i++) {
    var squareRoot = square.sqrt();
    if (!squareRoot.isSquare) {
      noneCount += 1;
    } else {
      expect(squareRoot.result * squareRoot.result, square);
    }
    square -= JubJubFq.one;
  }

  expect(49, noneCount);
}

void _invert() {
  List<Uint64> m2 = [
    Uint64.parseHex("0xfffffffeffffffff"),
    Uint64.parseHex("0x53bda402fffe5bfe"),
    Uint64.parseHex("0x3339d80809a1d805"),
    Uint64.parseHex("0x73eda753299d7d48"),
  ];

  JubJubFq r1 = JubJubFq.r;
  JubJubFq r2 = JubJubFq.r;
  JubJubFq r3 = JubJubFq.r;

  for (int i = 0; i < 100; i++) {
    r1 = r1.invert()!;
    r2 = r2.powVartime(m2);
    r3 = r3.pow(m2);
    expect(r1, r2);
    expect(r2, r3);
    // Add r so we check something different next time around
    r1 += JubJubFq.r;
    r2 = r1;
    r3 = r1;
  }
}

void _invert2() {
  expect(JubJubFq.zero.invert(), null);
  expect(JubJubFq.one.invert(), JubJubFq.one);
  expect((-JubJubFq.one).invert(), -JubJubFq.one);

  JubJubFq tmp = JubJubFq.r2;

  for (int i = 0; i < 100; i++) {
    JubJubFq tmp2 = tmp.invert()!;
    tmp2 *= tmp;
    expect(tmp2, JubJubFq.one);
    tmp += JubJubFq.r2;
  }
}

void _square() {
  JubJubFq cur = largest;

  for (int i = 0; i < 100; i++) {
    // tmp = cur.square()
    JubJubFq tmp = cur.square();

    // tmp2 = 0
    JubJubFq tmp2 = JubJubFq.zero;

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
  JubJubFq cur = largest;

  for (int i = 0; i < 100; i++) {
    JubJubFq tmp = cur.mul(cur); // cur * cur

    JubJubFq tmp2 = JubJubFq.zero;

    // convert cur to bytes and iterate bits MSB -> LSB
    List<int> bytes = cur.toBytes(); // returns List<int> of length 32
    for (int byteIndex = bytes.length - 1; byteIndex >= 0; byteIndex--) {
      int byte = bytes[byteIndex];
      for (int i = 7; i >= 0; i--) {
        bool b = ((byte >> i) & 1) == 1;

        // double tmp2
        JubJubFq tmp3 = tmp2; // clone to avoid overwriting
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

void _subtraction() {
  JubJubFq tmp = largest;
  tmp -= largest;

  expect(tmp, JubJubFq.zero);

  tmp = JubJubFq.zero;
  tmp -= largest;

  JubJubFq tmp2 = JubJubFqConst.modulus;
  tmp2 -= largest;

  expect(tmp, tmp2);
}

final largest = JubJubFq([
  Uint64.parseHex('0xffffffff00000000'), // 64-bit + overflow safe
  Uint64.parseHex('0x53bda402fffe5bfe'),
  Uint64.parseHex('0x3339d80809a1d805'),
  Uint64.parseHex('0x73eda753299d7d48'),
]);

void _negation() {
  JubJubFq tmp = -largest;

  expect(tmp, JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList()));

  tmp = -JubJubFq.zero;
  expect(tmp, JubJubFq.zero);
  tmp = -JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList());
  expect(tmp, largest);
}

void _addition() {
  JubJubFq tmp = largest;
  tmp += largest;

  expect(
    tmp,
    JubJubFq([
      Uint64.parseHex('0xfffffffeffffffff'),
      Uint64.parseHex('0x53bda402fffe5bfe'),
      Uint64.parseHex('0x3339d80809a1d805'),
      Uint64.parseHex('0x73eda753299d7d48'),
    ]),
  );

  tmp = largest;
  tmp += JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList());

  expect(tmp, JubJubFq.zero);
}

void _testZero() {
  expect(JubJubFq.zero, -JubJubFq.zero);
  expect(JubJubFq.zero, JubJubFq.zero + JubJubFq.zero);
  expect(JubJubFq.zero, JubJubFq.zero - JubJubFq.zero);
  expect(JubJubFq.zero, JubJubFq.zero * JubJubFq.zero);
}

void _fromBytesMax() {
  expect(
    JubJubFq([
      Uint64.parseHex('0xc62c1805439b73b1'),
      Uint64.parseHex('0xc2b9551e8ced218e'),
      Uint64.parseHex('0xda44ec81daf9a422'),
      Uint64.parseHex('0x5605aa601c162e79'),
    ]),
    JubJubFq.fromBytes64(List<int>.filled(64, 0xff)),
  );
}

void _fromBytes64() {
  expect(
    -JubJubFq.one,
    JubJubFq.fromBytes64(
      BytesUtils.fromHexString(
        "00000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed730000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
  expect(
    JubJubFq.r2,
    JubJubFq.fromBytes64(
      BytesUtils.fromHexString(
        "feffffff0100000002480300fab78458f54fbcecef4f8c996f05c5ac59b124180000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
}

void _toBytes() {
  final r2Bytes = BytesUtils.fromHexString(
    "feffffff0100000002480300fab78458f54fbcecef4f8c996f05c5ac59b12418",
  );
  expect(JubJubFq.r2.toBytes(), r2Bytes);
  expect(JubJubFq.r2, JubJubFq.fromBytes(r2Bytes));
}

void _constants() {
  final delta = JubJubFq([
    Uint64.parseHex('0x70e310d3d146f96a'),
    Uint64.parseHex('0x4b64c08919e299e6'),
    Uint64.parseHex('0x51e114186a8b970d'),
    Uint64.parseHex('0x6185d06627c067cb'),
  ]);
  expect((JubJubFq.from(Uint64(2)) * JubJubFq.twoInv), JubJubFq.one);
  expect((JubJubFq.rootOfUnity * JubJubFq.rootOfUnityInv), JubJubFq.one);
  expect(
    JubJubFq.rootOfUnity.pow([
      Uint64.one << JubJubFqConst.S,
      Uint64.zero,
      Uint64.zero,
      Uint64.zero,
    ]),
    JubJubFq.one,
  );
  expect(
    delta.pow([
      Uint64.parseHex('0xfffe5bfeffffffff'),
      Uint64.parseHex('0x09a1d80553bda402'),
      Uint64.parseHex('0x299d7d483339d808'),
      Uint64.parseHex('0x0000000073eda753'),
    ]),
    JubJubFq.one,
  );
}
