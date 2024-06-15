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
}

void _decodeFloat() {
  final cb = CborFloatValue(2.0);
  final dec2 = CborObject.fromCbor(cb.encode());
  expect(dec2.value, cb.value);
}

void _decodeString() {
  final cb = CborStringValue("mrtnetwork");
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.value, cb.value);
}

void _decodeStringIndefinite() {
  final cb = CborIndefiniteStringValue(["mrtnetwork", "mrtnetwork"]);
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec.runtimeType, CborIndefiniteStringValue);
  dec as CborIndefiniteStringValue;
  expect(CompareUtils.iterableIsEqual(dec.value, cb.value), true);
}

void _decodeMap() {
  final cb = CborMapValue.fixedLength(
      {0: "mrtnetwork", BigInt.one: BigInt.two, "metnetwork": "mrtnetwork"});
  final dec = CborObject.fromCbor(cb.encode());
  expect(dec is CborMapValue, true);

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

  dec as CborListValue;
  final valuesDec = dec.value.map((e) => e.value).toList();
  expect(CompareUtils.iterableIsEqual(cb.value, valuesDec), true);
}

void _decodeDateTime() {
  final cb = CborStringDateValue(DateTime.now());
  final decode = CborObject.fromCbor(cb.encode());
  expect(decode is CborStringDateValue, true);
  expect(cb.value.difference(decode.value).inMilliseconds, 0);
  final cb2 = CborEpochFloatValue(DateTime.now());
  final decode2 = CborObject.fromCbor(cb2.encode());
  expect(decode2 is CborEpochFloatValue, true);
  expect(cb2.value.difference(decode2.value).inMilliseconds, 0);

  final cb3 = CborEpochIntValue(DateTime.now());
  final decode3 = CborObject.fromCbor(cb3.encode());
  expect(decode3 is CborEpochIntValue, true);
  expect(cb3.value.difference(decode3.value).inSeconds, 0);
}

void main() {
  // decode
  test("cbor decode", () {
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
