import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

import '../../../utils.dart';

void addressTest() {
  _test();
}

void main() {
  BlockchainUtilsTestApi.runTest(addressTest, "Address");
}

void _test() {
  test("Ton encode, decode address", () {
    final encoder = TonAddrEncoder();
    final decoder = TonAddrDecoder();
    for (final i in tonTestVector.shuffleTake()) {
      final hash = BytesUtils.fromHexString(i["hash"]);
      final String bounceable = encoder.encodeKey(
        hash,
        workChain: i["workchain"],
      );
      final String nonBounceable = encoder.encodeKey(
        hash,
        workChain: i["workchain"],
        bounceable: false,
      );
      expect(bounceable, i["bounceable"]);
      expect(nonBounceable, i["nonBounceable"]);
      final decodeBounceable = decoder.decodeAddr(bounceable);
      final decodeNonBounceable = decoder.decodeAddr(bounceable);
      expect(decodeBounceable, hash);
      expect(decodeNonBounceable, hash);
    }
  });
}
