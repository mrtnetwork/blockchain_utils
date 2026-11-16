import 'package:blockchain_utils/blockchain_utils.dart';
import '../../utils.dart';

void main() {
  BlockchainUtilsTestApi.runTest(() {
    final r = List<int>.filled(32, 12);
    final kk = Secp256r1Signer.fromKeyBytes(r);
    final ss = kk.sign(List<int>.filled(32, 13), hashMessage: false);
    print("ss ${ss.encoded.toHex()}");

    /// 90cfad06808f997dd2d35ba32b00545dcd5ac186e306a4ddc485b89ecb2eac742dd27c89259810ae4a5f5d2f8f2b5b664dd35a79b051d5833d91ea2a33cf9b38
    for (int i = 0; i < 10; i++) {
      final keyBytes = QuickCrypto.generateRandom();
      final g = Secp256r1PrivateKey.fromBytes(keyBytes);

      final digest = QuickCrypto.generateRandom().asImmutableBytes;
      final ext = QuickCrypto.generateRandom().asImmutableBytes;
      final sParams = Secp256r1SigningParams(digest: digest, extraEntropy: ext);
      final signature = g.sign(sParams);
      final verify = g.verificationKey().verify(
        Secp256r1VerifyingParams(sParams, signature),
      );
      assert(verify, BytesUtils.toHexString(digest));
      final dart = DartSecp256r1SigningApi();
      final s2 = dart.sign(
        sk: g.takeSecretKey(),
        publicKey: g.publicKey.keyBytes,
        digest: digest,

        extraEntropy: ext,
      );
      assert(
        dart.verify(
          digest: digest,
          signature: signature,
          publicKey: g.publicKey.keyBytes,
        ),
      );

      print("equal ${s2 == signature}");
      if (s2 != signature) {
        print("privateKey ${g.takeSecretKey().toHex()}");
        print("digest ${BytesUtils.toHexString(digest)}");
        print("dart signature ${s2.toBytes().toHex()}");
        print("rust signature ${signature.toBytes().toHex()}");
      }
    }
    // print("vr $verify ${signature.recoveryId}");
  }, 'test');
}
