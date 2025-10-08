import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("blake2b test", () {
    for (final i in testVector64) {
      final k = BLAKE2b(digestLength: 64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("blake2b with key and nonce test", () {
    for (final i in testVectorWithKeyAndSalt) {
      final key = BytesUtils.fromHexString(i["key"]);
      final salt = BytesUtils.fromHexString(i["salt"]);
      final k = BLAKE2b(
          digestLength: 64, config: Blake2bConfig(key: key, salt: salt));
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
    }
  });
}
