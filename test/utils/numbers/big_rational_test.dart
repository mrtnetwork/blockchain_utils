import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void bigRationalTest() {
  group('BigRational.fromDouble', () {
    test('integral values convert exactly', () {
      final hundred = BigRational.fromDouble(100.0);
      expect(hundred.numerator, BigInt.from(100));
      expect(hundred.denominator, BigInt.one);

      // 10^21 is exactly representable (5^21 < 2^49); float formatting
      // renders it as "1e+21" and toInt() overflows, both must be avoided.
      final huge = BigRational.fromDouble(1e21);
      expect(huge.denominator, BigInt.one);
      expect(huge.numerator, BigInt.parse('1000000000000000000000'));

      expect(BigRational.fromDouble(0.0).numerator, BigInt.zero);
      expect(BigRational.fromDouble(-0.0).numerator, BigInt.zero);

      final neg = BigRational.fromDouble(-42.0);
      expect(neg.numerator, BigInt.from(-42));
      expect(neg.denominator, BigInt.one);
    });

    test('fractional values keep their exact binary value', () {
      final half = BigRational.fromDouble(0.5);
      expect(half.numerator, BigInt.one);
      expect(half.denominator, BigInt.from(2));

      final quarter = BigRational.fromDouble(2.5);
      expect(quarter.numerator, BigInt.from(5));
      expect(quarter.denominator, BigInt.from(2));
    });

    test('round-trips through toDouble', () {
      for (final v in [0.5, 100.0, 1e21, 123.456, 9007199254740992.0]) {
        expect(BigRational.fromDouble(v).toDouble(), v);
      }
    });

    test('NaN and infinities throw', () {
      expect(() => BigRational.fromDouble(double.nan), throwsA(anything));
      expect(() => BigRational.fromDouble(double.infinity), throwsA(anything));
      expect(
        () => BigRational.fromDouble(double.negativeInfinity),
        throwsA(anything),
      );
    });
  });
}

void main() {
  bigRationalTest();
  // BlockchainUtilsTestApi.runTest(bigRationalTest, "BigRational");
}
