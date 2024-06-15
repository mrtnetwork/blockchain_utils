import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:blockchain_utils/crypto/crypto/hmac/hmac.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  test("hmac sha512", () {
    for (final i in hmach512TestVector) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = HMAC(() => SHA512(), key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });
  test("hmac sha256", () {
    for (final i in hmac256TestVector) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = HMAC(() => SHA256(), key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });
  test("hmac sha3", () {
    for (final i in sha3TestVector) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = HMAC(() => SHA3(), key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });
}
