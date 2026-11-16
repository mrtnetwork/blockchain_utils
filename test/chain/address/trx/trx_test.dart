import 'package:blockchain_utils/chain/address/neworks/others/trx_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVecotr;

import '../../../utils.dart';

void trxTest() {
  test("trx address test", () {
    for (final i in testVecotr.shuffleTake()) {
      final z = TrxAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = TrxAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(trxTest, "Trx");
}
