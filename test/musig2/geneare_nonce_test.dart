import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'nonce_vector.dart';

void main() {
  test("generate nonce", () {
    for (final i in nonceVector) {
      final rand = BytesUtils.fromHexString(i["rand_"]!);
      final sk = BytesUtils.tryFromHexString(i["sk"]);
      final publicKey = BytesUtils.fromHexString(i["pk"]!);
      final aggpk = BytesUtils.tryFromHexString(i["aggpk"]);
      final msg = BytesUtils.tryFromHexString(i["msg"]);
      final extraIn = BytesUtils.tryFromHexString(i["extra_in"]);
      final nonce = MuSig2.nonceGenerate(
          rand: rand,
          publicKey: publicKey,
          aggPubKey: aggpk ?? [],
          extra: extraIn,
          msg: msg,
          sk: sk);
      expect(BytesUtils.toHexString(nonce.pubnonce, lowerCase: false),
          i["expected_pubnonce"]);
      expect(BytesUtils.toHexString(nonce.secnonce, lowerCase: false),
          i["expected_secnonce"]);
    }
  });
}
