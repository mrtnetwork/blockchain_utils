import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Bigint value.
class CborBigIntValue extends CborNumeric<BigInt> {
  /// Specifies whether the CBOR length encoding should be canonical or non-canonical.
  /// For bignum values, this only affects the value `0`:
  /// - In canonical form, zero is encoded with a 0-byte length.
  /// - In non-canonical form, zero is encoded with a 1-byte length (`0x00`).
  final CborLengthEncoding encoding;

  /// Constructor for creating a CborBigIntValue instance with the provided parameters.
  /// It accepts the bigint value.
  const CborBigIntValue(super.value,
      {this.encoding = CborLengthEncoding.canonical});

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
    final toBytes = BigintUtils.toBytes(v,
        length: v == BigInt.zero && encoding == CborLengthEncoding.nonCanonical
            ? 1
            : BigintUtils.bitlengthInBytes(v));
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
