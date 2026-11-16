// Pure-Dart DKLs23 engine verification (both curves): DKG roundtrip (framed
// codec), threshold sign/verify, additive import, refresh stability, agg +
// xOnly — plus native cross-checks (Dart sig verifies natively, native sig
// verifies in the engine), the same parity shape the FROST suites use.
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'utils.dart';

List<int> _b(int v, int n) => List<int>.generate(n, (i) => (v + i) & 0xFF);

void _checkIdentifiers<
  S extends WeierstrassScalar<S>,
  B extends CryptoField<B>,
  P extends WeierstrassPoint<S, B, P>
>(DklsEngine<S, B, P> engine) {
  // Valid weights: λ₁(0) over {1,2} is 2/(2-1) = 2.
  expect(
    engine.scalarToBytes(engine.lagrangeAtZero([1, 2], 1)),
    List<int>.filled(32, 0)..[31] = 2,
  );
  // Zero, negative, and out-of-u32-range ids rejected.
  for (final bad in [
    <int>[0, 1],
    <int>[-1, 1],
    <int>[1, 0x100000000],
  ]) {
    expect(
      () => engine.lagrangeAtZero(bad, bad.last),
      throwsA(isA<BuError>()),
    );
  }
  // Duplicates, unknown xi, and empty sets rejected.
  expect(
    () => engine.lagrangeAtZero([1, 1], 1),
    throwsA(isA<BuError>()),
  );
  expect(
    () => engine.lagrangeAtZero([1, 2], 3),
    throwsA(isA<BuError>()),
  );
  expect(
    () => engine.lagrangeAtZero(<int>[], 1),
    throwsA(isA<BuError>()),
  );
}

void main() {
  BlockchainUtilsTestApi.runTest(() {
    for (final curve in [DklsProtocolCurve.k1, DklsProtocolCurve.r1]) {
      final tag = curve.name;
      test('dkls23-dart dkg+sign [$tag]', () {
        final sid = _b(0xA0, 16);
        final seeds = [_b(1, 32), _b(2, 32), _b(3, 32)];
        final shares = DklsUtils.dkg(
          curve: curve,
          sid: sid,
          n: 3,
          t: 2,
          seeds: seeds,
        );
        expect(shares.length, 3);
        for (final sh in shares) {
          expect(
            DklsUtils.parseKeyshare(DklsUtils.keyshareBytes(sh)).pk,
            sh.pk,
          );
        }
        final blob = DklsUtils.frame([
          for (final s in shares) DklsUtils.keyshareBytes(s),
        ]);
        expect(DklsUtils.unframe(blob).length, 3);
        final sub = [shares[0], shares[2]];
        final msg = _b(0x55, 32);
        final sig = DklsUtils.sign(
          shares: sub,
          sid: _b(0xC0, 16),
          msgHash: msg,
          seeds: [_b(9, 32), _b(10, 32)],
        );
        expect(sig.length, 64);
        expect(
          DklsUtils.verify(
            curve: curve,
            groupPk: shares[0].pk,
            msgHash: msg,
            signature: sig,
          ),
          isTrue,
        );
        expect(
          DklsUtils.verify(
            curve: curve,
            groupPk: shares[0].pk,
            msgHash: _b(0x56, 32),
            signature: sig,
          ),
          isFalse,
        );
      });

      test('dkls23-dart import+refresh+agg [$tag]', () {
        final shares = DklsUtils.importSecrets(
          curve: curve,
          secrets: [_b(11, 32), _b(22, 32)],
        );
        expect(shares.first.t, 2);
        final msg = _b(0x77, 32);
        final sig = DklsUtils.sign(
          shares: shares,
          sid: _b(0xD0, 16),
          msgHash: msg,
          seeds: [_b(31, 32), _b(32, 32)],
        );
        expect(
          DklsUtils.verify(
            curve: curve,
            groupPk: shares[0].pk,
            msgHash: msg,
            signature: sig,
          ),
          isTrue,
        );
        expect(
          DklsUtils.agg(curve: curve, members: shares[0].shares),
          shares[0].pk,
        );
        expect(DklsUtils.xOnly(curve: curve, groupPk: shares[0].pk).length, 32);
        final fresh = DklsUtils.refresh(
          olds: shares,
          sid: _b(0xE0, 16),
          seeds: [_b(41, 32), _b(42, 32)],
        );
        expect(fresh[0].pk, shares[0].pk);
        expect(fresh[0].x == shares[0].x, isFalse);
        final sig2 = DklsUtils.sign(
          shares: fresh,
          sid: _b(0xE1, 16),
          msgHash: msg,
          seeds: [_b(51, 32), _b(52, 32)],
        );
        expect(
          DklsUtils.verify(
            curve: curve,
            groupPk: fresh[0].pk,
            msgHash: msg,
            signature: sig2,
          ),
          isTrue,
        );
      });

      test('dkls23-dart identifier validation [$tag]', () {
        switch (curve) {
          case DklsProtocolCurve.k1:
            _checkIdentifiers(const DklsK1Engine());
          case DklsProtocolCurve.r1:
            _checkIdentifiers(const DklsR1Engine());
        }
        // Duplicate shares fail at sign time with a clear error.
        final sid = _b(0xA0, 16);
        final shares = DklsUtils.dkg(
          curve: curve,
          sid: sid,
          n: 2,
          t: 2,
          seeds: [_b(1, 32), _b(2, 32)],
        );
        expect(
          () => DklsUtils.sign(
            shares: [shares[0], shares[0]],
            sid: _b(0xC0, 16),
            msgHash: _b(0x55, 32),
            seeds: [_b(9, 32), _b(10, 32)],
          ),
          throwsA(isA<BuError>()),
        );
      });
    }
  }, 'dkls23 dart engine');
}
