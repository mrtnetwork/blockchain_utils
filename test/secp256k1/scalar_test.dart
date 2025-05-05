import 'package:blockchain_utils/crypto/crypto/cdsa/curve/curves.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:test/test.dart';
import 'package:blockchain_utils/crypto/crypto/cdsa/secp256k1/secp256k1.dart';

final _generator = Curves.generatorSecp256k1;
final _curve = Curves.curveSecp256k1;
final BigInt _order = _generator.order!;

void main() {
  _scalarNegate();
  _scalarMul();
  _scalarAdd();
  _scalarIsEven();
  _scalarIsZero();
  _scalarIsOne();
  _scalarIsHigh();
  _scalarNegate();
  _overFlow();
  _scalarCmove();
  _scalarEqual();
  _half();
}

(Secp256k1Scalar, BigInt) _generateScalar({List<int>? bytes}) {
  final scalarBytes = bytes ?? QuickCrypto.generateRandom();
  final Secp256k1Scalar r = Secp256k1Scalar();
  Secp256k1.secp256k1ScalarSetB32(r, scalarBytes);
  final toBig = BigintUtils.fromBytes(scalarBytes);
  return (r, toBig);
}

(List<int>, BigInt) _scalarToBytes(Secp256k1Scalar r) {
  final result = List<int>.filled(32, 0);
  Secp256k1.secp256k1ScalarGetB32(result, r);
  final big = BigintUtils.fromBytes(result);
  return (result, big);
}

void _scalarAdd() {
  test("scalar add", () {
    for (int i = 0; i < 10000; i++) {
      final a = _generateScalar();
      final b = _generateScalar();
      if (!_isScalar(a.$1) || !_isScalar(b.$1)) {
        continue;
      }
      final Secp256k1Scalar r = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarAdd(r, a.$1, b.$1);
      final scalarToBytes = _scalarToBytes(r);
      final n = (a.$2 + b.$2) % _order;
      expect(n, scalarToBytes.$2);
    }
  });
}

void _scalarMul() {
  test("scalar mull", () {
    for (int i = 0; i < 10000; i++) {
      final aBytes = QuickCrypto.generateRandom();
      final bBytes = QuickCrypto.generateRandom();
      final a = _generateScalar(bytes: aBytes);
      final b = _generateScalar(bytes: bBytes);
      if (!_isScalar(a.$1) || !_isScalar(b.$1)) {
        continue;
      }
      final Secp256k1Scalar r = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarMul(r, a.$1, b.$1);
      final scalarToBytes = _scalarToBytes(r);
      final n = (a.$2 * b.$2) % _order;
      expect(n, scalarToBytes.$2);
    }
  });
}

bool _isScalar(Secp256k1Scalar r) {
  return Secp256k1.secp256k1ScalarCheckOverflow(r) == 0;
}

void _scalarIsEven() {
  test("scalar is evn", () {
    for (int i = 0; i < 10000; i++) {
      final a = _generateScalar();
      if (!_isScalar(a.$1)) continue;

      final int even = Secp256k1.secp256k1ScalarIsEven(a.$1);
      expect(a.$2.isEven, even == 1);
    }
  });
}

void _scalarIsZero() {
  test("scalar is zero", () {
    final a = _generateScalar(bytes: List<int>.filled(32, 0));
    final int zero = Secp256k1.secp256k1ScalarIsZero(a.$1);
    expect(zero, 1);
  });
}

void _scalarIsOne() {
  test("scalar is one", () {
    final r = List<int>.filled(32, 0);
    r.last = 1;
    final a = _generateScalar(bytes: r);
    final int one = Secp256k1.secp256k1ScalarIsOne(a.$1);
    expect(one, 1);
  });
  test("scalar is one", () {
    final r = List<int>.filled(32, 1);
    final a = _generateScalar(bytes: r);
    final int one = Secp256k1.secp256k1ScalarIsOne(a.$1);
    expect(one, 0);
  });
}

