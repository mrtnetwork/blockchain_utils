import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../utils.dart';

void hmacTest() {
  test("HMAC state", () {
    final key = QuickCrypto.generateRandom();
    final k = QuickCrypto.hmacSha512Instance(key);
    k.update([0, 0]);
    final r = k.saveState();
    final digest = k.digest();
    expect(k.digest(), digest);
    k.reset();
    k.update([0, 0]);
    expect(k.digest(), digest);

    k.clean();
    expect(() => k.reset(), buErrorOrCryptoException);

    final g = QuickCrypto.hmacSha512Instance(QuickCrypto.generateRandom());
    g.restoreState(r);
    expect(g.digest(), digest);
    // g.reset();
    // g.update([0, 0]);
    // expect(g.digest(), digest);
  });
  test("hmac sha512", () {
    for (final i in hmach512TestVector.shuffleTake()) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = QuickCrypto.hmacSha512Instance(key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });
  test("hmac sha256", () {
    for (final i in hmac256TestVector.shuffleTake()) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = QuickCrypto.hmacSha256Instance(key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });
  test("hmac sha3", () {
    for (final i in sha3TestVector.shuffleTake()) {
      final key = BytesUtils.fromHexString(i["key"]);
      final message = BytesUtils.fromHexString(i["message"]);
      final mac = HMAC(() => SHA3(), key);
      mac.update(message.sublist(0, 10));
      mac.update(message.sublist(10));
      expect(mac.digest().toHex(), i["hash"]);
      mac.reset();
      mac.update(message);
      expect(mac.digest().toHex(), i["hash"]);
    }
  });

  test("clean wipes keyed states", () {
    final key = List<int>.filled(32, 7);
    final h = HMAC(() => SHA256(), key);
    h.update([1, 2, 3]);
    final s = h.saveState();
    final innerKey = (s.innerKeyState as SHA256State).state;
    final outerKey = (s.outerKeyState as SHA256State).state;
    // Sanity: keyed states hold key-derived material before clean.
    expect(innerKey.any((b) => b != 0), isTrue);
    expect(outerKey.any((b) => b != 0), isTrue);
    h.clean();
    expect(innerKey, everyElement(0));
    expect(outerKey, everyElement(0));
    // Post-clean contract unchanged: the object is bricked.
    expect(() => h.update([0]), throwsA(isA<BuError>()));
  });
}

void main() {
  BlockchainUtilsTestApi.runTest(hmacTest, "Hmac");
}
