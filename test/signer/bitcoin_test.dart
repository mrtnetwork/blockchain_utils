import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

void main() {
  _legacySchnorr();
  _der();
  _tests();
}

void _legacySchnorr() {
  group("legacy schnorr", () {
    test("sign/verify", () {
      final signature = BytesUtils.fromHexString(
          "de00f0d9424152d5b0e4417d2b2843f7e5fed3b4e6d29d4189fafefb390ea7ca7a2c0e1d6bdbcff16f14e081d8e22162a46c494d04e32b6ab367f5823dacc320");
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "e16bd99298dc05e07f0f0821947efe10e288c3cf426f465357bec6315328d03b"));

      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final digest = BytesUtils.fromHexString(
          "819f570ca2b0d7569c01825b4588434bd728d24cc1cbe6658475d3884865ac88");
      final sign = btcSigner.signSchnorr(digest);
      final signConst = btcSigner.signSchnorrConst(digest);
      expect(signConst, signature);
      expect(sign, signature);
    });
    test("sign/verify 2", () {
      final signature = BytesUtils.fromHexString(
          "db4ce4fb0f12a20cd8db1096c1dd6e3884b66250cd7bcc32410afa0a5fcaddbdcda886de225e567f55099606bffbe4d070302ec6ea20f65282ab632cc716c39e");
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "e08d8207e60b7a145a38362cac13ff133854cecdfb49c33a48a1ec31ce7f3eff"));

      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final digest = BytesUtils.fromHexString(
          "96df91ea13303feb1754f2b1e53a840e5897ea1a9a24756f1ee934eb8570a8d5");
      final sign = btcSigner.signSchnorr(digest);
      final signConst = btcSigner.signSchnorrConst(digest);
      expect(signConst, signature);
      expect(sign, signature);
    });
  });
}

void _der() {
  group("ECDSA DER", () {
    test("sign/verify r bytes 31", () {
      final signature = BytesUtils.fromHexString(
          "3043021f7da924dfdcd2b34092cd46c49c0c30e33e69abad3278adf8e757b5f9fec36e02206e480592bb0b23384e97ef64309cc48ea21611038834f2c0278e048fde61580b");
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "02cd0537757280e3480f433931dea6457aafa2db7642401522760ed2b3edf4cb"));
      final entropy = BytesUtils.fromHexString(
          "0000000000000000000000000000000000000000000000000000000000000070");
      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final digest = BytesUtils.fromHexString(
          "d34ff82ed41227bb0e8b3c0a466c699107f7c5658371779ffdb9bf69e65f1967");
      final sign = btcSigner.signECDSADer(digest, extraEntropy: entropy);
      final signConst =
          btcSigner.signECDSADerConst(digest, extraEntropy: entropy);
      expect(signConst, signature);
      expect(sign, signature);
    });

    test("sign/verify s bytes 31", () {
      final signature = BytesUtils.fromHexString(
          "304302206dea19e91bbe5d0714b3c09f644829fdb0e6dd5bd5261543f1a2f573cec8bea0021f7e455ddd636ca49159827fc3f5d943ccbaa3464605746ad7b164a1c7d03f16");
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "02cd0537757280e3480f433931dea6457aafa2db7642401522760ed2b3edf4cb"));
      final entropy = BytesUtils.fromHexString(
          "0000000000000000000000000000000000000000000000000000000000000075");
      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final digest = BytesUtils.fromHexString(
          "d34ff82ed41227bb0e8b3c0a466c699107f7c5658371779ffdb9bf69e65f1967");
      final sign = btcSigner.signECDSADer(digest, extraEntropy: entropy);
      final signConst =
          btcSigner.signECDSADerConst(digest, extraEntropy: entropy);
      expect(signConst, signature);
      expect(sign, signature);
    });
  });
}

