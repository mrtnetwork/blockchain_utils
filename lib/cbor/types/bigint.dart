import 'package:blockchain_utils/binary/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';
import 'package:blockchain_utils/compare/compare.dart';

/// A class representing a CBOR (Concise Binary Object Representation) Bigint value.
class CborBigIntValue implements CborNumeric {
  /// Constructor for creating a CborBigIntValue instance with the provided parameters.
  /// It accepts the bigint value, and an optional list of CBOR tags.
  const CborBigIntValue(this.value, [this.tags = const []]);

  /// The value as a bigint.
  @override
  final BigInt value;

  /// List of CBOR tags associated with the URL value.
  @override
  final List<int> tags;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    BigInt v = value;
    if (tags.isEmpty) {
      if (v.isNegative) {
        bytes.pushTags([CborTags.negBigInt]);
        v = ~v;
      } else {
        bytes.pushTags([CborTags.posBigInt]);
      }
    }
    final b = List<int>.filled((v.bitLength + 7) ~/ 8, 0);

    for (var i = b.length - 1; i >= 0; i--) {
      b[i] = v.toUnsigned(8).toInt();
      v >>= 8;
    }
    bytes.pushInt(MajorTags.byteString, b.length);
    bytes.pushBytes(b);
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

    return value == other.value && bytesEqual(tags, other.tags);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
