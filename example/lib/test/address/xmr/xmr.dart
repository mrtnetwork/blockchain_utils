import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'test_vector.dart' show testVector;
import 'test_vector_integrate.dart' show integrateTestVecotr;

void xmrAddressTest() {
  for (final i in testVector) {
    final params = Map<String, dynamic>.from(i["params"]);
    if (params.containsKey("pub_vkey")) {
      params["pub_vkey"] = BytesUtils.fromHexString(params["pub_vkey"]);
    }
    final z = XmrAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = XmrAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
  for (final i in integrateTestVecotr) {
    final params = Map<String, dynamic>.from(i["params"]);
    if (params.containsKey("pub_vkey")) {
      params["pub_vkey"] = BytesUtils.fromHexString(params["pub_vkey"]);
    }
    if (params.containsKey("payment_id")) {
      params["payment_id"] = BytesUtils.fromHexString(params["payment_id"]);
    }
    final z = XmrIntegratedAddrEncoder()
        .encodeKey(BytesUtils.fromHexString(i["public"]), params);
    assert(z == i["address"]);
    final decode = XmrIntegratedAddrDecoder().decodeAddr(z, params);
    assert(decode.toHex() == i["decode"]);
  }
}
