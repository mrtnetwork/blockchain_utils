import 'package:blockchain_utils/bip/address/trx_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test.dart' show testVecotr;

void trxAddressTest() {
  for (final i in testVecotr) {
    final params = Map<String, dynamic>.from(i["params"]);

    final z = TrxAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = TrxAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
