import 'package:blockchain_utils/chain/address/neworks/others/nano_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void nanoTest() {
  test("neo address test", () {
    for (final i in testVector.shuffleTake()) {
      final z = NanoAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );

      expect(z, i["address"]);
      final decode = NanoAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(nanoTest, "Nano");
}
