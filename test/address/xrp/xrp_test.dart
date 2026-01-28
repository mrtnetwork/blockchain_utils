import 'package:blockchain_utils/bip/address/xrp_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("xrp address", () {
    for (final i in testVector) {
      final z = XrpAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
      );
      expect(z, i["address"]);
      final decode = XrpAddrDecoder().decodeAddr(z);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
