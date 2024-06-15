import 'package:blockchain_utils/crypto/crypto/chacha20poly1305/chacha20poly1305.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("chacha poly 1305 test", () {
    for (final i in testVector) {
      final plaintext = BytesUtils.fromHexString(i["plain_text"]);
      final assocData = BytesUtils.fromHexString(i["assoc_data"]);
      final key = BytesUtils.fromHexString(i["key"]);
      final nonce = BytesUtils.fromHexString(i["nonce"]);
      final chacha = ChaCha20Poly1305(key);
      final encrypt =
          chacha.encrypt(nonce, plaintext, associatedData: assocData);
      final result = encrypt.sublist(0, encrypt.length - chacha.tagLength);
      final tag = encrypt.sublist(encrypt.length - chacha.tagLength);
      expect(result.toHex(), i["encrypt"]);
      expect(tag.toHex(), i["tag"]);
      final decryptor = ChaCha20Poly1305(key);
      final decrypt =
          decryptor.decrypt(nonce, encrypt, associatedData: assocData);
      expect(decrypt?.toHex(), i["plain_text"]);
    }
  });
  test("description", () {
    for (final i in testVector2) {
      final plaintext = BytesUtils.fromHexString(i["plain_text"]);
      final key = BytesUtils.fromHexString(i["key"]);
      final nonce = BytesUtils.fromHexString(i["nonce"]);
      final chacha = ChaCha20Poly1305(key);
      final encrypt = chacha.encrypt(nonce, plaintext);
      final result = encrypt.sublist(0, encrypt.length - chacha.tagLength);
      final tag = encrypt.sublist(encrypt.length - chacha.tagLength);
      expect(result.toHex(), i["encrypt"]);
      expect(tag.toHex(), i["tag"]);
      final decryptor = ChaCha20Poly1305(key);
      final decrypt = decryptor.decrypt(nonce, encrypt);
      expect(decrypt?.toHex(), i["plain_text"]);
    }
  });
}
