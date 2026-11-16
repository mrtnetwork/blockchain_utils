import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/crypto.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/numbers/utils/bigint_utils.dart';
import 'package:blockchain_utils_connector/src/bytes/bytes.dart';
import 'package:test/test.dart';

abstract class CurveTest<API extends CurveApi> {
  final List<API> apis;
  final RandomScalarGeneratorGenerator randomGenerator;

  // /// Valid canonical scalar encodings.
  late final List<BuBytes> scalars = randomGenerator.scalars();

  // /// Valid canonical point encodings.
  late final List<BuBytes> points = buildPoints();

  /// Scalars that must be rejected by [scCheck].
  ///
  /// Examples:
  /// - scalar == order
  /// - scalar > order
  /// - malformed length
  late final List<BuBytes> badScalars = randomGenerator.badScalars();

  /// Point encodings that must be rejected by point operations.
  ///
  /// Examples:
  /// - malformed length
  /// - invalid point encoding
  /// - non-canonical encoding
  late final List<BuBytes> badPoints = randomGenerator.badPoints();

  /// The canonical zero scalar.
  BuBytes? get zeroScalar => randomGenerator.zero();

  // /// The canonical one scalar.
  BuBytes get oneScalar => randomGenerator.one();

  // /// The canonical identity point.
  BuBytes? get zeroPoint => randomGenerator.zeroPoint();

  /// The canonical generator point.
  BuBytes get generator => randomGenerator.generator();

  // /// Optional scalar inputs larger than [scalarLen].
  // ///
  // /// These are particularly useful for testing [CurveApi.scReduce].
  late final List<BuBytes> oversizedScalars =
      randomGenerator.oversizedScalars();

  final String name;

  /// Test points for scalar/point law checks. Defaults to the raw
  /// `multBase` outputs. Curves whose generator is not torsion-free
  /// override this to supply prime-subgroup points, since scalar laws
  /// (e.g. `(-s)P == -(sP)`) only hold there.
  List<BuBytes> buildPoints() => randomGenerator.validPoints();

  CurveTest({
    required this.apis,
    required this.randomGenerator,
    required this.name,
  });

  void testCases() {}

  void run() {
    group("CurveApi $name/${randomGenerator.entropy.toHex()}", () {
      _testConfiguration();

      _testIdentity();
      _testGenerator();

      _testScCheck();
      _testScReduce();

      _testAdd();
      _testSub();
      _testNeg();

      _testScAdd();
      _testScSub();
      _testScMul();
      _testScNeg();

      _testMult();
      _testMultBase();
      _testMulAdd();

      _testGroupIdentity();
      _testGroupInverse();
      _testGroupCommutativity();
      _testGroupAssociativity();

      _testScalarIdentity();
      _testScalarInverse();
      _testScalarCommutativity();
      _testScalarDistributivity();

      _testMultZero();
      _testMultOne();
      _testMultGenerator();
      _testMultNeg();

      _testMulAddConsistency();
      _testNegConsistency();
      _testSubConsistency();

      _testInvalidScalars();
      _testInvalidPoints();

      _testOutputLengths();
      testCases();
    });
  }

  // ===========================================================================
  // Configuration
  // ===========================================================================

  void _testConfiguration() {
    test("configuration", () {
      expect(apis, isNotEmpty);

      final pointLens = apis.map((e) => e.pointLen).toSet();
      final scalarLens = apis.map((e) => e.scalarLen).toSet();

      expect(
        pointLens.length,
        1,
        reason: "CurveApi implementations have different pointLen.",
      );

      expect(
        scalarLens.length,
        1,
        reason: "CurveApi implementations have different scalarLen.",
      );

      expect(apis.first.pointLen, greaterThan(0));
      expect(apis.first.scalarLen, greaterThan(0));
      if (zeroScalar != null) {
        expect(
          zeroScalar!.length,
          apis.first.scalarLen,
          reason: "Invalid zeroScalar length.",
        );
      }

      expect(
        oneScalar.length,
        apis.first.scalarLen,
        reason: "Invalid oneScalar length.",
      );
      if (zeroPoint != null) {
        expect(
          zeroPoint!.length,
          apis.first.pointLen,
          reason: "Invalid zeroPoint length.",
        );
      }
      expect(
        generator.length,
        apis.first.pointLen,
        reason: "Invalid generator length.",
      );
    });
  }

