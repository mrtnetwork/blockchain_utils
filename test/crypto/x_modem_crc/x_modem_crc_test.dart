import 'package:blockchain_utils/crypto/crypto/checksum/x_modem_crc/x_modem_crc.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void xModemCrcTest() {
  test("x-Modem crc", () {
    for (final i in testVector) {
      final result = XModemCrc.quickDigest(
        BytesUtils.fromHexString(i["message"]),
      );
      expect(result.toHex(), i["crc"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(xModemCrcTest, "X Modem Crc");
}
