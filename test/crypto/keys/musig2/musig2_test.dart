import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../../utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {
    test("MuSig2 keys", () {
      final keys = List.generate(3, (_) => Secp256k1PrivateKey.random());
      final key = Musig2PrivateKey.generate(keys, sortPubKeys: true);
      final toBytes = key.toBytes();
      final decode = Musig2PrivateKey.fromBytes(toBytes);
      expect(key.secretKeys, decode.secretKeys);
      expect(key.publicKey, decode.publicKey);
      final msg = QuickCrypto.generateRandom();
      final params = MuSig2GenerateSessionParams(
        message: msg.asImmutableBytes,
        nonceGenerationParams: MuSig2GenerateNoncesParams(
          aggPubKey: key.publicKey.point.toBytes(),
          sk: QuickCrypto.generateRandom(),
        ),
      );
      final signParams = key.generateSession(params);
      for (final i in signParams) {
        final signature = key.partialSign(i);
        final veryfy = key.publicKey.verify(
          MuSig2PartialVerifiyingParams(
            signature: signature,
            session: signParams[0].session,
          ),
        );
        expect(veryfy, isTrue);
      }

      final sign = key.sign(params);
      final verify = key.publicKey.verifyAggregate(
        MuSig2AggregateVerifiyingParams(
          signature: sign.aggSignature,
          message: params.message,
        ),
      );
      expect(verify, true);

      final pk = MuSig2AggregatePublicKey.fromBytes(key.publicKey.toBytes());
      expect(pk, key.publicKey);
      {
        final key2 = Musig2PrivateKey.generate(
          List.from(keys)..shuffle(),
          sortPubKeys: true,
        );
        expect(key2, key);
      }
    });
  }, "MuSig2 Keys");
}
