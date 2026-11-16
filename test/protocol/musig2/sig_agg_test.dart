import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';
import 'sig_agg_vector.dart';

import '../../utils.dart';

void sigAggTest() {
  _test();
}

void main() {
  BlockchainUtilsTestApi.runTest(sigAggTest, "Sig Agg", onNative: _testNative);
}

void _test() {
  test("MuSig2 sign/verify", () {
    final musigConst = Musig2Const();
    final List<List<int>> pubKeys =
        (sigAggVector["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<List<int>> tweaks =
        (sigAggVector["tweaks"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<List<int>> psigs =
        (sigAggVector["psigs"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> message = BytesUtils.fromHexString(sigAggVector["msg"]);
    final validateTestCase = List<Map<String, dynamic>>.from(
      sigAggVector["valid_test_cases"]!,
    );
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final List<int> aggnonce = BytesUtils.fromHexString(e["aggnonce"]);
      final sigIndices = List<int>.from(e["psig_indices"]);
      final sigs = List.generate(sigIndices.length, (i) {
        return psigs.elementAt(sigIndices[i]);
      });
      final tweakIndices = List<int>.from(e["tweak_indices"]);
      final tw = List.generate(tweakIndices.length, (i) {
        return tweaks.elementAt(tweakIndices[i]);
      });
      final List<bool> isXOnly = List<bool>.from(e["is_xonly"]);
      final session = MuSig2Session(
        aggnonce: aggnonce,
        publicKeys: keys,
        tweaks: List.generate(
          tw.length,
          (i) => MuSig2Tweak(tweak: tw[i], isXOnly: isXOnly[i]),
        ),
        msg: message,
      );
      final sign = musigConst.partialSigAgg(signatures: sigs, session: session);
      final sigHex = BytesUtils.toHexString(sign, lowerCase: false);
      expect(sigHex, e["expected"], reason: "Failed $j");
    }
  });
}

void _testNative(BlockchainUtilsApi api) {
  test("MuSig2 sign/verify native", () {
    final musig = api.muSig2;
    final List<List<int>> pubKeys =
        (sigAggVector["pubkeys"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<List<int>> tweaks =
        (sigAggVector["tweaks"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<List<int>> psigs =
        (sigAggVector["psigs"] as List)
            .map((e) => BytesUtils.fromHexString(e).asImmutableBytes)
            .toList();
    final List<int> message = BytesUtils.fromHexString(sigAggVector["msg"]);
    final validateTestCase = List<Map<String, dynamic>>.from(
      sigAggVector["valid_test_cases"]!,
    );
    for (int j = 0; j < validateTestCase.length; j++) {
      final e = validateTestCase[j];
      final keyIndices = List<int>.from(e["key_indices"]);
      final keys = List.generate(keyIndices.length, (i) {
        return pubKeys.elementAt(keyIndices[i]);
      });
      final List<int> aggnonce = BytesUtils.fromHexString(e["aggnonce"]);
      final sigIndices = List<int>.from(e["psig_indices"]);
      final sigs = List.generate(sigIndices.length, (i) {
        return psigs.elementAt(sigIndices[i]);
      });
      final tweakIndices = List<int>.from(e["tweak_indices"]);
      final tw = List.generate(tweakIndices.length, (i) {
        return tweaks.elementAt(tweakIndices[i]);
      });
      final List<bool> isXOnly = List<bool>.from(e["is_xonly"]);
      final session = MuSig2Session(
        aggnonce: aggnonce,
        publicKeys: keys,
        tweaks: List.generate(
          tw.length,
          (i) => MuSig2Tweak(tweak: tw[i], isXOnly: isXOnly[i]),
        ),
        msg: message,
      );
      final sign = musig.partialSigAgg(signatures: sigs, session: session);
      final sigHex = BytesUtils.toHexString(sign, lowerCase: false);
      expect(sigHex, e["expected"]);
    }
  });
}
