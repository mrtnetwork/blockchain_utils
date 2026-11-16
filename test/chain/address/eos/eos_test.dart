import 'package:blockchain_utils/chain/address/neworks/others/eos_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void eosTest() {
  test("eos address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = EosAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = EosAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(eosTest, "Eos");
}
