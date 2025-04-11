import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

void main() {
  _tests();
}

void _tests() {
  group("BIP340", () {
    test("sign/verify", () {
      final digest = BytesUtils.fromHexString(
          "0000000000000000000000000000000000000000000000000000000000000000");
      final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(
          BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000003"));
      final btcSigner = BitcoinKeySigner.fromKeyBytes(privateKey.raw);
      final sig = btcSigner.signBip340(
          digest: digest,
          aux: BytesUtils.fromHexString(
              "0000000000000000000000000000000000000000000000000000000000000000"));
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
      expect(
          sig,
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
      expect(
          sig,
          BytesUtils.fromHexString(
              "7EB0509757E246F19449885651611CB965ECC1A187DD51B64FDA1EDC9637D5EC97582B9CB13DB3933705B32BA982AF5AF25FD78881EBB32771FC5922EFC66EA3"));
    });

    test("sign/verify with tap tweak", () {
      final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(
          BytesUtils.fromHexString(
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
    final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(
        BytesUtils.fromHexString(
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
    final privateKey = Secp256k1PrivateKeyEcdsa.fromBytes(
        BytesUtils.fromHexString(
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
