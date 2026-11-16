// This file assumes it lives inside your blockchain_utils project (or
// anywhere with that package as a dependency), since UUIDError extends
// BlockchainUtilsException. Adjust the import below to wherever you place
// these files.
import 'package:blockchain_utils/utils/uuid/uuid.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

List<int> hexToBytes(String hex) {
  final out = <int>[];
  for (var i = 0; i < hex.length; i += 2) {
    out.add(int.parse(hex.substring(i, i + 2), radix: 16));
  }
  return out;
}

void uuidUuidTest() {
  group(
    'v3 / v5 - name-based, verified against Python\'s reference uuid module',
    () {
      // uuid.uuid3(uuid.NAMESPACE_DNS, 'python.org') and
      // uuid.uuid5(uuid.NAMESPACE_DNS, 'python.org'), from the official
      // Python docs (RFC 4122/9562 reference implementation).
      test('v3(namespaceDns, "python.org") matches the reference vector', () {
        expect(
          UUID.v3(UUID.namespaceDns, 'python.org'),
          equals('6fa459ea-ee8a-3ca4-894e-db77e160355e'),
        );
      });

      test('v5(namespaceDns, "python.org") matches the reference vector', () {
        expect(
          UUID.v5(UUID.namespaceDns, 'python.org'),
          equals('886313e1-3b8a-5372-9b90-0c9aee199e5d'),
        );
      });

      test('deterministic: same namespace+name always gives the same UUID', () {
        expect(
          UUID.v5(UUID.namespaceUrl, 'example.com'),
          equals(UUID.v5(UUID.namespaceUrl, 'example.com')),
        );
        expect(
          UUID.v3(UUID.namespaceUrl, 'example.com'),
          equals(UUID.v3(UUID.namespaceUrl, 'example.com')),
        );
      });

      test('different names give different UUIDs', () {
        expect(
          UUID.v5(UUID.namespaceDns, 'a.com'),
          isNot(equals(UUID.v5(UUID.namespaceDns, 'b.com'))),
        );
      });

      test('different namespaces give different UUIDs for the same name', () {
        expect(
          UUID.v5(UUID.namespaceDns, 'example'),
          isNot(equals(UUID.v5(UUID.namespaceUrl, 'example'))),
        );
      });

      test('v3/v5 output is validly formatted with the correct version', () {
        final v3 = UUID.v3(UUID.namespaceDns, 'test');
        final v5 = UUID.v5(UUID.namespaceDns, 'test');
        expect(UUID.isValid(v3), isTrue);
        expect(UUID.isValid(v5), isTrue);
        expect(v3[14], equals('3')); // version nibble
        expect(v5[14], equals('5'));
        expect(['8', '9', 'a', 'b'], contains(v3[19].toLowerCase())); // variant
        expect(['8', '9', 'a', 'b'], contains(v5[19].toLowerCase()));
      });
    },
  );

  group('v4 - test vector', () {
    final List<int> buffer1 = List<int>.from([
      174,
      91,
      168,
      91,
      107,
      15,
      78,
      26,
      181,
      132,
      151,
      91,
      160,
      7,
      157,
      152,
    ]);

    final List<int> buffer2 = List<int>.from([
      42,
      118,
      243,
      204,
      168,
      139,
      49,
      8,
      163,
      241,
      253,
      29,
      91,
      63,
      219,
      178,
    ]);
    final List<int> buffer3 = List<int>.from([
      115,
      181,
      16,
      102,
      139,
      73,
      65,
      95,
      181,
      34,
      94,
      80,
      60,
      118,
      197,
      55,
    ]);
    final List<int> buffer4 = List<int>.from([
      215,
      154,
      165,
      99,
      152,
      96,
      226,
      52,
      181,
      118,
      60,
      118,
      136,
      156,
      165,
      177,
    ]);
    final List<int> buffer5 = List<int>.from([
      97,
      148,
      163,
      150,
      135,
      56,
      166,
      2,
      171,
      26,
      194,
      71,
      2,
      140,
      199,
      132,
    ]);

    // Test cases for UUID operations
    test("testUUid", () {
      // Verify that UUIDs can be created from the buffers and match the expected values
      expect(UUID.fromBuffer(buffer1), "ae5ba85b-6b0f-4e1a-b584-975ba0079d98");
      expect(UUID.fromBuffer(buffer2), "2a76f3cc-a88b-3108-a3f1-fd1d5b3fdbb2");
      expect(UUID.fromBuffer(buffer3), "73b51066-8b49-415f-b522-5e503c76c537");
      expect(UUID.fromBuffer(buffer4), "d79aa563-9860-e234-b576-3c76889ca5b1");
      expect(UUID.fromBuffer(buffer5), "6194a396-8738-a602-ab1a-c247028cc784");

      // Generate a random UUIDv4, validate it, and convert it to a buffer and back to UUID
      final uuid = UUID.v4();
      expect(UUID.isValid(uuid), true);
      expect(UUID.fromBuffer(UUID.toBuffer(uuid)), uuid);
    });
  });

  group('v4 - random', () {
    test('output is validly formatted with version 4 and correct variant', () {
      final id = UUID.v4();
      expect(UUID.isValid(id), isTrue);
      expect(id[14], equals('4'));
      expect(['8', '9', 'a', 'b'], contains(id[19].toLowerCase()));
    });

    test('generates distinct values', () {
      final ids = List.generate(20, (_) => UUID.v4());
      expect(ids.toSet().length, equals(20));
    });

    test(
      'deprecated generateUUIDv4() and random() both produce valid v4 UUIDs',
      () {
        // ignore: deprecated_member_use_from_same_package
        final a = UUID.v4();
        // ignore: deprecated_member_use_from_same_package
        final b = UUID.v4();
        expect(UUID.isValid(a), isTrue);
        expect(a[14], equals('4'));
        expect(UUID.isValid(b), isTrue);
        expect(
          b[14],
          equals('4'),
        ); // regression check: random() used to skip this
      },
    );
  });

  group('v1 - time-based', () {
    test('output is validly formatted with version 1 and correct variant', () {
      final id = UUID.v1();
      expect(UUID.isValid(id), isTrue);
      expect(id[14], equals('1'));
      expect(['8', '9', 'a', 'b'], contains(id[19].toLowerCase()));
    });

    test('embedded timestamp is close to the current time', () {
      final before = DateTime.now().toUtc();
      final id = UUID.v1();
      final after = DateTime.now().toUtc();

      final bytes = UUID.toBuffer(id);
      // Arithmetic (multiply/add), not shifts, to combine these bytes -
      // same reasoning as uuid.dart itself: avoids any doubt about
      // dart2js bitwise-op exactness near/above the 32-bit boundary.
      final timeLow =
          bytes[0] * 0x1000000 +
          bytes[1] * 0x10000 +
          bytes[2] * 0x100 +
          bytes[3];
      final timeMid = bytes[4] * 0x100 + bytes[5];
      final timeHi =
          (bytes[6] & 0x0F) * 0x100 + bytes[7]; // version nibble stripped

      final timestamp100ns =
          (BigInt.from(timeHi) << 48) |
          (BigInt.from(timeMid) << 32) |
          BigInt.from(timeLow);
      final v1EpochOffset100ns = BigInt.parse('122192928000000000');
      final microsSinceUnixEpoch =
          (timestamp100ns - v1EpochOffset100ns) ~/ BigInt.from(10);
      final decodedTime = DateTime.fromMicrosecondsSinceEpoch(
        microsSinceUnixEpoch.toInt(),
        isUtc: true,
      );

      expect(
        decodedTime.isAfter(before.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        decodedTime.isBefore(after.add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test('generates distinct values', () {
      final ids = List.generate(10, (_) => UUID.v1());
      expect(ids.toSet().length, equals(10));
    });
  });

  group('v7 - Unix Epoch time-based', () {
    test('output is validly formatted with version 7 and correct variant', () {
      final id = UUID.v7();
      expect(UUID.isValid(id), isTrue);
      expect(id[14], equals('7'));
      expect(['8', '9', 'a', 'b'], contains(id[19].toLowerCase()));
    });

    test('embedded timestamp is close to the current time', () {
      final before = DateTime.now().toUtc();
      final id = UUID.v7();
      final after = DateTime.now().toUtc();

      final bytes = UUID.toBuffer(id);
      final ms =
          bytes[0] * 0x10000000000 +
          bytes[1] * 0x100000000 +
          bytes[2] * 0x1000000 +
          bytes[3] * 0x10000 +
          bytes[4] * 0x100 +
          bytes[5];
      final decodedTime = DateTime.fromMillisecondsSinceEpoch(ms, isUtc: true);

      expect(
        decodedTime.isAfter(before.subtract(const Duration(seconds: 2))),
        isTrue,
      );
      expect(
        decodedTime.isBefore(after.add(const Duration(seconds: 2))),
        isTrue,
      );
    });

    test(
      'UUIDs generated in increasing time order sort in increasing lexicographic order',
      () async {
        // v7's ordering guarantee is over the *timestamp*, not the random
        // bits - two UUIDs generated within the same millisecond have no
        // ordering guarantee at all (their random bits are, well, random).
        // So this needs genuinely distinct timestamps to test anything
        // meaningful, not just back-to-back calls.
        final ids = <String>[];
        for (var i = 0; i < 5; i++) {
          ids.add(UUID.v7());
          await Future.delayed(const Duration(milliseconds: 2));
        }
        final sorted = [...ids]..sort();
        expect(ids, equals(sorted));
      },
    );

    test('generates distinct values', () {
      final ids = List.generate(20, (_) => UUID.v7());
      expect(ids.toSet().length, equals(20));
    });
  });

  group('toBuffer / fromBuffer round trip', () {
    test('round trips for every generated version', () {
      final ids = [
        UUID.v1(),
        UUID.v3(UUID.namespaceDns, 'x'),
        UUID.v4(),
        UUID.v5(UUID.namespaceDns, 'x'),
        UUID.v7(),
      ];
      for (final id in ids) {
        final buffer = UUID.toBuffer(id);
        expect(buffer.length, equals(16));
        expect(UUID.fromBuffer(buffer), equals(id));
      }
    });

    test('namespace UUID constants themselves round trip', () {
      for (final ns in [
        UUID.namespaceDns,
        UUID.namespaceUrl,
        UUID.namespaceOid,
        UUID.namespaceX500,
      ]) {
        expect(UUID.fromBuffer(UUID.toBuffer(ns)), equals(ns));
      }
    });

    test('a known 16-byte buffer produces the expected UUID string', () {
      final bytes = hexToBytes('886313e13b8a53729b900c9aee199e5d');
      expect(bytes.length, equals(16));
      expect(
        UUID.fromBuffer(bytes),
        equals('886313e1-3b8a-5372-9b90-0c9aee199e5d'),
      );
    });
  });

  group('validation', () {
    test('isValid accepts all five supported versions', () {
      expect(UUID.isValid(UUID.v1()), isTrue);
      expect(UUID.isValid(UUID.v3(UUID.namespaceDns, 'x')), isTrue);
      expect(UUID.isValid(UUID.v4()), isTrue);
      expect(UUID.isValid(UUID.v5(UUID.namespaceDns, 'x')), isTrue);
      expect(UUID.isValid(UUID.v7()), isTrue);
    });

    test('isValid rejects a garbage string', () {
      expect(UUID.isValid('not-a-uuid'), isFalse);
      expect(UUID.isValid(''), isFalse);
    });

    test('isValid rejects an unsupported version nibble (e.g. 2)', () {
      expect(UUID.isValid('6ba7b810-9dad-21d1-80b4-00c04fd430c8'), isFalse);
    });

    test('isValid rejects a bad variant nibble', () {
      expect(UUID.isValid('6ba7b810-9dad-41d1-00b4-00c04fd430c8'), isFalse);
    });

    // ignore: deprecated_member_use_from_same_package
  });

  group('error handling', () {
    test('toBuffer throws UUIDError on an invalid string', () {
      expect(() => UUID.toBuffer('not-a-uuid'), throwsA(isA<BuError>()));
    });

    test('toBuffer with validate:false skips format checking', () {
      // Still must be parseable as hex once dashes are stripped, but
      // doesn't need to match the version/variant pattern.
      final bytes = UUID.toBuffer(
        '00000000-0000-0000-0000-000000000000',
        validate: false,
      );
      expect(bytes, equals(List<int>.filled(16, 0)));
    });

    test('fromBuffer throws UUIDError on the wrong buffer length', () {
      expect(() => UUID.fromBuffer([1, 2, 3]), throwsA(isA<BuError>()));
      expect(
        () => UUID.fromBuffer(List<int>.filled(17, 0)),
        throwsA(isA<BuError>()),
      );
    });
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(uuidUuidTest, "Uuid");
}
