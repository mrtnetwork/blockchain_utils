import 'package:blockchain_utils/bip/address/egld_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;

void main() {
  test("egld address test", () {
    for (final i in testVector) {
      final params = Map<String, dynamic>.from(i["params"]);

      final z = EgldAddrEncoder()
          .encodeKey(BytesUtils.fromHexString(i["public"]), params);
      expect(z, i["address"]);
      final decode = EgldAddrDecoder().decodeAddr(z, params);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
