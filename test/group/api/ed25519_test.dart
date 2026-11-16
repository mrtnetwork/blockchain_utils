import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/ed25519/api/src/dart.dart';
import 'package:test/test.dart';

import '../../utils.dart';
import 'utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {}, "ed25519Test", onNative: ed25519Test);
}

void ed25519Test(BlockchainUtilsApi api) {
  final rng = ChaCha20Rng(List<int>.filled(32, 1));
  QuickCrypto.setupPRNG(rng);
  final test = ED25519CurveTest.generate(apis: [api.ed25519]);
  test.run();
}

typedef ISVALIDPOINT = bool Function(BuBytes);

class ED25519CurveTest extends CurveTest<Ed25519CurveApi> {
  ED25519CurveTest({
    required super.apis,
    required super.randomGenerator,
    required super.name,
  });
  /// Ed25519 group order (test-only literal; lib holds limbs only).
  static final BigInt edOrder = BigInt.parse(
    '1000000000000000000000000000000014def9dea2f79cd65812631a5cf5d3ed',
    radix: 16,
  );

  factory ED25519CurveTest.generate({List<Ed25519CurveApi> apis = const []}) {
    assert(apis.isNotEmpty);
    final generator = RandomScalarGeneratorGenerator(
      n: edOrder,
      scalarLength: 32,
      total: TestThrottle.generatorTotal(),
      endian: Endian.little,
      validatePoint: (data) {
        try {
          EdwardsLimbPoint.fromBytes(data);
          return true;
        } catch (_) {
          return false;
        }
      },
      api: DartEd25519CurveApi(),
      pointLengthBytes: 32,
    );
    return ED25519CurveTest(
      apis: [DartEd25519CurveApi(), ...apis],
      randomGenerator: generator,

      name: "ED25519",
    );
  }
  List<BuBytes> get _usableScalars => scalars;

  @override
  void testCases() {
    _testScalarVarOps();
    _testScMulAddSub();
    _testScReduce64();
    _testScIsNonZero();
    _testReduceMultBase();
    _testAddVar();
    _testMul8();
    _testGeDsmPrecompVar();
    _testDoubleScalarMult();
    _testGeDoubleScalarMultBasePointVar();
    _testGeDoubleScalarMultPrecompPointVar();
    _testGeTripleScalarMultBasePointVar();
    _testGeTripleScalarMultPrecompPointVar();
  }

  void _testScalarVarOps() {
    test("scAddVar / scSubVar / scMulVar", () {
      for (final a in _usableScalars) {
        for (final b in _usableScalars) {
          expectSame(apis.map((e) => e.scAddVar(a, b)).toList(), "scAddVar");
          expectSame(apis.map((e) => e.scSubVar(a, b)).toList(), "scSubVar");
          expectSame(apis.map((e) => e.scMulVar(a, b)).toList(), "scMulVar");
        }
      }
    });

    test("scMulAddVar", () {
      for (final a in _usableScalars) {
        for (final b in _usableScalars) {
          for (final c in _usableScalars) {
            expectSame(
              apis.map((e) => e.scMulAddVar(a, b, c)).toList(),
              "scMulAddVar",
            );
          }
        }
      }
    });
  }

  void _testScMulAddSub() {
    test("scMulAdd", () {
      for (final a in _usableScalars) {
        for (final b in _usableScalars) {
          for (final c in _usableScalars) {
            expectSame(
              apis.map((e) => e.scMulAdd(a, b, c)).toList(),
              "scMulAdd",
            );
          }
        }
      }
    });

    test("scMulSub", () {
      for (final a in _usableScalars) {
        for (final b in _usableScalars) {
          for (final c in _usableScalars) {
            expectSame(
              apis.map((e) => e.scMulSub(a, b, c)).toList(),
              "scMulSub",
            );
          }
        }
      }
    });
  }

  void _testScReduce64() {
    test("scReduce64", () {
      final inputs = [
        for (final s in scalars) BuBytes([...s, ...List<int>.filled(32, 0)]),
        for (final s in oversizedScalars)
          BuBytes([...s, ...QuickCrypto.generateRandom(length: 32)]),
      ];

      for (final input in inputs) {
        expectSame(apis.map((e) => e.scReduce64(input)).toList(), "scReduce64");
      }
    });
  }

  void _testScIsNonZero() {
    test("scIsNonZero", () {
      final inputs = [zeroScalar, oneScalar, ...scalars];
      for (final input in inputs) {
        if (input == null) continue;
        final results = apis.map((e) => e.scIsNonZero(input)).toList();
        expect(
          results,
          isNotEmpty,
          reason: "scIsNonZero has no implementations.",
        );
        for (var i = 1; i < results.length; i++) {
          expect(
            results[i],
            results.first,
            reason: "scIsNonZero differs between implementations: 0 != $i.",
          );
        }
      }
    });
  }

