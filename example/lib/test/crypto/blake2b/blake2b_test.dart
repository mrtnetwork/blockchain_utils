import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart';

void blake2bTest() {
  for (final i in testVector64) {
    final k = BLAKE2b(digestLength: 64);
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.reset();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
  for (final i in testVectorWithKeyAndSalt) {
    final key = BytesUtils.fromHexString(i["key"]);
    final salt = BytesUtils.fromHexString(i["salt"]);
    final k =
        BLAKE2b(digestLength: 64, config: Blake2bConfig(key: key, salt: salt));
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
  }
}
