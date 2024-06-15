import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void testKecc() {
  for (final i in testVector) {
    final k = Keccack();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
  for (final i in keccack512TestVector) {
    final k = Keccack(64);
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    final result = k.digest();
    assert(result.toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
}
