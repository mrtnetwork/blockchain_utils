import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'tweak_vector.dart';

import '../../utils.dart';

void tweakTest() {
  _test();
}

void main() {
  BlockchainUtilsTestApi.runTest(tweakTest, "Tweak", onNative: _nativeSign);
}

void _test() {
  test("MuSign2 sign tweak", () {
    final musig = blockchainUtils.api.muSig2;
    final List<int> secretKey =
        BytesUtils.fromHexString(tweakTestVecotr['sk']).asImmutableBytes;
    final List<List<int>> pubKeys =
        (tweakTestVecotr["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> secnonce =
        BytesUtils.fromHexString(tweakTestVecotr["secnonce"]).asImmutableBytes;
    final List<int> aggnonce =
        BytesUtils.fromHexString(tweakTestVecotr["aggnonce"]).asImmutableBytes;

    final List<List<int>> tweakBytes =
        (tweakTestVecotr["tweaks"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> msg =
        BytesUtils.fromHexString(tweakTestVecotr["msg"]).immutable;
    final validateTestCase = List<Map<String, dynamic>>.from(
      tweakTestVecotr["valid_test_cases"]!,
    );
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final tweakIndeces = List<int>.from(e["tweak_indices"]);
      final tweaks = List.generate(tweakIndeces.length, (i) {
        return tweakBytes.elementAt(tweakIndeces[i]);
      });
      final xonlyIndeces = List<bool>.from(e["is_xonly"]);

      final t =
          tweaks.indexed
              .map(
                (e) => MuSig2Tweak(
                  tweak: e.$2,
                  isXOnly: xonlyIndeces.elementAt(e.$1),
                ),
              )
              .toList();
      final r = MuSig2Session(
        aggnonce: aggnonce,
        publicKeys: keys,
        msg: msg,
        tweaks: t,
      );
      List<int> sign = musig.sign(
        session: r,
        secnonce: secnonce,
        sk: secretKey,
      );
      String sigHex = BytesUtils.toHexString(sign, lowerCase: false);
      expect(StringUtils.hexEqual(sigHex, e["expected"]), true);
    }
  });
}

void _nativeSign(BlockchainUtilsApi api) {
  test("MuSign2 sign tweak native", () {
    final musig = api.muSig2;
    final List<int> secretKey =
        BytesUtils.fromHexString(tweakTestVecotr['sk']).asImmutableBytes;
    final List<List<int>> pubKeys =
        (tweakTestVecotr["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> secnonce =
        BytesUtils.fromHexString(tweakTestVecotr["secnonce"]).asImmutableBytes;
    final List<int> aggnonce =
        BytesUtils.fromHexString(tweakTestVecotr["aggnonce"]).asImmutableBytes;

    final List<List<int>> tweakBytes =
        (tweakTestVecotr["tweaks"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> msg =
        BytesUtils.fromHexString(tweakTestVecotr["msg"]).immutable;
    final validateTestCase = List<Map<String, dynamic>>.from(
      tweakTestVecotr["valid_test_cases"]!,
    );
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final tweakIndeces = List<int>.from(e["tweak_indices"]);
      final tweaks = List.generate(tweakIndeces.length, (i) {
        return tweakBytes.elementAt(tweakIndeces[i]);
      });
      final xonlyIndeces = List<bool>.from(e["is_xonly"]);

      final t =
          tweaks.indexed
              .map(
                (e) => MuSig2Tweak(
                  tweak: e.$2,
                  isXOnly: xonlyIndeces.elementAt(e.$1),
                ),
              )
              .toList();
      final r = MuSig2Session(
        aggnonce: aggnonce,
        publicKeys: keys,
        msg: msg,
        tweaks: t,
      );
      List<int> sign = musig.sign(
        session: r,
        secnonce: secnonce,
        sk: secretKey,
      );
      String sigHex = BytesUtils.toHexString(sign, lowerCase: false);
      expect(StringUtils.hexEqual(sigHex, e["expected"]), true);
    }
  });
}
