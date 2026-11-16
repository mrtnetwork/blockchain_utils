import 'package:blockchain_utils/chain/address/neworks/others/algo_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

void algoTest() {
  test("algo address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = AlgoAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = AlgoAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(algoTest, "Algo");
}
