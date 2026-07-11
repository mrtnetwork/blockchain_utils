import 'package:blockchain_utils/cbor/utils/cbor_utils.dart';

import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) int (64-byte) value.
class CborSafeIntValue extends CborNumeric<BigInt> {
  /// Constructor for creating a CborInt64Value instance with the provided parameters.
  /// It accepts the Bigint value.
  const CborSafeIntValue(super.value);

  factory CborSafeIntValue.decode(List<int> bytes) {
    return CborUtils.decodeCbor(bytes);
  }

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    if (value.isValidInt) {
      return CborIntValue(value.toInt()).encode();
    }
    final bytes = CborBytesTracker();
    bytes.pushMajorTag(
      value.isNegative ? MajorTags.negInt : MajorTags.posInt,
      NumBytes.eight,
    );
    bytes.pushBigint(value.isNegative ? ~value : value);
    return bytes.toBytes();
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
