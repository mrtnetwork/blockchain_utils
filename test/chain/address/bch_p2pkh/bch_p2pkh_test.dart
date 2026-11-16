import 'package:blockchain_utils/chain/address/protocol/p2pkh_addr.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void bchP2pkhTest() {
  test("bch p2pkh test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final z = BchP2PKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        netVersion: BytesUtils.fromHexString(params["net_ver"]),
        hrp: params["hrp"],
      );
      expect(z, i["address"]);
      final decode = BchP2PKHAddrDecoder().decodeAddr(
        z,
        netVersion: BytesUtils.fromHexString(params["net_ver"]),
        hrp: params["hrp"],
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(bchP2pkhTest, "Bch P2pkh");
}
