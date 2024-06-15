// all keys generated from https://github.com/noot/schnorrkel/blob/f7551a43845ba65e8782a2c7d80439111eeda687/src/keys.rs#L983

import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'key_test_vector.dart';

void schnoorKeyTest() {
  for (final i in keyTestVector) {
    final seed = BytesUtils.fromHexString(i["mini_secret"]);
    final miniSecret = SchnorrkelMiniSecretKey.fromBytes(seed);
    final edSecret = miniSecret.toSecretKey(ExpansionMode.ed25519);
    assert(edSecret.toBytes().toHex().toUpperCase() == i["ed_secret"]);
    assert(
        edSecret.publicKey().toBytes().toHex().toUpperCase() == i["ed_public"]);
    final uniSecret = miniSecret.toSecretKey(ExpansionMode.uniform);
    assert(uniSecret.toBytes().toHex().toUpperCase() == i["uniform_secret"]);
    assert(uniSecret.publicKey().toBytes().toHex().toUpperCase() ==
        i["uniform_public"]);
  }
}
