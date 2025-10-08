import 'package:blockchain_utils/bip/address/xtz_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("xtz address", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from({"prefix": XtzAddrPrefixes.tz1});
      final z = XtzAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);

      expect(z, i["address"]);
      final decode = XtzAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
