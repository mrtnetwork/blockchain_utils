import 'package:blockchain_utils/chain/address/neworks/others/zil_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void zilTest() {
  test("zil address", () {
    for (final i in testVector.shuffleTake()) {
      final z = ZilAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = ZilAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(zilTest, "Zil");
}
