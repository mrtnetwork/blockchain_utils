import 'package:blockchain_utils/bech32/bech32_base.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/exception/exceptions.dart';
import 'package:test/test.dart';

final List<Map<String, String>> _testVect = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "cosmos1w508d6qejxtdg4y5r3zarvary0c5xw7k6ah60c",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "cosmos1xr4fjkvnxjqphuyaw5a08za9g6qqh65t36srck",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "band1rz46a4gt0sghvvyt4gy5kp2rswmhtufv49nfef",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "band199v450rcwc87jrlgswuj9u6nke6yr55dxjrx4e",
  },
];

void main() {
  test("bach32 decode", () {
    for (final i in _testVect) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
      final decode = Bech32Decoder.decode(hrp, i["encode"]!);
      expect(BytesUtils.toHexString(decode), i["raw"]);
    }
  });
  test("bach32 encode", () {
    for (final i in _testVect) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
      final encode =
          Bech32Encoder.encode(hrp, BytesUtils.fromHexString(i["raw"]!));
      expect(encode, i["encode"]);
    }
  });
  test("invalid decode", () {
    expect(() {
      Bech32Decoder.decode(
          "cosmos", "cosmis1w508d6qejxtdg4y5r3zarvary0c5xw7khxen85");
    }, throwsA(isA<ArgumentException>()));
  });
}
