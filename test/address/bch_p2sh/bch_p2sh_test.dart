import 'package:blockchain_utils/bip/address/p2sh_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("bch address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      params["net_ver"] = BytesUtils.fromHexString(params["net_ver"]);

      final z = BchP2SHAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = BchP2SHAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
