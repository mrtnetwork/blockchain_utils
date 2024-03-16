import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector.dart';

void testSha512() {
  for (final i in testVector) {
    final k = SHA512();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
}
