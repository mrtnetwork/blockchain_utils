import 'package:blockchain_utils/encoding/cbor/cbor.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';
import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

extension ExtCborBigint on BigInt {
  CborBigIntValue toCbor() {
    return CborBigIntValue(this);
  }

  CborSafeIntValue toSafeIntCbor() {
    if ((isNegative && this < BinaryOps.minInt64) || this > BinaryOps.maxU64) {
      throw BuError(
        DefaultErrorType.invalidLength,
        "Invalid integer value.",
        details: {"reason": "Value is too large for type int."},
      );
    }
    return CborSafeIntValue(this);
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

extension ExtCborBuBytes on BuBytes {
  CborBytesValue toCbor() {
    return CborBytesValue(this);
  }

  CborBytesValue toCborUnsafe() {
    return CborBytesValue.unsafe(this);
  }
}

extension ExCbortSecretBytes on SecretBytes {
  CborBytesValue toCbor() {
    return CborBytesValue.unsafe(toBytes());
  }
}

extension ExtCborBoolean on bool {
  CborBooleanValue toCbor() {
    return CborBooleanValue(this);
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
