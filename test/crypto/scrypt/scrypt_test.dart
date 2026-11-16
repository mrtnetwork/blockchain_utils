import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'test_vector.dart';

import '../../utils.dart';

void scryptTest() {
  test("scrypt", () {
    for (final i in testVector.shuffleTake()) {
      final d = QuickCrypto.scryptDerive(
        BytesUtils.fromHexString(i["password"]),
        BytesUtils.fromHexString(i["salt"]),
        dkLen: 32,
        n: i["n"],
        r: i["r"],
        p: i["p"],
      );
      expect(d.toHex(), i["hash"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(scryptTest, "Scrypt");
}
