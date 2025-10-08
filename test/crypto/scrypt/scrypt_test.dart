import 'package:blockchain_utils/crypto/crypto/scrypt/scrypt.dart';
import 'package:test/test.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

void main() {
  test("scrypt", () {
    for (final i in testVector) {
      final s = Scrypt(i["n"], i["r"], i["p"]);
      final derive = s.derive(BytesUtils.fromHexString(i["password"]),
          BytesUtils.fromHexString(i["salt"]), 32);
      expect(derive.toHex(), i["hash"]);
    }
  });
}
