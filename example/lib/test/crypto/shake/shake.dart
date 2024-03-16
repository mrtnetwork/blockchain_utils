import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'test_vector_256.dart';
import 'test_vector_128.dart';

void testShakeDigest() {
  for (final i in testVecotr256) {
    final inp = BytesUtils.fromHexString(i["input"]);
    final int out = i["out_size"];
    final h = SHAKE256();
    h.update(inp.sublist(0, 1));
    h.update(inp.sublist(1));
    final digest = h.digest(out);
    assert(digest.toHex() == i["out"]);
    h.reset();
    h.update(inp);
    assert(digest.toHex() == i["out"]);
  }
  for (final i in testVector128) {
    final inp = BytesUtils.fromHexString(i["input"]);
    final int out = i["out_size"];
    final h = SHAKE128();
    h.update(inp.sublist(0, 1));
    h.update(inp.sublist(1));
    final digest = h.digest(out);
    assert(digest.toHex() == i["out"]);
    h.reset();
    h.update(inp);
    assert(digest.toHex() == i["out"]);
  }
}
