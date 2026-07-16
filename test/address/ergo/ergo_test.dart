import 'package:blockchain_utils/bip/address/ergo.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
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
