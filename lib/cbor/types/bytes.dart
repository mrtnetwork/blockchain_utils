import 'package:blockchain_utils/utils/utils.dart';
import 'package:blockchain_utils/cbor/utils/dynamic_bytes.dart';
import 'package:blockchain_utils/cbor/core/tags.dart';
import 'package:blockchain_utils/cbor/core/cbor.dart';

/// A class representing a CBOR (Concise Binary Object Representation) bytes value.
class CborBytesValue implements CborObject {
  /// Constructor for creating a CborBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  const CborBytesValue(this.value);

  /// The value as a List<int>.
  @override
  final List<int> value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushInt(MajorTags.byteString, value.length);
    bytes.pushBytes(value);
    return bytes.toBytes();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborBytesValue) return false;

    return BytesUtils.bytesEqual(other.value, value);
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}

/// A class representing a CBOR (Concise Binary Object Representation) bytes value with indefinite tag.
class CborDynamicBytesValue implements CborObject {
  /// Constructor for creating a CborDynamicBytesValue instance with the provided parameters.
  /// It accepts the bytes value.
  const CborDynamicBytesValue(this.value);

  /// The value as a List<List<int>>.
  @override
  final List<List<int>> value;

  /// Encode the value into CBOR bytes
  @override
  List<int> encode() {
    final bytes = CborBytesTracker();
    bytes.pushIndefinite(MajorTags.byteString);
    for (final v in value) {
      bytes.pushInt(MajorTags.byteString, v.length);
      bytes.pushBytes(v);
    }
    bytes.breakDynamic();
    return bytes.toBytes();
  }

  /// Returns the string representation of the value.
  @override
  String toString() {
    return value.toString();
  }

  /// Encode the value into CBOR bytes an then to hex
  @override
  String toCborHex() {
    return BytesUtils.toHexString(encode());
  }

  /// overide equal operation
  @override
  operator ==(other) {
    if (other is! CborDynamicBytesValue) return false;

    return value == other.value;
  }

  /// ovveride hash code
  @override
  int get hashCode => value.hashCode;
}