  // ===========================================================================
  // Basic point values
  // ===========================================================================

  void _testIdentity() {
    test("identity", () {
      final zeroPoint = this.zeroPoint;
      if (zeroPoint == null) {
        // Curves without an encodable identity (e.g. SEC1-compressed
        // secp256k1/r1, BLS): every implementation must reject identity().
        for (final api in apis) {
          expect(
            () => api.identity(),
            throwsA(anything),
            reason: "identity() should throw when no identity encoding exists.",
          );
        }
        return;
      }
      final results = apis.map((e) => e.identity()).toList();

      expectSame(results, "identity");

      for (final api in apis) {
        expect(
          api.identity(),
          zeroPoint,
          reason: "identity() does not match zeroPoint.",
        );
      }
    });
  }

  void _testGenerator() {
    test("generator", () {
      final results = apis.map((e) => e.generator()).toList();

      expectSame(results, "generator");

      for (final api in apis) {
        expect(
          api.generator(),
          generator,
          reason: "generator() does not match generator vector.",
        );
      }
    });
  }

  // ===========================================================================
  // Scalar validation / reduction
  // ===========================================================================

  void _testScCheck() {
    test("scCheck", () {
      for (final scalar in scalars) {
        for (final api in apis) {
          expect(
            api.scCheck(scalar),
            isTrue,
            reason: "Valid scalar was rejected.",
          );
        }
      }

      for (final scalar in badScalars) {
        for (final api in apis) {
          expect(
            api.scCheck(scalar),
            isFalse,
            reason: "Invalid scalar was accepted. $api",
          );
        }
      }
    });
  }

  void _testScReduce() {
    test("scReduce", () {
      for (final scalar in scalars) {
        for (final api in apis) {
          final result = api.scReduce(scalar);

          expect(
            result.length,
            api.scalarLen,
            reason: "scReduce returned invalid length.",
          );

          expect(
            api.scCheck(result),
            isTrue,
            reason: "scReduce returned an invalid scalar.",
          );
        }
      }

      for (final scalar in oversizedScalars) {
        for (final api in apis) {
          final result = api.scReduce(scalar);

          expect(
            result.length,
            api.scalarLen,
            reason: "scReduce returned invalid length.",
          );

          expect(
            api.scCheck(result),
            isTrue,
            reason: "scReduce returned an invalid scalar.",
          );
        }
      }

      // Reduction must be idempotent:
      //
      // reduce(reduce(x)) == reduce(x)
      for (final scalar in oversizedScalars) {
        for (final api in apis) {
          final first = api.scReduce(scalar);
          final second = api.scReduce(first);

          expect(second, first, reason: "scReduce is not idempotent.");
        }
      }
    });
  }

  // ===========================================================================
  // Point operations
  // ===========================================================================

  void _testAdd() {
    test("add", () {
      for (final a in points) {
        for (final b in points) {
          expectSame(apis.map((e) => e.add(a, b)).toList(), "add");
        }
      }
    });
  }

  void _testSub() {
    test("sub", () {
      for (final a in points) {
        for (final b in points) {
          if (zeroPoint == null && a.toHex() == b.toHex()) {
            // a - a is unrepresentable without an identity encoding.
            continue;
          }
          expectSame(apis.map((e) => e.sub(a, b)).toList(), "sub");
        }
      }
    });
  }

  void _testNeg() {
    test("neg", () {
      for (final point in points) {
        expectSame(apis.map((e) => e.neg(point)).toList(), "neg");
      }
    });
  }

