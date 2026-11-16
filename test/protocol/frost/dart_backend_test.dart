// Frost protocol backends: identical deterministic flows on Dart and FFI.
//
// Run: BU_BACKEND=dart dart test test/frost/dart_backend_test.dart
//      BU_BACKEND=ffi dart test test/frost/dart_backend_test.dart

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../utils.dart';

const k1Engine = FrostSecp256k1();
const edEngine = FrostEd25519();

List<int> _bytes(int base, int len) =>
    List<int>.generate(len, (i) => (base + i) & 0xFF);

void main() {
  BlockchainUtilsTestApi.runTest(() {
    test('FROST(secp256k1) full flow via api backend', () {
      final api = blockchainUtils.api.frost;
      final secret = _bytes(0x11, 32);
      final coeff = _bytes(0x22, 32);
      final shard = api.k1Shard(
        secret: secret,
        coefficients: coeff,
        maxParticipants: 3,
      );
      expect(shard.shares, hasLength(3));
      // Combine recovers the secret.
      expect(api.k1Combine(shard.shares).toList(), secret);
      // Sign with participants 1 and 3, fixed randomness (deterministic).
      final use = [shard.shares[0], shard.shares[2]];
      final groupPk = k1Engine
          .scalarBaseMult(k1Engine.deserializeScalar(secret))
          .toBytes()
          .toList();
      final msg = 'frost-dart-backend'.codeUnits;
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
      final shares = [
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
            .scalarBaseMult(k1Engine.deserializeScalar(use[k].share.toList()))
            .toBytes()
            .toList();
        expect(
          api.k1VerifyShare(
            identifier: use[k].id,
            participantPublicKey: participantPk,
            commitment: commitments[k],
            share: shares[k].toList(),
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
        shares: shares.map((e) => e.toList()).toList(),
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
    });

    test('FROST(Ed25519) full flow via api backend', () {
      final api = blockchainUtils.api.frost;
      // Ed25519 scalars must be < L: keep the top (little-endian last) low.
      final secret = [..._bytes(0x51, 31), 0x05];
      final coeff = [..._bytes(0x62, 31), 0x06];
      final shard = api.edShard(
        secret: secret,
        coefficients: coeff,
        maxParticipants: 3,
      );
      expect(shard.shares, hasLength(3));
      expect(api.edCombine(shard.shares).toList(), secret);
      final use = [shard.shares[0], shard.shares[2]];
      final groupPk = edEngine
          .scalarBaseMult(edEngine.deserializeScalar(secret))
          .toBytes()
          .toList();
      final msg = 'frost-dart-backend-ed'.codeUnits;
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
      final shares = [
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
        shares: shares.map((e) => e.toList()).toList(),
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
    });
  }, 'Frost Dart Backend');
}
