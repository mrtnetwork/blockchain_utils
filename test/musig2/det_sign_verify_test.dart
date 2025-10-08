import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'det_sign_vector.dart';

void main() {
  _test();
}

void _test() {
  test("valid sign verify", () {
    final List<int> secretKey =
        BytesUtils.fromHexString(detSignVector['sk']).asImmutableBytes;
    final List<List<int>> pubKeys = (detSignVector["pubkeys"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> msgs = (detSignVector["msgs"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final validateTestCase =
        List<Map<String, dynamic>>.from(detSignVector["valid_test_cases"]!);
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final rand = BytesUtils.tryFromHexString(e["rand"]);
      final List<List<int>> tweaks = (e["tweaks"] as List)
          .map((e) => BytesUtils.fromHexString(e))
          .toList();
      final List<bool> isXonly = (e["is_xonly"] as List).cast();
      final List<int> msg = msgs.elementAt(e["msg_index"]);
      final List<int> aggothernonce =
          BytesUtils.fromHexString(e["aggothernonce"]);
      final List<String> expected = (e["expected"] as List).cast();
      final sign = MuSig2.deterministicSign(
          aggotherNonce: aggothernonce,
          msg: msg,
          sk: secretKey,
          publicKeys: keys,
          tweaks: List.generate(tweaks.length,
              (i) => MuSig2Tweak(tweak: tweaks[i], isXOnly: isXonly[i])),
          rand: rand);
      expect(
          BytesUtils.toHexString(sign.pubnonce, lowerCase: false), expected[0]);
      expect(BytesUtils.toHexString(sign.signature, lowerCase: false),
          expected[1]);
    }
  });
}
