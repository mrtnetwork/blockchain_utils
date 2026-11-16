import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

bool _allZero(List<int> bytes) => bytes.every((b) => b == 0);

void f4jumbleTest() {
  group('F4Jumble roundtrip', () {
    test('apply/applyInv invert each other', () {
      for (final len in [48, 49, 64, 100, 255, 1000]) {
        final input = List<int>.generate(len, (i) => (i * 37 + 11) & 0xFF);
        final jumbled = F4Jumble.apply(input);
        expect(jumbled.length, len);
        expect(F4Jumble.applyInv(jumbled), input, reason: 'len $len');
      }
    });

    test('zero input roundtrips', () {
      final input = List<int>.filled(64, 0);
      expect(F4Jumble.applyInv(F4Jumble.apply(input)), input);
    });

    test('jumbling actually permutes (not identity)', () {
      final input = List<int>.generate(64, (i) => i & 0xFF);
      final jumbled = F4Jumble.apply(input);
      expect(jumbled, isNot(equals(input)));
      expect(_allZero(jumbled), isFalse);
    });

    test('deterministic', () {
      final input = List<int>.generate(100, (i) => (i * 7) & 0xFF);
      expect(F4Jumble.apply(input), F4Jumble.apply(input));
    });

    test('all-same-byte input roundtrips', () {
      final input = List<int>.filled(48, 0xAB);
      expect(F4Jumble.applyInv(F4Jumble.apply(input)), input);
    });
  });

  group('F4Jumble length validation', () {
    test('minimum length boundary', () {
      expect(F4Jumble.haveValidLength(List<int>.filled(47, 0)), isFalse);
      expect(F4Jumble.haveValidLength(List<int>.filled(48, 0)), isTrue);
    });

    test('maximum length boundary', () {
      expect(F4Jumble.haveValidLength(List<int>.filled(4194368, 0)), isTrue);
      expect(F4Jumble.haveValidLength(List<int>.filled(4194369, 0)), isFalse);
    });

    test('short input throws ArgumentException', () {
      expect(
        () => F4Jumble.apply(List<int>.filled(47, 1)),
        throwsA(isA<BuError>()),
      );
      expect(() => F4Jumble.apply([]), throwsA(isA<BuError>()));
      expect(
        () => F4Jumble.applyInv(List<int>.filled(10, 1)),
        throwsA(isA<BuError>()),
      );
    });

    test('oversize input throws ArgumentException', () {
      // haveValidLength rejects without allocating the payload.
      expect(
        () => F4Jumble.apply(List<int>.filled(4194369, 1)),
        throwsA(isA<BuError>()),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(f4jumbleTest, "F4Jumble");
}
