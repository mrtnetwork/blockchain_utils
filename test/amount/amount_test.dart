import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

void main() {
  group('AmountConverter Tests', () {
    test('Convert 6 decimals → 10 decimals', () {
      final result = AmountConverterUtils.convertDecimals(
        amount: BigInt.from(6000000),
        from: 6,
        to: 10,
      );
      expect(result, BigInt.from(60000000000)); // ×10^(10−6)
    });

    test('Convert 10 decimals → 6 decimals', () {
      final result = AmountConverterUtils.convertDecimals(
        amount: BigInt.from(60000000000),
        from: 10,
        to: 6,
      );
      expect(result, BigInt.from(6000000)); // ÷10^(10−6)
    });

    test('Same decimals = no change', () {
      final result = AmountConverterUtils.convertDecimals(
        amount: BigInt.from(123456),
        from: 10,
        to: 10,
      );
      expect(result, BigInt.from(123456));
    });
    test('Bitcoin conversions', () {
      // toAmount
      expect(AmountConverter.btc.toAmount(BigInt.parse("100000000")), '1');
      expect(AmountConverter.btc.toAmount(BigInt.parse("123456789")),
          '1.23456789');

      expect(
          AmountConverter(decimals: 8, displayPrecision: 2)
              .toAmount(BigInt.parse("123456789")),
          '1.23');

      // toUnit
      expect(AmountConverter.btc.toUnit('1'), BigInt.parse('100000000'));
      expect(
          AmountConverter.btc.toUnit('1.23456789'), BigInt.parse('123456789'));

      // edge cases
      expect(AmountConverter.btc.toUnit('0'), BigInt.zero);
      expect(AmountConverter.btc.toAmount(BigInt.zero), '0');
    });
    test('No Decimals', () {
      expect(
          AmountConverter(decimals: 0)
              .toAmount(BigInt.parse('1000000000000000000')),
          '1000000000000000000');
      expect(AmountConverter(decimals: 0).toUnit('1000000'),
          BigInt.parse('1000000'));
    });
    test('Ethereum conversions', () {
      expect(AmountConverter.eth.toAmount(BigInt.parse('1000000000000000000')),
          '1');
      expect(AmountConverter.eth.toUnit('1.5'),
          BigInt.parse('1500000000000000000'));
    });

    test('Tron conversions', () {
      expect(AmountConverter.tron.toAmount(BigInt.parse('1000000')), '1');
      expect(AmountConverter.tron.toUnit('1.234567'), BigInt.parse('1234567'));
    });

    test('Polkadot conversions', () {
      expect(
          AmountConverter.polkadot.toAmount(BigInt.parse('10000000000')), '1');
      expect(AmountConverter.polkadot.toUnit('1.2345678901'),
          BigInt.parse('12345678901'));
    });

    test('Kusama conversions', () {
      expect(
          AmountConverter.kusama.toAmount(BigInt.parse('1000000000000')), '1');
      expect(AmountConverter.kusama.toUnit('1.123456789012'),
          BigInt.parse('1123456789012'));
    });

    test('To many decimals', () {
      expect(
        () => AmountConverter.btc.toUnit('1.123456789'),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
        () => AmountConverter(decimals: 256),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
        () => AmountConverter(decimals: -1),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
        () => AmountConverter(decimals: 1, displayPrecision: -1),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
          AmountConverter.btc.toUnit('1.123456789', enforceMaxDecimals: false),
          BigInt.from(112345678));
    });

    test('Parsing invalid string throws', () {
      expect(
        () => AmountConverter.btc.toUnit('abc'),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
        () => AmountConverter.btc.toUnit('1..'),
        throwsA(isA<AmountConverterException>()),
      );
      expect(
        () => AmountConverter.btc.toUnit('.1'),
        throwsA(isA<AmountConverterException>()),
      );
    });
  });
}
