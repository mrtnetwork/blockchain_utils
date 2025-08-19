import 'package:blockchain_utils/blockchain_utils.dart';
import 'package:test/test.dart';

import 'quick_hex.dart';

List<CborObject> _testList1 = [
  CborIntValue(0),
  CborIntValue(0),
  CborStringValue("mrtnetwork"),
  CborBigIntValue(BigInt.parse("10000000000000000000000")),
];
Map<CborObject, CborObject> _mapTest1 = {
  CborIntValue(0): CborIntValue(0),
  CborStringValue("mrtnetwork"):
      CborBigIntValue(BigInt.parse("10000000000000000000000")),
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
  final cb = CborMapValue<CborObject, CborObject>.definite({
    CborIntValue(0): CborStringValue("mrtnetwork"),
    CborBigIntValue(BigInt.one): CborBigIntValue(BigInt.two),
    CborStringValue("mrtnetwork"): CborStringValue("mrtnetwork")
  });
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborMapValue, true);
  expect(dec.encode(), cb.encode());
  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(keys.map((e) => e.value), keysDec), true);
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(values.map((e) => e.value), valuesDec),
      true);
}

void _decodeMapDynamic() {
  final cb = CborMapValue<CborObject, CborObject>.inDefinite({
    CborIntValue(0): CborStringValue("mrtnetwork"),
    CborBigIntValue(BigInt.one): CborBigIntValue(BigInt.two),
    CborStringValue("mrtnetwork"): CborStringValue("mrtnetwork"),
  });
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.encode(), cb.encode());
  expect(dec is CborMapValue, true);

  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(keys.map((e) => e.value), keysDec), true);
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(values.map((e) => e.value), valuesDec),
      true);
}

void _decodeList() {
  final cb = CborListValue<CborObject>.inDefinite([
    CborIntValue(0),
    CborStringValue("mrtnetwork"),
    CborBigIntValue(BigInt.one),
    CborBigIntValue(BigInt.two),
    CborStringValue("metnetwork"),
    CborStringValue("mrtnetwork"),
  ]);
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborListValue, true);
  expect(dec.encode(), cb.encode());

  dec as CborListValue;
  final valuesDec = dec.value.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(cb.value.map((e) => e.value), valuesDec),
      true);
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
  final list = CborListValue<CborObject>.definite([
    CborIntValue(0),
    CborListValue<CborObject>.definite([
      CborIntValue(1),
      CborIntValue(2),
      CborBigIntValue(BigInt.parse("111111111111111111111111110")),
    ]),
    CborListValue<CborObject>.definite([
      CborIntValue(1),
      CborIntValue(2),
      CborBigIntValue(BigInt.parse("111111111111111111111111110")),
      CborListValue<CborObject>.definite([
        CborIntValue(-1),
        CborIntValue(2),
        CborBigIntValue(BigInt.parse("111111111111111111111111110")),
      ]),
      CborBoleanValue(false),
      CborBoleanValue(false),
      CborBoleanValue(false),
      CborBoleanValue(true)
    ]),
    CborBytesValue(List<int>.filled(100, 12)),
    CborMapValue<CborObject, CborObject>.definite({
      CborIntValue(1): CborIntValue(1),
      CborStringValue("one"): CborStringValue("one"),
      CborBigIntValue(BigInt.two): CborBytesValue(List<int>.filled(19, 31)),
      CborListValue<CborObject>.definite([
        CborIntValue(-1),
        CborIntValue(2),
        CborBigIntValue(BigInt.parse("111111111111111111111111110")),
      ]): CborListValue<CborObject>.definite([
        CborIntValue(-1),
        CborIntValue(2),
        CborBigIntValue(BigInt.parse("111111111111111111111111110")),
      ])
    }),
    CborNullValue(),
    CborBigIntValue(BigInt.one),
    CborBigIntValue(BigInt.two),
    CborStringValue("metnetwork"),
    CborStringValue("mrtnetwork"),
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
      CborListValue<CborObject>.definite([
        CborIntValue(1),
        CborIntValue(2),
        CborIntValue(3),
        CborBigIntValue(BigInt.from(-1)),
        CborBigIntValue(BigInt.from(-2)),
        CborBigIntValue(BigInt.from(-3)),
        const CborUriValue("https://github.com/mrtnetwork"),
        const CborRegxpValue(r'[A-Za-z0-9+/_-]+'),
        const CborMimeValue("image/svg+xml"),
        const CborBaseUrlValue("cXdlbHF3amVsa3Fqd2VranFrd2pla2xxd2pla2xxdw==",
            CborBase64Types.base64),
        const CborBaseUrlValue("cXdlbHF3amVsa3Fqd2VranFrd2pla2xxd2pla2xxdw",
            CborBase64Types.base64Url),
        CborStringValue("mystrig"),

        ///
        CborListValue<CborObject>.inDefinite([
          CborEpochFloatValue(DateTime.now()),
          CborDecimalFracValue(
              BigInt.from(123123), BigInt.parse("123123123123123")),
          CborEpochIntValue(DateTime.now()),
          CborTagValue(
              CborListValue<CborObject>.definite([
                CborIntValue(1),
                CborBytesValue(List<int>.filled(32, 32)),
              ]),
              [
                1,
                2,
                3,
              ])
        ]),
        CborMapValue<CborObject, CborObject>.definite({
          CborStringValue("key1"): CborIntValue(1),
          CborStringValue("key2"): CborStringValue("2"),
          CborStringValue("key3"): CborBytesValue([3]),
          CborIntValue(4): CborStringValue("value 4"),
          CborBigIntValue(BigInt.parse("11111111111111111111111111")):
              CborIntValue(5),
          CborStringValue("key6"): CborListValue<CborIntValue>.inDefinite([
            CborIntValue(1),
            CborIntValue(2),
            CborIntValue(3),
            CborIntValue(4),
            CborIntValue(5)
          ]),
          CborStringValue("key7"): CborTagValue(
              CborMapValue<CborObject, CborObject>.inDefinite({
                CborStringValue("1"): CborStringValue("1"),
                CborStringValue("2"): CborStringValue("2"),
                CborIntValue(1): CborIntValue(1)
              }),
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
    expect(CborListValue<CborObject>.definite(_testList1).encode().toHex(),
        "8400006a6d72746e6574776f726bc24a021e19e0c9bab2400000");
    expect(CborListValue<CborObject>.inDefinite(_testList1).encode().toHex(),
        "9f00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
    expect(CborMapValue.inDefinite(_mapTest1).encode().toHex(),
        "bf00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
    expect(CborMapValue.definite(_mapTest1).encode().toHex(),
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
    expect(
        CborListValue<CborObject>.definite(
                [CborBigIntValue(BigInt.one), CborBigIntValue(BigInt.one)])
            .encode()
            .toHex(),
        "82c24101c24101");

    expect(
        CborMapValue.definite({CborIntValue(0): CborIntValue(0)})
            .encode()
            .toHex(),
        "a10000");
    expect(
        CborMapValue.definite({const CborIntValue(0): const CborIntValue(0)})
            .encode()
            .toHex(),
        "a10000");
  });
}
