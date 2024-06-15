import 'package:blockchain_utils/bip/address/nano_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("neo address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final z = NanoAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);

      expect(z, i["address"]);
      final decode = NanoAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
