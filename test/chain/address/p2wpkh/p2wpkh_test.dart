import 'package:blockchain_utils/chain/address/protocol/p2wpkh_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void p2wpkhTest() {
  test("p2wpkh address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = P2WPKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        hrp: params["hrp"],
      );
      expect(z, i["address"]);
      final decode = P2WPKHAddrDecoder().decodeAddr(z, hrp: params["hrp"]);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(p2wpkhTest, "P2wpkh");
}
