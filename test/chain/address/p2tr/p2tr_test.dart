import 'package:blockchain_utils/chain/address/protocol/p2tr_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void p2trTest() {
  test("p2tr address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = P2TRAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        hrp: params["hrp"],
      );
      expect(z, i["address"]);
      final decode = P2TRAddrDecoder().decodeAddr(z, hrp: params["hrp"]);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(p2trTest, "P2tr");
}
