import 'package:blockchain_utils/chain/address/neworks/others/okex_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void okexTest() {
  test("okex address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = OkexAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = OkexAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(okexTest, "Okex");
}
