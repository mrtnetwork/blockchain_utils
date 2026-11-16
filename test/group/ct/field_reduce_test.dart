/// Functional edge-case tests for fixed-limb Uint64 field reduction.
///
/// Covers the 4-limb Montgomery fields (JubJubFr/Fq, VestaFq, PallasFp,
/// Secp256k1Fp/Fr, Secp256r1Fp/Fr) and the 6-limb field (Bls12Fp).
/// BigInt implementations are intentionally out of scope.
///
/// For each field: reduction of boundary values (0, 1, mod-1, mod, mod+1,
/// 2*mod+5, max-width, wide-max) must equal a BigInt oracle, be canonical
/// (accepted by the checked `fromBytes`), and be idempotent.
/// Browser-safe: no `dart:io`.
library;

import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/group/bls12_381/src/fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/jubjub/fields/field.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/pallas_fp.dart';
import 'package:blockchain_utils/crypto/crypto/group/pasta/fields/vesta_fq.dart';
import 'package:blockchain_utils/crypto/crypto/group/weierstrass/src/fields.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:test/test.dart';

BigInt _le(List<int> b) {
  var v = BigInt.zero;
  for (var i = b.length - 1; i >= 0; i--) {
    v = (v << 8) | BigInt.from(b[i]);
  }
  return v;
}

BigInt _be(List<int> b) => _le(b.reversed.toList());

List<int> _leBytes(BigInt v, int len) {
  final out = List<int>.filled(len, 0);
  var t = v;
  for (var i = 0; i < len; i++) {
    out[i] = (t & BigInt.from(0xff)).toInt();
    t >>= 8;
  }
  return out;
}

List<int> _beBytes(BigInt v, int len) => _leBytes(v, len).reversed.toList();

/// Field adapter: BigInt oracle + reduce/canonical-roundtrip entry points.
class _F {
  final String name;
  final BigInt mod;
  final List<int> Function(BigInt v) reduce; // canonical bytes out
  final List<int> Function(List<int> canonical) recanonical;
  final Endian endian;
  final int len;
  const _F({
    required this.name,
    required this.mod,
    required this.reduce,
    required this.recanonical,
    required this.endian,
    required this.len,
  });

  BigInt decode(List<int> b) => endian == Endian.big ? _be(b) : _le(b);
}

