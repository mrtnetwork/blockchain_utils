import 'package:blockchain_utils/chain/address/neworks/others/avax_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_p_vector.dart' as p;
import 'test_x_vector.dart' as x;

import '../../../utils.dart';

void avaxTest() {
  test("avax P-address test", () {
    for (final i in p.testVector.shuffleTake()) {
      final z = AvaxPChainAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AvaxPChainAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("avax x-address test", () {
    for (final i in x.testVector.shuffleTake()) {
      final z = AvaxXChainAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AvaxXChainAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(avaxTest, "Avax");
}
