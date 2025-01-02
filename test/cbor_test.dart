import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'quick_hex.dart';

List<dynamic> _testList1 = [
  0,
  0,
  "mrtnetwork",
  BigInt.parse("10000000000000000000000"),
];
Map<dynamic, dynamic> _mapTest1 = {
  0: 0,
  "mrtnetwork": BigInt.parse("10000000000000000000000"),
};
void _decodeInt() {
  const cb = CborIntValue(0);
  final dec2 = CborObject.fromCbor(cb.encode());
  expect(dec2.value, cb.value);
  expect(dec2.encode(), cb.encode());
}

void _decodeFloat() {
  final cb = CborFloatValue(2.0);
  final dec2 = CborObject.fromCbor(cb.encode());
  expect(dec2.value, cb.value);
  expect(dec2.encode(), cb.encode());
}

void _decodeString() {
  final cb = CborStringValue("mrtnetwork");
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.value, cb.value);
  expect(dec.encode(), cb.encode());
}

void _decodeStringIndefinite() {
  final cb = CborIndefiniteStringValue(["mrtnetwork", "mrtnetwork"]);
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.runtimeType, CborIndefiniteStringValue);
  dec as CborIndefiniteStringValue;
  expect(CompareUtils.iterableIsEqual(dec.value, cb.value), true);
  expect(dec.encode(), cb.encode());
}

void _decodeMap() {
  final cb = CborMapValue.fixedLength(
      {0: "mrtnetwork", BigInt.one: BigInt.two, "mrtnetwork": "mrtnetwork"});
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborMapValue, true);
  expect(dec.encode(), cb.encode());

  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(keys, keysDec), true);
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(values, valuesDec), true);
}

void _decodeMapDynamic() {
  final cb = CborMapValue.dynamicLength({
    0: "mrtnetwork",
    BigInt.one: BigInt.two,
    "metnetwork": "mrtnetwork",
  });
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.encode(), cb.encode());
  expect(dec is CborMapValue, true);

  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(keys, keysDec), true);
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(values, valuesDec), true);
}

void _decodeList() {
  final cb = CborListValue.dynamicLength([
    0,
    "mrtnetwork",
    BigInt.one,
    BigInt.two,
    "metnetwork",
    "mrtnetwork",
  ]);
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborListValue, true);
  expect(dec.encode(), cb.encode());

  dec as CborListValue;
  final valuesDec = dec.value.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(cb.value, valuesDec), true);
}

void _decodeDateTime() {
  final cb = CborStringDateValue(DateTime.now());
  final decode = CborObject.fromCbor(cb.encode());
  expect(decode is CborStringDateValue, true);
  expect(cb.value.difference(decode.value).inMilliseconds, 0);
  expect(decode.encode(), cb.encode());
  final cb2 = CborEpochFloatValue(DateTime.now());
  final decode2 = CborObject.fromCbor(cb2.encode());
  expect(decode2 is CborEpochFloatValue, true);
  expect(cb2.value.difference(decode2.value).inMilliseconds, 0);
  expect(decode2.encode(), cb2.encode());

  final cb3 = CborEpochIntValue(DateTime.now());
  final decode3 = CborObject.fromCbor(cb3.encode());
  expect(decode3 is CborEpochIntValue, true);
  expect(cb3.value.difference(decode3.value).inSeconds, 0);
  expect(decode3.encode(), cb3.encode());
}

void _nestedList() {
  final list = CborListValue.fixedLength([
    0,
    CborListValue.fixedLength([
      1,
      2,
      BigInt.parse("111111111111111111111111110"),
    ]),
    CborListValue.fixedLength([
      1,
      2,
      BigInt.parse("111111111111111111111111110"),
      CborListValue.fixedLength([
        -1,
        2,
        BigInt.parse("111111111111111111111111110"),
      ]),
      false,
      false,
      false,
      true
    ]),
    CborBytesValue(List<int>.filled(100, 12)),
    CborMapValue.fixedLength({
      1: 1,
      "one": "one",
      BigInt.two: CborBytesValue(List<int>.filled(19, 31)),
      CborListValue.fixedLength([
        -1,
        2,
        BigInt.parse("111111111111111111111111110"),
      ]): CborListValue.fixedLength([
        -1,
        2,
        BigInt.parse("111111111111111111111111110"),
      ])
    }),
    null,
    BigInt.one,
    BigInt.two,
    "metnetwork",
    "mrtnetwork",
    CborFloatValue.from16BytesFloat(2.0),
    CborFloatValue(-2.0),
    CborFloatValue.from64BytesFloat(233333333333.100000)
  ]);
  final cb = CborTagValue(list, [1, 2, 3]);
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborTagValue, true);
  expect(dec.encode(), cb.encode());
}

