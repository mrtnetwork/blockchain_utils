import 'package:blockchain_utils/bip/address/p2pkh_addr.dart';
import 'package:blockchain_utils/bip/bip/bip38/bip38.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';
import 'package:flutter/foundation.dart';

List<Map<String, dynamic>> _testVector = [
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "TestingOneTwoThree",
    "priv_key_bytes":
        "cbf4b9f70470856bb4f40f80b87edb90865997ffee6df315ab166d713af433a5",
    "encrypted": "6PRVWUbkzzsbcVac2qwfssoUJAN1Xhrg6bNk8J7Nzm5H7kxEbn2Nh2ZoGg",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "Satoshi",
    "priv_key_bytes":
        "09c2686880095b1a4c249ee3ac4eea8a014f11e6f986d0b5025ac1f39afbd9ae",
    "encrypted": "6PRNFFkZc2NZ6dJqFfhRoFNMR9Lnyj7dYGrzdgXXVMXcxoKTePPX1dWByq",
  },
  {
    "pub_key_mode": PubKeyModes.compressed,
    "passphrase": "TestingOneTwoThree",
    "priv_key_bytes":
        "cbf4b9f70470856bb4f40f80b87edb90865997ffee6df315ab166d713af433a5",
    "encrypted": "6PYNKZ1EAgYgmQfmNVamxyXVWHzK5s6DGhwP4J5o44cvXdoY7sRzhtpUeo",
  },
  {
    "pub_key_mode": PubKeyModes.compressed,
    "passphrase": "Satoshi",
    "priv_key_bytes":
        "09c2686880095b1a4c249ee3ac4eea8a014f11e6f986d0b5025ac1f39afbd9ae",
    "encrypted": "6PYLtMnXvfG3oJde97zRyLYFZCYizPU5T3LwgdYJz1fRhh16bU7u6PPmY7",
  },
];

void bip38NoEcdsaTest() {
  for (final i in _testVector) {
    final enc = Bip38Encrypter.encryptNoEc(
        BytesUtils.fromHexString(i["priv_key_bytes"]), i["passphrase"],
        pubKeyMode: i["pub_key_mode"]);
    assert(enc == i["encrypted"]);
    final dec = Bip38Decrypter.decryptNoEc(i["encrypted"], i["passphrase"]);
    assert(i["priv_key_bytes"] == dec.item1.toHex());
    assert(i["pub_key_mode"] == dec.item2);

    // this method use scrypt with parameters 16384N  8P and 8R . very slow on web debug!! :-ss
    if (kIsWeb) break;
  }
}
