import 'package:blockchain_utils/blockchain_utils.dart';
import '../../quick_hex.dart';
import 'package:test/test.dart';

import 'comperesed_test_vector.dart' show compresedTestVector;
import 'uncompresed_test_vector.dart' show uncompressedTestVector;

void main() {
  test("p2pkh address test", () {
    for (final i in compresedTestVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final mode = PubKeyModes.compressed;
      final netVersion = BytesUtils.fromHexString(params["net_ver"]);
      final z = P2PKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        pubKeyMode: mode,
        netVersion: netVersion,
      );
      expect(z, i["address"]);
      final decode = P2PKHAddrDecoder().decodeAddr(z, netVersion: netVersion);
      expect(decode.toHex(), i["decode"]);
    }
  });
  test("p2pkh uncompressed publickey address test", () {
    for (final i in uncompressedTestVector) {
      final params = Map<String, dynamic>.from(i["params"]);
      final mode = PubKeyModes.uncompressed;
      final netVersion = BytesUtils.fromHexString(params["net_ver"]);
      final z = P2PKHAddrEncoder().encodeKey(
        BytesUtils.fromHexString(i["public"]),
        pubKeyMode: mode,
        netVersion: netVersion,
      );
      expect(z, i["address"]);
      final decode = P2PKHAddrDecoder().decodeAddr(z, netVersion: netVersion);
      expect(decode.toHex(), i["decode"]);
    }
  });
}
