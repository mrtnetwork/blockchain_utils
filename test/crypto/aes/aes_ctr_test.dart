import 'dart:typed_data';

import 'package:blockchain_utils/crypto/crypto/aes/aes.dart';
import 'package:blockchain_utils/crypto/crypto/ctr/ctr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("test aes ctr", () {
    for (final i in testVector) {
      final key = BytesUtils.fromHexString(i["key"]);
      final iv = BytesUtils.fromHexString(i["iv"]);
      final plainText = BytesUtils.fromHexString(i["plain_text"]);
      final encrypt = BytesUtils.fromHexString(i["encrypt"]);
      final CTR ctr = CTR(AES(key), iv);
      final encryptOut = Uint8List(plainText.length);
      ctr.streamXOR(plainText, encryptOut);
      ctr.clean();
      ctr.setCipher(AES(key), iv);
      final decryptOut = Uint8List(encrypt.length);
      ctr.streamXOR(encrypt, decryptOut);
      expect(encryptOut.toHex(), encrypt.toHex());
      expect(decryptOut.toHex(), plainText.toHex());
    }
  });
}