void _tag() {
  CborObject cborTag = CborTagValue(const CborNullValue(), [1, 2, 3]);
  expect(cborTag.encode(), CborObject.fromCbor(cborTag.encode()).encode());
  cborTag = CborTagValue(
      CborListValue.fixedLength([
        1,
        2,
        3,
        BigInt.from(-1),
        BigInt.from(-2),
        BigInt.from(-3),
        const CborUriValue("https://github.com/mrtnetwork"),
        const CborRegxpValue(r'[A-Za-z0-9+/_-]+'),
        const CborMimeValue("image/svg+xml"),
        const CborBaseUrlValue("cXdlbHF3amVsa3Fqd2VranFrd2pla2xxd2pla2xxdw==",
            CborBase64Types.base64),
        const CborBaseUrlValue("cXdlbHF3amVsa3Fqd2VranFrd2pla2xxd2pla2xxdw",
            CborBase64Types.base64Url),
        "mystrig",

        ///
        CborListValue.dynamicLength([
          CborEpochFloatValue(DateTime.now()),
          CborDecimalFracValue(
              BigInt.from(123123), BigInt.parse("123123123123123")),
          CborEpochIntValue(DateTime.now()),
          CborTagValue(
              CborListValue.fixedLength([
                1,
                CborBytesValue(List<int>.filled(32, 32)),
              ]),
              [
                1,
                2,
                3,
              ])
        ]),
        CborMapValue.fixedLength({
          "key1": 1,
          "key2": "2",
          "key3": CborBytesValue([3]),
          4: CborStringValue("value 4"),
          BigInt.parse("11111111111111111111111111"): 5,
          "key6": CborListValue.dynamicLength([1, 2, 3, 4, 5]),
          "key7": CborTagValue(
              CborMapValue.dynamicLength({"1": "1", "2": "2", 1: 1}),
              [100, 1001, 100002])
        }),
      ]),
      [1, 2, 3]);
  expect(cborTag.encode(), CborObject.fromCbor(cborTag.encode()).encode());
}

void main() {
  test("cbor decode", () {
    _tag();
    _nestedList();
    _decodeInt();
    _decodeFloat();
    _decodeString();
    _decodeStringIndefinite();
    _decodeMap();
    _decodeMapDynamic();
    _decodeList();
    _decodeDateTime();
  });

  test("cbor encode", () {
    expect(CborListValue.fixedLength(_testList1).encode().toHex(),
        "8400006a6d72746e6574776f726bc24a021e19e0c9bab2400000");
    expect(CborListValue.dynamicLength(_testList1).encode().toHex(),
        "9f00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
    expect(CborMapValue.dynamicLength(_mapTest1).encode().toHex(),
        "bf00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
    expect(CborMapValue.fixedLength(_mapTest1).encode().toHex(),
        "a200006a6d72746e6574776f726bc24a021e19e0c9bab2400000");
    expect(const CborIntValue(1).encode().toHex(), "01");
    expect(const CborIntValue(-1).encode().toHex(), "20");
    expect(const CborIntValue(1000000000000000).encode().toHex(),
        "1b00038d7ea4c68000");
    expect(const CborIntValue(-1000000000000000).encode().toHex(),
        "3b00038d7ea4c67fff");
    expect(CborBigIntValue(BigInt.parse("1")).encode().toHex(), "c24101");
    expect(CborBigIntValue(BigInt.parse("-1")).encode().toHex(), "c340");
    expect(CborStringValue("MRTNETWORK").encode().toHex(),
        "6a4d52544e4554574f524b");
    expect(
        CborBytesValue(BytesUtils.fromHexString("1b00038d7ea4c68000"))
            .encode()
            .toHex(),
        "491b00038d7ea4c68000");
    expect(CborFloatValue(1.0).encode().toHex(), "f93c00");
    expect(
        CborFloatValue(123123123123.2).encode().toHex(), "fb423caab5c3b33333");
    expect(CborDecimalFracValue(BigInt.one, BigInt.one).encode().toHex(),
        "c4820101");
    expect(CborListValue.fixedLength([BigInt.one, BigInt.one]).encode().toHex(),
        "82c24101c24101");

    expect(CborMapValue.fixedLength({0: 0}).encode().toHex(), "a10000");
    expect(
        CborMapValue.fixedLength({const CborIntValue(0): const CborIntValue(0)})
            .encode()
            .toHex(),
        "a10000");
  });
}