void main() {
  // Moduli derived in-test via -(1) = mod-1 (also exercises neg()).
  // NOTE: weierstrass toBytes/fromBytes default to big-endian.
  final frMod = _le((-JubJubFr.one).toBytes().toList()) + BigInt.one;
  final fqMod = _le((-JubJubFq.one).toBytes().toList()) + BigInt.one;
  final vestaMod = _le((-VestaFq.one).toBytes().toList()) + BigInt.one;
  final pallasMod = _le((-PallasFp.one).toBytes().toList()) + BigInt.one;
  final k1FpMod = _be((-Secp256k1Fp.one).toBytes().toList()) + BigInt.one;
  final k1FrMod = _be((-Secp256k1Fr.one).toBytes().toList()) + BigInt.one;
  final r1FpMod = _be((-Secp256r1Fp.one).toBytes().toList()) + BigInt.one;
  final r1FrMod = _be((-Secp256r1Fr.one).toBytes().toList()) + BigInt.one;
  final blsMod = _be((-Bls12Fp.one).toBytes().toList()) + BigInt.one;

  List<Uint64> leLimbs(BigInt v) => List<Uint64>.generate(
    4,
    (i) =>
        Uint64.fromBytes(_leBytes(v, 32), endian: Endian.little, offset: i * 8),
  );

  final fields = <_F>[
    _F(
      name: 'JubJubFr',
      mod: frMod,
      endian: Endian.little,
      len: 32,
      reduce:
          (v) =>
              JubJubFr.fromBytesUnchecked(_leBytes(v, 32)).toBytes().toList(),
      recanonical: (c) => JubJubFr.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'JubJubFq',
      mod: fqMod,
      endian: Endian.little,
      len: 32,
      reduce:
          (v) =>
              JubJubFq.fromBytesUnchecked(_leBytes(v, 32)).toBytes().toList(),
      recanonical: (c) => JubJubFq.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'VestaFq',
      mod: vestaMod,
      endian: Endian.little,
      len: 32,
      reduce:
          (v) => VestaFq.fromBytesUnchecked(_leBytes(v, 32)).toBytes().toList(),
      recanonical: (c) => VestaFq.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'PallasFp/via-fromRaw',
      mod: pallasMod,
      endian: Endian.little,
      len: 32,
      reduce: (v) => PallasFp.fromRaw(leLimbs(v)).toBytes().toList(),
      recanonical: (c) => PallasFp.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'Secp256k1Fp/via-fromBytes64',
      mod: k1FpMod,
      endian: Endian.big,
      len: 32,
      reduce:
          (v) => Secp256k1Fp.fromBytes64(_leBytes(v, 64)).toBytes().toList(),
      recanonical: (c) => Secp256k1Fp.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'Secp256k1Fr/via-fromBytes64',
      mod: k1FrMod,
      endian: Endian.big,
      len: 32,
      reduce:
          (v) => Secp256k1Fr.fromBytes64(_leBytes(v, 64)).toBytes().toList(),
      recanonical: (c) => Secp256k1Fr.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'Secp256r1Fp/via-fromBytes64',
      mod: r1FpMod,
      endian: Endian.big,
      len: 32,
      reduce:
          (v) => Secp256r1Fp.fromBytes64(_leBytes(v, 64)).toBytes().toList(),
      recanonical: (c) => Secp256r1Fp.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'Secp256r1Fr/via-fromBytes64',
      mod: r1FrMod,
      endian: Endian.big,
      len: 32,
      reduce:
          (v) => Secp256r1Fr.fromBytes64(_leBytes(v, 64)).toBytes().toList(),
      recanonical: (c) => Secp256r1Fr.fromBytes(c).toBytes().toList(),
    ),
    _F(
      name: 'Bls12Fp/via-fromBytes64',
      mod: blsMod,
      endian: Endian.big,
      len: 48,
      reduce: (v) => Bls12Fp.fromBytes64(_beBytes(v, 64)).toBytes().toList(),
      recanonical: (c) => Bls12Fp.fromBytes(c).toBytes().toList(),
    ),
  ];

  group('fixed-limb field reduction edges', () {
    for (final f in fields) {
      group(f.name, () {
        final wideBits = f.name.startsWith('Bls12Fp') ? 512 : 256;
        final vectors = <String, BigInt>{
          'zero': BigInt.zero,
          'one': BigInt.one,
          'mod-1': f.mod - BigInt.one,
          'mod': f.mod,
          'mod+1': f.mod + BigInt.one,
          '2mod+5': f.mod * BigInt.two + BigInt.from(5),
          'max-width': (BigInt.one << wideBits) - BigInt.one,
          'max-width-1': (BigInt.one << wideBits) - BigInt.two,
          '2^200+0xdeadbeef': (BigInt.one << 200) + BigInt.from(0xdeadbeef),
        };
        for (final e in vectors.entries) {
          test('${e.key} reduces to oracle value', () {
            // Skip vectors that do not fit the reduce entry width.
            if (e.value < BigInt.zero || e.value >= (BigInt.one << wideBits)) {
              return;
            }
            final expected = e.value % f.mod;
            final out = f.reduce(e.value);
            expect(out.length, f.len, reason: 'bad output length');
            expect(
              f.decode(out),
              expected,
              reason: '${f.name}.${e.key}: mismatch vs BigInt oracle',
            );
            // Canonical: the checked constructor must accept the output.
            expect(
              f.recanonical(out),
              out,
              reason: '${f.name}.${e.key}: output not canonical',
            );
            // Idempotent: reduce(reduce(x)) == reduce(x).
            expect(
              f.decode(f.reduce(f.decode(out))),
              expected,
              reason: '${f.name}.${e.key}: not idempotent',
            );
          });
        }

        test('fromBytes64 zero-extension matches 32-byte reduce', () {
          if (f.name.startsWith('Bls12Fp')) return; // 48-byte field
          final v = (BigInt.one << 200) + BigInt.from(123456789);
          final narrow = f.reduce(v);
          final wide = switch (f.name) {
            'JubJubFr' =>
              JubJubFr.fromBytes64([
                ..._leBytes(v, 32),
                ...List<int>.filled(32, 0),
              ]).toBytes().toList(),
            'JubJubFq' =>
              JubJubFq.fromBytes64([
                ..._leBytes(v, 32),
                ...List<int>.filled(32, 0),
              ]).toBytes().toList(),
            'VestaFq' =>
              VestaFq.fromBytes64([
                ..._leBytes(v, 32),
                ...List<int>.filled(32, 0),
              ]).toBytes().toList(),
            _ => narrow, // PallasFp/weierstrass already go through wide path
          };
          expect(wide, narrow);
        });
      });
    }

    test('weierstrass fromBytes64 reduces full 512-bit inputs', () {
      // Values above 2^256 only fit the 64-byte wide entry point.
      final v = (BigInt.one << 300) + BigInt.from(7);
      final cases = <String, BigInt Function(BigInt, BigInt)>{
        'k1Fp':
            (x, m) => _be(
              Secp256k1Fp.fromBytes64(_leBytes(x, 64)).toBytes().toList(),
            ),
        'k1Fr':
            (x, m) => _be(
              Secp256k1Fr.fromBytes64(_leBytes(x, 64)).toBytes().toList(),
            ),
        'r1Fp':
            (x, m) => _be(
              Secp256r1Fp.fromBytes64(_leBytes(x, 64)).toBytes().toList(),
            ),
        'r1Fr':
            (x, m) => _be(
              Secp256r1Fr.fromBytes64(_leBytes(x, 64)).toBytes().toList(),
            ),
      };
      final mods = <String, BigInt>{
        'k1Fp': k1FpMod,
        'k1Fr': k1FrMod,
        'r1Fp': r1FpMod,
        'r1Fr': r1FrMod,
      };
      for (final e in cases.entries) {
        expect(e.value(v, mods[e.key]!), v % mods[e.key]!);
      }
    });

    test('JubJubFq BE unchecked matches wide LE path (G1/G2 scReduce)', () {
      final v = fqMod + BigInt.from(7);
      final be = _beBytes(v, 32);
      final viaUnchecked =
          JubJubFq.fromBytesUnchecked(
            be,
            endian: Endian.big,
          ).toBytes().toList();
      final viaWide =
          JubJubFq.fromBytes64([
            ...be.reversed,
            ...List<int>.filled(32, 0),
          ]).toBytes().toList();
      expect(viaUnchecked, viaWide);
      expect(_le(viaUnchecked), v % fqMod);
    });
  });
}
