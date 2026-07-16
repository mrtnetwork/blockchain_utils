import 'package:blockchain_utils/bip/address/xtz_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("xtz address", () {
    for (final i in testVector.shuffleTake()) {
      final z = XtzAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        addressPrefix: XtzAddrPrefixes.tz1,
      );

      expect(z, i["address"]);
      final decode = XtzAddrDecoder().decodeAddr(
        z,
        addressPrefix: XtzAddrPrefixes.tz1,
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}
