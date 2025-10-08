// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import '../../quick_hex.dart';

List<Map<String, dynamic>> _testVectorDec = [
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "TestingOneTwoThree",
    "priv_key_bytes":
        "a43a940577f4e97f5c4d39eb14ff083a98187c64ea7c99ef7ce460833959a519",
    "encrypted": "6PfQu77ygVyJLZjfvMLyhLMQbYnu5uguoJJ4kMCLqWwPEdfpwANVS76gTX",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "Satoshi",
    "priv_key_bytes":
        "c2c8036df268f498099350718c4a3ef3984d2be84618c2650f5171dcc5eb660a",
    "encrypted": "6PfLGnQs6VZnrNpmVKfjotbnQuaJK4KZoPFrAjx1JMJUa1Ft8gnf5WxfKd",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "MOLON LABE",
    "priv_key_bytes":
        "44ea95afbf138356a05ea32110dfd627232d0f2991ad221187be356f19fa8190",
    "encrypted": "6PgNBNNzDkKdhkT6uJntUXwwzQV8Rr2tZcbkDcuC9DZRsS6AtHts4Ypo1j",
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "ΜΟΛΩΝ ΛΑΒΕ",
    "priv_key_bytes":
        "ca2759aa4adb0f96c414f36abeb8db59342985be9fa50faac228c8e7d90e3006",
    "encrypted": "6PgGWtx25kUg8QWvwuJAgorN6k9FbE25rv5dMRwu5SKMnfpfVe5mar2ngH",
  },
];
final List<Map<String, dynamic>> _testVectEnc = [
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "TestingOneTwoThree",
    "lot_num": null,
    "seq_num": null,
  },
  {
    "pub_key_mode": PubKeyModes.compressed,
    "passphrase": "TestingOneTwoThree",
    "lot_num": null,
    "seq_num": null,
  },
  {
    "pub_key_mode": PubKeyModes.uncompressed,
    "passphrase": "TestingOneTwoThree",
    "lot_num": 100000,
    "seq_num": 1,
  },
  {
    "pub_key_mode": PubKeyModes.compressed,
    "passphrase": "TestingOneTwoThree",
    "lot_num": 100001,
    "seq_num": 2,
  }
];
void main() {
  test("decrypt ec", () {
    for (final i in _testVectorDec) {
      final dec = Bip38Decrypter.decryptEc(i["encrypted"], i["passphrase"]);
      expect(dec.item1.toHex(), i["priv_key_bytes"]);
      expect(dec.item2, i["pub_key_mode"]);
    }
  });
  test("encrypt", () {
    for (final i in _testVectEnc) {
      final enc = Bip38Encrypter.generatePrivateKeyEc(i["passphrase"],
          pubKeyMode: i["pub_key_mode"],
          lotNum: i["lot_num"],
          sequenceNum: i["seq_num"]);

      final decrypt = Bip38Decrypter.decryptEc(enc, i["passphrase"]);

      expect(decrypt.item2, i["pub_key_mode"]);
    }
  });
}
