import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void testRipemd() {
  for (final i in ripemd128) {
    final k = RIPEMD128();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
  for (final i in ripemd160) {
    final k = RIPEMD160();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
  for (final i in ripemd256) {
    final k = RIPEMD256();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
  for (final i in ripemd320) {
    final k = RIPEMD320();
    final message = BytesUtils.fromHexString(i["message"]);
    k.update(message.sublist(0, 10));
    k.update(message.sublist(10));
    assert(k.digest().toHex() == i["hash"]);
    k.clean();
    k.update(message);
    assert(k.digest().toHex() == i["hash"]);
  }
}
