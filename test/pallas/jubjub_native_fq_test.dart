import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/numbers/src/u64/u64.dart';
import 'package:test/test.dart';

void main() {
  test("JubJub/FQ Native", () {
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
    _bytes64();
    _fromBytesMax();
  });
}

void _sqrt() {
  expect(JubJubNativeFq.zero().sqrt().result, JubJubNativeFq.zero());
  JubJubNativeFq square = JubJubNativeFq.fromBytes(
    JubJubFq([
      Uint64.parseHex("0x46cd85a5f273077e"),
      Uint64.parseHex("0x1d30c47dd68fc735"),
      Uint64.parseHex("0x77f656f60beca0eb"),
      Uint64.parseHex("0x494aa01bdf32468d"),
    ]).toBytes(),
  );

  int noneCount = 0;

  for (int i = 0; i < 100; i++) {
    var squareRoot = square.sqrt();
    if (!squareRoot.isSquare) {
      noneCount += 1;
    } else {
      expect(squareRoot.result * squareRoot.result, square);
    }
    square -= JubJubNativeFq.one();
  }

  expect(49, noneCount);
}

void _invert() {
  List<BigInt> m2 = [
    BigInt.parse("0xfffffffeffffffff"),
    BigInt.parse("0x53bda402fffe5bfe"),
    BigInt.parse("0x3339d80809a1d805"),
    BigInt.parse("0x73eda753299d7d48"),
  ];
  final r = JubJubNativeFq.fromBytes(JubJubFq.r.toBytes());

  JubJubNativeFq r1 = r;
  JubJubNativeFq r2 = r;
  JubJubNativeFq r3 = r;

  for (int i = 0; i < 100; i++) {
    r1 = r1.invert()!;
    r2 = r2.powVartime(m2);
    r3 = r3.powVartime(m2);
    expect(r1, r2);
    expect(r2, r3);
    // Add r so we check something different next time around
    r1 += r;
    r2 = r1;
    r3 = r1;
  }
}

void _invert2() {
  expect(JubJubNativeFq.zero().invert(), null);
  expect(JubJubNativeFq.one().invert(), JubJubNativeFq.one());
  expect((-JubJubNativeFq.one()).invert(), -JubJubNativeFq.one());

  JubJubNativeFq tmp = JubJubNativeFq.fromBytes(JubJubFq.r2.toBytes());

  for (int i = 0; i < 100; i++) {
    JubJubNativeFq tmp2 = tmp.invert()!;
    tmp2 *= tmp;
    expect(tmp2, JubJubNativeFq.one());
    tmp += JubJubNativeFq.fromBytes(JubJubFq.r2.toBytes());
  }
}

final l = JubJubNativeFq.fromBytes(largest.toBytes());

void _square() {
  final l = JubJubNativeFq.fromBytes(largest.toBytes());
  JubJubNativeFq cur = l;

  for (int i = 0; i < 100; i++) {
    // tmp = cur.square()
    JubJubNativeFq tmp = cur.square();

    // tmp2 = 0
    JubJubNativeFq tmp2 = JubJubNativeFq.zero();

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
    cur += l;
  }
}

void _testMul() {
  JubJubNativeFq cur = l;

  for (int i = 0; i < 100; i++) {
    JubJubNativeFq tmp = cur * cur; // cur * cur

    JubJubNativeFq tmp2 = JubJubNativeFq.zero();

    // convert cur to bytes and iterate bits MSB -> LSB
    List<int> bytes = cur.toBytes(); // returns List<int> of length 32
    for (int byteIndex = bytes.length - 1; byteIndex >= 0; byteIndex--) {
      int byte = bytes[byteIndex];
      for (int i = 7; i >= 0; i--) {
        bool b = ((byte >> i) & 1) == 1;

        // double tmp2
        JubJubNativeFq tmp3 = tmp2; // clone to avoid overwriting
        tmp2 += tmp3;

        // add cur if bit is set
        if (b) {
          tmp2 += cur;
        }
      }
    }
    expect(tmp, tmp2);

    // increment cur by LARGEST
    cur += l;
  }
}

void _subtraction() {
  JubJubNativeFq tmp = l;
  tmp -= l;

  expect(tmp, JubJubNativeFq.zero());

  tmp = JubJubNativeFq.zero();
  tmp -= l;

  JubJubNativeFq tmp2 = JubJubNativeFq.fromBytes(JubJubFqConst.modulus.toBytes());
  tmp2 -= l;

  expect(tmp, tmp2);
}

final largest = JubJubFq([
  Uint64.parseHex('0xffffffff00000000'), // 64-bit + overflow safe
  Uint64.parseHex('0x53bda402fffe5bfe'),
  Uint64.parseHex('0x3339d80809a1d805'),
  Uint64.parseHex('0x73eda753299d7d48'),
]);

