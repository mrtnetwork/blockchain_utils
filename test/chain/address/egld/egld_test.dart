import 'package:blockchain_utils/chain/address/neworks/others/egld_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void egldTest() {
  test("egld address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = EgldAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = EgldAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(egldTest, "Egld");
}
