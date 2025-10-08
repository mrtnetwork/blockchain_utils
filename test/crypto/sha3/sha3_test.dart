import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:test/test.dart';

import '../../quick_hex.dart';
import 'test_vector.dart';

void main() {
  test("sha3-512", () {
    for (final i in testVector) {
      final k = SHA3(64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.clean();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });

  test("sha3-256", () {
    for (final i in testVectorSha332) {
      final k = SHA3(32);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.clean();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
}
