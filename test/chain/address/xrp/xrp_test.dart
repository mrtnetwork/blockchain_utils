import 'package:blockchain_utils/chain/address/neworks/others/xrp_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void xrpXrpTest() {
  test("xrp address", () {
    for (final i in testVector.shuffleTake()) {
      final z = XrpAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = XrpAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(xrpXrpTest, "Xrp");
}