void _scalarIsHigh() {
  test("scalar is high", () {
    for (int i = 0; i < 1000; i++) {
      final a = _generateScalar();
      if (!_isScalar(a.$1)) continue;
      final int high = Secp256k1.secp256k1ScalarIsHigh(a.$1);
      final half = _order >> 1;
      final isHigh = a.$2 > half;
      expect(isHigh, high == 1);
    }
  });
}

void _scalarNegate() {
  test("scalar negate", () {
    for (int i = 0; i < 1000; i++) {
      final scalarBytes = QuickCrypto.generateRandom();
      final List<int> result = List<int>.filled(32, 0);
      final Secp256k1Scalar r = Secp256k1Scalar();
      final Secp256k1Scalar negate = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarSetB32(r, scalarBytes);
      Secp256k1.secp256k1ScalarNegate(negate, r);
      Secp256k1.secp256k1ScalarGetB32(result, negate);
      BigInt scalarBig = BigintUtils.fromBytes(scalarBytes);
      scalarBig = _order - scalarBig % _order;
      final toBytes = BigintUtils.toBytes(scalarBig, length: _curve.baselen);
      expect(toBytes, result);
      Secp256k1.secp256k1ScalarSetB32(r, toBytes);
      expect(negate, r);
    }
  });
}

void _overFlow() {
  test('overflowed', () {
    final Secp256k1Scalar overflowed = Secp256k1Scalar.constants(
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF),
        BigInt.from(0xFFFFFFFF));
    expect(_isScalar(overflowed), false);
  });
}

void _scalarCmove() {
  test("secp256k1ScalarCmov", () {
    for (int i = 0; i < 1000; i++) {
      final aBytes = QuickCrypto.generateRandom();
      final Secp256k1Scalar a = Secp256k1Scalar();
      final Secp256k1Scalar negate = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarSetB32(a, aBytes);
      Secp256k1.secp256k1ScalarNegate(negate, a);

      final bBytes = QuickCrypto.generateRandom();
      final Secp256k1Scalar b = Secp256k1Scalar();
      final Secp256k1Scalar bNegate = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarSetB32(b, bBytes);
      Secp256k1.secp256k1ScalarNegate(bNegate, b);
      final cNegage = negate.clone();
      Secp256k1.secp256k1ScalarCmov(negate, bNegate, i.isEven ? 0 : 1);
      if (i.isEven) {
        expect(cNegage, negate);
        expect(cNegage != bNegate, true);
      } else {
        expect(bNegate, negate);
        expect(bNegate, negate);
      }
    }
  });
}

void _scalarEqual() {
  test("scalar equal", () {
    for (int i = 0; i < 1000; i++) {
      final rand = QuickCrypto.generateRandom();
      final a = _generateScalar(bytes: rand);
      final b = _generateScalar(bytes: rand);
      if (!_isScalar(a.$1) || !_isScalar(b.$1)) continue;
      final eq = Secp256k1.secp256k1ScalarEq(a.$1, b.$1);
      expect(eq, 1);
    }
  });

  test("scalar not equal", () {
    for (int i = 0; i < 1000; i++) {
      final a = _generateScalar();
      final b = _generateScalar();
      if (!_isScalar(a.$1) || !_isScalar(b.$1)) continue;
      final eq = Secp256k1.secp256k1ScalarEq(a.$1, b.$1);
      expect(eq, 0);
    }
  });
}

void _half() {
  BigInt conditionalModularHalve(BigInt a) {
    final isOdd = a.isOdd;
    final adjusted = isOdd ? a + _order : a;
    return adjusted >> 1;
  }

  test("scalar half", () {
    for (int i = 0; i < 1000; i++) {
      final a = _generateScalar();
      if (!_isScalar(a.$1)) continue;
      final r = Secp256k1Scalar();
      Secp256k1.secp256k1ScalarHalf(r, a.$1);
      final toBytes = _scalarToBytes(r);
      final half = conditionalModularHalve(a.$2);
      expect(half, toBytes.$2);
    }
  });
}
