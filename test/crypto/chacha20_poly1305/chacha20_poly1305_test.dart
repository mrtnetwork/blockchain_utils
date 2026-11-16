import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void chacha20Poly1305Test() {
  test("chacha poly 1305 test", () {
    for (final i in testVector.shuffleTake()) {
      final plaintext = BytesUtils.fromHexString(i["plain_text"]);
      final assocData = BytesUtils.fromHexString(i["assoc_data"]);
      final key = BytesUtils.fromHexString(i["key"]);
      final nonce = BytesUtils.fromHexString(i["nonce"]);
      final chacha = QuickCrypto.chacha20Poly1305Instance(key);
      final encrypt = chacha.encrypt(
        nonce,
        plaintext,
        associatedData: assocData,
      );
      final result = encrypt.sublist(0, encrypt.length - chacha.tagLength);
      final tag = encrypt.sublist(encrypt.length - chacha.tagLength);
      expect(result.toHex(), i["encrypt"]);
      expect(tag.toHex(), i["tag"]);
      final decryptor = QuickCrypto.chacha20Poly1305Instance(key);
      final decrypt = decryptor.decrypt(
        nonce,
        encrypt,
        associatedData: assocData,
      );
      expect(decrypt?.toHex(), i["plain_text"]);
    }
    for (final i in testVector2) {
      final plaintext = BytesUtils.fromHexString(i["plain_text"]);
      final key = BytesUtils.fromHexString(i["key"]);
      final nonce = BytesUtils.fromHexString(i["nonce"]);
      final chacha = QuickCrypto.chacha20Poly1305Instance(key);
      final encrypt = chacha.encrypt(nonce, plaintext);
      final result = encrypt.sublist(0, encrypt.length - chacha.tagLength);
      final tag = encrypt.sublist(encrypt.length - chacha.tagLength);
      expect(result.toHex(), i["encrypt"]);
      expect(tag.toHex(), i["tag"]);
      final decryptor = QuickCrypto.chacha20Poly1305Instance(key);
      final decrypt = decryptor.decrypt(nonce, encrypt);
      expect(decrypt?.toHex(), i["plain_text"]);
    }
  });

  test("Chacha with seek bytes", () {
    List<int> xor(List<int> pt, List<int> key, List<int> nonce, int seek) {
      final dst = BuBytes.fill(pt.length, 0);
      QuickCrypto.chacha20Instance(
        key,
      ).process(pt, nonce: nonce, dst: dst, seekBytes: seek);
      return dst;
    }

    for (final i in testVectorChacha20WithSeekBytes) {
      final key = BytesUtils.fromHexString(i["key"]);
      final nonce = BytesUtils.fromHexString(i["nonce"]);
      final pt = BytesUtils.fromHexString(i["plaintext"]);
      final seek1 = i["seek1"] as int;
      final seek2 = i["seek2"] as int;
      final afterSink1 = BytesUtils.fromHexString(i["after_seek1"]);
      final afterSink2 = BytesUtils.fromHexString(i["after_seek2"]);
      final d = xor(pt, key, nonce, seek1);
      expect(d, afterSink1);
      final d2 = xor(d, key, nonce, seek2);
      expect(d2, afterSink2);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(chacha20Poly1305Test, "Chacha20 Poly1305");
}
