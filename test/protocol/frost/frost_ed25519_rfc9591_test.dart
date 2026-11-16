// Review tests for RFC 9591 FROST(Ed25519, SHA-512), Appendix E.1.
// Run: dart test test/frost/frost_ed25519_rfc9591_test.dart

import 'package:blockchain_utils/api/api/api.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/fields.dart';
import 'package:blockchain_utils/crypto/crypto/keys/types/types.dart';
import 'package:blockchain_utils/utils/numbers/fixed/src/u64/u64.dart';
import 'package:test/test.dart';

import '../../utils.dart';
import 'package:blockchain_utils/crypto/crypto/group/edwards_limb/points.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/frost_ed25519.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/frost/engine/types.dart';

const edEngine = FrostEd25519();

bool _backendEd25519Verify({
  required List<int> message,
  required List<int> signature,
  required List<int> publicKey,
}) {
  try {
    return blockchainUtils.api.signing.ed25519.verify(
      message: message,
      signature: signature,
      publicKey: publicKey,
      type: CryptoKeyType.ed25519,
    );
  } catch (_) {
    return false;
  }
}

void main() {
  BlockchainUtilsTestApi.runTest(() {
    const messageHex = '74657374'; // "test"
    const groupSecretHex =
        '7b1c33d3f5291d85de664833beb1ad469f7fb6025a0ec78b3a7'
        '90c6e13a98304';
    const groupPublicHex =
        '15d21ccd7ee42959562fc8aa63224c8851fb3ec85a3faf66040'
        'd380fb9738673';
    const coeff1Hex =
        '178199860edd8c62f5212ee91eff1295d0d'
        '670ab4ed4506866bae57e7030b204';
    const p1ShareHex =
        '929dcc590407aae7d388761cddb0c0db6f5627aea8e217f'
        '4a033f2ec83d93509';
    const p3ShareHex =
        'd3cb090a075eb154e82fdb4b3cb507f110040905468bb9c'
        '46da8bdea643a9a02';

    const p1HidingRandHex =
        '0fd2e39e111cdc266f6c0f4d0fd45c947761f1f5d'
        '3cb583dfcb9bbaf8d4c9fec';
    const p1BindingRandHex =
        '69cd85f631d5f7f2721ed5e40519b1366f340a87'
        'c2f6856363dbdcda348a7501';
    const p1HidingNonceHex =
        '812d6104142944d5a55924de6d49940956206909f2acaeedecda'
        '2b726e630407';
    const p1BindingNonceHex =
        'b1110165fc2334149750b28dd813a39244f315cff14d4e89e61'
        '42f262ed83301';
    const p1HidingCommHex =
        'b5aa8ab305882a6fc69cbee9327e5a45e54c08af6'
        '1ae77cb8207be3d2ce13de3';
    const p1BindingCommHex =
        '67e98ab55aa310c3120418e5050c9cf76cf387cb'
        '20ac9e4b6fdb6f82a469f932';
    const p1FactorInputHex =
        '15d21ccd7ee42959562fc8aa63224c8851fb3ec85a3f'
        'af66040d380fb9738673504df914fa965023fb75c25ded4bb260f417de6d32e5c442c'
        '6ba313791cc9a4948d6273e8d3511f93348ea7a708a9b862bc73ba2a79cfdfe07729a'
        '193751cbc973af46d8ac3440e518d4ce440a0e7d4ad5f62ca8940f32de6d8dc00fc12'
        'c660b817d587d82f856d277ce6473cae6d2f5763f7da2e8b4d799a3f3e725d4522ec7'
        '0100000000000000000000000000000000000000000000000000000000000000';
    const p1FactorHex =
        'f2cb9d7dd9beff688da6fcc83fa89046b3479417f47f55600b'
        '106760eb3b5603';

    const p3HidingRandHex =
        '86d64a260059e495d0fb4fcc17ea3da7452391baa'
        '494d4b00321098ed2a0062f';
    const p3BindingRandHex =
        '13e6b25afb2eba51716a9a7d44130c0dbae0004a'
        '9ef8d7b5550c8a0e07c61775';
    const p3HidingNonceHex =
        'c256de65476204095ebdc01bd11dc10e57b36bc96284595b8215'
        '222374f99c0e';
    const p3BindingNonceHex =
        '243d71944d929063bc51205714ae3c2218bd3451d0214dfb5ae'
        'ec2a90c35180d';
    const p3HidingCommHex =
        'cfbdb165bd8aad6eb79deb8d287bcc0ab6658ae57'
        'fdcc98ed12c0669e90aec91';
    const p3BindingCommHex =
        '7487bc41a6e712eea2f2af24681b58b1cf1da278'
        'ea11fe4e8b78398965f13552';
    const p3FactorInputHex =
        '15d21ccd7ee42959562fc8aa63224c8851fb3ec85a3f'
        'af66040d380fb9738673504df914fa965023fb75c25ded4bb260f417de6d32e5c442c'
        '6ba313791cc9a4948d6273e8d3511f93348ea7a708a9b862bc73ba2a79cfdfe07729a'
        '193751cbc973af46d8ac3440e518d4ce440a0e7d4ad5f62ca8940f32de6d8dc00fc12'
        'c660b817d587d82f856d277ce6473cae6d2f5763f7da2e8b4d799a3f3e725d4522ec7'
        '0300000000000000000000000000000000000000000000000000000000000000';
    const p3FactorHex =
        'b087686bf35a13f3dc78e780a34b0fe8a77fef1b9938c563f5'
        '573d71d8d7890f';

    const p1ShareOutHex =
        '001719ab5a53ee1a12095cd088fd149702c0720ce5fd2f29dbecf24'
        'b7281b603';
    const p3ShareOutHex =
        'bd86125de990acc5e1f13781d8e32c03a9bbd4c53539bbc106058bf'
        'd14326007';
    const sigHex =
        '36282629c383bb820a88b71cae937d41f2f2adfcc3d02e55507e2fb9e2dd3cbe'
        'bd9d2b0844e49ae0f3fa935161e1419aab7b47d21a37ebeae1f17d4987b3160b';

    group('FROST(Ed25519,SHA-512) Appendix E.1', () {
      test('codecs match group key and shares', () {
        final sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(groupSecretHex),
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(sk)),
          groupSecretHex,
        );
        final pk = edEngine.deserializeElement(
          FrostEngineHex.decode(groupPublicHex),
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeElement(pk)),
          groupPublicHex,
        );
        expect(edEngine.scalarBaseMult(sk) == pk, isTrue);
        final coeff1 = edEngine.deserializeScalar(
          FrostEngineHex.decode(coeff1Hex),
        );
        final p1 = edEngine.deserializeScalar(
          FrostEngineHex.decode(p1ShareHex),
        );
        final p3 = edEngine.deserializeScalar(
          FrostEngineHex.decode(p3ShareHex),
        );
        expect(edEngine.polynomialEvaluate(Ed25519Fr.one, [sk, coeff1]), p1);
        expect(edEngine.polynomialEvaluate(Ed25519Fr.from(Uint64(3)), [sk, coeff1]), p3);
        expect(
          edEngine.secretShareCombine([
            FrostEngineShare(identifier: Ed25519Fr.one, secretShare: p1),
            FrostEngineShare(identifier: Ed25519Fr.from(Uint64(3)), secretShare: p3),
          ]),
          sk,
        );
      });

      test('round one nonces and commitments', () {
        final p1sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(p1ShareHex),
        );
        final p3sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(p3ShareHex),
        );
        final n1 = edEngine.commitWithRandomness(
          p1sk,
          FrostEngineHex.decode(p1HidingRandHex),
          FrostEngineHex.decode(p1BindingRandHex),
        );
        final n3 = edEngine.commitWithRandomness(
          p3sk,
          FrostEngineHex.decode(p3HidingRandHex),
          FrostEngineHex.decode(p3BindingRandHex),
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(n1.hidingNonce)),
          p1HidingNonceHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(n1.bindingNonce)),
          p1BindingNonceHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeElement(n1.hidingCommitment)),
          p1HidingCommHex,
        );
        expect(
          FrostEngineHex.encode(
            edEngine.serializeElement(n1.bindingCommitment),
          ),
          p1BindingCommHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(n3.hidingNonce)),
          p3HidingNonceHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(n3.bindingNonce)),
          p3BindingNonceHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeElement(n3.hidingCommitment)),
          p3HidingCommHex,
        );
        expect(
          FrostEngineHex.encode(
            edEngine.serializeElement(n3.bindingCommitment),
          ),
          p3BindingCommHex,
        );
      });

      test('binding factors, shares, aggregate signature', () {
        final msg = FrostEngineHex.decode(messageHex);
        final groupPk = edEngine.deserializeElement(
          FrostEngineHex.decode(groupPublicHex),
        );
        final p1sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(p1ShareHex),
        );
        final p3sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(p3ShareHex),
        );
        final n1 = edEngine.commitWithRandomness(
          p1sk,
          FrostEngineHex.decode(p1HidingRandHex),
          FrostEngineHex.decode(p1BindingRandHex),
        );
        final n3 = edEngine.commitWithRandomness(
          p3sk,
          FrostEngineHex.decode(p3HidingRandHex),
          FrostEngineHex.decode(p3BindingRandHex),
        );
        final commitments = [
          n1.commitment(1),
          n3.commitment(3),
        ];

        final encoded = edEngine.encodeGroupCommitmentList(commitments);
        final manualPrefix = [
          ...edEngine.serializeElement(groupPk),
          ...edEngine.h4(msg),
          ...edEngine.h5(encoded),
        ];
        expect(
          FrostEngineHex.encode([
            ...manualPrefix,
            ...edEngine.serializeScalar(Ed25519Fr.one),
          ]),
          p1FactorInputHex,
        );
        expect(
          FrostEngineHex.encode([
            ...manualPrefix,
            ...edEngine.serializeScalar(Ed25519Fr.from(Uint64(3))),
          ]),
          p3FactorInputHex,
        );

        final factors = edEngine.computeBindingFactors(
          groupPk,
          commitments,
          msg,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(factors[1]!)),
          p1FactorHex,
        );
        expect(
          FrostEngineHex.encode(
            edEngine.serializeScalar(factors[3]!),
          ),
          p3FactorHex,
        );

        final s1 = edEngine.sign(
          1,
          p1sk,
          groupPk,
          n1,
          msg,
          commitments,
        );
        final s3 = edEngine.sign(
          3,
          p3sk,
          groupPk,
          n3,
          msg,
          commitments,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(s1)),
          p1ShareOutHex,
        );
        expect(
          FrostEngineHex.encode(edEngine.serializeScalar(s3)),
          p3ShareOutHex,
        );

        final pk1 = edEngine.scalarBaseMult(p1sk);
        final pk3 = edEngine.scalarBaseMult(p3sk);
        expect(
          edEngine.verifyShare(
            1,
            pk1,
            commitments[0],
            s1,
            commitments,
            groupPk,
            msg,
          ),
          isTrue,
        );
        expect(
          edEngine.verifyShare(
            3,
            pk3,
            commitments[1],
            s3,
            commitments,
            groupPk,
            msg,
          ),
          isTrue,
        );
        expect(
          edEngine.verifyShare(
            1,
            pk1,
            commitments[0],
            (s1 + Ed25519Fr.one),
            commitments,
            groupPk,
            msg,
          ),
          isFalse,
        );

        final (r, z) = edEngine.aggregate(commitments, msg, groupPk, [s1, s3]);
        expect(FrostEngineHex.encode(edEngine.encodeSignature(r, z)), sigHex);
        expect(edEngine.verifySignature(r, z, groupPk, msg), isTrue);
        expect(edEngine.verifySignature(r, z, groupPk, [0x00]), isFalse);
        expect(
          _backendEd25519Verify(
            message: msg,
            signature: edEngine.encodeSignature(r, z),
            publicKey: edEngine.serializeElement(groupPk),
          ),
          isTrue,
        );
      });

      test('VSS round-trip and dealer group info', () {
        final sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(groupSecretHex),
        );
        final coeff1 = edEngine.deserializeScalar(
          FrostEngineHex.decode(coeff1Hex),
        );
        final shard = edEngine.secretShareShard(sk, [coeff1], 3);
        expect(shard.shares.length, 3);
        expect(
          FrostEngineHex.encode(
            edEngine.serializeScalar(shard.shares[0].secretShare),
          ),
          p1ShareHex,
        );
        final commitment = edEngine.vssCommit(shard.coeffs);
        for (final s in shard.shares) {
          expect(edEngine.vssVerify(s, commitment), isTrue);
        }
        final (groupPk, pks) = edEngine.deriveGroupInfo(3, commitment);
        expect(
          FrostEngineHex.encode(edEngine.serializeElement(groupPk)),
          groupPublicHex,
        );
        expect(
          pks[0] == edEngine.scalarBaseMult(shard.shares[0].secretShare),
          isTrue,
        );
      });

      test('invalid inputs abort', () {
        expect(
          () => edEngine.deserializeScalar(List.filled(32, 0xff)),
          throwsA(anything),
        );
        expect(
          () => edEngine.deserializeElement(List.filled(32, 0)),
          throwsA(anything),
        );
        expect(
          () => edEngine.serializeElement(EdwardsLimbPoint.identity_),
          throwsA(anything),
        );
        expect(
          () => edEngine.deriveInterpolatingValue([1, 1], 1),
          throwsA(anything),
        );
        expect(
          () => edEngine.bindingFactorFor({1: Ed25519Fr.one}, 2),
          throwsA(anything),
        );
      });

      test('fresh random signing session verifies', () {
        final sk = edEngine.deserializeScalar(
          FrostEngineHex.decode(
            '0100000000000000000000000000000000000000000000000000000000000000',
          ),
        );
        final c = edEngine.h1([1, 2, 3]);
        final shard = edEngine.secretShareShard(sk, [c], 3);
        final commitment = edEngine.vssCommit(shard.coeffs);
        final (groupPk, _) = edEngine.deriveGroupInfo(3, commitment);
        const msg = [104, 101, 108, 108, 111];
        final n1 = edEngine.commit(shard.shares[0].secretShare);
        final n2 = edEngine.commit(shard.shares[1].secretShare);
        final coms = [n1.commitment(1), n2.commitment(2)];
        final s1 = edEngine.sign(
          1,
          shard.shares[0].secretShare,
          groupPk,
          n1,
          msg,
          coms,
        );
        final s2 = edEngine.sign(
          2,
          shard.shares[1].secretShare,
          groupPk,
          n2,
          msg,
          coms,
        );
        final (r, z) = edEngine.aggregate(coms, msg, groupPk, [s1, s2]);
        expect(edEngine.verifySignature(r, z, groupPk, msg), isTrue);
        expect(
          _backendEd25519Verify(
            message: msg,
            signature: edEngine.encodeSignature(r, z),
            publicKey: edEngine.serializeElement(groupPk),
          ),
          isTrue,
        );
      });
    });
  }, 'frost_ed25519_rfc9591');
}
