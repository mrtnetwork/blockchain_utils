import 'dart:math';

import 'package:blockchain_utils/numbers/src/i128.dart';
import 'package:blockchain_utils/numbers/src/i32.dart';
import 'package:blockchain_utils/numbers/src/i64.dart';
import 'package:blockchain_utils/numbers/src/u128.dart';
import 'package:blockchain_utils/numbers/src/u256.dart';
import 'package:blockchain_utils/numbers/src/u32.dart';
import 'package:blockchain_utils/numbers/src/u64.dart';
import 'package:test/test.dart';

import 'helpers/oracle.dart';

/// Describes one of the 7 fixed-width types for the purposes of this
/// data-driven matrix test: how to build an instance from an arbitrary
/// [BigInt] (any sign, any magnitude — the builder is responsible for
/// wrapping it the same way the type's own constructors document), its
/// width/signedness (needed to compute the expected `as`-cast result),
/// and a name -> converter map covering every `toXxx()` method it
/// exposes to its 6 siblings.
class _TypeDesc {
  final String name;
  final int bits;
  final bool signed;
  final dynamic Function(BigInt) build;
  final Map<String, dynamic Function(dynamic)> converters;

  _TypeDesc({
    required this.name,
    required this.bits,
    required this.signed,
    required this.build,
    required this.converters,
  });
}

void main() {
  final rnd = Random(0xC0FFEE);

  final types = <_TypeDesc>[
    _TypeDesc(
      name: 'Uint32',
      bits: 32,
      signed: false,
      build: (v) => Uint32.fromBigInt(v),
      converters: {
        'Uint64': (x) => (x as Uint32).toUint64(),
        'Uint128': (x) => (x as Uint32).toUint128(),
        'Uint256': (x) => (x as Uint32).toUint256(),
        'Int32': (x) => (x as Uint32).toInt32(),
        'Int64': (x) => (x as Uint32).toInt64(),
        'Int128': (x) => (x as Uint32).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Uint64',
      bits: 64,
      signed: false,
      build: (v) => Uint64.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Uint64).toUint32(),
        'Uint128': (x) => (x as Uint64).toUint128(),
        'Uint256': (x) => (x as Uint64).toUint256(),
        'Int32': (x) => (x as Uint64).toInt32(),
        'Int64': (x) => (x as Uint64).toInt64(),
        'Int128': (x) => (x as Uint64).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Uint128',
      bits: 128,
      signed: false,
      build: (v) => Uint128.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Uint128).toUint32(),
        'Uint64': (x) => (x as Uint128).toUint64(),
        'Uint256': (x) => (x as Uint128).toUint256(),
        'Int32': (x) => (x as Uint128).toInt32(),
        'Int64': (x) => (x as Uint128).toInt64(),
        'Int128': (x) => (x as Uint128).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Uint256',
      bits: 256,
      signed: false,
      build: (v) => Uint256.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Uint256).toUint32(),
        'Uint64': (x) => (x as Uint256).toUint64(),
        'Uint128': (x) => (x as Uint256).toUint128(),
        'Int32': (x) => (x as Uint256).toInt32(),
        'Int64': (x) => (x as Uint256).toInt64(),
        'Int128': (x) => (x as Uint256).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Int32',
      bits: 32,
      signed: true,
      build: (v) => Int32.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Int32).toUint32(),
        'Uint64': (x) => (x as Int32).toUint64(),
        'Uint128': (x) => (x as Int32).toUint128(),
        'Uint256': (x) => (x as Int32).toUint256(),
        'Int64': (x) => (x as Int32).toInt64(),
        'Int128': (x) => (x as Int32).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Int64',
      bits: 64,
      signed: true,
      build: (v) => Int64.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Int64).toUint32(),
        'Uint64': (x) => (x as Int64).toUint64(),
        'Uint128': (x) => (x as Int64).toUint128(),
        'Uint256': (x) => (x as Int64).toUint256(),
        'Int32': (x) => (x as Int64).toInt32(),
        'Int128': (x) => (x as Int64).toInt128(),
      },
    ),
    _TypeDesc(
      name: 'Int128',
      bits: 128,
      signed: true,
      build: (v) => Int128.fromBigInt(v),
      converters: {
        'Uint32': (x) => (x as Int128).toUint32(),
        'Uint64': (x) => (x as Int128).toUint64(),
        'Uint128': (x) => (x as Int128).toUint128(),
        'Uint256': (x) => (x as Int128).toUint256(),
        'Int32': (x) => (x as Int128).toInt32(),
        'Int64': (x) => (x as Int128).toInt64(),
      },
    ),
  ];

  final byName = {for (final t in types) t.name: t};

  group('conversion matrix completeness', () {
    test('every type exposes a converter to all 6 sibling types', () {
      for (final t in types) {
        final expected =
            types.map((e) => e.name).where((n) => n != t.name).toSet();
        expect(t.converters.keys.toSet(), expected, reason: t.name);
      }
    });
  });

  group(
    'conversion matrix correctness (as-cast oracle: sign/zero-extend then truncate)',
    () {
      for (final src in types) {
        final values = <BigInt>{
          ...(src.signed
              ? interestingSigned(src.bits)
              : interestingUnsigned(src.bits)),
        };
        for (var i = 0; i < 40; i++) {
          values.add(
            src.signed
                ? randomSigned(rnd, src.bits)
                : randomUnsigned(rnd, src.bits),
          );
        }

        for (final entry in src.converters.entries) {
          final target = byName[entry.key]!;
          final convert = entry.value;

          test('${src.name}.to${target.name}()', () {
            for (final v in values) {
              final source = src.build(v);
              final dynamic result = convert(source);
              final expected =
                  target.signed
                      ? v.toSigned(target.bits)
                      : v.toUnsigned(target.bits);
              final BigInt actual = (result as dynamic).toBigInt() as BigInt;
              expect(
                actual,
                expected,
                reason: '${src.name}($v).to${target.name}()',
              );
            }
          });
        }
      }
    },
  );

  group('conversion matrix: known hand-checked vectors', () {
    test('widening zero-extends for unsigned sources', () {
      expect(Uint32.max.toUint64().toBigInt(), BigInt.from(0xFFFFFFFF));
      expect(Uint32.max.toUint128().toBigInt(), BigInt.from(0xFFFFFFFF));
      expect(Uint64.max.toUint128().toBigInt(), maxUnsigned(64));
    });

    test('widening sign-extends for negative signed sources', () {
      expect(Int32.minusOne.toUint64().toBigInt(), maxUnsigned(64)); // all-ones
      expect(Int32.minusOne.toInt64().toBigInt(), -BigInt.one);
      expect(Int32.min.toInt128().toBigInt(), BigInt.from(-0x80000000));
    });

    test('same-width reinterpretation flips between max and -1', () {
      expect(Uint32.max.toInt32().toBigInt(), -BigInt.one);
      expect(Int32.minusOne.toUint32().toBigInt(), maxUnsigned(32));
      expect(Uint64.max.toInt64().toBigInt(), -BigInt.one);
      expect(Uint128.max.toInt128().toBigInt(), -BigInt.one);
    });

    test('narrowing truncates (wraps), like a Rust `as` cast', () {
      expect(Uint256.max.toUint32().toBigInt(), maxUnsigned(32));
      expect(
        (Uint256.fromBigInt(BigInt.from(0x100000000)).toUint32()).toBigInt(),
        BigInt.zero,
      );
      expect(
        Int128.min.toInt32().toBigInt(),
        BigInt.zero,
      ); // low 32 bits of 2^127 are all zero
    });
  });
}