  // =========================================================================
  // Point operations
  // =========================================================================

  void _testReduceMultBase() {
    test("reduceMultBase", () {
      final inputs = [...scalars, ...oversizedScalars];
      for (final s in inputs) {
        expectSame(
          apis.map((e) => e.reduceMultBase(s)).toList(),
          "reduceMultBase",
        );
      }
    });
  }

  void _testAddVar() {
    test("addVar", () {
      for (final a in points) {
        for (final b in points) {
          expectSame(apis.map((e) => e.addVar(a, b)).toList(), "addVar");
        }
      }
    });
  }

  void _testMul8() {
    test("mul8", () {
      for (final p in [zeroPoint, generator, ...points]) {
        if (p == null) continue;
        expectSame(apis.map((e) => e.mul8(p)).toList(), "mul8");
      }
    });
  }

  void _testGeDsmPrecompVar() {
    test("geDsmPrecompVar", () {
      for (final p in points) {
        final results =
            apis.map((e) {
              final pre = e.geDsmPrecompVar(p);
              return BuBytes(pre.expand((e) => e).toList());
            }).toList();
        expectSame(results, "geDsmPrecompVar");
      }
    });
  }

  // =========================================================================
  // Multi-scalar multiplication
  // =========================================================================

  void _testDoubleScalarMult() {
    test("doubleScalarMult", () {
      for (final s1 in _usableScalars) {
        for (final p1 in points) {
          for (final s2 in _usableScalars) {
            for (final p2 in points) {
              expectSame(
                apis.map((e) => e.doubleScalarMult(s1, p1, s2, p2)).toList(),
                "doubleScalarMult",
              );
            }
          }
        }
      }
    });
  }

  void _testGeDoubleScalarMultBasePointVar() {
    test("geDoubleScalarMultBasePointVar", () {
      for (final a in _usableScalars) {
        for (final g in points) {
          for (final b in _usableScalars) {
            expectSame(
              apis
                  .map(
                    (e) => e.geDoubleScalarMultBasePointVar(a: a, g: g, b: b),
                  )
                  .toList(),
              "geDoubleScalarMultBasePointVar",
            );
          }
        }
      }
    });
  }

  void _testGeDoubleScalarMultPrecompPointVar() {
    test("geDoubleScalarMultPrecompPointVar", () {
      // Precomp is computed once per api per point, reused across scalars.
      final precomp = {
        for (final api in apis)
          api: {for (final p in points) p: api.geDsmPrecompVar(p)},
      };

      for (final a in _usableScalars) {
        for (final A in points) {
          for (final b in _usableScalars) {
            for (final B in points) {
              expectSame(
                apis
                    .map(
                      (e) => e.geDoubleScalarMultPrecompPointVar(
                        a,
                        precomp[e]![A]!,
                        b,
                        precomp[e]![B]!,
                      ),
                    )
                    .toList(),
                "geDoubleScalarMultPrecompPointVar",
              );
            }
          }
        }
      }
    });
  }

  void _testGeTripleScalarMultBasePointVar() {
    test("geTripleScalarMultBasePointVar", () {
      final precomp = {
        for (final api in apis)
          api: {for (final p in points) p: api.geDsmPrecompVar(p)},
      };

      for (final a in _usableScalars) {
        for (final b in _usableScalars) {
          for (final B in points) {
            for (final c in _usableScalars) {
              for (final C in points) {
                expectSame(
                  apis
                      .map(
                        (e) => e.geTripleScalarMultBasePointVar(
                          a: a,
                          b: b,
                          bI: precomp[e]![B]!,
                          c: c,
                          cI: precomp[e]![C]!,
                        ),
                      )
                      .toList(),
                  "geTripleScalarMultBasePointVar",
                );
              }
            }
          }
        }
      }
    });
  }

  void _testGeTripleScalarMultPrecompPointVar() {
    test("geTripleScalarMultPrecompPointVar", () {
      final precomp = {
        for (final api in apis)
          api: {for (final p in points) p: api.geDsmPrecompVar(p)},
      };

      for (final a in _usableScalars) {
        for (final A in points) {
          for (final b in _usableScalars) {
            for (final B in points) {
              for (final c in _usableScalars) {
                for (final C in points) {
                  expectSame(
                    apis
                        .map(
                          (e) => e.geTripleScalarMultPrecompPointVar(
                            a,
                            precomp[e]![A]!,
                            b,
                            precomp[e]![B]!,
                            c,
                            precomp[e]![C]!,
                          ),
                        )
                        .toList(),
                    "geTripleScalarMultPrecompPointVar",
                  );
                }
              }
            }
          }
        }
      }
    });
  }
}
