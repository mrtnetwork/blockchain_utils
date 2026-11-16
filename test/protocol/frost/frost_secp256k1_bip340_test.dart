// Review tests for RFC 9591 FROST(secp256k1, SHA-256), Appendix E.5.
//
// Run: dart test test/frost/frost_secp256k1_bip340_test.dart

import 'package:test/test.dart';

import '../../utils.dart';
import 'package:blockchain_utils/blockchain_utils.dart';

const k1Engine = FrostSecp256k1();

void main() {
  BlockchainUtilsTestApi.runTest(() {
    group('FROST(secp256k1,SHA-256) Appendix E.5', () {
      // -- E.5 configuration -------------------------------------------
      const signerIds = [1, 3];
      const groupSecretHex =
          '0d004150d27c3bf2a42f312683d35fac7394b1e9e318249c1bf'
          'e7f0795a83114';
      const groupPublicHex =
          '02f37c34b66ced1fb51c34a90bdae006901f10625cc06c4f646'
          '63b0eae87d87b4f';
      const messageHex = '74657374'; // "test"
      const coeffHex =
          'fbf85eadae3058ea14f19148bb72b45e439'
          '9c0b16028acaf0395c9b03c823579';
      const sharesHex = {
        1:
            '08f89ffe80ac94dcb920c26f3f46140bfc7f95b493f8310'
            'f5fc1ea2b01f4254c',
        2:
            '04f0feac2edcedc6ce1253b7fab8c86b856a797f44d83d8'
            '2a385554e6e401984',
        3:
            '00e95d59dd0d46b0e303e500b62b7ccb0e555d49f5b849f'
            '5e748c071da8c0dbc',
      };
      const nonceRandomnessHex = {
        1: (
          '7ea5ed09af19f6ff21040c07ec2d2adbd35b759da'
              '5a401d4c99dd26b82391cb2',
          '47acab018f116020c10cb9b9abdc7ac10aae1b48'
              'ca6e36dc15acb6ec9be5cdc5',
        ),
        3: (
          'e6cc56ccbd0502b3f6f831d91e2ebd01c4de0479e'
              '0191b66895a4ffd9b68d544',
          '7203d55eb82a5ca0d7d83674541ab55f6e76f1b8'
              '5391d2c13706a89a064fd5b9',
        ),
      };
      const nonceHex = {
        1: (
          '841d3a6450d7580b4da83c8e618414d0f024391f2aeb511d7579'
              '224420aa81f0',
          '8d2624f532af631377f33cf44b5ac5f849067cae2eacb88680a'
              '31e77c79b5a80',
        ),
        3: (
          '2b19b13f193f4ce83a399362a90cdc1e0ddcd83e57089a7af0bd'
              'ca71d47869b2',
          '7a443bde83dc63ef52dda354005225ba0e553243402a4705ce2'
              '8ffaafe0f5b98',
        ),
      };
      const commitmentsHex = {
        1: (
          '03c699af97d26bb4d3f05232ec5e1938c12f1e6ae'
              '97643c8f8f11c9820303f1904',
          '02fa2aaccd51b948c9dc1a325d77226e98a5a3fe'
              '65fe9ba213761a60123040a45e',
        ),
        3: (
          '03077507ba327fc074d2793955ef3410ee3f03b82'
              'b4cdc2370f71d865beb926ef6',
          '02ad53031ddfbbacfc5fbda3d3b0c2445c8e3e99'
              'cbc4ca2db2aa283fa68525b135',
        ),
      };
      const bindingFactorsHex = {
        1:
            '3e08fe561e075c653cbfd46908a10e7637c70c74f0a77d5fd4'
            '5d1a750c739ec6',
        3:
            '93f79041bb3fd266105be251adaeb5fd7f8b104fb554a4ba9a'
            '0becea48ddbfd7',
      };
      const sigSharesHex = {
        1:
            'c4fce1775a1e141fb579944166eab0d65eefe7b98d480a569bbbfcb'
            '14f91c197',
        3:
            '0160fd0d388932f4826d2ebcd6b9eaba734f7c71cf25b4279a4ca25'
            '81e47b18d',
      };
      const sigHex =
          '0205b6d04d3774c8929413e3c76024d54149c372d57aae62574ed74319b5ea14'
          'd0c65dde8492a7471437e6c2fe3da49b90d23f642b5c6dbe7e36089f096dd97324';

      Secp256k1Fr scalar(String hex) =>
          k1Engine.deserializeScalar(FrostEngineHex.decode(hex));
      Secp256k1Fr idFr(int id) =>
          k1Engine.deserializeScalar(List<int>.filled(32, 0)..[31] = id);

      test('dealer shares match vectors', () {
        final secret = scalar(groupSecretHex);
        final coeff = scalar(coeffHex);
        for (final entry in sharesHex.entries) {
          final id = entry.key;
          expect(
            k1Engine.polynomialEvaluate(idFr(id), [secret, coeff]),
            scalar(entry.value),
          );
        }
        // Group public key from secret.
        final pk = k1Engine.scalarBaseMult(secret);
        expect(
          FrostEngineHex.encode(k1Engine.serializeElement(pk)),
          groupPublicHex,
        );
        // Combine P1+P3 recovers the secret.
        expect(
          k1Engine.secretShareCombine([
            FrostEngineShare(
              identifier: idFr(1),
              secretShare: scalar(sharesHex[1]!),
            ),
            FrostEngineShare(
              identifier: idFr(3),
              secretShare: scalar(sharesHex[3]!),
            ),
          ]),
          secret,
        );
      });

      FrostEngineNonces<Secp256k1Point, Secp256k1Fr> nonces(int id) {
        final share = scalar(sharesHex[id]!);
        final (hidingRand, bindingRand) = nonceRandomnessHex[id]!;
        final pair = k1Engine.commitWithRandomness(
          share,
          FrostEngineHex.decode(hidingRand),
          FrostEngineHex.decode(bindingRand),
        );
        final (hidingHex, bindingHex) = nonceHex[id]!;
        expect(
          FrostEngineHex.encode(k1Engine.serializeScalar(pair.hidingNonce)),
          hidingHex,
        );
        expect(
          FrostEngineHex.encode(k1Engine.serializeScalar(pair.bindingNonce)),
          bindingHex,
        );
        final (hidingComHex, bindingComHex) = commitmentsHex[id]!;
        expect(
          FrostEngineHex.encode(
            k1Engine.serializeElement(pair.hidingCommitment),
          ),
          hidingComHex,
        );
        expect(
          FrostEngineHex.encode(
            k1Engine.serializeElement(pair.bindingCommitment),
          ),
          bindingComHex,
        );
        return pair;
      }

      List<FrostEngineCommitment<Secp256k1Point>> commitmentList(
        Map<int, FrostEngineNonces<Secp256k1Point, Secp256k1Fr>> ps,
      ) {
        return signerIds.map((id) => ps[id]!.commitment(id)).toList();
      }

      test('round 1 + binding factors match vectors', () {
        final ps = {for (final id in signerIds) id: nonces(id)};
        final groupPk = k1Engine.deserializeElement(
          FrostEngineHex.decode(groupPublicHex),
        );
        final msg = FrostEngineHex.decode(messageHex);
        final list = commitmentList(ps);
        final factors = k1Engine.computeBindingFactors(groupPk, list, msg);
        for (final id in signerIds) {
          expect(
            FrostEngineHex.encode(
              k1Engine.serializeScalar(factors[id]!),
            ),
            bindingFactorsHex[id],
          );
        }
      });

      test('round 2 + aggregate match vectors', () {
        final ps = {for (final id in signerIds) id: nonces(id)};
        final groupPk = k1Engine.deserializeElement(
          FrostEngineHex.decode(groupPublicHex),
        );
        final msg = FrostEngineHex.decode(messageHex);
        final list = commitmentList(ps);
        final sharesOut = <Secp256k1Fr>[];
        for (final id in signerIds) {
          final share = k1Engine.sign(
            id,
            scalar(sharesHex[id]!),
            groupPk,
            ps[id]!,
            msg,
            list,
          );
          expect(
            FrostEngineHex.encode(k1Engine.serializeScalar(share)),
            sigSharesHex[id],
          );
          sharesOut.add(share);
        }
        final (groupCommitment, z) = k1Engine.aggregate(
          list,
          msg,
          groupPk,
          sharesOut,
        );
        final sig = k1Engine.encodeSignature(groupCommitment, z);
        expect(FrostEngineHex.encode(sig), sigHex);
        expect(
          k1Engine.verifySignature(groupCommitment, z, groupPk, msg),
          isTrue,
        );
        final (r, zz) = k1Engine.decodeSignature(sig);
        expect(r, groupCommitment);
        expect(zz, z);
      });

      test('share verification catches tampering', () {
        final ps = {for (final id in signerIds) id: nonces(id)};
        final groupPk = k1Engine.deserializeElement(
          FrostEngineHex.decode(groupPublicHex),
        );
        final msg = FrostEngineHex.decode(messageHex);
        final list = commitmentList(ps);
        final pks = {
          for (final id in signerIds)
            id: k1Engine.scalarBaseMult(scalar(sharesHex[id]!)),
        };
        for (final id in signerIds) {
          final share = k1Engine.sign(
            id,
            scalar(sharesHex[id]!),
            groupPk,
            ps[id]!,
            msg,
            list,
          );
          expect(
            k1Engine.verifyShare(
              id,
              pks[id]!,
              list.firstWhere((c) => c.id == id),
              share,
              list,
              groupPk,
              msg,
            ),
            isTrue,
          );
          expect(
            k1Engine.verifyShare(
              id,
              pks[id]!,
              list.firstWhere((c) => c.id == id),
              share + Secp256k1Fr.one,
              list,
              groupPk,
              msg,
            ),
            isFalse,
          );
        }
      });
    });
  }, 'frost_secp256k1');
}
