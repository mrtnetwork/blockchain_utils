import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';
import '../quick_hex.dart';
import 'vrf_test_vector.dart' as vrf_test;

void main() {
  test("schnorrkel vrf test", () {
    for (int i = 0; i < 100; i++) {
      final rand = QuickCrypto.generateRandom(32);
      final message = QuickCrypto.generateRandom(32);
      final signingContext = QuickCrypto.generateRandom(32);
      final miniSecretKey = SchnorrkelMiniSecretKey.fromBytes(rand);
      final secret = miniSecretKey.toSecretKey();
      final script = MerlinTranscript("SigningContext");
      script.additionalData("".codeUnits, signingContext);
      script.additionalData("sign-bytes".codeUnits, message);
      final vrfout = secret.vrfSign(script);

      final VRFProof vrproof = vrfout.item2;
      final verifyScript = MerlinTranscript("SigningContext");
      verifyScript.additionalData("".codeUnits, signingContext);
      verifyScript.additionalData("sign-bytes".codeUnits, message);
      expect(
          secret
              .publicKey()
              .vrfVerify(verifyScript, vrfout.item1.toVRFPreOut(), vrproof),
          true);
    }
  });

  test("schnorrkel vrf sign", () {
    /// test vrf sign
    /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
    for (final i in vrf_test.testVrfSign) {
      final keyPair =
          SchnorrkelKeypair.fromBytes(BytesUtils.fromHexString(i["keypair"]));
      final script = MerlinTranscript("SigningContext");
      script.additionalData("".codeUnits, "yo!".codeUnits);
      script.additionalData("sign-bytes".codeUnits, "meow".codeUnits);
      final vrfout = keyPair.secretKey().vrfSign(script).item1;

      expect(vrfout.input.toHex().toUpperCase(), i["input"]);
      expect(vrfout.output.toHex().toUpperCase(), i["output"]);
    }
  });

  test("schnorrkel vrf verify", () {
    /// test vrf verify
    /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
    for (final i in vrf_test.testVector) {
      final keyPair =
          SchnorrkelKeypair.fromBytes(BytesUtils.fromHexString(i["keypair"]));
      final public = keyPair.secretKey().publicKey();
      final output = VRFPreOut(BytesUtils.fromHexString(i["out"]));
      final proof = VRFProof.fromBytes(BytesUtils.fromHexString(i["proof"]));
      final script = MerlinTranscript("SigningContext");
      script.additionalData("".codeUnits, "yo!".codeUnits);
      script.additionalData("sign-bytes".codeUnits, "meow".codeUnits);
      final verify = public.vrfVerify(script, output, proof);
      expect(verify, true);
    }
  });
}
