import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  const bool native = bool.fromEnvironment('dart.library.io');
  group("Sinsemilla", () {
    test("test vector", _testV);
    test("SinsemillaPad", _test);
    if (native) test("Sinsemilla", _testDomainHash);
  });
}

void _testDomainHash() {
  _testSinseMillaNative();
  final sinsemillaS = _testSinseMilla();
  for (final t in _testVector) {
    final i = _TestVector.fromJson(t);
    final s = HashDomain.fromDomain(i.domain, sinsemillaS: sinsemillaS);
    final r = s.hashToPoint(i.msg);
    final toBytes = r?.toBytes();
    expect(toBytes, i.point);
  }
}

void _testV() {
  for (final t in _testVector) {
    final i = _TestVector.fromJson(t);
    final s = HashDomainNative.fromDomain(i.domain);
    final r = s.hashToPoint(i.msg);
    final toBytes = r?.toBytes();
    expect(toBytes, i.point);
  }
}

void _test() {
  SinsemillaPad pad = SinsemillaPad([]);
  expect(pad.toList(), <bool>[]);
  pad = SinsemillaPad([true]);
  expect(pad.toList(), [
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ]);
  pad = SinsemillaPad([true, true]);
  expect(pad.toList(), [
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ]);
  pad = SinsemillaPad([true, true, true]);
  expect(pad.toList(), [
    true,
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ]);
  pad = SinsemillaPad([
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
  ]);
  expect(pad.toList(), [
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
  ]);
  pad = SinsemillaPad([
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    true,
  ]);
  expect(pad.toList(), [
    true,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    false,
    true,
    true,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
    false,
  ]);
}

List<PallasPoint> _testSinseMilla() {
  final constants = HashDomainNative.generateSinsemillaSConstants();
  List<PallasPoint> sinsemillaS = [];
  for (int j = 0; j < constants.length; j++) {
    final hash = PallasPoint.hashToCurve(
      domainPrefix: "z.cash:SinsemillaS",
      message: j.toU32LeBytes(),
    );
    final s = PallasPoint.fromBytes(constants[j].toBytes());
    sinsemillaS.add(hash);
    expect(s, hash);
  }
  return sinsemillaS;
}

List<PallasNativePoint> _testSinseMillaNative() {
  final constants = HashDomainNative.generateSinsemillaSConstants();
  List<PallasNativePoint> sinsemillaS = [];
  for (int j = 0; j < constants.length; j++) {
    final hash = PallasNativePoint.hashToCurve(
      domainPrefix: "z.cash:SinsemillaS",
      message: j.toU32LeBytes(),
    );
    expect(constants[j], hash);
    sinsemillaS.add(hash);
  }
  return sinsemillaS;
}

