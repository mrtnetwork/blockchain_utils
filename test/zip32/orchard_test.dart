import 'dart:typed_data';
import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

void main() {
  test("Orchard/ZIP-32", _zip32);
  test("Orchard/Diversifier", _diversifier);
  test("Orchard/Diversifier", _diversifierCompare);
}

void _zip32() async {
  final context = DefaultZCryptoContext();
  final i1h = Bip32KeyIndex.hardenIndex(1);
  final i2h = Bip32KeyIndex.hardenIndex(2);
  final i3h = Bip32KeyIndex.hardenIndex(3);
  final m = Zip32Orchard.fromSeed(
    BytesUtils.fromHexString(
      "000102030405060708090a0b0c0d0e0f101112131415161718191a1b1c1d1e1f",
    ),
  );

  final mh1 = m.childKey(i1h, context: context);
  final m1h2h = m.derivePath(
    Bip32Path(elems: [i1h, i2h]).toString(),
    context: context,
  );
  final m1h2h3h = m1h2h.childKey(i3h, context: context);
  final keys = [m, mh1, m1h2h, m1h2h3h];
  for (final i in keys.indexed) {
    final key = i.$2;
    final tv = _TestVector.fromJson(_tVector.elementAt(i.$1));
    expect(key.privateKey.sk.toBytes(), tv.sk);
    expect(key.chainCode.toBytes(), tv.c);
    expect(key.depth.depth, tv.xsk[0]);
    expect(key.fingerPrint.toBytes(), tv.xsk.sublist(1, 5));
    expect(key.index.toBytes(Endian.little), tv.xsk.sublist(5, 9));
    expect(key.privateKey.sk.sk, tv.xsk.sublist(9 + 32));
    expect(
      tv.fp,
      OrchardZip32ChildKeyDerivator().deriveFingerPrint(key.publicKey.fvk),
    );
  }
}

void _diversifierCompare() {
  final i =
      List.generate(
        1000,
        (i) => DiversifierIndex.from(QuickCrypto.nextU32()),
      ).toList();
  i.sort();
  final ids = i.map((e) => e.toU32()).toList();
  int latest = 0;
  for (final i in ids) {
    expect(i >= latest, true);
    latest = i;
  }
}
// 1114858840
// 286111924
// 2900752092

void _diversifier() {
  final two = DiversifierIndex([
    0x02,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ]);
  expect(two.toU32(), 2);
  final mu32 = DiversifierIndex([
    0xff,
    0xff,
    0xff,
    0xff,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
    0x00,
  ]);
  expect(mu32.toU32(), BinaryOps.maxUint32);
  final maxU64 = DiversifierIndex([
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0x00,
    0x00,
    0x00,
  ]);
  expect(maxU64.toU128(), BinaryOps.maxU64);
  expect(DiversifierIndex.fromBigInt(BinaryOps.maxU64), maxU64);
  final maxD = DiversifierIndex([
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
    0xff,
  ]);
  expect(maxD.toU128(), BigInt.parse("0x00ffffffffffffffffffffff"));
  expect(maxD, DiversifierIndex.fromBigInt(maxD.toU128()));
  DiversifierIndex d = DiversifierIndex.zero();
  expect(d.toU32(), 0);
  d = d.increment();
  expect(d.toU32(), 1);
  DiversifierIndex di = DiversifierIndex.from(0xff);
  expect(di.toU32(), 0x00ff);
  di = di.increment();
  expect(di.toU32(), 0x0100);
  di = di.increment();
  expect(di.toU32(), 0x0101);
}

class _TestVector {
  final List<int> sk;
  final List<int> c;
  final List<int> xsk;
  final List<int> fp;
  factory _TestVector.fromJson(Map<String, dynamic> json) {
    return _TestVector(
      sk: json.valueAsBytes("sk"),
      c: json.valueAsBytes("c"),
      xsk: json.valueAsBytes("xsk"),
      fp: json.valueAsBytes("fp"),
    );
  }

  const _TestVector({
    required this.sk,
    required this.c,
    required this.xsk,
    required this.fp,
  });

  Map<String, dynamic> toJson() {
    return {
      "sk": BytesUtils.toHexString(sk),
      "c": BytesUtils.toHexString(c),
      "xsk": BytesUtils.toHexString(xsk),
      "fp": BytesUtils.toHexString(fp),
    };
  }
}

const List<Map<String, dynamic>> _tVector = [
  {
    "sk": "7eee3c1017870990a3dd6891b82f80be8976c1e7dc20d60817a5e88e8b2cd4b8",
    "c": "ab8b7a00509ef20e469b5292b61d474b7cffcb1657924cda720250ae40526677",
    "xsk":
        "000000000000000000ab8b7a00509ef20e469b5292b61d474b7cffcb1657924cda720250ae405266777eee3c1017870990a3dd6891b82f80be8976c1e7dc20d60817a5e88e8b2cd4b8",
    "fp": "ff4cda5002c8d182058807b84e616b6d339e1bbeecea01650568d891a438e706",
  },
  {
    "sk": "98d703fcb40504c95b3b6ed10ecd50082cff97dfd1dd9aa0913c78f977c962af",
    "c": "6a041dfb9cfebee97cb1854fdc481cc04f02c9577aa6f13b2c445b80a9669a22",
    "xsk":
        "01ff4cda50010000806a041dfb9cfebee97cb1854fdc481cc04f02c9577aa6f13b2c445b80a9669a2298d703fcb40504c95b3b6ed10ecd50082cff97dfd1dd9aa0913c78f977c962af",
    "fp": "32bbdc921d066f235dc93e913b8fe1fd5b9f7f6a13d56f18ec0d3620d1f7b9a6",
  },
  {
    "sk": "99afd8894baad58784d0ec08f5148ee2c2a17b2b294b08ef9e0a0cf14bcc0920",
    "c": "6da8b57a36c77ad6412a9dc0115f12aced0ee01c402a0cf0a507cb17fc7bbd1d",
    "xsk":
        "0232bbdc92020000806da8b57a36c77ad6412a9dc0115f12aced0ee01c402a0cf0a507cb17fc7bbd1d99afd8894baad58784d0ec08f5148ee2c2a17b2b294b08ef9e0a0cf14bcc0920",
    "fp": "36a57c4fc5b8b4a3d62f22a5500878f393856b7ecce771ad597ca964b98637d9",
  },
  {
    "sk": "96439ea348a4b2ce4ec7beb4543c70274c8f76495d60c5fa5f018b68f3c32367",
    "c": "b196e9b5809d76577a8944c3f8c8a83f93f0c8f5ace6e7bc9ce4396c034d93fe",
    "xsk":
        "0336a57c4f03000080b196e9b5809d76577a8944c3f8c8a83f93f0c8f5ace6e7bc9ce4396c034d93fe96439ea348a4b2ce4ec7beb4543c70274c8f76495d60c5fa5f018b68f3c32367",
    "fp": "be1a1b661d2ca319822a32550d6dc488b6571e0cd781d5078b8f7ba366ddd368",
  },
];
