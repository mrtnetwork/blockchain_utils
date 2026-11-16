import 'package:blockchain_utils/chain/address/neworks/others/icx_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVecotr;

import '../../../utils.dart';

void icxTest() {
  test("icx address test", () {
    for (final i in testVecotr.shuffleTake()) {
      final z = IcxAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = IcxAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(icxTest, "Icx");
}