void _negation() {
  JubJubNativeFq tmp = -l;

  expect(
    tmp,
    JubJubNativeFq.fromBytes(
      JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes(),
    ),
  );

  tmp = -JubJubNativeFq.zero();
  expect(tmp, JubJubNativeFq.zero());
  tmp =
      -JubJubNativeFq.fromBytes(
        JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes(),
      );
  expect(tmp, l);
}

void _addition() {
  JubJubNativeFq tmp = l;
  tmp += l;

  expect(
    tmp,
    JubJubNativeFq.fromBytes(
      JubJubFq([
        Uint64.parseHex('0xfffffffeffffffff'),
        Uint64.parseHex('0x53bda402fffe5bfe'),
        Uint64.parseHex('0x3339d80809a1d805'),
        Uint64.parseHex('0x73eda753299d7d48'),
      ]).toBytes(),
    ),
  );

  tmp = l;
  tmp += JubJubNativeFq.fromBytes(
    JubJubFq([1, 0, 0, 0].map((e) => Uint64(e)).toList()).toBytes(),
  );

  expect(tmp, JubJubNativeFq.zero());
}

void _testZero() {
  expect(JubJubNativeFq.zero(), -JubJubNativeFq.zero());
  expect(JubJubNativeFq.zero(), JubJubNativeFq.zero() + JubJubNativeFq.zero());
  expect(JubJubNativeFq.zero(), JubJubNativeFq.zero() - JubJubNativeFq.zero());
  expect(JubJubNativeFq.zero(), JubJubNativeFq.zero() * JubJubNativeFq.zero());
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

void _bytes64() {
  expect(
    (-JubJubNativeFq.one()),
    JubJubNativeFq.fromBytes64(
      BytesUtils.fromHexString(
        "00000000fffffffffe5bfeff02a4bd5305d8a10908d83933487d9d2953a7ed730000000000000000000000000000000000000000000000000000000000000000",
      ),
    ),
  );
  expect(
    JubJubFq.r2.toBytes(),
    JubJubNativeFq.fromBytes64(
      BytesUtils.fromHexString(
        "feffffff0100000002480300fab78458f54fbcecef4f8c996f05c5ac59b124180000000000000000000000000000000000000000000000000000000000000000",
      ),
    ).toBytes(),
  );
}

void _toBytes() {
  final r2Bytes = BytesUtils.fromHexString(
    "feffffff0100000002480300fab78458f54fbcecef4f8c996f05c5ac59b12418",
  );
  expect(JubJubNativeFq.fromBytes(JubJubFq.r2.toBytes()).toBytes(), r2Bytes);
  expect(
    JubJubNativeFq.fromBytes(JubJubFq.r2.toBytes()),
    JubJubNativeFq.fromBytes(r2Bytes),
  );
}

void _constants() {
  final delta = JubJubNativeFq.fromBytes(
    JubJubFq([
      Uint64.parseHex('0x70e310d3d146f96a'),
      Uint64.parseHex('0x4b64c08919e299e6'),
      Uint64.parseHex('0x51e114186a8b970d'),
      Uint64.parseHex('0x6185d06627c067cb'),
    ]).toBytes(),
  );
  expect(
    (JubJubNativeFq.fromBytes(JubJubFq.from(Uint64(2)).toBytes()) *
            JubJubNativeFq.fromBytes(JubJubFq.twoInv.toBytes()))
        .toBytes(),
    JubJubFq.one.toBytes(),
  );
  expect(
    (JubJubNativeFq.fromBytes(JubJubFq.rootOfUnity.toBytes()) *
        JubJubNativeFq.fromBytes(JubJubFq.rootOfUnityInv.toBytes())),
    JubJubNativeFq.one(),
  );
  expect(
    JubJubNativeFq.fromBytes(
      JubJubFq.rootOfUnity.toBytes(),
    ).powVartime([BigInt.one << JubJubFqConst.S, BigInt.zero, BigInt.zero, BigInt.zero]),
    JubJubNativeFq.one(),
  );
  expect(
    delta.powVartime([
      BigInt.parse('0xfffe5bfeffffffff'),
      BigInt.parse('0x09a1d80553bda402'),
      BigInt.parse('0x299d7d483339d808'),
      BigInt.parse('0x0000000073eda753'),
    ]),
    JubJubNativeFq.one(),
  );
  final a = JubJubNativeFq(
    BigInt.parse(
      "-13443226831829260228624682877674385705155231329884953466695813022153219761455",
    ),
  );
  final squared = JubJubNativeFq(
    BigInt.parse(
      "1615918303262283860389448007513155112015187847020867660361132469416696757234",
    ),
  );
  expect(a * a, squared);
  expect(a.pow(BigInt.two), squared);
  expect(squared.sqrt().result, a);
}
