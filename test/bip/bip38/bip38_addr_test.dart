// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

List<Map<String, dynamic>> _testVector = [
  {
    "pub_key_mode": PubKeyModes.compressed,
    "pub_key":
        "03aaeb52dd7494c361049de67cc680e83ebcbbbdbeb13637d92cd845f70308af5e",
    "address_hash": "a374deb6",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "pub_key":
        "03aaeb52dd7494c361049de67cc680e83ebcbbbdbeb13637d92cd845f70308af5e",
    "address_hash": "6a531625",
  },
  {
    "pub_key_mode": PubKeyModes.compressed,
    "pub_key":
        "02b5cbfe6ee73b7c5e968e1c515a964894f306a7c882dd18433ab4e16a66d36972",
    "address_hash": "97c1e671",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "pub_key":
        "02b5cbfe6ee73b7c5e968e1c515a964894f306a7c882dd18433ab4e16a66d36972",
    "address_hash": "8805ef61",
  },
];
void main() {
  test("address hash", () {
    for (final i in _testVector) {
      final result = Bip38Addr.addressHash(
          BytesUtils.fromHexString(i["pub_key"]), i["pub_key_mode"]);
      expect(BytesUtils.toHexString(result), i["address_hash"]);
    }
  });
}
