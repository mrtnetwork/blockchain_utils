import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:test/test.dart';

//

import 'sign_test_vector.dart';

import '../../utils.dart';

void signTest() {
  test("schnorrkel sign ", () {
    for (final i in signTestVector.shuffleTake()) {
      final mini = SchnorrkelMiniSecretKey(
        BytesUtils.fromHexString(i["seed"]!),
      );
      final secretKey = mini.toSecretKey();
      final pubkey = secretKey.publicKey;

      final message = BytesUtils.fromHexString(i["message"]!);
      // final signingScript = MerlinTranscript("SigningContext");
      // signingScript.additionalData("".codeUnits, "substrate".codeUnits);
      // signingScript.additionalData("sign-bytes".codeUnits, message);
      // final clone = signingScript.clone();
      final sign = secretKey.sign(
        SR25519SigningParams(
          message: message,
          context: "substrate".codeUnits,
          nonce: BytesUtils.fromHexString(i["random_nonce"]!),
        ),
      );
      expect(BytesUtils.toHexString(sign.toBytes()), i["signature"]);
      expect(
        pubkey.verify(
          SR25519VerifyingParams(
            signingParams: SR25519SigningParams(
              context: "substrate".codeUnits,
              message: message,
            ),
            signature: sign,
          ),
        ),
        true,
      );
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(signTest, "Sign");
}

// mult 548807a01b70f37d2b4a96d457e564e5a4d457243c9166fb0a3ea867d3b84adc
// k 70cb768ed0ce6ec45b97ac146ff5135aaa2f6788b08bb86aad0f4be58dd3f209
// scNonce: 96681fa2c226a07547e9a9f508cc93b6f7dfef0941e13ba11c2786fc53f69f04
