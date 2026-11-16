// FROST threshold-reshare (additive) via the api backend (Dart or FFI).
//
// Run: BU_BACKEND=dart dart test test/protocol/frost/frost_reshare_backend_test.dart
//      BU_BACKEND=ffi dart test test/protocol/frost/frost_reshare_backend_test.dart

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

const k1Engine = FrostSecp256k1();
const edEngine = FrostEd25519();

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

/// Dart throws [ArgumentError] for bad quorums while FFI/Rust surfaces
/// [BuError]/[CryptoException]; accept any of them on either backend.
final Matcher badQuorumThrows = anyOf([
  buErrorOrCryptoException,
  throwsArgumentException,
  throwsArgumentError,
]);

void main() {
  BlockchainUtilsTestApi.runTest(() {
    test('FROST(secp256k1) reshare via api backend', () {
      final api = blockchainUtils.api.frost;
      // Raw scalars (big-endian, all < order).
      final secretBytes = [
        _bytes(0x11, 32),
        _bytes(0x22, 32),
        _bytes(0x33, 32),
      ];
      final coeffBytes = [_bytes(0x41, 32), _bytes(0x42, 32), _bytes(0x43, 32)];
      final ids = [1, 2, 3];
      final secretsConcat = secretBytes.expand((e) => e).toList();
      final coeffsConcat = coeffBytes.expand((e) => e).toList();

      final r = api.k1Reshare(
        ids: ids,
        secretsConcat: secretsConcat,
        coeffsConcat: coeffsConcat,
        threshold: 2,
      );
      final sharesRaw = r.sharesConcat.toList();
      expect(sharesRaw, hasLength(96));
      expect(r.pubs, hasLength(3));
      expect(r.group.toList(), hasLength(33));

      // Pubs match recomputed base mults of the fresh shares.
      for (var i = 0; i < 3; i++) {
        final s = k1Engine.deserializeScalar(
          sharesRaw.sublist(i * 32, (i + 1) * 32),
        );
        expect(
          r.pubs[i].toList(),
          k1Engine.serializeElement(k1Engine.scalarBaseMult(s)),
        );
      }

      // Group == sum of the original secret pubs.
      var expectedGroup = Secp256k1Point.identity_;
      for (final sb in secretBytes) {
        expectedGroup =
            expectedGroup +
            k1Engine.scalarBaseMult(k1Engine.deserializeScalar(sb));
      }
      expect(r.group.toList(), k1Engine.serializeElement(expectedGroup));

      FrostKeyShare shareAt(int index) => FrostKeyShare(
        id: index + 1,
        share: sharesRaw.sublist(index * 32, (index + 1) * 32),
      );

      // Combine of any 2 new shares recovers the same secret S.
      final s01 = api.k1Combine([shareAt(0), shareAt(1)]).toList();
      final s02 = api.k1Combine([shareAt(0), shareAt(2)]).toList();
      final s12 = api.k1Combine([shareAt(1), shareAt(2)]).toList();
      expect(s02, s01);
      expect(s12, s01);

      // Full sign + verify flow with subset [0, 2] (ids 1 and 3).
      final use = [shareAt(0), shareAt(2)];
      final groupPk = r.group.toList();
      final msg = 'frost-reshare-k1'.codeUnits;
      final nonces = [
        for (final s in use)
          api.k1Commit(
            secretShare: s.share.toList(),
            hidingRandomness: _bytes(0x30 + s.id, 32),
            bindingRandomness: _bytes(0x40 + s.id, 32),
          ),
      ];
      final commitments = [
        for (var k = 0; k < use.length; k++)
          FrostCommitment(
            id: use[k].id,
            hiding: nonces[k].hidingCommitment,
            binding: nonces[k].bindingCommitment,
          ),
      ];
      final sigShares = [
        for (var k = 0; k < use.length; k++)
          api.k1Sign(
            identifier: use[k].id,
            secretShare: use[k].share.toList(),
            groupPublicKey: groupPk,
            nonces: nonces[k],
            commitments: commitments,
            message: msg,
          ),
      ];
      for (var k = 0; k < use.length; k++) {
        final participantPk = k1Engine
            .serializeElement(
              k1Engine.scalarBaseMult(
                k1Engine.deserializeScalar(use[k].share.toList()),
              ),
            )
            .toList();
        expect(
          api.k1VerifyShare(
            identifier: use[k].id,
            participantPublicKey: participantPk,
            commitment: commitments[k],
            share: sigShares[k].toList(),
            commitments: commitments,
            groupPublicKey: groupPk,
            message: msg,
          ),
          isTrue,
        );
      }
      final sig = api.k1Aggregate(
        commitments: commitments,
        message: msg,
        groupPublicKey: groupPk,
        shares: sigShares.map((e) => e.toList()).toList(),
      );
      expect(
        api.k1Verify(
          commitment: sig.r.toList(),
          z: sig.z.toList(),
          groupPublicKey: groupPk,
          message: msg,
        ),
        isTrue,
      );

      // Bad threshold (t = 1) throws.
      expect(
        () => api.k1Reshare(
          ids: ids,
          secretsConcat: secretsConcat,
          coeffsConcat: const [],
          threshold: 1,
        ),
        badQuorumThrows,
      );
    });

    test('FROST(Ed25519) reshare via api backend', () {
      final api = blockchainUtils.api.frost;
      // RFC 8032 seeds (expanded inside the backend); any bytes are valid.
      final seedBytes = [_bytes(0x11, 32), _bytes(0x22, 32), _bytes(0x33, 32)];
      final coeffSeedBytes = [
        _bytes(0x41, 32),
        _bytes(0x42, 32),
        _bytes(0x43, 32),
      ];
      final ids = [1, 2, 3];
      final seedsConcat = seedBytes.expand((e) => e).toList();
      final coeffSeedsConcat = coeffSeedBytes.expand((e) => e).toList();

      final r = api.edReshare(
        ids: ids,
        seedsConcat: seedsConcat,
        coeffSeedsConcat: coeffSeedsConcat,
        threshold: 2,
      );
      final sharesRaw = r.sharesConcat.toList();
      expect(sharesRaw, hasLength(96));
      expect(r.pubs, hasLength(3));
      expect(r.group.toList(), hasLength(32));

      // Pubs match recomputed base mults of the fresh shares.
      for (var i = 0; i < 3; i++) {
        final s = edEngine.deserializeScalar(
          sharesRaw.sublist(i * 32, (i + 1) * 32),
        );
        expect(
          r.pubs[i].toList(),
          edEngine.serializeElement(edEngine.scalarBaseMult(s)),
        );
      }

      FrostKeyShare shareAt(int index) => FrostKeyShare(
        id: index + 1,
        share: sharesRaw.sublist(index * 32, (index + 1) * 32),
      );

      // Combine of any 2 new shares (scalars) recovers the same secret S.
      final s01 = api.edCombine([shareAt(0), shareAt(1)]).toList();
      final s02 = api.edCombine([shareAt(0), shareAt(2)]).toList();
      final s12 = api.edCombine([shareAt(1), shareAt(2)]).toList();
      expect(s02, s01);
      expect(s12, s01);

      // Cross-check: the pure-Dart backend must agree exactly with the
      // active backend (covers both backends in one run: when
      // BU_BACKEND=ffi, `api` is native and DartFrostApi is dart and
      // vice versa).
      final ref = const DartFrostApi().edReshare(
        ids: ids,
        seedsConcat: seedsConcat,
        coeffSeedsConcat: coeffSeedsConcat,
        threshold: 2,
      );
      expect(sharesRaw, ref.sharesConcat.toList());
      for (var i = 0; i < 3; i++) {
        expect(r.pubs[i].toList(), ref.pubs[i].toList());
      }
      expect(r.group.toList(), ref.group.toList());

      // Full sign + verify flow with subset [0, 2] (ids 1 and 3).
      final use = [shareAt(0), shareAt(2)];
      final groupPk = r.group.toList();
      final msg = 'frost-reshare-ed'.codeUnits;
      final nonces = [
        for (final s in use)
          api.edCommit(
            secretShare: s.share.toList(),
            hidingRandomness: _bytes(0x70 + s.id, 32),
            bindingRandomness: _bytes(0x80 + s.id, 32),
          ),
      ];
      final commitments = [
        for (var k = 0; k < use.length; k++)
          FrostCommitment(
            id: use[k].id,
            hiding: nonces[k].hidingCommitment,
            binding: nonces[k].bindingCommitment,
          ),
      ];
      final sigShares = [
        for (var k = 0; k < use.length; k++)
          api.edSign(
            identifier: use[k].id,
            secretShare: use[k].share.toList(),
            groupPublicKey: groupPk,
            nonces: nonces[k],
            commitments: commitments,
            message: msg,
          ),
      ];
      final sig = api.edAggregate(
        commitments: commitments,
        message: msg,
        groupPublicKey: groupPk,
        shares: sigShares.map((e) => e.toList()).toList(),
      );
      expect(
        api.edVerify(
          commitment: sig.r.toList(),
          z: sig.z.toList(),
          groupPublicKey: groupPk,
          message: msg,
        ),
        isTrue,
      );

      // Bad threshold (t = 1) throws.
      expect(
        () => api.edReshare(
          ids: ids,
          seedsConcat: seedsConcat,
          coeffSeedsConcat: const [],
          threshold: 1,
        ),
        badQuorumThrows,
      );
    });
  }, 'Frost Reshare Backend');
}
