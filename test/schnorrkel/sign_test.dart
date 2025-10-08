import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/merlin/transcript.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

// import '../quick_hex.dart';
import 'sign_test_vector.dart';

void main() {
  test("schnorrkel sign ", () {
    for (final i in signTestVector) {
      final mini = SchnorrkelMiniSecretKey.fromBytes(
          BytesUtils.fromHexString(i["seed"]!));
      final secretKey = mini.toSecretKey();
      final pubkey = secretKey.publicKey();

      final message = BytesUtils.fromHexString(i["message"]!);
      final signingScript = MerlinTranscript("SigningContext");
      signingScript.additionalData("".codeUnits, "substrate".codeUnits);
      signingScript.additionalData("sign-bytes".codeUnits, message);
      final clone = signingScript.clone();
      final sign = secretKey.sign(
        signingScript,

        /// Be sure to use a secure random generator for nonce,
        /// i provide nonce here only for validate signature.
        ///
        /// You can remove this line in production and the
        /// method automatically generates a Random nonce by Fortuna `QuickCrypto.generateRandom`
        nonceGenerator: (length) {
          /// return QuickCrypto.generateRandom(length);
          return BytesUtils.fromHexString(i["random_nonce"]!);
        },
      );
      expect(BytesUtils.toHexString(sign.toBytes()), i["signature"]);
      expect(pubkey.verify(sign, clone), true);
    }
  });
}