  // ===========================================================================
  // Scalar operations
  // ===========================================================================

  void _testScAdd() {
    test("scAdd", () {
      for (final a in scalars) {
        for (final b in scalars) {
          expectSame(apis.map((e) => e.scAdd(a, b)).toList(), "scAdd");
        }
      }
    });
  }

  void _testScSub() {
    test("scSub", () {
      for (final a in scalars) {
        for (final b in scalars) {
          expectSame(apis.map((e) => e.scSub(a, b)).toList(), "scSub");
        }
      }
    });
  }

  void _testScMul() {
    test("scMul", () {
      for (final a in scalars) {
        for (final b in scalars) {
          expectSame(apis.map((e) => e.scMul(a, b)).toList(), "scMul");
        }
      }
    });
  }

  void _testScNeg() {
    test("scNeg", () {
      for (final scalar in scalars) {
        expectSame(apis.map((e) => e.scNeg(scalar)).toList(), "scNeg");
      }
    });
  }

  // ===========================================================================
  // Multiplication
  // ===========================================================================

  void _testMult() {
    test("mult", () {
      for (final scalar in scalars) {
        for (final point in points) {
          expectSame(apis.map((e) => e.mult(scalar, point)).toList(), "mult");
        }
      }
    });
  }

  void _testMultBase() {
    test("multBase", () {
      for (final scalar in scalars) {
        expectSame(apis.map((e) => e.multBase(scalar)).toList(), "multBase");
      }
    });
  }

  void _testMulAdd() {
    test("mulAdd", () {
      for (final s1 in scalars) {
        for (final p1 in points) {
          for (final s2 in scalars) {
            for (final p2 in points) {
              expectSame(
                apis.map((e) => e.mulAdd(s1, p1, s2, p2)).toList(),
                "mulAdd",
              );
            }
          }
        }
      }
    });
  }

  // ===========================================================================
  // Group laws
  // ===========================================================================

  void _testGroupIdentity() {
    test("group identity", () {
      final zeroPoint = this.zeroPoint;
      if (zeroPoint != null) {
        for (final api in apis) {
          for (final point in points) {
            expect(api.add(point, zeroPoint), point, reason: "P + 0 != P.");

            expect(api.add(zeroPoint, point), point, reason: "0 + P != P.");

            expect(api.sub(point, zeroPoint), point, reason: "P - 0 != P.");
          }
        }
      }
    });
  }

  void _testGroupInverse() {
    test("group inverse", () {
      // Without an encodable identity, P + (-P) is unrepresentable.
      if (zeroPoint == null) return;
      for (final api in apis) {
        for (final point in points) {
          final neg = api.neg(point);

          expect(api.add(point, neg), zeroPoint, reason: "P + (-P) != 0.");

          expect(api.add(neg, point), zeroPoint, reason: "(-P) + P != 0.");

          expect(api.sub(point, point), zeroPoint, reason: "P - P != 0.");

          expect(api.neg(neg), point, reason: "-(-P) != P.");
        }
      }
    });
  }

  void _testGroupCommutativity() {
    test("group commutativity", () {
      for (final api in apis) {
        for (final a in points) {
          for (final b in points) {
            expect(api.add(a, b), api.add(b, a), reason: "P + Q != Q + P.");
          }
        }
      }
    });
  }

  void _testGroupAssociativity() {
    test("group associativity", () {
      for (final api in apis) {
        for (final a in points) {
          for (final b in points) {
            for (final c in points) {
              final left = api.add(api.add(a, b), c);

              final right = api.add(a, api.add(b, c));

              expect(left, right, reason: "(P + Q) + R != P + (Q + R).");
            }
          }
        }
      }
    });
  }

  // ===========================================================================
  // Scalar algebra
  // ===========================================================================

