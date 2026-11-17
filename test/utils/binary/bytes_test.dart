// Requires `package:test` in dev_dependencies:
//   dart pub add --dev test
// Run with: dart test secret_bytes_test.dart

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

void bytesTest() {
  Matcher throwsBuError = throwsA(isA<BuError>());

  group('BuBytes', () {
    test('safe constructor validates range', () {
      expect(() => BuBytes([0, 128, 255]), returnsNormally);
      expect(() => BuBytes([-1, 0, 1]), throwsBuError);
      expect(() => BuBytes([0, 256]), throwsBuError);
    });

    test('safe constructor copies — no aliasing either direction', () {
      final source = [1, 2, 3];
      final bytes = BuBytes(source);
      source[0] = 99;
      expect(bytes[0], 1); // unaffected by mutating the source afterwards

      final mutable = BuBytes([1, 2, 3]);
      mutable[0] = 42;
      expect(mutable[0], 42);
    });

    test('isImmutable field is set correctly per constructor', () {
      expect(BuBytes([1, 2]).isImmutable, isFalse);
      expect(BuBytes.immutable([1, 2]).isImmutable, isTrue);
      expect(const BuBytes.unsafe([1, 2]).isImmutable, isTrue);
    });

    test('BuBytes.unsafe skips validation and copying (aliases input)', () {
      final source = [1, 2, 3];
      final bytes = BuBytes.unsafe(source);
      source[0] = 42;
      expect(bytes[0], 42); // aliased on purpose — "unsafe"
    });

    test('BuBytes.unsafe is usable as a const expression', () {
      const bytes = BuBytes.unsafe([10, 20, 30]);
      expect(bytes.isImmutable, isTrue);
      expect(bytes[1], 20);
    });

    test('BuBytes.immutable rejects mutation', () {
      final bytes = BuBytes.immutable([1, 2, 3]);
      expect(() => bytes[0] = 9, throwsA(isA<BuError>()));
      expect(() => bytes.add(9), throwsA(isA<BuError>()));
      expect(() => bytes.length = 5, throwsA(isA<BuError>()));
    });

    test('mutable BuBytes supports write, add, resize', () {
      final bytes = BuBytes([1, 2, 3]);
      bytes[0] = 9;
      expect(bytes[0], 9);
      bytes.add(4);
      expect(bytes.toList(), [9, 2, 3, 4]);
      bytes.length = 2;
      expect(bytes.toList(), [9, 2]);
    });

    test('write rejects out-of-range values', () {
      final bytes = BuBytes([1, 2, 3]);
      expect(() => bytes[0] = -1, throwsBuError);
      expect(() => bytes[0] = 256, throwsBuError);
      expect(() => bytes.add(999), throwsBuError);
    });

    test('clone() default matches source mutability', () {
      final mutable = BuBytes([1, 2, 3]);
      final mutableClone = mutable.cloneBytes();
      expect(mutableClone.isImmutable, isFalse);
      mutableClone[0] = 42;
      expect(mutable[0], 1); // independent copy

      final immutable = BuBytes.immutable([1, 2, 3]);
      final immutableClone = immutable.cloneBytes();
      expect(immutableClone.isImmutable, false);
    });

    test('clone() honors explicit immutable override', () {
      final mutable = BuBytes([1, 2, 3]);
      final asImmutable = mutable.cloneBytes(immutable: true);
      expect(asImmutable.isImmutable, isTrue);
      expect(() => asImmutable[0] = 9, throwsA(isA<BuError>()));

      final immutable = BuBytes.immutable([1, 2, 3]);
      final asMutable = immutable.cloneBytes(immutable: false);
      expect(asMutable.isImmutable, isFalse);
      asMutable[0] = 9;
      expect(asMutable[0], 9);
      expect(immutable[0], 1); // original untouched
    });

    // test('toString does not throw and reflects mutability', () {
    //   expect(BuBytes([1]).toString(), contains('mutable'));
    //   expect(BuBytes.immutable([1]).toString(), contains('immutable'));
    // });

    test('behaves as a List<int>', () {
      final bytes = BuBytes([1, 2, 3]);
      expect(bytes, isA<List<int>>());
      expect(bytes.map((b) => b * 2).toList(), [2, 4, 6]);
      expect(bytes.where((b) => b > 1).toList(), [2, 3]);
    });
  });

  group('SecretBytes', () {
    test(
      'always copies — mutating the source afterwards does not affect it',
      () {
        final source = [1, 2, 3];
        final secret = SecretBytes(source);
        source[0] = 99;
        secret.useValue((plain) => expect(plain, [1, 2, 3]));
        secret.zero();
      },
    );

    test('reads return the exact original values', () {
      final secret = SecretBytes([10, 20, 30]);
      expect(secret[0], 10);
      expect(secret[1], 20);
      expect(secret[2], 30);
      secret.zero();
    });

    test(
      'rejects out-of-range values during construction (whole list scanned)',
      () {
        expect(() => SecretBytes([1, 2, -5, 300]), throwsBuError);
      },
    );

    test('write rejects out-of-range values', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(() => secret[0] = -1, throwsBuError);
      expect(() => secret[0] = 256, throwsBuError);
      secret.zero();
    });

    test('is never immutable and has fixed length', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(() => secret.length = 5, throwsA(isA<BuError>()));
      expect(() => secret.add(1), throwsA(isA<BuError>()));
      secret.zero();
    });

    test('wipeSource zeros a mutable source list after construction', () {
      final source = [1, 2, 3];
      SecretBytes(source, wipeSource: true);
      expect(source, [0, 0, 0]);
    });

    test('wipeSource silently no-ops on an unmodifiable source', () {
      final source = List<int>.unmodifiable([1, 2, 3]);
      expect(() => SecretBytes(source, wipeSource: true), returnsNormally);
    });

    test('useValue exposes exact plaintext then wipes the temp buffer', () {
      final secret = SecretBytes([5, 6, 7]);
      late List<int> leaked;
      final result = secret.useValue((plain) {
        expect(plain, [5, 6, 7]);
        leaked = plain; // keep the reference to inspect after the callback
        return plain.length;
      });
      expect(result, 3);
      expect(leaked, [0, 0, 0]); // wiped once useValue returned
      secret.zero();
    });

    test('useValue still wipes the temp buffer if the callback throws', () {
      final secret = SecretBytes([5, 6, 7]);
      late List<int> leaked;
      expect(
        () => secret.useValue((plain) {
          leaked = plain;
          throw StateError('boom');
        }),
        throwsStateError,
      );
      expect(leaked, [0, 0, 0]);
      secret.zero();
    });

    test('zero() clears the secret and is idempotent', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(secret.isZeroed, isFalse);
      secret.zero();
      expect(secret.isZeroed, isTrue);
      expect(secret.zero, returnsNormally); // calling twice is fine
    });

    test('read, write, useValue, and == all throw after zero()', () {
      final secret = SecretBytes([1, 2, 3]);
      secret.zero();
      expect(() => secret[0], throwsA(isA<BuError>()));
      expect(() => secret[0] = 1, throwsA(isA<BuError>()));
      expect(() => secret.useValue((p) => p), throwsA(isA<BuError>()));
      expect(() => secret == SecretBytes([1, 2, 3]), throwsA(isA<BuError>()));
    });

    test('hashCode always throws', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(() => secret.hashCode, throwsA(isA<BuError>()));
      secret.zero();
    });

    test('toString never reveals the plaintext bytes', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(secret.toString(), isNot(contains('1')));
      expect(secret.toString(), contains('hidden'));
      secret.zero();
      expect(secret.toString(), contains('zeroed'));
    });

    group('constant-time equality', () {
      test('static constantTimeEquals compares plain lists correctly', () {
        expect(SecretBytes.constantTimeEquals([1, 2, 3], [1, 2, 3]), isTrue);
        expect(SecretBytes.constantTimeEquals([1, 2, 3], [1, 2, 4]), isFalse);
        expect(SecretBytes.constantTimeEquals([1, 2], [1, 2, 3]), isFalse);
        expect(SecretBytes.constantTimeEquals([], []), isTrue);
      });

      test('== returns true for equal-content SecretBytes', () {
        final a = SecretBytes([1, 2, 3]);
        final b = SecretBytes([1, 2, 3]);
        expect(a == b, isTrue);
        a.zero();
        b.zero();
      });

      test('== returns false for different content or length', () {
        final a = SecretBytes([1, 2, 3]);
        final different = SecretBytes([1, 2, 4]);
        final shorter = SecretBytes([1, 2]);
        expect(a == different, isFalse);
        expect(a == shorter, isFalse);
        expect(a == [1, 2, 3], isTrue); // works against a plain List<int>
        a.zero();
        different.zero();
        shorter.zero();
      });
    });

    test(
      'SecretBytes.random produces the requested length and valid bytes',
      () {
        final secret = SecretBytes.random(32);
        expect(secret.length, 32);
        secret.useValue((plain) {
          expect(plain.every((b) => b >= 0 && b <= 255), isTrue);
        });
        secret.zero();
      },
    );

    test('clone() creates an independent copy with a fresh mask', () {
      final original = SecretBytes([1, 2, 3]);
      final copy = original.cloneBytes();
      copy.useValue((plain) => expect(plain, [1, 2, 3]));

      copy.zero();
      expect(copy.isZeroed, isTrue);
      expect(original.isZeroed, isFalse); // zeroing the clone is independent
      original.useValue((plain) => expect(plain, [1, 2, 3]));
      original.zero();
    });

    test('behaves as a List<int> for iteration/read-only operations', () {
      final secret = SecretBytes([1, 2, 3]);
      expect(secret, isA<List<int>>());
      expect(secret.map((b) => b * 2).toList(), [2, 4, 6]);
      secret.zero();
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(bytesTest, "BuBytes");
}
