import 'dart:typed_data';

import 'package:blockchain_utils/blockchain_utils.dart';

import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void aesCtrCbcTest() {
  test("test aes ctr", () {
    for (final i in testVector.shuffleTake()) {
      final key = BytesUtils.fromHexString(i["key"]).asImmutableBytes;
      final iv = BytesUtils.fromHexString(i["iv"]).asImmutableBytes;

      final plainText =
          BytesUtils.fromHexString(i["plain_text"]).asImmutableBytes;
      final encrypt = BytesUtils.fromHexString(i["encrypt"]).asImmutableBytes;
      var ctr = QuickCrypto.aesCtrInstance(key.cloneBytes(), iv.cloneBytes());
      final encryptOut = Uint8List(plainText.length);
      ctr.process(plainText, encryptOut);
      ctr.clean();
      ctr = QuickCrypto.aesCtrInstance(key, iv);
      final decryptOut = Uint8List(encrypt.length);
      ctr.process(encrypt, decryptOut);
      expect(encryptOut.toHex(), encrypt.toHex());
      expect(decryptOut.toHex(), plainText.toHex());
    }
  });

  test("ECB", () {
    for (final i in ecbTestVector) {
      final algs = PaddingAlgorithm.values.firstWhereNullable(
        (e) => e.name == i.valueAs("type"),
      );
      final aes = QuickCrypto.aesEcbInstance(i.valueAsBytes("key"), padding: algs);
      final List<int> plain = i.valueAsBytes("plain");
      final encrypt = aes.encrypt(plain);
      expect(encrypt, i.valueAsBytes("enc"));
      final decypt = aes.decrypt(encrypt);
      expect(decypt, plain);
    }

    for (int i = 0; i < 10; i++) {
      final aes = QuickCrypto.aesEcbInstance(QuickCrypto.generateRandom(length: 32));
      final plain = QuickCrypto.generateRandom(length: i * 16);
      final enc = aes.encrypt(plain);
      final dec = aes.decrypt(enc);
      expect(dec, plain);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(aesCtrCbcTest, "Aes Ctr");
}
