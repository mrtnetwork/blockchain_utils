import 'package:blockchain_utils/bip/address/neo_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVecotr;

void main() {
  test("neo address test", () {
    for (final i in testVecotr.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final z = NeoAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        versionBytes: BytesUtils.fromHexString(params["ver"]),
      );
      expect(z, i["address"]);
      final decode = NeoAddrDecoder().decodeAddr(
        z,
        versionBytes: BytesUtils.fromHexString(params["ver"]),
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}
