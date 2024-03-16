import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/types/types.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) int (64-byte) value.
class CborSafeIntValue implements CborNumeric {
  /// Constructor for creating a CborInt64Value instance with the provided parameters.
  /// It accepts the Bigint value.
  const CborSafeIntValue(this.value);

  /// value as bigint
  @override
  final BigInt value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    if (value.isValidInt) {
      return CborIntValue(value.toInt()).encode();
    }
    final bytes = CborBytesTracker();
    bytes.pushMajorTag(
        value.isNegative ? MajorTags.negInt : MajorTags.posInt, NumBytes.eight);
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

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toString();
  }

  /// override equal operation
  @override
  operator ==(other) {
    if (other is! CborNumeric) return false;
    if (other is CborBigIntValue) return false;
    return toBigInt() == other.toBigInt();
  }

  /// override hashcode
  @override
  int get hashCode => value.hashCode;
}
