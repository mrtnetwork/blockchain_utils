import 'package:blockchain_utils/chain/address/neworks/others/ergo.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

import '../../../utils.dart';

void ergoTest() {
  test("ergo address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final netType = ErgoNetworkTypes.values.firstWhere(
        (element) =>
            element.name.toLowerCase() ==
            (params["net_type"] as String).toLowerCase(),
      );
      final z = ErgoP2PKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        netType: netType,
      );
      expect(z, i["address"]);
      final decode = ErgoP2PKHAddrDecoder().decodeAddr(z, netType: netType);
      expect(decode.toHex(), i["decode"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ergoTest, "Ergo");
}
