import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import 'package:blockchain_utils/crypto/crypto/pbkdf2/pbkdf2.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void pbkdf2Test() {
  for (final i in testVector) {
    final password = BytesUtils.fromHexString(i["password"]);
    final salt = BytesUtils.fromHexString(i["salt"]);
    final h = PBKDF2.deriveKey(
        mac: () => HMAC(() => SHA512(), password),
        salt: salt,
        iterations: i["n"],
        length: 32);
    assert(h.toHex() == i["hash"]);
  }
}
