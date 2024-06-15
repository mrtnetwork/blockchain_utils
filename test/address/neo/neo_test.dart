import 'package:blockchain_utils/bip/address/neo_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVecotr;

void main() {
  test("neo address test", () {
    for (final i in testVecotr) {
      final params = Map<String, dynamic>.from(i["params"]);
      params["ver"] = BytesUtils.fromHexString(params["ver"]);
      final z = NeoAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = NeoAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
