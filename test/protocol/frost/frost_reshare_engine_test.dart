// FROST threshold-reshare (additive) pure-engine tests. No backend needed.
//
// Run: dart test test/protocol/frost/frost_reshare_engine_test.dart

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:test/test.dart';

const k1 = FrostSecp256k1();
const ed = FrostEd25519();

void main() {
  group('FrostSecp256k1.reshareAdditive', () {
    // n = 3, t = 2: poly_j(x) = secrets[j] + coeffs[j] * x, chunk = t - 1 = 1,
    // so coeffs holds n * (t - 1) = 3 entries (row-major, one per poly).
    // B(x) = sum polys = 23 + 10 * x -> shares [33, 43, 53].
    Secp256k1Fr k1fr(int v) => Secp256k1Fr.from(Uint64(v));
    final secrets = [k1fr(5), k1fr(7), k1fr(11)];
    final coeffs = [k1fr(2), k1fr(3), k1fr(5)];
    final ids = [1, 2, 3];

    test('shares, pubs and group correctness', () {
      final r = k1.reshareAdditive(secrets, coeffs, ids, 2);
      expect(r.shares, hasLength(3));
      expect(r.pubs, hasLength(3));
      expect(r.shares, [k1fr(33), k1fr(43), k1fr(53)]);
      for (var i = 0; i < 3; i++) {
        expect(r.pubs[i], k1.scalarBaseMult(r.shares[i]));
      }
      // Secrets are tiny (sum 23 << n), so no modular reduction applies.
      final sum = secrets.reduce((a, b) => a + b);
      expect(sum, k1fr(23));
      var expectedGroup = Secp256k1Point.identity_;
      for (final s in secrets) {
        expectedGroup = expectedGroup + k1.scalarBaseMult(s);
      }
      expect(r.group, expectedGroup);
      // Lagrange combine of any 2 shares recovers sum(secrets).
      const pairs = [
        [0, 1],
        [0, 2],
        [1, 2],
      ];
      for (final pair in pairs) {
        final points = [
          (k1fr(ids[pair[0]]), r.shares[pair[0]]),
          (k1fr(ids[pair[1]]), r.shares[pair[1]]),
        ];
        expect(
          k1.polynomialInterpolateConstant(points),
          sum,
          reason: 'pair ${pair[0]},${pair[1]}',
        );
      }
    });

    test('bad inputs throw', () {
      final badThreshold = [0, 1, 4];
      for (final t in badThreshold) {
        expect(
          () => k1.reshareAdditive(secrets, coeffs, ids, t),
          throwsA(isA<BuError>()),
          reason: 'threshold=$t',
        );
      }
      // n < 2.
      expect(
        () => k1.reshareAdditive([k1fr(5)], [], [1], 2),
        throwsA(isA<BuError>()),
      );
      // Duplicate ids.
      expect(
        () => k1.reshareAdditive(secrets, coeffs, [
          1,
          1,
          3,
        ], 2),
        throwsA(isA<BuError>()),
      );
      // Zero id.
      expect(
        () => k1.reshareAdditive(secrets, coeffs, [
          0,
          2,
          3,
        ], 2),
        throwsA(isA<BuError>()),
      );
      // Wrong coeffs length (need n * (t - 1) = 3).
      expect(
        () => k1.reshareAdditive(
          secrets,
          [k1fr(2), k1fr(3)],
          ids,
          2,
        ),
        throwsA(isA<BuError>()),
      );
      // Zero secret.
      expect(
        () => k1.reshareAdditive(
          [Secp256k1Fr.zero, k1fr(7), k1fr(11)],
          coeffs,
          ids,
          2,
        ),
        throwsA(isA<BuError>()),
      );
    });
  });

  group('FrostEd25519.reshareAdditive', () {
    Ed25519Fr fr(int v) => Ed25519Fr.from(Uint64(v));
    final secrets = [fr(5), fr(7), fr(11)];
    final coeffs = [fr(2), fr(3), fr(5)];
    final ids = [1, 2, 3];

    test('shares, pubs and group correctness', () {
      final r = ed.reshareAdditive(secrets, coeffs, ids, 2);
      expect(r.shares, hasLength(3));
      expect(r.pubs, hasLength(3));
      expect(r.shares, [fr(33), fr(43), fr(53)]);
      for (var i = 0; i < 3; i++) {
        expect(r.pubs[i], ed.scalarBaseMult(r.shares[i]));
      }
      final sum = secrets.reduce((a, b) => a + b);
      expect(sum, fr(23));
      var expectedGroup = EdwardsLimbPoint.identity_;
      for (final s in secrets) {
        expectedGroup = expectedGroup + ed.scalarBaseMult(s);
      }
      expect(r.group, expectedGroup);
      const pairs = [
        [0, 1],
        [0, 2],
        [1, 2],
      ];
      for (final pair in pairs) {
        final points = [
          (fr(ids[pair[0]]), r.shares[pair[0]]),
          (fr(ids[pair[1]]), r.shares[pair[1]]),
        ];
        expect(
          ed.polynomialInterpolateConstant(points),
          sum,
          reason: 'pair ${pair[0]},${pair[1]}',
        );
      }
    });

    test('bad inputs throw', () {
      for (final t in [0, 1, 4]) {
        expect(
          () => ed.reshareAdditive(secrets, coeffs, ids, t),
          throwsA(isA<BuError>()),
          reason: 'threshold=$t',
        );
      }
      expect(
        () => ed.reshareAdditive([fr(5)], [], [1], 2),
        throwsA(isA<BuError>()),
      );
      expect(
        () => ed.reshareAdditive(secrets, coeffs, [
          1,
          1,
          3,
        ], 2),
        throwsA(isA<BuError>()),
      );
      expect(
        () => ed.reshareAdditive(secrets, coeffs, [
          0,
          2,
          3,
        ], 2),
        throwsA(isA<BuError>()),
      );
      expect(
        () => ed.reshareAdditive(secrets, [fr(2), fr(3)], ids, 2),
        throwsA(isA<BuError>()),
      );
      expect(
        () =>
            ed.reshareAdditive([Ed25519Fr.zero, fr(7), fr(11)], coeffs, ids, 2),
        throwsA(isA<BuError>()),
      );
    });
  });
}
