import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/expect.dart';
import 'package:test/scaffolding.dart';

void main() {
  test("FF1", _ff1);
}

void _ff1() {
  for (final t in _testVector) {
    final i = _TestVector.fromJson(t);
    final aes = AES(i.key);
    final ff = FF1Flexible(radix: i.radix, aes: aes);
    FlexibleNumeralString enc = ff.encrypt(
      FlexibleNumeralString(i.pt),
      tweak: i.tweak,
    );
    expect(enc.digits, i.ct);
    FlexibleNumeralString dec = ff.decrypt(
      FlexibleNumeralString(i.ct),
      tweak: i.tweak,
    );
    expect(dec.digits, i.pt);
  }

  for (final t in _testVector.indexed) {
    final i = _TestVector.fromJson(t.$2);
    final binary = i.binary;
    if (binary == null) continue;
    final aes = AES(i.key);
    final ff = FF1Binary(aes: aes, radix: i.radix);
    BinaryNumeralString enc = ff.encrypt(
      BinaryNumeralString(binary.pt),
      tweak: i.tweak,
    );
    expect(enc.data, binary.ct);
    BinaryNumeralString dec = ff.decrypt(
      BinaryNumeralString(binary.ct),
      tweak: i.tweak,
    );
    expect(dec.data, binary.pt);
  }
}

class _BinaryTestVector {
  final List<int> pt; // plaintext bytes
  final List<int> ct; // ciphertext bytes

  _BinaryTestVector({required this.pt, required this.ct});
  factory _BinaryTestVector.fromJson(Map<String, dynamic> json) {
    return _BinaryTestVector(
      pt: json.valueAsBytes("pt"),
      ct: json.valueAsBytes("ct"),
    );
  }

  Map<String, dynamic> toJson() {
    return {"pt": BytesUtils.toHexString(pt), "ct": BytesUtils.toHexString(ct)};
  }
}

class _TestVector {
  final List<int> key;
  final int radix;
  final List<int> tweak;
  final List<int> pt;
  final List<int> ct;
  final _BinaryTestVector? binary;
  factory _TestVector.fromJson(Map<String, dynamic> json) {
    return _TestVector(
      key: json.valueAsBytes("key"),
      radix: json.valueAs("radix"),
      tweak: json.valueAsBytes("tweak"),
      pt: json.valueAsBytes("pt"),
      ct: json.valueAsBytes("ct"),
      binary: json.valueTo<_BinaryTestVector?, Map<String, dynamic>>(
        key: "binary",
        parse: (v) => _BinaryTestVector.fromJson(v),
      ),
    );
  }
  Map<String, dynamic> toJson() {
    return {
      "pt": BytesUtils.toHexString(pt),
      "ct": BytesUtils.toHexString(ct),
      "tweak": BytesUtils.toHexString(tweak),
      "radix": radix,
      "key": BytesUtils.toHexString(key),
      "binary": binary?.toJson(),
    };
  }

  _TestVector({
    required this.key,
    required this.radix,
    required this.tweak,
    required this.pt,
    required this.ct,
    this.binary,
  });
}

