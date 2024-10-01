import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/cbor/exception/exception.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/utils/utils.dart';

import 'bigint.dart';

/// A class representing a CBOR (Concise Binary Object Representation) int value.
class CborIntValue implements CborNumeric {
  /// Constructor for creating a CborDecimalFracValue instance with the provided parameters.
  /// It accepts the int value.
  const CborIntValue(this.value);

  /// value as int
  @override
  final int value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    if (value.bitLength > 31 && value.isNegative) {
      final value = (~BigInt.parse(this.value.toString()));
      if (!value.isValidInt) {
        throw CborException("Value is to large for encoding as CborInteger",
            details: {"value": this.value.toString()});
      }
      bytes.pushInt(MajorTags.negInt, value.toInt());
    } else {
      bytes.pushInt(value.isNegative ? MajorTags.negInt : MajorTags.posInt,
          value.isNegative ? ~value : value);
    }
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
    if (other is! CborNumeric) return false;
    if (other is CborBigIntValue) return false;
    return toBigInt() == other.toBigInt();
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
