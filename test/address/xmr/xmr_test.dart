import 'package:blockchain_utils/bip/address/xmr_addr.dart';
import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart' show testVector;
import 'test_vector_integrate.dart' show integrateTestVecotr;

void main() {
  test("xrm address test", () {
    for (final i in testVector.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final pubVkey = BytesUtils.tryFromHexString(params["pub_vkey"]);
      final netVersion = params["net_ver"];
      final z = XmrAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        pubVKey: pubVkey,
        netVersion: netVersion,
      );
      expect(z, i["address"]);
      final decode = XmrAddrDecoder().decodeAddr(z, netVersion: netVersion);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("xmr integrate address test", () {
    for (final i in integrateTestVecotr.shuffleTake()) {
      final params = Map<String, dynamic>.from(i["params"]);
      final pubVkey = BytesUtils.tryFromHexString(params["pub_vkey"]);
      final netVersion = params["net_ver"];
      final paymentId = BytesUtils.tryFromHexString(params["payment_id"]);
      final z = XmrIntegratedAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        pubVKey: pubVkey,
        netVersion: netVersion,
        paymentId: paymentId,
      );
      expect(z, i["address"]);
      final decode = XmrIntegratedAddrDecoder().decodeAddr(
        z,
        netVersion: netVersion,
        paymentId: paymentId,
      );
      expect(decode.toHex(), i["decode"]);
    }
  });
}