List<Map<String, dynamic>> _testVector = [
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg": "0001011010100110001101100011011011110110",
    "point": "9854aa384363b5708e06b419b643586839653fba5a782d2db14ced13c19a83ab",
    "hash": "9854aa384363b5708e06b419b643586839653fba5a782d2db14ced13c19a832b",
  },
  {
    "domain": "z.cash:test-Sinsemilla-longer",
    "msg":
        "11010010100001010010111000011001010101110001011101010111011111110100111011110010100000101001101000011010101101000110001101",
    "point": "ed5b988e4e98171f618feeb123e5cd0dc2d36711c506d5be115cfe388f03c480",
    "hash": "ed5b988e4e98171f618feeb123e5cd0dc2d36711c506d5be115cfe388f03c400",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg":
        "101101010101111111010110101010100101100011010011111011001000110000100110010010110110011111000100100",
    "point": "d95ee58fbdaa6f3de5e4fd7afc35fa9dcfe82ad19306b07e6cda0c30e5983407",
    "hash": "d95ee58fbdaa6f3de5e4fd7afc35fa9dcfe82ad19306b07e6cda0c30e5983407",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg":
        "0011000100101111001010001100111101001001100001100100010010110101011110010011111011011001111110001010011011110011001001110000010001010111101001000000111101100001110111110111010010010000100001110101000110010001100",
    "point": "6a924b41398429910a78832b61192a0b6740d62777eb71545032eb6ce93ec9b8",
    "hash": "6a924b41398429910a78832b61192a0b6740d62777eb71545032eb6ce93ec938",
  },
  {
    "domain": "z.cash:test-Sinsemilla-longer",
    "msg": "0111111110000101001010111011101010011001000011101000000100000",
    "point": "dc5ff05b6f18b076b6128237a759edc7c8778c70222c79b734037b69393abfbe",
    "hash": "dc5ff05b6f18b076b6128237a759edc7c8778c70222c79b734037b69393abf3e",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg":
        "11001101001100110101110110110111111000100110001000111000010011111000100111101110001001001101011110110001111110001001111001101110111100101111000101110110111111111010010101011000100001000100011001011011101110011",
    "point": "c76c8d7c4355041bd7a7c99b548644196f419456207537c282858a9b192d07bb",
    "hash": "c76c8d7c4355041bd7a7c99b548644196f419456207537c282858a9b192d073b",
  },
  {
    "domain": "z.cash:test-Sinsemilla-longer",
    "msg":
        "0010011001101101111000110110101011110000011101001110110011011100100111001000100101101111101100000000",
    "point": "1ae825eb42d74e1bca7ee8a1f8f3ded801ffcd1f22ba75c34bd6e06a2c7c5aa0",
    "hash": "1ae825eb42d74e1bca7ee8a1f8f3ded801ffcd1f22ba75c34bd6e06a2c7c5a20",
  },
  {
    "domain": "z.cash:test-Sinsemilla-longer",
    "msg":
        "110111001000110011100101111011100110111110111110110111010100101111101101100010110001000010010000100000111000110000100111010011000100100000100111001000100010000101010000110001111",
    "point": "38cfa600afd8670e1f9a79cb22425fa950cc4d3a3f5afe3976d71bb111460c2b",
    "hash": "38cfa600afd8670e1f9a79cb22425fa950cc4d3a3f5afe3976d71bb111460c2b",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg":
        "00101010011011111001101011100001001100001111111100101000010111111011110101000",
    "point": "826fcbedfc83b9faa5711aab59bfc91bd445581467725dde941d58e626566615",
    "hash": "826fcbedfc83b9faa5711aab59bfc91bd445581467725dde941d58e626566615",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg":
        "1110101011110101010101011100100100110100010110100000011110011100101010000000001011010111001101000111001100101000110",
    "point": "0bf06ce81005b81a14809fa6ebcb94e2b6375f87ce51958c9498ed1a313c6a94",
    "hash": "0bf06ce81005b81a14809fa6ebcb94e2b6375f87ce51958c9498ed1a313c6a14",
  },
  {
    "domain": "z.cash:test-Sinsemilla",
    "msg": "10111010",
    "point": "806acc247ac9ba90d25f583dadb5e0ee5c03e1ab3570b362b4be5a8bceb60b00",
    "hash": "806acc247ac9ba90d25f583dadb5e0ee5c03e1ab3570b362b4be5a8bceb60b00",
  },
];

class _TestVector {
  final String domain; // Vec<u8>
  final List<bool> msg; // Vec<bool>
  final List<int> point; // [u8; 32]
  final List<int> hash; // [u8; 32]

  Map<String, dynamic> toJson() {
    return {
      "domain": domain,
      "msg": msg.map((e) => e ? "1" : "0").join(),
      "point": BytesUtils.toHexString(point),
      "hash": BytesUtils.toHexString(hash),
    };
  }

  _TestVector({
    required this.domain,
    required this.msg,
    required this.point,
    required this.hash,
  });

  factory _TestVector.fromJson(Map<String, dynamic> json) {
    final point = BytesUtils.fromHexString(json['point']);
    final hash = BytesUtils.fromHexString(json['hash']);

    return _TestVector(
      domain: json['domain'],
      msg: BitUtils.fromString(json['msg']),
      point: point,
      hash: hash,
    );
  }
}