List<Map<String, dynamic>> _testVector = [
  {
    "pt": "00010203040506070809",
    "ct": "02040303040707040804",
    "tweak": "",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3c",
  },
  {
    "pt": "00010203040506070809",
    "ct": "06010204020000070703",
    "tweak": "39383736353433323130",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3c",
  },
  {
    "pt": "000102030405060708090a0b0c0d0e0f101112",
    "ct": "0a091d1f040016151509140d1e0500090e1e16",
    "tweak": "3737373770717273373737",
    "radix": 36,
    "key": "2b7e151628aed2a6abf7158809cf4f3c",
  },
  {
    "pt": "00010203040506070809",
    "ct": "02080300060608010302",
    "tweak": "",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f",
  },
  {
    "pt": "00010203040506070809",
    "ct": "02040906060505050409",
    "tweak": "39383736353433323130",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f",
  },
  {
    "pt": "000102030405060708090a0b0c0d0e0f101112",
    "ct": "210b1303141f0305131b0a20211f0302221c1b",
    "tweak": "3737373770717273373737",
    "radix": 36,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f",
  },
  {
    "pt": "00010203040506070809",
    "ct": "06060507060607000009",
    "tweak": "",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
  },
  {
    "pt": "00010203040506070809",
    "ct": "01000001060203040603",
    "tweak": "39383736353433323130",
    "radix": 10,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
  },
  {
    "pt": "000102030405060708090a0b0c0d0e0f101112",
    "ct": "211c080a000a2311020a1f220a1522231e200d",
    "tweak": "3737373770717273373737",
    "radix": 36,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
  },
  {
    "pt":
        "211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a1522231e200d211c080a000a2311020a1f220a15",
    "ct":
        "15201e15120b0f1901131e03141c231d1e161a1816200e17191f070d1e22091a07191007230f030e10031b13150f220406101610141a130f201f1b18160f1313141d160b0e2208160e1a140923140c16101f141f041c091515050c1d1823160e01110f01052007211806231c22151a0c1b00170b2109130b0f01001e16231814",
    "tweak": "",
    "radix": 36,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
  },
  {
    "pt":
        "00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000",
    "ct":
        "00000000010000010000010100010001000101010001010101010101010100000101000000000001010001010000010101010100000101010001010100010001000101000100010000010000000100000101000001010101",
    "tweak": "",
    "radix": 2,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
    "binary": {"pt": "0000000000000000000000", "ct": "90acee3f83cde7ae5622f3"},
  },
  {
    "pt":
        "00000000010000010000010100010001000101010001010101010101010100000101000000000001010001010000010101010100000101010001010100010001000101000100010000010000000100000101000001010101",
    "ct":
        "01010001010001000101000100000001010000000101010100000000000100000101000001010101010100010100000101010001000100010100010000000001010101000001000000010001000101010101000101000000",
    "tweak": "",
    "radix": 2,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
    "binary": {"pt": "90acee3f83cde7ae5622f3", "ct": "5b8bf120f39bab8527ea1b"},
  },
  {
    "pt":
        "00010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001",
    "ct":
        "00000000010101010001000000000001010101000101000100010101000101010101010100000001010000010001000000000000000001010001010001010100010000000100000100010101000001010000010000010100",
    "tweak": "",
    "radix": 2,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
    "binary": {"pt": "aaaaaaaaaaaaaaaaaaaaaa", "ct": "f082b7ee8f29c07691ce64"},
  },
  {
    "pt":
        "00010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001000100010001",
    "ct":
        "00010101010100010100000001000000000000010101000100010100000000010000000100010001010001000000000000000101010000010101010000010000010000000100010001010001010101000100010000000101",
    "tweak":
        "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f202122232425262728292a2b2c2d2e2f303132333435363738393a3b3c3d3e3f404142434445464748494a4b4c4d4e4f505152535455565758595a5b5c5d5e5f606162636465666768696a6b6c6d6e6f707172737475767778797a7b7c7d7e7f808182838485868788898a8b8c8d8e8f909192939495969798999a9b9c9d9e9fa0a1a2a3a4a5a6a7a8a9aaabacadaeafb0b1b2b3b4b5b6b7b8b9babbbcbdbebfc0c1c2c3c4c5c6c7c8c9cacbcccdcecfd0d1d2d3d4d5d6d7d8d9dadbdcdddedfe0e1e2e3e4e5e6e7e8e9eaebecedeeeff0f1f2f3f4f5f6f7f8f9fafbfcfdfe",
    "radix": 2,
    "key": "2b7e151628aed2a6abf7158809cf4f3cef4359d8d580aa4f7f036d6f04fc6a94",
    "binary": {"pt": "aaaaaaaaaaaaaaaaaaaaaa", "ct": "be11b886a8059c27517bc5"},
  },
  {
    "pt": "0000000000000000000000000000000000000000000000000000000000000000",
    "ct": "0101000101010100010000010101010100000100000000000101000101000000",
    "tweak": "",
    "radix": 2,
    "key": "0000000000000000000000000000000000000000000000000000000000000000",
    "binary": {"pt": "00000000", "ct": "7bf9041b"},
  },
];