  void _testScalarIdentity() {
    test("scalar identity", () {
      for (final api in apis) {
        for (final scalar in scalars) {
          final zeroScalar = this.zeroScalar;
          if (zeroScalar != null) {
            expect(
              api.scAdd(scalar, zeroScalar),
              api.scReduce(scalar),
              reason: "a + 0 != a.",
            );

            expect(
              api.scAdd(zeroScalar, scalar),
              api.scReduce(scalar),
              reason: "0 + a != a.",
            );

            expect(
              api.scSub(scalar, zeroScalar),
              api.scReduce(scalar),
              reason: "a - 0 != a.",
            );
            expect(
              api.scMul(scalar, zeroScalar),
              zeroScalar,
              reason: "a * 0 != 0.",
            );

            expect(
              api.scMul(zeroScalar, scalar),
              zeroScalar,
              reason: "0 * a != 0.",
            );
          }

          expect(
            api.scMul(scalar, oneScalar),
            api.scReduce(scalar),
            reason: "a * 1 != a. $api ${oneScalar.toHex()}",
          );

          expect(
            api.scMul(oneScalar, scalar),
            api.scReduce(scalar),
            reason: "1 * a != a.",
          );
        }
      }
    });
  }

  void _testScalarInverse() {
    test("scalar negation", () {
      // Curves without a zero-scalar concept compare against 32 zero bytes.
      final zero =
          zeroScalar ?? BuBytes(List<int>.filled(apis.first.scalarLen, 0));
      for (final api in apis) {
        for (final scalar in scalars) {
          expect(
            api.scAdd(scalar, api.scNeg(scalar)),
            zero,
            reason: "a + (-a) != 0.",
          );

          expect(api.scSub(scalar, scalar), zero, reason: "a - a != 0.");

          expect(
            api.scNeg(api.scNeg(scalar)),
            api.scReduce(scalar),
            reason: "-(-a) != a.",
          );
        }
      }
    });
  }

  void _testScalarCommutativity() {
    test("scalar commutativity", () {
      for (final api in apis) {
        for (final a in scalars) {
          for (final b in scalars) {
            expect(api.scAdd(a, b), api.scAdd(b, a), reason: "a + b != b + a.");

            expect(api.scMul(a, b), api.scMul(b, a), reason: "a * b != b * a.");
          }
        }
      }
    });
  }

  void _testScalarDistributivity() {
    test("scalar distributivity", () {
      for (final api in apis) {
        for (final a in scalars) {
          for (final b in scalars) {
            for (final c in scalars) {
              final left = api.scMul(a, api.scAdd(b, c));

              final right = api.scAdd(api.scMul(a, b), api.scMul(a, c));

              expect(left, right, reason: "a * (b + c) != a*b + a*c.");
            }
          }
        }
      }
    });
  }

  // ===========================================================================
  // Scalar / point relationships
  // ===========================================================================

  void _testMultZero() {
    test("mult zero", () {
      final zeroScalar = this.zeroScalar;
      if (zeroScalar != null) {
        for (final api in apis) {
          for (final point in points) {
            expect(
              api.mult(zeroScalar, point),
              zeroPoint,
              reason: "0P != 0. $api/${zeroPoint?.toHex()}",
            );
          }
        }
      }
    });
  }

  void _testMultOne() {
    test("mult one", () {
      for (final api in apis) {
        for (final point in points) {
          expect(api.mult(oneScalar, point), point, reason: "1P != P.");
        }
      }
    });
  }

  void _testMultGenerator() {
    test("mult generator", () {
      for (final api in apis) {
        for (final scalar in scalars) {
          expect(
            api.mult(scalar, generator),
            api.multBase(scalar),
            reason: "mult(s, G) != multBase(s).",
          );
        }
      }
    });
  }

  void _testMultNeg() {
    test("mult negative scalar", () {
      for (final api in apis) {
        for (final scalar in scalars) {
          for (final point in points) {
            final negativeScalar = api.scNeg(scalar);

            final left = api.mult(negativeScalar, point);

            final right = api.neg(api.mult(scalar, point));

            expect(left, right, reason: "(-s)P != -(sP).");
          }
        }
      }
    });
  }

