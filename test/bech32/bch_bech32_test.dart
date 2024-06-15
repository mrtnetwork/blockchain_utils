import 'package:blockchain_utils/bip/coin_conf/coins_conf.dart';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

final List<Map<String, String>> _testVect = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "bitcoincash:qp63uahgrxged4z5jswyt5dn5v3lzsem6cy4spdc2h",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "bitcoincash:qqcw4x2ejv6gqxlsn46n4uut54rgqzl23v4y77ks69",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "bitcoincash:qqv2htk4pd7pza3s3w4qjjc9gwpmwa039s9cgntx7v",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "bchtest:qq54jk3u0pmql6g0azpmjghn2wm8gswj35af22xyv3",
  },
  {
    "raw": "b819a85f25b116c2f7e64416a55b8d49b744d209",
    "encode": "bchtest:qzupn2zlykc3dshhuezpdf2m34ymw3xjpycg0fwyaq",
  },
  {
    "raw": "904c82e2c1a8508ba784e4e53e195b5047682e87",
    "encode": "bchtest:qzgyeqhzcx59pza8snjw20setdgyw6pwsulf9dv498",
  },
];

void main() {
  test("bach32 decode", () {
    for (final i in _testVect) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf(":"));
      final decode = BchBech32Decoder.decode(hrp, i["encode"]!);
      expect(BytesUtils.toHexString(decode.item2), i["raw"]);
      expect(
          BytesUtils.bytesEqual(
              decode.item1, CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer),
          true);
    }
  });
  test("bach32 encode", () {
    for (final i in _testVect) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf(":"));
      final decode = BchBech32Encoder.encode(
          hrp,
          CoinsConf.bitcoinCashMainNet.params.p2pkhStdNetVer!,
          BytesUtils.fromHexString(i["raw"]!));
      expect(decode, i["encode"]);
    }
  });

  test("invalid decode", () {
    expect(() {
      BchBech32Decoder.decode("bitcoincash",
          "bitciincash:qq54jk3u0pmql6g0azpmjghn2wm8gswj35853zv6sr");
    }, throwsA(isA<ArgumentException>()));
  });
}
