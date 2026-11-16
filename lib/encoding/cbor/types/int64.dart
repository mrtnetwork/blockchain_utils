import 'package:blockchain_utils/encoding/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/encoding/cbor/types/types.dart';
import 'package:blockchain_utils/encoding/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/encoding/cbor/core/tags.dart';
import 'package:blockchain_utils/encoding/cbor/core/cbor.dart';
import 'package:blockchain_utils/helper/extensions/extensions.dart';
import 'package:blockchain_utils/utils/binary/src/binary_operation.dart';

import 'package:blockchain_utils_connector/blockchain_utils_connector.dart';

/// A class representing a CBOR (Concise Binary Object Representation) int (64-bit) value.
class CborSafeIntValue extends CborNumeric<BigInt> {
  /// Constructor for creating a CborSafeIntValue instance with the provided parameters.
  /// It accepts the BigInt value.
  const CborSafeIntValue(super.value);

  factory CborSafeIntValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  BuBytes encode() {
    if ((value.isNegative && value < BinaryOps.minInt64) ||
        value > BinaryOps.maxU64) {
      throw BuError(DefaultErrorType.invalidLength,
        "Invalid integer value.",
        details: {"reason": "Value is too large for type int."},
      );
    }
    if (value.isSafeInt()) {
      return CborIntValue(value.toInt()).encode();
    }
    final bytes = CborBytesTracker();
    bytes.pushMajorTag(
      value.isNegative ? MajorTags.negInt : MajorTags.posInt,
      NumBytes.eight,
    );
    bytes.pushUint64(value.isNegative ? ~value : value);
    return bytes.buffer();
  }

  /// value as bigint
  @override
  BigInt toBigInt() {
    return value;
  }

  /// value as int
  @override
  int toInt() {
    return value.toInt();
  }

  @override
  String toString() {
    return "CborSafeIntValue($value)";
  }
}
