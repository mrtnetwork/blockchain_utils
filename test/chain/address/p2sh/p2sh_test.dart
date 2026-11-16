import 'package:blockchain_utils/chain/address/protocol/p2sh_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void p2shTest() {
  test("p2sh address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final netVersion = BytesUtils.fromHexString(params["net_ver"]);
      final z = P2SHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        netVersion: netVersion,
      );
      expect(z, i["address"]);
      final decode = P2SHAddrDecoder().decodeAddr(z, netVersion: netVersion);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(p2shTest, "P2sh");
}
