import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'sign_verify_vector.dart';

void main() {
  _test();
}

void _test() {
  test("valid sign verify", () {
    final List<int> secretKey =
        BytesUtils.fromHexString(signVerifyVector['sk']).asImmutableBytes;
    final List<List<int>> pubKeys = (signVerifyVector["pubkeys"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> secnonces = (signVerifyVector["secnonces"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> aggnonces = (signVerifyVector["aggnonces"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> msgs = (signVerifyVector["msgs"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final validateTestCase =
        List<Map<String, dynamic>>.from(signVerifyVector["valid_test_cases"]!);
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final List<int> aggnonce = aggnonces.elementAt(e["aggnonce_index"]);
      final List<int> msg = msgs.elementAt(e["msg_index"]);
      final session =
          MuSig2Session(aggnonce: aggnonce, publicKeys: keys, msg: msg);
      final sign = MuSig2.sign(
          secnonce: List<int>.from(secnonces[0]),
          sk: secretKey,
          session: session);
      final sigHex = BytesUtils.toHexString(sign, lowerCase: false);
      expect(sigHex, e["expected"]);
    }
  });

  test("failed verify", () {
    final List<int> secretKey =
        BytesUtils.fromHexString(signVerifyVector['sk']).asImmutableBytes;
    final List<List<int>> pubKeys = (signVerifyVector["pubkeys"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> secnonces = (signVerifyVector["secnonces"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> aggnonces = (signVerifyVector["aggnonces"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final List<List<int>> msgs = (signVerifyVector["msgs"] as List)
        .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
        .toList();
    final errorTestCase = List<Map<String, dynamic>>.from(
        signVerifyVector["sign_error_test_cases"]!);
    for (int j = 0; j < errorTestCase.length; j++) {
      final e = errorTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final List<int> aggnonce = aggnonces.elementAt(e["aggnonce_index"]);
      final List<int> msg = msgs.elementAt(e["msg_index"]);

      expect(() {
        final session =
            MuSig2Session(aggnonce: aggnonce, publicKeys: keys, msg: msg);
        return MuSig2.sign(
            secnonce: List<int>.from(secnonces[e["secnonce_index"]]),
            sk: secretKey,
            session: session);
      }, throwsA(isA<MuSig2Exception>()));
    }
  });
}
