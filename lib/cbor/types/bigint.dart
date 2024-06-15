import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Bigint value.
class CborBigIntValue implements CborNumeric {
  /// Constructor for creating a CborBigIntValue instance with the provided parameters.
  /// It accepts the bigint value.
  const CborBigIntValue(this.value);

  /// The value as a bigint.
  @override
  final BigInt value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    BigInt v = value;
    if (v.isNegative) {
      bytes.pushTags(CborTags.negBigInt);
      v = ~v;
    } else {
      bytes.pushTags(CborTags.posBigInt);
    }
    final toBytes =
        BigintUtils.toBytes(v, length: BigintUtils.bitlengthInBytes(v));
    bytes.pushInt(MajorTags.byteString, toBytes.length);
    bytes.pushBytes(toBytes);
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

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborBigIntValue) return false;

    return value == other.value;
  }

  /// overide hash code
  @override
  int get hashCode => value.hashCode;
}
