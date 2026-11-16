import 'package:blockchain_utils/chain/address/neworks/others/eth_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void ethTest() {
  test("eth address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = EthAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = EthAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ethTest, "Eth");
}
