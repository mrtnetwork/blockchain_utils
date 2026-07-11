import 'package:blockchain_utils/cbor/cbor.dart';

extension ExtCborBigint on BigInt {
  CborBigIntValue toCbor() {
    return CborBigIntValue(this);
  }
}

extension ExtCborInt on int {
  CborIntValue toCbor() {
    return CborIntValue(this);
  }
}

extension ExtCborString on String {
  CborStringValue toCbor() {
    return CborStringValue(this);
  }
}

extension ExtCborDouble on double {
  CborFloatValue toCbor() {
    return CborFloatValue(this);
  }
}

extension ExtCborDateTime on DateTime {
  CborEpochIntValue toCbor() {
    return CborEpochIntValue(this);
  }
}

extension ExtCborBytes on List<int> {
  CborBytesValue toCborBytes() {
    return CborBytesValue(this);
  }
}

extension ExtCborBoolean on bool {
  CborBoleanValue toCbor() {
    return CborBoleanValue(this);
  }
}

extension ExtCborListString on List<String> {
  CborListValue<CborStringValue> toCbor() {
    return CborListValue.definite(map((e) => CborStringValue(e)).toList());
  }
}

extension ExtCborMap on Map<String, String?> {
  CborMapValue<CborString, CborObject> toCbor() {
    return CborMapValue.definite(
      map(
        (k, v) => MapEntry<CborStringValue, CborObject>(
          k.toCbor(),
          v?.toCbor() ?? CborNullValue(),
        ),
      ),
    );
  }
}

extension ExtCborMapDynamic on Map<String, dynamic> {
  CborMapValue<CborString, CborObject> toCbor(
    CborObject Function(Object obj) mapper,
  ) {
    return CborMapValue.definite(
      map(
        (k, v) => MapEntry<CborStringValue, CborObject>(k.toCbor(), switch (v) {
          null => CborNullValue(),
          _ => mapper(v),
        }),
      ),
    );
  }
}
