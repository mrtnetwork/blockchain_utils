import 'package:blockchain_utils/crypto/quick_crypto.dart';

import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void ripemdTest() {
  test("RIPEMD state", () {
    final k = QuickCrypto.ripemd128Instance();
    k.update([0, 0]);
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);

    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);
  });

  test("RIPEMD128", () {
    for (final i in ripemd128.shuffleTake()) {
      final k = QuickCrypto.ripemd128Instance();
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("RIPEMD160", () {
    for (final i in ripemd160.shuffleTake()) {
      final k = QuickCrypto.ripemd160Instance();
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("RIPEMD256", () {
    for (final i in ripemd256.shuffleTake()) {
      final k = QuickCrypto.ripemd256Instance();
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
  test("RIPEMD320", () {
    for (final i in ripemd320.shuffleTake()) {
      final k = QuickCrypto.ripemd320Instance();
      final message = BytesUtils.fromHexString(i["message"]);
      k.update(message.sublist(0, 10));
      k.update(message.sublist(10));
      expect(k.digest().toHex(), i["hash"]);
      k.reset();
      k.update(message);
      expect(k.digest().toHex(), i["hash"]);
    }
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(ripemdTest, "Ripemd");
}
