import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'nonce_vector.dart';

import '../../utils.dart';

void geneareNonceTest() {
  test("generate nonce", () {
    final musigConst = Musig2Const();
    for (final i in nonceVector.shuffleTake()) {
      final rand = BytesUtils.fromHexString(i["rand_"]!);
      final sk = BytesUtils.tryFromHexString(i["sk"]);
      final publicKey = BytesUtils.fromHexString(i["pk"]!);
      final aggpk = BytesUtils.tryFromHexString(i["aggpk"]);
      final msg = BytesUtils.tryFromHexString(i["msg"]);
      final extraIn = BytesUtils.tryFromHexString(i["extra_in"]);
      MuSig2Nonce nonce = musigConst.nonceGenerate(
        rand: rand,
        publicKey: publicKey,
        aggPubKey: aggpk ?? [],
        extra: extraIn,
        msg: msg,
        sk: sk,
      );
      expect(
        BytesUtils.toHexString(nonce.pubnonce, lowerCase: false),
        i["expected_pubnonce"],
      );
      expect(
        BytesUtils.toHexString(nonce.secnonce, lowerCase: false),
        i["expected_secnonce"],
      );
    }
  });
}

void nativeGenerateNonce(BlockchainUtilsApi api) {
  test("generate nonce api", () {
    final musig = api.muSig2;
    for (final i in nonceVector.shuffleTake()) {
      final rand = BytesUtils.fromHexString(i["rand_"]!);
      final sk = BytesUtils.tryFromHexString(i["sk"]);
      final publicKey = BytesUtils.fromHexString(i["pk"]!);
      final aggpk = BytesUtils.tryFromHexString(i["aggpk"]);
      final msg = BytesUtils.tryFromHexString(i["msg"]);
      final extraIn = BytesUtils.tryFromHexString(i["extra_in"]);
      MuSig2Nonce nonce = musig.nonceGenerate(
        rand: rand,
        publicKey: publicKey,
        aggPubKey: aggpk ?? [],
        extra: extraIn,
        msg: msg,
        sk: sk,
      );
      expect(
        BytesUtils.toHexString(nonce.pubnonce, lowerCase: false),
        i["expected_pubnonce"],
      );
      expect(
        BytesUtils.toHexString(nonce.secnonce, lowerCase: false),
        i["expected_secnonce"],
      );
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(
    geneareNonceTest,
    "Geneare Nonce",
    onNative: nativeGenerateNonce,
  );
}
