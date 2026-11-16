import 'package:blockchain_utils/crypto/quick_crypto.dart';
import 'package:test/test.dart';

import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart';

import '../../utils.dart';

void pbkdf2Test() {
  test("pbkdf2", () {
    for (final i in testVector.shuffleTake()) {
      final password = BytesUtils.fromHexString(i["password"]);
      final salt = BytesUtils.fromHexString(i["salt"]);
      final h = QuickCrypto.pbkdf2Sha512DeriveKey(
        password: password,
        salt: salt,
        iterations: i["n"],
        dklen: 32,
      );
      expect(h.toHex(), i["hash"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(pbkdf2Test, "Pbkdf2");
}
