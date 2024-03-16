import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:blockchain_utils/crypto/crypto/schnorrkel/merlin/transcript.dart';
import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'vrf_test_vector.dart' as vrf_test;

void vrfSignTest() {
  /// sign and verify
  for (int i = 0; i < 5; i++) {
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
    assert(secret
        .publicKey()
        .vrfVerify(verifyScript, vrfout.item1.output, vrproof));
  }

  /// test vrf sign
  /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
  for (final i in vrf_test.testVrfSign) {
    final keyPair =
        SchnorrkelKeypair.fromBytes(BytesUtils.fromHexString(i["keypair"]));
    final script = MerlinTranscript("SigningContext");
    script.additionalData("".codeUnits, "yo!".codeUnits);
    script.additionalData("sign-bytes".codeUnits, "meow".codeUnits);
    final vrfout = keyPair.secretKey().vrfSign(script).item1;

    assert(vrfout.input.toHex().toUpperCase() == i["input"]);
    assert(vrfout.output.toHex().toUpperCase() == i["output"]);
  }

  /// test vrf verify
  /// https://github.com/noot/schnorrkel/blob/master/src/vrf.rs#L922
  for (final i in vrf_test.testVector) {
    final keyPair =
        SchnorrkelKeypair.fromBytes(BytesUtils.fromHexString(i["keypair"]));
    final public = keyPair.secretKey().publicKey();
    final output = BytesUtils.fromHexString(i["out"]);
    final proof = VRFProof.fromBytes(BytesUtils.fromHexString(i["proof"]));
    final script = MerlinTranscript("SigningContext");
    script.additionalData("".codeUnits, "yo!".codeUnits);
    script.additionalData("sign-bytes".codeUnits, "meow".codeUnits);
    final verify = public.vrfVerify(script, output, proof);
    assert(verify);
  }
}