void _tests() {
  group("BIP340", () {
    test("sign/verify", () {
      final digest = BytesUtils.fromHexString(
          "0000000000000000000000000000000000000000000000000000000000000000");
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "0000000000000000000000000000000000000000000000000000000000000003"));
      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final sig = btcSigner.signBip340(
          digest: digest,
          aux: BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000000"));
      final sigConst = btcSigner.signBip340Const(
          digest: digest,
          aux: BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000000"));
      expect(
          sigConst,
          BytesUtils.fromHexString(
              "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0"));

      expect(
          sig,
          BytesUtils.fromHexString(
              "E907831F80848D1069A5371B402410364BDF1C5F8307B0084C55F1CE2DCA821525F66A4A85EA8B71E482A74F382D2CE5EBEEE8FDB2172F477DF4900D310536C0"));

      final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(
          privateKey.publicKey.compressed);
      final verify =
          verifyKey.verifyBip340Signature(digest: digest, signature: sig);
      expect(verify, true);
    });
    test("sign/verify", () {
      final btcSigner = BitcoinKeySigner.fromKeyBytes(BytesUtils.fromHexString(
          "B7E151628AED2A6ABF7158809CF4F3C762E7160F38B4DA56A784D9045190CFEF"));
      final sig = btcSigner.signBip340(
          digest: BytesUtils.fromHexString(
              "243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89"),
          aux: BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000001"));
      final sigConst = btcSigner.signBip340Const(
          digest: BytesUtils.fromHexString(
              "243F6A8885A308D313198A2E03707344A4093822299F31D0082EFA98EC4E6C89"),
          aux: BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000001"));
      expect(
          sig,
          BytesUtils.fromHexString(
              "6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A"));
      expect(
          sigConst,
          BytesUtils.fromHexString(
              "6896BD60EEAE296DB48A229FF71DFE071BDE413E6D43F917DC8DCF8C78DE33418906D11AC976ABCCB20B091292BFF4EA897EFCB639EA871CFA95F6DE339E4B0A"));
    });
    test("sign/verify", () {
      final btcSigner = BitcoinKeySigner.fromKeyBytes(BytesUtils.fromHexString(
          "C90FDAA22168C234C4C6628B80DC1CD129024E088A67CC74020BBEA63B14E5C9"));
      final sig = btcSigner.signBip340(
          digest: BytesUtils.fromHexString(
              "7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C"),
          aux: BytesUtils.fromHexString(
              "C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906"));
      final sigConst = btcSigner.signBip340Const(
          digest: BytesUtils.fromHexString(
              "7E2D58D8B3BCDF1ABADEC7829054F90DDA9805AAB56C77333024B9D0A508B75C"),
          aux: BytesUtils.fromHexString(
              "C87AA53824B4D7AE2EB035A2B5BBBCCC080E76CDC6D1692C4B0B62D798E6D906"));
      expect(
          sigConst,
          BytesUtils.fromHexString(
              "5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7"));

      expect(
          sig,
          BytesUtils.fromHexString(
              "5831AAEED7B44BB74E5EAB94BA9D4294C49BCF2A60728D8B4C200F50DD313C1BAB745879A5AD954A72C45A91C3A51D3C7ADEA98D82F8481E0E1E03674A6F3FB7"));
    });
    test("sign/verify", () {
      final btcSigner = BitcoinKeySigner.fromKeyBytes(BytesUtils.fromHexString(
          "0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710"));
      final sig = btcSigner.signBip340(
          digest: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
          aux: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
      final sigConst = btcSigner.signBip340Const(
          digest: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
          aux: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"));
      expect(
          sigConst,
          BytesUtils.fromHexString(
              "7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3"));

      expect(
          sig,
          BytesUtils.fromHexString(
              "7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3"));
    });

    test("sign/verify with tap tweak", () {
      final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
          "0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710"));
      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final digest = BytesUtils.fromHexString(
          "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");
      final merkleRoot = BitcoinSignerUtils.calculatePrivateTweek(
          privateKey.raw, List<int>.filled(32, 12));
      final sig = btcSigner.signBip340(
          digest: digest,
          aux: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
          tapTweakHash: merkleRoot);
      final sigConst = btcSigner.signBip340(
          digest: digest,
          aux: BytesUtils.fromHexString(
              "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
          tapTweakHash: merkleRoot);

      expect(
          sigConst,
          BytesUtils.fromHexString(
              "c88bdc629973e5dded442c76c1b9cdcb8554bc7dd13f0a07393cc21bbffa18088d25a95724cae28fabc76c49fb5555af6a15755f577e307ed6e8f943c57eee77"));

      expect(
          sig,
          BytesUtils.fromHexString(
              "c88bdc629973e5dded442c76c1b9cdcb8554bc7dd13f0a07393cc21bbffa18088d25a95724cae28fabc76c49fb5555af6a15755f577e307ed6e8f943c57eee77"));

      final verifyKey = BitcoinSignatureVerifier.fromKeyBytes(
          privateKey.publicKey.compressed);
      final verify = verifyKey.verifyBip340Signature(
          digest: digest, signature: sig, tapTweakHash: merkleRoot);
      expect(verify, true);
    });
  });

  test("invalid private key", () {
    expect(
        () => BitcoinKeySigner.fromKeyBytes(List<int>.filled(32, 0)),
        throwsA(isA<CryptoSignException>().having((e) => e.message,
            'error message', contains('Invalid secp256k1 private key'))));
  });

  test("invalid tap tweak", () {
    final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
        "0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710"));
    final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
    final digest = BytesUtils.fromHexString(
        "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF");

    expect(
        () => btcSigner.signBip340(
            digest: digest,
            aux: BytesUtils.fromHexString(
                "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF"),
            tapTweakHash: List<int>.filled(33, 12)),
        throwsA(isA<CryptoSignException>().having(
            (e) => e.message,
            'error message',
            contains('The tap tweak hash must be 32-byte array'))));
  });

  test("invalid digest length", () {
    final privateKey = Secp256k1PrivateKey.fromBytes(BytesUtils.fromHexString(
        "0B432B2677937381AEF05BB02A66ECD012773062CF3FA2549E44F58ED2401710"));
    final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
    final digest = List<int>.filled(33, 12);

    expect(
        () => btcSigner.signBip340(
            digest: digest,
            aux: BytesUtils.fromHexString(
                "FFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF")),
        throwsA(isA<CryptoSignException>().having((e) => e.message,
            'error message', contains('The digest must be a'))));
  });
}
