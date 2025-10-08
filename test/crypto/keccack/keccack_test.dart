import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';
import 'package:test/test.dart';

import '../../quick_hex.dart';
import 'test_vector.dart';

void main() {
  test("kechack 256 bit", () {
    for (final i in testVector) {
      final k = Keccack();
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.clean();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("test keccack 512 bit", () {
    for (final i in keccack512TestVector) {
      final k = Keccack(64);
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      final result = k.digest();
      expect(result.toHex(), i["hash"]);
      k.clean();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
}
