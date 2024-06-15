import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'test_vector.dart';

void main() {
  _test();
}

void _test() {
  test("Ton encode, decode address", () {
    final encoder = TonAddrEncoder();
    final decoder = TonAddrDecoder();
    for (final i in tonTestVector) {
      final hash = BytesUtils.fromHexString(i["hash"]);
      final String bounceable =
          encoder.encodeKey(hash, {"workchain": i["workchain"]});
      final String nonBounceable = encoder
          .encodeKey(hash, {"workchain": i["workchain"], "bounceable": false});
      expect(bounceable, i["bounceable"]);
      expect(nonBounceable, i["nonBounceable"]);
      final decodeBounceable = decoder.decodeAddr(bounceable);
      final decodeNonBounceable = decoder.decodeAddr(bounceable);
      expect(decodeBounceable, hash);
      expect(decodeNonBounceable, hash);
    }
  });
}