  void _testMulAddConsistency() {
    test("mulAdd consistency", () {
      for (final api in apis) {
        for (final s1 in scalars) {
          for (final p1 in points) {
            for (final s2 in scalars) {
              for (final p2 in points) {
                final expected = api.add(api.mult(s1, p1), api.mult(s2, p2));

                final actual = api.mulAdd(s1, p1, s2, p2);

                expect(actual, expected, reason: "mulAdd != s1*p1 + s2*p2.");
              }
            }
          }
        }
      }
    });
  }

  void _testNegConsistency() {
    test("neg consistency", () {
      final zeroPoint = this.zeroPoint;
      if (zeroPoint != null) {
        for (final api in apis) {
          for (final point in points) {
            expect(
              api.sub(zeroPoint, point),
              api.neg(point),
              reason: "0 - P != -P.",
            );
          }
        }
      }
    });
  }

  void _testSubConsistency() {
    test("sub consistency", () {
      for (final api in apis) {
        for (final a in points) {
          for (final b in points) {
            if (zeroPoint == null && a.toHex() == b.toHex()) {
              // a - a is unrepresentable without an identity encoding.
              continue;
            }
            expect(
              api.sub(a, b),
              api.add(a, api.neg(b)),
              reason: "a - b != a + (-b). $api",
            );
          }
        }
      }
    });
  }

  // ===========================================================================
  // Invalid values
  // ===========================================================================

  void _testInvalidScalars() {
    test("invalid scalars", () {
      for (final api in apis) {
        for (final scalar in badScalars) {
          expect(
            () => api.mult(scalar, generator),
            throwsA(anything),
            reason: "mult accepted an invalid scalar. $api/${scalar.toHex()}",
          );

          expect(
            () => api.multBase(scalar),
            throwsA(anything),
            reason: "multBase accepted an invalid scalar $api",
          );
        }
      }
    });
  }

  void _testInvalidPoints() {
    test("invalid points", () {
      final zeroPoint = this.zeroPoint;
      for (final api in apis) {
        for (final point in badPoints) {
          expect(
            () => api.mult(oneScalar, point),
            throwsA(anything),
            reason: "mult accepted an invalid point ${api.runtimeType}.",
          );

          if (zeroPoint != null) {
            expect(
              () => api.add(point, zeroPoint),
              throwsA(anything),
              reason: "add accepted an invalid point ${api.runtimeType}.",
            );

            expect(
              () => api.sub(point, zeroPoint),
              throwsA(anything),
              reason: "sub accepted an invalid point ${api.runtimeType}.",
            );
          }

          expect(
            () => api.neg(point),
            throwsA(anything),
            reason: "neg accepted an invalid point ${api.runtimeType}.",
          );
        }
      }
    });
  }

  // ===========================================================================
  // Output validation
  // ===========================================================================

  void _testOutputLengths() {
    test("output lengths", () {
      for (final api in apis) {
        for (final scalar in scalars) {
          expect(api.scReduce(scalar).length, api.scalarLen);

          expect(api.scNeg(scalar).length, api.scalarLen);
        }

        for (final point in points) {
          expect(api.neg(point).length, api.pointLen);
        }

        for (final scalar in scalars) {
          expect(api.multBase(scalar).length, api.pointLen);

          for (final point in points) {
            expect(api.mult(scalar, point).length, api.pointLen);
          }
        }
      }
    });
  }

  // ===========================================================================
  // Helpers
  // ===========================================================================

  void expectSame(List<BuBytes> results, String operation) {
    expect(results, isNotEmpty, reason: "$operation has no implementations.");

    final expected = results.first;

    for (var i = 1; i < results.length; i++) {
      expect(
        results[i],
        expected,
        reason:
            "$operation differs between CurveApi implementations: "
            "implementation 0 != implementation $i.",
      );
    }
  }
}

typedef ISVALIDPOINT = bool Function(BuBytes);

