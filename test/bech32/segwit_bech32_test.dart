// ignore_for_file: depend_on_referenced_packages

import 'package:blockchain_utils/bech32/segwit_bech32.dart';
import 'package:blockchain_utils/utils/utils.dart';
import 'package:test/test.dart';

final List<Map<String, String>> _testVectors = [
  {
    "raw": "751e76e8199196d454941c45d1b3a323f1433bd6",
    "encode": "bc1qw508d6qejxtdg4y5r3zarvary0c5xw7kv8f3t4",
  },
  {
    "raw": "30ea99599334801bf09d753af38ba546800bea8b",
    "encode": "bc1qxr4fjkvnxjqphuyaw5a08za9g6qqh65t8qwgum",
  },
  {
    "raw": "18abaed50b7c1176308baa094b054383b775f12c",
    "encode": "bc1qrz46a4gt0sghvvyt4gy5kp2rswmhtufv6sdq9v",
  },
  {
    "raw": "5788df3047dd2c2545eee12784e6212745916bb7",
    "encode": "bc1q27yd7vz8m5kz230wuyncfe3pyazez6ah58yzy0",
  },
  {
    "raw": "3a3eff6f41ce759a8dd95fc1a2d762077f4f3b64",
    "encode": "bc1q8gl07m6pee6e4rwetlq694mzqal57wmyadd9sn",
  },
  {
    "raw": "37552063bb0baa42b910712df06b814b928a88f0",
    "encode": "bc1qxa2jqcampw4y9wgswyklq6upfwfg4z8s5m4v3v",
  },
  {
    "raw": "f9ce94eab4ed454dd0077e3dc24bdfb8d5df4008",
    "encode": "bc1ql88ff645a4z5m5q80c7uyj7lhr2a7sqgtss7ek",
  },
  {
    "raw": "29595a3c78760fe90fe883b922f353b67441d28d",
    "encode": "tb1q99v450rcwc87jrlgswuj9u6nke6yr55drpxuj0",
  },
  {
    "raw": "b819a85f25b116c2f7e64416a55b8d49b744d209",
    "encode": "tb1qhqv6she9kytv9alxgst22kudfxm5f5sf2lgpc6",
  },
  {
    "raw": "904c82e2c1a8508ba784e4e53e195b5047682e87",
    "encode": "tb1qjpxg9ckp4pgghfuyunjnux2m2prkst580chf9n",
  },
];
void main() {
  test("test decode", () {
    for (final i in _testVectors) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
      final decode = SegwitBech32Decoder.decode(hrp, i["encode"]!);
      expect(decode.item1, 0);
      expect(BytesUtils.toHexString(decode.item2), i["raw"]);
    }
  });
  test("test encode", () {
    for (final i in _testVectors) {
      final hrp = i["encode"]!.substring(0, i["encode"]!.indexOf("1"));
      final decode = SegwitBech32Encoder.encode(
          hrp, 0, BytesUtils.fromHexString(i["raw"]!));
      expect(decode, i["encode"]);
    }
  });
}
