import 'package:blockchain_utils/crypto/crypto/schnorrkel/keys/keys.dart';
import 'package:example/test/quick_hex.dart';
import 'package:blockchain_utils/binary/utils.dart';

import 'derive_test_vector.dart';
import 'derive_public_vector.dart';

void schnoorTestDerive() {
  for (final i in derivePublicTestVector) {
    SchnorrkelPublicKey publicKey =
        SchnorrkelPublicKey(BytesUtils.fromHexString(i["public_key"]));
    final child = List.from(i["child"]);
    for (int c = 0; c < child.length; c++) {
      final chainCode = BytesUtils.fromHexString(child[c]["chain_code"]);
      publicKey = publicKey.derive(chainCode).item1;
      assert(publicKey.toBytes().toHex() == child[c]["public_key"]);
    }
  }
  for (final i in testVector) {
    final seed = BytesUtils.fromHexString(i["seed"]);
    final miniSecret = SchnorrkelMiniSecretKey.fromBytes(seed);
    SchnorrkelSecretKey secretKey = miniSecret.toSecretKey();
    assert(secretKey.publicKey().toBytes().toHex() == i["public_key"]);
    assert(secretKey.toBytes().toHex() == i["private_key"]);
    final child = List.from(i["child"]);
    for (int c = 0; c < child.length; c++) {
      final bool isHard = child[c]["is_hard"];
      final chainCode = BytesUtils.fromHexString(child[c]["chain_code"]);
      if (isHard) {
        final deriveHard = secretKey.hardDerive(chainCode);
        secretKey = deriveHard.item1;
      } else {
        final deriveSoft = secretKey.softDerive(chainCode);
        secretKey = deriveSoft.item1;
      }
      assert(secretKey.publicKey().toBytes().toHex() == child[c]["public_key"]);
      if (isHard) {
        assert(secretKey.toBytes().toHex() == child[c]["private_key"]);
      } else {
        final keyBytes = SchnorrkelSecretKey.fromBytes(
            BytesUtils.fromHexString(child[c]["private_key"]));
        assert(secretKey.key().toHex() == keyBytes.key().toHex());
      }
    }
  }
}
