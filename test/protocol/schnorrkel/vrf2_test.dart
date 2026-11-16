import 'package:blockchain_utils/crypto/crypto/keys/sr25519/sr25519.dart';
import 'package:blockchain_utils/crypto/crypto/protocol/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'vrf_test_vector.dart';

import '../../utils.dart';

void vrf2Test() {
  test("schnorrkel vrf test", () {
    for (int i = 0; i < 10; i++) {
      final rand = QuickCrypto.generateRandom(length: 32);
      final message = QuickCrypto.generateRandom(length: 32);
      final signingContext = QuickCrypto.generateRandom(length: 32);
      final miniSecretKey = SchnorrkelMiniSecretKey(rand);
      final secret = miniSecretKey.toSecretKey();
      final signingParams = SR25519VrfSigningParams(
        context: signingContext,
        message: message,
      );
      final signature = secret.vrfSign(signingParams);
      final verifyScript = MerlinTranscript("SigningContext");
      verifyScript.additionalData("".codeUnits, signingContext);
      verifyScript.additionalData("sign-bytes".codeUnits, message);
      expect(
        secret.publicKey.vrfVerify(
          SR25519VRFVerifyingParams(
            signingParams: signingParams,
            signature: signature,
          ),
        ),
        true,
      );
    }
  });

  test("schnorrkel vrf sign", () {
    /// test vrf sign
    /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
    for (final i in testVrfSign) {
      final keyPair = SR25519Keypair.fromBytes(
        BytesUtils.fromHexString(i["keypair"]),
      );
      final script = MerlinTranscript("SigningContext");
      script.additionalData("".codeUnits, "yo!".codeUnits);
      script.additionalData("sign-bytes".codeUnits, "meow".codeUnits);
      final vrfout = keyPair.secretKey.vrfSign(
        SR25519VrfSigningParams(
          context: "yo!".codeUnits,
          message: "meow".codeUnits,
        ),
      );
      // return;
      expect(vrfout.output.toBytes().toHex().toUpperCase(), i["output"]);
    }
  });
  // return;
  test("schnorrkel vrf verify", () {
    /// test vrf verify
    /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
    for (final i in testVector.shuffleTake()) {
      final keyPair = SR25519Keypair.fromBytes(
        BytesUtils.fromHexString(i["keypair"]),
      );
      final public = keyPair.publicKey;
      final output = VRFPreOut(BytesUtils.fromHexString(i["out"]));
      final proof = VRFProof.fromBytes(BytesUtils.fromHexString(i["proof"]));
      final verify = public.vrfVerify(
        SR25519VRFVerifyingParams(
          signingParams: SR25519VrfSigningParams(
            context: "yo!".codeUnits,
            message: "meow".codeUnits,
          ),
          signature: SR25519VRFSignature(output: output, proof: proof),
        ),
      );
      expect(verify, true);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(vrf2Test, "Vrf2");
}
