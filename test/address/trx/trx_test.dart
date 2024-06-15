import 'package:blockchain_utils/bip/address/trx_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVecotr;

void main() {
  test("trx address test", () {
    for (final i in testVecotr) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = TrxAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = TrxAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