class RandomScalarGeneratorGenerator {
  final BigInt n;
  final int scalarLength;
  final int pointLengthBytes;
  final int total;
  final Endian endian;
  final ISVALIDPOINT validatePoint;
  final CurveApi api;
  late final BuBytes entropy;
  late final Rng rng;

  RandomScalarGeneratorGenerator({
    required this.n,
    required this.scalarLength,
    required this.total,
    required this.endian,
    required this.validatePoint,
    required this.api,
    required this.pointLengthBytes,
    BuBytes? entropy,
  }) {
    this.entropy = entropy ??= QuickCrypto.generateRandom();
    rng = ChaCha20Rng(entropy);
  }

  BuBytes nextRandom(int length) => rng.nextBytes(length);

  BigInt nextBigIntRandom(int lengthInBytes) =>
      BigintUtils.fromBytes(nextRandom(lengthInBytes), byteOrder: endian);

  BuBytes bigIntToBytes(BigInt value, int length) =>
      value.toBytes(length: length, byteOrder: endian);

  BuBytes nextScalar() {
    BigInt value = nextBigIntRandom(scalarLength) % n;
    return bigIntToBytes(value, scalarLength);
  }

  List<BuBytes> oversizedScalars() {
    return List.generate(
      total,
      (i) => bigIntToBytes(n + (BigInt.from(i) + BigInt.one), scalarLength),
    );
  }

  /// Generates a random canonical scalar:
  ///
  ///     0 <= scalar < n
  ///
  /// Rejection sampling is used so the generated value is uniformly
  /// distributed over the scalar field.
  List<BuBytes> scalars() {
    if (n <= BigInt.zero) {
      throw ArgumentError.value(n, "n", "Must be greater than zero.");
    }

    if (scalarLength <= 0) {
      throw ArgumentError.value(
        scalarLength,
        "scalarLength",
        "Must be greater than zero.",
      );
    }

    if (total < 0) {
      throw ArgumentError.value(total, "total", "Must not be negative.");
    }

    final result = <BuBytes>[];

    while (result.length < total) {
      result.add(nextScalar());
    }

    return result;
  }

  /// Returns deterministic invalid scalar values.
  ///
  /// These are useful for testing `scCheck()`.
  ///
  /// All returned values are >= n.
  List<BuBytes> badScalars() {
    if (n <= BigInt.zero) {
      throw ArgumentError.value(n, "n", "Must be greater than zero.");
    }

    final values = <BigInt>[
      n,
      n + BigInt.one,
      n + BigInt.two,
      (n * BigInt.two) - BigInt.one,
    ];

    // Maximum unsigned value representable by [scalarLength] bytes.
    final max = (BigInt.one << (scalarLength * 8)) - BigInt.one;

    if (max >= n) {
      values.add(max);
    }

    return values
        .where((e) => e >= n && e <= max)
        .map((e) => bigIntToBytes(e, scalarLength))
        .toList();
  }

  BuBytes zero() => bigIntToBytes(BigInt.zero, scalarLength);
  BuBytes one() => bigIntToBytes(BigInt.one, scalarLength);

  List<BuBytes> validPoints() {
    List<BuBytes> validPoints = [];
    for (int i = 0; i < total; i++) {
      final p = api.multBase(nextScalar());
      validPoints.add(p);
    }
    // validPoints.add(api.multBase(bigIntToBytes(BigInt.one, scalarLength)));
    // validPoints.add(api.multBase(bigIntToBytes(n - BigInt.one, scalarLength)));

    return validPoints;
  }

  List<BuBytes> badPoints() {
    // List<BuBytes> validPoints = [];
    final result = <BuBytes>[];

    while (result.length < total) {
      final bytes = nextRandom(pointLengthBytes);
      if (!validatePoint(bytes)) result.add(bytes);
    }

    return result;
  }

  BuBytes generator() => api.generator();

  BuBytes zeroPoint() => api.multBase(zero());
}
