import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) int value.
class CborIntValue implements CborNumeric {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the int value and an optional list of CBOR tags.
  const CborIntValue(this.value, [this.tags = const []]);

  /// value as int
  @override
  final int value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushTags(tags);
    bytes.pushInt(value.isNegative ? MajorTags.negInt : MajorTags.posInt,
        value.isNegative ? ~value : value);
    return bytes.toBytes();
  }

  /// value as bigint
  @override
  BigInt toBigInt() {
    return BigInt.from(value);
  }

  /// value as int
  @override
  int toInt() {
    return value;
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

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborIntValue) return false;
    return value == other.value && bytesEqual(tags, other.tags);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
