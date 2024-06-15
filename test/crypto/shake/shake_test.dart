import 'package:blockchain_utils/crypto/crypto/hash/hash.dart';

import '../../quick_hex.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

import 'test_vector_256.dart';
import 'test_vector_128.dart';

void main() {
  test("shake25", () {
    for (final i in testVecotr256) {
      final inp = BytesUtils.fromHexString(i["input"]);
      final int out = i["out_size"];
      final h = SHAKE256();
      h.update(inp.sublist(0, 1));
      h.update(inp.sublist(1));
      final digest = h.digest(out);
      expect(digest.toHex(), i["out"]);
      h.reset();
      h.update(inp);
      expect(digest.toHex(), i["out"]);
    }
  });
  test("shake128", () {
    for (final i in testVector128) {
      final inp = BytesUtils.fromHexString(i["input"]);
      final int out = i["out_size"];
      final h = SHAKE128();
      h.update(inp.sublist(0, 1));
      h.update(inp.sublist(1));
      final digest = h.digest(out);
      expect(digest.toHex(), i["out"]);
      h.reset();
      h.update(inp);
      expect(digest.toHex(), i["out"]);
    }
  });
}
