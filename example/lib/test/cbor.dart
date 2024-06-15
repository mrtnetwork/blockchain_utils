import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/types/bigint.dart';
import 'package:blockchain_utils/cbor/types/bytes.dart';
import 'package:blockchain_utils/cbor/types/datetime.dart';
import 'package:blockchain_utils/cbor/types/decimal.dart';
import 'package:blockchain_utils/cbor/types/double.dart';
import 'package:blockchain_utils/cbor/types/int.dart';
import 'package:blockchain_utils/cbor/types/int64.dart';
import 'package:blockchain_utils/cbor/types/list.dart';
import 'package:blockchain_utils/cbor/types/map.dart';
import 'package:blockchain_utils/cbor/types/string.dart';
import 'package:example/test/quick_hex.dart';

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
  assert(dec2.value == cb.value);
}

void _decodeFloat() {
  final cb = CborFloatValue(2.0);
  final dec2 = CborObject.fromCbor(cb.encode());
  assert(dec2.value == cb.value);
}

void _decodeString() {
  final cb = CborStringValue("mrtnetwork");
  final dec = CborObject.fromCbor(cb.encode());
  assert(dec.value == cb.value);
}

void _decodeStringIndefinite() {
  final cb = CborIndefiniteStringValue(["mrtnetwork", "mrtnetwork"]);
  final dec = CborObject.fromCbor(cb.encode());
  assert(dec.runtimeType == CborIndefiniteStringValue);
  dec as CborIndefiniteStringValue;
  assert(CompareUtils.iterableIsEqual(dec.value, cb.value));
}

void _decodeMap() {
  final cb = CborMapValue.fixedLength(
      {0: "mrtnetwork", BigInt.one: BigInt.two, "metnetwork": "mrtnetwork"});
  final dec = CborObject.fromCbor(cb.encode());
  assert(dec is CborMapValue);

  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  assert(CompareUtils.iterableIsEqual(keys, keysDec));
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  assert(CompareUtils.iterableIsEqual(values, valuesDec));
}

void _decodeMapDynamic() {
  final cb = CborMapValue.dynamicLength({
    0: "mrtnetwork",
    BigInt.one: BigInt.two,
    "metnetwork": "mrtnetwork",
  });
  final dec = CborObject.fromCbor(cb.encode());
  assert(dec is CborMapValue);

  dec as CborMapValue<CborObject, CborObject>;
  final keys = cb.value.keys.map((e) => e).toList();
  final keysDec = dec.value.keys.map((e) => e.value).toList();
  assert(CompareUtils.iterableIsEqual(keys, keysDec));
  final values = cb.value.values.map((e) => e).toList();
  final valuesDec = dec.value.values.map((e) => e.value).toList();
  assert(CompareUtils.iterableIsEqual(values, valuesDec));
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
  assert(dec is CborListValue);

  dec as CborListValue;
  final valuesDec = dec.value.map((e) => e.value).toList();
  assert(CompareUtils.iterableIsEqual(cb.value, valuesDec));
}

void _decodeDateTime() {
  final cb = CborStringDateValue(DateTime.now());
  final decode = CborObject.fromCbor(cb.encode());
  assert(decode is CborStringDateValue);
  assert(cb.value.difference(decode.value).inMilliseconds == 0);
  final cb2 = CborEpochFloatValue(DateTime.now());
  final decode2 = CborObject.fromCbor(cb2.encode());
  assert(decode2 is CborEpochFloatValue);
  assert(cb2.value.difference(decode2.value).inMilliseconds == 0);

  final cb3 = CborEpochIntValue(DateTime.now());
  final decode3 = CborObject.fromCbor(cb3.encode());
  assert(decode3 is CborEpochIntValue);
  assert(cb3.value.difference(decode3.value).inSeconds == 0);
}

void cborTest() {
  // some decode test
  _decodeInt();
  _decodeFloat();
  _decodeString();
  _decodeStringIndefinite();
  _decodeMap();
  _decodeMapDynamic();
  _decodeList();
  _decodeDateTime();

  assert(CborListValue.fixedLength(_testList1).encode().toHex() ==
      "8400006a6d72746e6574776f726bc24a021e19e0c9bab2400000");
  assert(CborListValue.dynamicLength(_testList1).encode().toHex() ==
      "9f00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
  assert(CborMapValue.dynamicLength(_mapTest1).encode().toHex() ==
      "bf00006a6d72746e6574776f726bc24a021e19e0c9bab2400000ff");
  assert(CborMapValue.fixedLength(_mapTest1).encode().toHex() ==
      "a200006a6d72746e6574776f726bc24a021e19e0c9bab2400000");
  assert(const CborIntValue(1).encode().toHex() == "01");
  assert(const CborIntValue(-1).encode().toHex() == "20");
  assert(const CborIntValue(1000000000000000).encode().toHex() ==
      "1b00038d7ea4c68000");
  assert(CborSafeIntValue(BigInt.from(-1000000000000000)).encode().toHex() ==
      "3b00038d7ea4c67fff");
  assert(CborBigIntValue(BigInt.parse("1")).encode().toHex() == "c24101");
  assert(CborBigIntValue(BigInt.parse("-1")).encode().toHex() == "c340");
  assert(CborStringValue("MRTNETWORK").encode().toHex() ==
      "6a4d52544e4554574f524b");
  assert(CborBytesValue(BytesUtils.fromHexString("1b00038d7ea4c68000"))
          .encode()
          .toHex() ==
      "491b00038d7ea4c68000");
  assert(CborFloatValue(1.0).encode().toHex() == "f93c00");
  assert(CborFloatValue.from64BytesFloat(123123123123.2).encode().toHex() ==
      "fb423caab5c3b33333");
  assert(CborDecimalFracValue(BigInt.one, BigInt.one).encode().toHex() ==
      "c4820101");
  assert(CborListValue.fixedLength([BigInt.one, BigInt.one]).encode().toHex() ==
      "82c24101c24101");

  assert(CborMapValue.fixedLength({0: 0}).encode().toHex() == "a10000");
  assert(
      CborMapValue.fixedLength({const CborIntValue(0): const CborIntValue(0)})
              .encode()
              .toHex() ==
          "a10000");
}
